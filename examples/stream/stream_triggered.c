/**
 * Name: stream_triggered.c
 * Desc: Demonstrates triggered stream on DIO0 / FIO0.
**/

#include <stdio.h>
#include <string.h>

#include <LabJackM.h>

#include "LJM_StreamUtilities.h"

#define SCAN_RATE 1000
const int SCANS_PER_READ = SCAN_RATE / 2;

enum { NUM_CHANNELS = 4 };

// Because SYSTEM_TIMER_20HZ is a 32-bit value and stream can only collect
// 16-bit values per channel, STREAM_DATA_CAPTURE_16 is used to capture the
// final 16 bits of SYSTEM_TIMER_20HZ. See HardcodedPrintScans().
const char * POS_NAMES[] = {
	"AIN0",  "FIO_STATE",  "SYSTEM_TIMER_20HZ", "STREAM_DATA_CAPTURE_16"
};

const int NUM_LOOP_ITERATIONS = 10;

void StreamTriggered(int handle);

/**
 * Prints a scan of the channels:
 *     "AIN0",  "FIO_STATE",  "SYSTEM_TIMER_20HZ", "STREAM_DATA_CAPTURE_16".
 * Combines SYSTEM_TIMER_20HZ and STREAM_DATA_CAPTURE_16 to create the original
 * 32-bit value of SYSTEM_TIMER_20HZ.
**/
void HardcodedPrintScans(const char ** chanNames, const double * aData,
	int numScansReceived, int numChannelsPerScan, int deviceScanBacklog,
	int LJMScanBacklog);

int main()
{
	int handle;

	// Open first found LabJack
	handle = OpenOrDie(LJM_dtANY, LJM_ctANY, "LJM_idANY");
	// handle = OpenSOrDie("LJM_dtANY", "LJM_ctANY", "LJM_idANY");

	PrintDeviceInfoFromHandle(handle);
	printf("\n");

	DisableStreamIfEnabled(handle);

	StreamTriggered(handle);

	CloseOrDie(handle);

	WaitForUserIfWindows();

	return LJME_NOERROR;
}

void StreamTriggered(int handle)
{
	int err;

	// Variables for LJM_eStreamStart
	double scanRate = SCAN_RATE;
	int * aScanList = malloc(sizeof(int) * NUM_CHANNELS);

	// Variables for LJM_eStreamRead
	unsigned int aDataSize = NUM_CHANNELS * SCANS_PER_READ;
	double * aData = malloc(sizeof(double) * aDataSize);
	int deviceScanBacklog = 0;
	int LJMScanBacklog = 0;
	int streamRead = 0;
	double value = 0;

	err = LJM_NamesToAddresses(NUM_CHANNELS, POS_NAMES, aScanList, NULL);
	ErrorCheck(err, "Getting positive channel addresses");

	// Configure LJM for unpredictable stream timing
	SetConfigValue(LJM_STREAM_SCANS_RETURN, LJM_STREAM_SCANS_RETURN_ALL_OR_NONE);
	SetConfigValue(LJM_STREAM_RECEIVE_TIMEOUT_MS, 0);

	// 2000 sets DIO0 / FIO0 as the stream trigger
	WriteNameOrDie(handle, "STREAM_TRIGGER_INDEX", 2000);

	// Clear any previous DIO0_EF settings
	WriteNameOrDie(handle, "DIO0_EF_ENABLE", 0);

	// 5 enables a rising or falling edge to trigger stream
	WriteNameOrDie(handle, "DIO0_EF_INDEX", 5);

	// Enable DIO0_EF
	WriteNameOrDie(handle, "DIO0_EF_ENABLE", 1);

	err = LJM_eStreamStart(handle, SCANS_PER_READ, NUM_CHANNELS, aScanList,
		&scanRate);
	ErrorCheck(err, "LJM_eStreamStart");

	printf("You can trigger stream now via a rising or falling edge on DIO0 / FIO0.\n");
	printf("(Press ctrl + c to cancel.)\n");

	while (streamRead < NUM_LOOP_ITERATIONS) {
		VariableStreamSleep(SCANS_PER_READ, SCAN_RATE, LJMScanBacklog);

		err = LJM_eStreamRead(handle, aData, &deviceScanBacklog, &LJMScanBacklog);
		if (err == LJME_NO_SCANS_RETURNED) {
			printf(".");
			fflush(stdout);
		}
		else {
			ErrorCheck(err, "LJM_eStreamRead");
			printf("\niteration: %d    ", streamRead);
			HardcodedPrintScans(POS_NAMES, aData, SCANS_PER_READ, NUM_CHANNELS,
				deviceScanBacklog, LJMScanBacklog);
			++streamRead;
		}

		err = LJM_eReadName(handle, "STREAM_ENABLE", &value);
		ErrorCheck(err, "LJM_eReadName(%d, STREAM_ENABLE, ...", handle);
		if (!value) {
			printf("\nSTREAM_ENABLE is disabled.\n");
			printf("  This means the device reset or another program disabled stream.\n");
			printf("  Exiting stream read loop now.\n");
			break;
		}
	}

	err = LJM_eStreamStop(handle);
	ErrorCheck(err, "Stopping stream");

	free(aData);
	free(aScanList);

	printf("\nDone with %d iterations\n", NUM_LOOP_ITERATIONS);
}

void HardcodedPrintScans(const char ** chanNames, const double * aData,
	int numScansReceived, int numChannelsPerScan, int deviceScanBacklog,
	int LJMScanBacklog)
{
	int dataI, scanI;
	unsigned int timerValue;
	const int NUM_SCANS_TO_PRINT = 1;

	if (numChannelsPerScan < 4 || numChannelsPerScan > 4) {
		printf("%s:%d - HardcodedPrintScans() - unexpected numChannelsPerScan: %d\n",
			__FILE__, __LINE__, numChannelsPerScan);
		return;
	}

	printf("devBacklog: % 4d - LJMBacklog: % 4d  - %d of %d scans: \n",
		deviceScanBacklog, LJMScanBacklog, NUM_SCANS_TO_PRINT, numScansReceived);
	for (scanI = 0; scanI < NUM_SCANS_TO_PRINT; scanI++) {
		for (dataI = 0; dataI < 2; dataI++) {
			printf(" % 4.03f (%s),", aData[scanI * 4 + dataI], chanNames[dataI]);
		}

		if (strcmp(chanNames[2], "SYSTEM_TIMER_20HZ") != 0
			|| strcmp(chanNames[3], "STREAM_DATA_CAPTURE_16") != 0)
		{
			printf("%s:%d - HardcodedPrintScans() - unexpected register: %s and/or %s\n",
				__FILE__, __LINE__, chanNames[2], chanNames[3]);
			return;
		}

		// Combine CORE_TIMER's lower byte and STREAM_DATA_CAPTURE_16, which
		// contains CORE_TIMER's upper byte
		timerValue = ((unsigned short) aData[scanI * 4 + 3] << 16) +
			(unsigned short) aData[scanI * 4 + 2];
		printf("  0x%8X (%s)", timerValue, chanNames[2]);

		printf("\n");
	}
}
