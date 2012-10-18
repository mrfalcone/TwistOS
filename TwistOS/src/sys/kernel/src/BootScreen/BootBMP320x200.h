/***************************************************************************
 * BootBMP320x200.h
 * -------------------------
 * Models a boot screen image that is 320x200 with 256 colors, using the
 * default VGA palette. Implemented in assembly.
 *
 *
 * Author   : Mike Falcone
 * E-mail   : mr.falcone@gmail.com
 * Modified : 05/18/2009
 ***************************************************************************/
 
#ifndef _BOOTBMP320X200_H_
#define _BOOTBMP320X200_H_


class BootBMP320x200{

public:
	BootBMP320x200();
	
	void UpdateProgress();
	const char* GetScreenBuffer();


};

#endif // _BOOTBMP320X200_H_
