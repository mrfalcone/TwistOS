/***************************************************************************
 * KernelDriver.cpp
 * -------------------------
 * Defines int main(). Creates TwistKernel object and executes the kernel.
 *
 *
 * Author   : Mike Falcone
 * E-mail   : mr.falcone@gmail.com
 * Modified : 05/08/2009
 ***************************************************************************/

#include "TwistKernel.h"


// this structure stores information needed by the kernel from the kernel loader
struct BootStruct{

	int execMode;				// kernel's execution mode
	int memInKB;				// total installed RAM in KB
	int totalMemPages;			// total number of available memory pages upon boot
	int freeMemPages;			// number of free physical memory pages
	int *pAddressStack;			// pointer to the top of the address stack
	int *pPageDirectory;		// pointer to the page directory table
	const char *devDriver;		// device driver filename
	int *pDevDriver;			// pointer to the device driver
	const char *fsDriver;		// filesystem driver filename
	int *pFSDriver;				// pointer to the filesystem driver
};



// entry point into kernel application
int main(BootStruct *boot){

	// create and initialize kernel object
	TwistKernel kernel;
	kernel.Initialize();
	
	
	
	// hang system, we should never get to this point:
	while(1);

	return 0;
}

