/**
 * Name: eReadNameArray.c
 * Desc: Shows how to use the LJM_eReadNameArray function
**/

// For printf
#include <stdio.h>

// For the LabJackM Library
#include <LabJackM.h>

// For LabJackM helper functions, such as OpenOrDie, PrintDeviceInfoFromHandle,
// ErrorCheck, etc.
#include "LJM_Utilities.h"

int main()
{
	int err, i, handle;

	#define NUM_VALUES 3

	const char * NAME = "AIN0";
	const char * BASE_NAME = "AIN";
	double aValues[NUM_VALUES] = {0.0, 0.0, 0.0};

	int errorAddress = INITIAL_ERR_ADDRESS;

	// Open first found LabJack
	err = LJM_Open(LJM_dtANY, LJM_ctANY, "LJM_idANY", &handle);
	ErrorCheck(err, "LJM_Open");

	PrintDeviceInfoFromHandle(handle);
	printf("\nLJM_eReadNameArray(Handle=%d, Name=%s, NumValues=%d, ...):\n", handle,
		NAME, NUM_VALUES);

	err = LJM_eReadNameArray(handle, NAME, NUM_VALUES, aValues, &errorAddress);
	ErrorCheckWithAddress(err, errorAddress, "LJM_eReadNameArray");

	// Print results
	for (i = 0; i < NUM_VALUES; i++) {
		printf("%s%d: %f\n", BASE_NAME, i, aValues[i]);
	}

	err = LJM_Close(handle);
	ErrorCheck(err, "LJM_Close");

	WaitForUserIfWindows();

	return LJME_NOERROR;
}
