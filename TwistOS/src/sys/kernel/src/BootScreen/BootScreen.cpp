#include "BootScreen.h"

#include <cstring>	// included for memcpy()

#if VIDEO_MODE == 0x13
	#include "BootBMP320x200.h"
#endif





/*** Inline Assembly ***/
/***********************/

/* use the kernel's INT86 interrupt to run the BIOS video interrupt to set
   the display mode to specified value */
#define SetVideoMode(mode) \
__asm__ __volatile__ \
	(	"pushal\n\t" \
		"movb $0x0,%%ah\n\t" \
		"movl $0x10,%%esi\n\t" \
		"int $86\n\t" \
		"popal" \
		:   \
		: "a" (mode) \
	)


	
/*************************************
 *** BEGIN PUBLIC MEMBER FUNCTIONS ***
 *************************************/

BootScreen::BootScreen(){
	
	SetVideoMode(VIDEO_MODE);
	
	// setup pointer used to access video memory
	mScreenMem = (char*)VIDEO_MEMORY;
	
	
	#if VIDEO_MODE == 0x13
		BootBMP320x200 bmp;
	#endif
	
	mBootBMP = &bmp;
	

	DrawScreen();
}



/**************************************
 *** BEGIN PRIVATE MEMBER FUNCTIONS ***
 **************************************/
 
 void BootScreen::DrawScreen(){
	
	// get the bytes from the bitmap and copy them to the screen's memory
	memcpy(mScreenMem, mBootBMP->GetScreenBuffer(), VIDMEM_LIMIT);
}



