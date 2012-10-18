#include "TwistKernel.h"

#include "InterruptInterface.h"
#include "HardwareInterface.h"

#include "BootScreen/BootScreen.h"


/*************************************
 *** BEGIN PUBLIC MEMBER FUNCTIONS ***
 *************************************/
 
TwistKernel::TwistKernel(){

	// create the exception interface object
	InterruptInterface intInterface(&TwistKernel::OnPageFault, &TwistKernel::OnInterrupt);
	mInterruptInterface = &intInterface;
	
	HardwareInterface hwInterface;
	
	
	
}



void TwistKernel::Initialize(){

// asm("int $14");

	// load the boot screen and begin initializing the kernel
	BootScreen bootScreen;
	
	
	
	
	
}






/**************************************
 *** BEGIN PRIVATE MEMBER FUNCTIONS ***
 **************************************/

 

void TwistKernel::Die(const char *reason){

	// abort the system
	mInterruptInterface->Abort(reason);
}





/*** Functions for interrupt interface ***/

BOOL TwistKernel::OnPageFault(){
	
	// returns FALSE when page fault could not be corrected
	return FALSE;
}


void TwistKernel::OnInterrupt(int intCode){
	
	
}

