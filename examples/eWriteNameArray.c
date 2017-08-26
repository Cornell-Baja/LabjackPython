/**
 * Name: eWriteNameArray.c
 * Desc: Shows how to use the LJM_eWriteNameArray function
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
	int err, handle;

	#define NUM_VALUES 2

	// DAC1 is the address after DAC0 in an array write
	const char * NAME = "DAC0";
	double aValues[NUM_VALUES] = {1.2, 3.4};

	int errorAddress = INITIAL_ERR_ADDRESS;

	// Open first found LabJack
	err = LJM_Open(LJM_dtANY, LJM_ctANY, "LJM_idANY", &handle);
	ErrorCheck(err, "LJM_Open");

	PrintDeviceInfoFromHandle(handle);
	printf("\nLJM_eWriteNameArray(Handle=%d, Name=%s, NumValues=%d, aValues=[%f, %f], ...)\n", handle,
		NAME, NUM_VALUES, aValues[0], aValues[1]);

	err = LJM_eWriteNameArray(handle, NAME, NUM_VALUES, aValues, &errorAddress);
	ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteNameArray");

	err = LJM_Close(handle);
	ErrorCheck(err, "LJM_Close");

	WaitForUserIfWindows();

	return LJME_NOERROR;
}
