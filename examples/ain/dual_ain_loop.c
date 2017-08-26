/**
 * Name: dual_ain_loop.c
 * Desc: Demonstrates reading 2 analog inputs (AINs) in a loop from a LabJack.
**/

// For printf
#include <stdio.h>

// For the LabJackM Library
#include <LabJackM.h>

// For LabJackM helper functions, such as OpenOrDie, PrintDeviceInfoFromHandle,
// ErrorCheck, etc., such as OpenOrDie, PrintDeviceInfoFromHandle,
// ErrorCheck, etc.
#include "../LJM_Utilities.h"

int main()
{
	int err;
	int handle;
	int i;
	int errorAddress = INITIAL_ERR_ADDRESS;

	// Set up for configuring the AINs
	// AIN0 and AIN1:
	//   Negative channel = single ended (199)
	//   Range: +/-10.0 V (10.0). T4 note: Only AIN0-AIN3 can support +/-10 V range.
	//   Resolution index = Default (0)
	//   Settling, in microseconds = Auto (0)
	enum { NUM_FRAMES_CONFIG = 8 };
	const char * aNamesConfig[NUM_FRAMES_CONFIG] = \
		{"AIN0_NEGATIVE_CH", "AIN0_RANGE", "AIN0_RESOLUTION_INDEX", "AIN0_SETTLING_US",
		 "AIN1_NEGATIVE_CH", "AIN1_RANGE", "AIN1_RESOLUTION_INDEX", "AIN1_SETTLING_US"};
	const double aValuesConfig[NUM_FRAMES_CONFIG] = {199, 10, 0, 0,
													 199, 10, 0, 0};

	// Set up for reading AIN values
	enum { NUM_FRAMES_AIN = 2 };
	double aValuesAIN[NUM_FRAMES_AIN] = {0};
	const char * aNamesAIN[NUM_FRAMES_AIN] = {"AIN0", "AIN1"};

	int msDelay = 1000;

	// Open first found LabJack
	handle = OpenOrDie(LJM_dtANY, LJM_ctANY, "LJM_idANY");
	// handle = OpenSOrDie("LJM_dtANY", "LJM_ctANY", "LJM_idANY");

	PrintDeviceInfoFromHandle(handle);

	// Setup and call eWriteNames to configure AINs on the LabJack.
	err = LJM_eWriteNames(handle, NUM_FRAMES_CONFIG, aNamesConfig, aValuesConfig,
		&errorAddress);
	ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteNames");

	printf("\nSet configuration:\n");
	for (i=0; i<NUM_FRAMES_CONFIG; i++) {
		printf("    %s : %f\n", aNamesConfig[i], aValuesConfig[i]);
	}

	printf("\nStarting read loop.  Press Ctrl+c to stop.\n");

	// Note: The LabJackM (LJM) library will catch the Ctrl+c signal, close
	//       all open devices, then exit the program.
	while (1) {
		// Read AIN from the LabJack
		err = LJM_eReadNames(handle, NUM_FRAMES_AIN, aNamesAIN, aValuesAIN,
			&errorAddress);
		ErrorCheckWithAddress(err, errorAddress, "LJM_eReadNames");

		printf("%s : %f V, %s : %f V\n", aNamesAIN[0], aValuesAIN[0],
			aNamesAIN[1], aValuesAIN[1]);

		// This loop will not happen every msDelay - it will actually take
		// longer because of the work being done between MillisecondSleep calls
		// and the variability of the operating system's scheduler. To loop
		// accurately at a specific frequency, a periodic/interval timer or
		// stream mode must be used.
		MillisecondSleep(msDelay);
	}

	CloseOrDie(handle);

	WaitForUserIfWindows();

	return LJME_NOERROR;
}
