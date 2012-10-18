#ifndef _MAKEIMAGE_H_
#define _MAKEIMAGE_H_

#define SECTOR_SIZE 2048

#define BOOT_SECTOR_FILE	"boot.bin"


#include <fstream>

#include "Directory.h"
#include "File.h"

#include "AnyEndianNumber.h"

#include "PathTable.h"



class MakeImage{

public:
	
	MakeImage();

	void Build(Directory *root, const char *filename, int totalBlocks);


private:

	void WriteSector(ofstream &stream, int sectorNum, char *data);

	void MakePrimaryVolumeDescriptor(char *bytes, int totalBlocks, int pathTableSize);
	void MakeBootVolumeDescriptor(char *bytes);
	void MakeTerminatorVolumeDescriptor(char *bytes);
	void MakeBootCatalog(char *bytes);
	void MakeBootSector(char *bytes);

	void WriteFiles(Directory *root, ofstream &out);


	int mLPathSector;		// sector num of type L path table
	int mMPathSector;		// sector num of type M path table

	int mPrimaryVolSector;
	int mBootCatSector;
	int mBootVolSector;
	int mTermVolSector;
	int mBootSector;

	int mBlockCount;		// number of blocks on the disk


	Directory *mRootDir;

};



#endif // _MAKEIMAGE_H_