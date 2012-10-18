/***************************************************************************
 * BootScreen.h
 * -------------------------
 * Models a boot screen to be displayed at OS initialization.
 *
 *
 * Author   : Mike Falcone
 * E-mail   : mr.falcone@gmail.com
 * Modified : 05/20/2009
 ***************************************************************************/
 
#ifndef _BOOTSCREEN_H_
#define _BOOTSCREEN_H_


#define VIDEO_MODE		0x13	// video mode used as parameter for BIOS INT 0x10


#if VIDEO_MODE == 0x13
	#define VIDEO_MEMORY	0x000A0000
	#define SCREEN_HEIGHT	320
	#define SCREEN_WIDTH	200
	#define VIDMEM_LIMIT	SCREEN_HEIGHT*SCREEN_WIDTH		// number of bytes in video memory
#endif



// forward declaration for boot bitmap
#if VIDEO_MODE == 0x13
	class BootBMP320x200;
#endif




class BootScreen{

public:
	BootScreen();

	
private:
	void DrawScreen();
	
	
	char *mScreenMem;				// this array will be used to access video memory
	
	
	#if VIDEO_MODE == 0x13
		BootBMP320x200 *mBootBMP;	// bitmap object to display as the boot screen
	#endif
};




#endif // _BOOTSCREEN_H_
