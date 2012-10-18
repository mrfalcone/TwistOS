#include "MakeImage.h"


MakeImage::MakeImage(){

	mLPathSector = 21;
	mMPathSector = 22;

	mPrimaryVolSector = 16;
	mBootVolSector = 17;
	mTermVolSector = 18;

	mBootCatSector = 19;
	mBootSector = 20;

}


void MakeImage::Build(Directory *root, const char *filename, int totalBlocks){

	mRootDir = root;

	ofstream outFile;
	outFile.open(filename, ios_base::binary | ios_base::trunc);
	

	char *sector = 0;


	int pathTableSize = 0;
	char *rootPathEntry = 0;


	//=======================
	// write path table
	PathTable *table = new PathTable(mRootDir);

	sector = new char[SECTOR_SIZE];					// create char array
	ZeroMemory(sector, SECTOR_SIZE);				// clear to 0
	table->MakeTable(sector, PathTable::TYPE_L);	// make type L path table
	WriteSector(outFile, mLPathSector, sector);		// write it to file
	delete [] sector;								// delete char array

	sector = new char[SECTOR_SIZE];					// create char array
	ZeroMemory(sector, SECTOR_SIZE);				// clear to 0
	table->MakeTable(sector, PathTable::TYPE_M);	// make type M path table
	WriteSector(outFile, mMPathSector, sector);		// write it to file
	delete [] sector;								// delete char array

	pathTableSize = table->GetSize();

	delete table;
	//=======================



	//=======================
	// write primary volume descriptor
	sector = new char[SECTOR_SIZE];					// create char array
	ZeroMemory(sector, SECTOR_SIZE);				// clear to 0
	MakePrimaryVolumeDescriptor(sector, totalBlocks, pathTableSize);
	WriteSector(outFile, mPrimaryVolSector, sector);	// write it to file

	delete [] sector;								// delete char array
	//=======================


	//=======================
	// write boot volume descriptor
	sector = new char[SECTOR_SIZE];					// create char array
	ZeroMemory(sector, SECTOR_SIZE);				// clear to 0
	MakeBootVolumeDescriptor(sector);				// make boot volume descriptor
	WriteSector(outFile, mBootVolSector, sector);	// write it to file

	delete [] sector;								// delete char array
	//=======================


	//=======================
	// write terminator volume descriptor
	sector = new char[SECTOR_SIZE];					// create char array
	ZeroMemory(sector, SECTOR_SIZE);				// clear to 0
	MakeTerminatorVolumeDescriptor(sector);			// make terminator volume descriptor
	WriteSector(outFile, mTermVolSector, sector);	// write it to file

	delete [] sector;								// delete char array
	//=======================


	//=======================
	// write boot catalog
	sector = new char[SECTOR_SIZE];					// create char array
	ZeroMemory(sector, SECTOR_SIZE);				// clear to 0
	MakeBootCatalog(sector);						// make boot catalog
	WriteSector(outFile, mBootCatSector, sector);	// write it to file

	delete [] sector;								// delete char array
	//=======================


	//=======================
	// write boot sector
	sector = new char[SECTOR_SIZE];					// create char array
	ZeroMemory(sector, SECTOR_SIZE);				// clear to 0
	MakeBootSector(sector);							// make boot sector
	WriteSector(outFile, mBootSector, sector);		// write it to file

	delete [] sector;								// delete char array
	//=======================


	WriteFiles(mRootDir, outFile);



	outFile.close();


	mRootDir = 0;

}



void MakeImage::WriteSector(ofstream &stream, int sectorNum, char *data){

	int writePos = sectorNum * SECTOR_SIZE;

	// get end of file pos
	stream.seekp(0, ios::end);
	int endPos = stream.tellp();

	if(endPos <= writePos){

		do{
			stream.put(0);
			endPos = stream.tellp();
		}
		while(endPos <= writePos);
	}


	stream.seekp(writePos);
	stream.seekp(0, ios_base::cur);

	stream.write(data, SECTOR_SIZE);

}




void MakeImage::MakePrimaryVolumeDescriptor(char *bytes, int totalBlocks, int pathTableSize){


	AnyEndianNumber *AENum = 0;


	*bytes = (char)0x01;								// volume descriptor type

	memcpy( (bytes + 1), "CD001", 5);				// standard identifier

	*(bytes+6) = (char)0x01;								// volume descriptor version
	
	// system identifier
	memcpy( (bytes + 8),  "BOOT DISK                       ", 32);


	// volume identifier
	memcpy( (bytes + 40), "TWIST_BOOT_CD                   ", 32);



	// set the volume space size
	AENum = new AnyEndianNumber( totalBlocks, AnyEndianNumber::ORDER_MIXED );

	AENum->GetNumber( (bytes+80) );

	delete AENum;


	
	// make volume set size and sequence number both 1
	AENum = new AnyEndianNumber( (short)1, AnyEndianNumber::ORDER_MIXED );

	// set volume set size
	AENum->GetNumber( (bytes+120) );

	// and volume sequence number
	AENum->GetNumber( (bytes+124) );

	delete AENum;
	


	AENum = new AnyEndianNumber( (short)SECTOR_SIZE, AnyEndianNumber::ORDER_MIXED );

	// set logical block size
	AENum->GetNumber( (bytes+128) );

	delete AENum;



	AENum = new AnyEndianNumber( pathTableSize, AnyEndianNumber::ORDER_MIXED );

	// set path table size
	AENum->GetNumber( (bytes+132) );

	delete AENum;


	AENum = new AnyEndianNumber( mLPathSector, AnyEndianNumber::ORDER_LEAST );

	// set type L path table location
	AENum->GetNumber( (bytes+140) );

	delete AENum;


	AENum = new AnyEndianNumber( mMPathSector, AnyEndianNumber::ORDER_MOST );

	// set type M path table location
	AENum->GetNumber( (bytes+148) );

	delete AENum;


	char rootPathEntry[34];		// root path entry can't be more than 34 or it won't fit
	ZeroMemory(&rootPathEntry, 34);

	mRootDir->CreatePathDescriptor(rootPathEntry, true);

	memcpy( (bytes+156), &rootPathEntry, 34 );
	

	// volume set identifier
	memset( (bytes+190), '_', 128 );

	// publisher identifier
	memcpy( (bytes + 318), "Mike Falcone                    ", 32);
	memcpy( (bytes + 350), "mr.falcone@gmail.com            ", 32);
	memcpy( (bytes + 382), "                                ", 32);
	memcpy( (bytes + 414), "                                ", 32);


	// data preparer identifier
	memcpy( (bytes + 446), "Mike Falcone                    ", 32);
	memcpy( (bytes + 478), "                                ", 32);
	memcpy( (bytes + 510), "                                ", 32);
	memcpy( (bytes + 542), "                                ", 32);


	// data preparer identifier
	memset( (bytes+574), 32, 239 );


	// file structure version
	*(bytes+881) = 1;

}


void MakeImage::MakeBootVolumeDescriptor(char *bytes){

	memcpy((bytes+1), "CD001", 5);

	*(bytes+6) = 1;

	memcpy((bytes+7), "EL TORITO SPECIFICATION", 23);

	*(bytes+71) = mBootCatSector;

}


void MakeImage::MakeTerminatorVolumeDescriptor(char *bytes){

	bytes[0] = (char)255;							// terminator descriptor
	memcpy( (bytes + 1), "CD001", 5);				// standard identifier
	*(bytes+6) = (char)1;							// volume descriptor version
}


void MakeImage::MakeBootCatalog(char *bytes){

	*(bytes) = 1;				// header id
	
	*(bytes+28) = (char)0xAA;
	*(bytes+29) = (char)0x55;
	*(bytes+30) = (char)0x55;
	*(bytes+31) = (char)0xAA;

	*(bytes+32) = (char)0x88;			// bootable
	*(bytes+34) = (char)0xC0;
	*(bytes+35) = (char)0x07;

	*(bytes+38) = (char)4;
	*(bytes+40) = (char)20;
}


void MakeImage::MakeBootSector(char *bytes){

	ifstream file;
	file.open(BOOT_SECTOR_FILE, ios::binary);

	file.read(bytes, 512);

	file.close();
}


// recursively write the files and dirs
void MakeImage::WriteFiles(Directory *root, ofstream &out){

	char *sector = 0;


	sector = new char[SECTOR_SIZE];
	ZeroMemory(sector, SECTOR_SIZE);

	root->CreatePathDescriptor(sector, false);
	WriteSector(out, root->GetBlock(), sector);

	delete [] sector;


	for(UINT i=0; i < root->mChildren.size(); ++i){

		WriteFiles(root->mChildren[i], out);
	}


	for(UINT i=0; i < root->mFiles.size(); ++i){

		File *curFile = root->mFiles[i];
		int writeSector = curFile->GetBlock();

		char filePath[MAX_PATH];

		strcpy_s(filePath, MAX_PATH, "cd_root");
		strcat_s(filePath, MAX_PATH, curFile->GetAbsolutePath());


		ifstream in;
		in.open(filePath, ios_base::binary);


		do{

			sector = new char[SECTOR_SIZE];
			ZeroMemory(sector, SECTOR_SIZE);

			in.read(sector, SECTOR_SIZE);

			WriteSector(out, writeSector, sector);

			delete [] sector;

			++writeSector;
		}
		while(!in.eof());

		in.close();
	}
}