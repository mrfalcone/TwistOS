#ifndef _IMAGECREATOR_H_
#define _IMAGECREATOR_H_

#define SECTOR_SIZE		2048		// size of each sector on the cd

#define DATA_BLOCK		25			// block where the files begin to be added

#include <fstream>
#include <windows.h>
#include <string>
#include <vector>
#include <cmath>
#include <deque>

#include "Directory.h"
#include "AnyEndianNumber.h"


using namespace std;


typedef union
{
	int   i;
	char c[4];
} DWORD_UNION;


typedef union
{
	short  s;
	char c[2];
} WORD_UNION;


class ImageCreator{

public:
	ImageCreator(deque<string> files, const bool &verbose);
	~ImageCreator();

	void BuildImage(const char *filename);

	const int& GetByteCount() const { return mFileSize; }


private:
	const short mBlockSize;

	int		mFileSize;		// size of the cd image in bytes
	char	*mBytes;		// byte array making up the cd image
	int		mByteOffset;	// current position at which to write bytes

	bool	mVerbose;		// if this is true, a message will output to the console at each write step

	char	mRootPathEntry[34];


	// create the path table with specified type M or L and insert into byte array
	void	CreatePathTable(const char type, int residingBlock, int *tableSize);

	void	CreateRootPath(const int block);

	void	WritePrimaryVolumeDescriptor(const int sector, int rootStart, int pathTableSize);
	void	WriteBootVolumeDescriptor(const int sector, const int bootCatSector);
	void	WriteTerminatorVolumeDescriptor(const int sector);

	void	WriteBootCatalogue(const int sector);
	void	WriteBootLoaderSector(const int sector);

	// write the files to the iso
	void	WriteFiles(ofstream &stream);

	Directory *mRootDir;
};

ImageCreator::ImageCreator(Directory *root, const bool &verbose)
: mBlockSize(SECTOR_SIZE), mRootDir(root){

	mVerbose = verbose;
	mByteOffset = 0;


	mFileSize = DATA_BLOCK * SECTOR_SIZE;

	// initialize the image data and fill with zeros
	mBytes = new char[mFileSize];
	ZeroMemory(mBytes, mFileSize);


	cout << "****Creating boot disk****" << endl << endl;


	mRootDir = new Directory("\\", 0);

	//cout << "Building filesystem...";

	BuildFileSystem(files, mRootDir);

	//cout << "ok" << endl;
delete mRootDir;
	/*for(UINT i=0; i < files.size(); ++i){

		cout << files[i] << endl;

	}*/

}

ImageCreator::~ImageCreator(){

	// free array of bytes
	delete [] mBytes;

	
}


void ImageCreator::BuildFileSystem(deque<string> &files, Directory *root){

	deque<string> curDir;

	
	const char *dirId = root->GetId();


	for(UINT i=0; i < files.size(); ++i){

		//cout << ".";

		const char *name = files[i].c_str();


		if(name[0] == '+'){

			char *slash = (char*)memchr( (name+1+strlen(dirId)), '\\', strlen(name)-strlen(dirId)-1 );
			
			int slashPos = slash-name+1;
			int idLength = slashPos - strlen(dirId)-2;


			//cout << ".";

			if(strncmp( (name+1), dirId, strlen(dirId)) == 0){

				if(strlen(name) == slashPos){

					char childDir[MAX_PATH];

					memcpy(&childDir, (name+strlen(dirId)+1), idLength);
					childDir[idLength] = 0;

					//Directory *child = BuildFileSystem(curDir, childDir, dir);

					Directory *child = new Directory(childDir, root);
					
					root->AddDirectory(child);
				}

				
				else{
					stringstream dirStream;

					dirStream << "+" << (name+1+strlen(dirId));

					curDir.push_back(dirStream.str());
				}


			}


			//curDir.push_back( (name+1) );
		}

		else{

			if(strncmp(name, dirId, strlen(dirId)) == 0)
				curDir.push_back( (name+strlen(dirId)) );
		}

	}


	for(UINT i=0; i < root->mChildren.size(); ++i){

		//const char *id = root->mChildren[i]->GetId();

		BuildFileSystem(curDir, root->mChildren[i]);
	}


	cout << "===inside " << dirId << " :" << endl;
	cout << root->mChildren.size() << " dirs" << endl;

	while(!curDir.empty()){

		

		//BuildFileSystem(curDir, root);

		string back = curDir.back();

		curDir.pop_back();

		const char *s = strchr(back.c_str(), '\\');

		
		if(s == 0){

			//dir->AddFile(back);

			cout << "file:" << back << endl;

			
		}
		else{

			cout << "     " << back << endl;

		}

	}


	cout << endl << endl;


	
	


}


void ImageCreator::CreatePathTable(const char type, const int residingBlock, int *tableSize){

	/*
	Build a path table with only the root directory
	*/

	int tableBlock = 22;

	if(type == 'M')
		tableBlock = 23;

	DWORD_UNION extentBlock;
	extentBlock.i = residingBlock;

	WORD_UNION parentNumber;
	parentNumber.s = 1;


	char startingBlockArray[4];
	char parentNumberArray[2];

	// least significant byte first
	if(type == 'L'){

		memcpy(&startingBlockArray, &(extentBlock.c), 4);
		memcpy(&parentNumberArray, &(parentNumber.c), 2);
	}

	// most significant byte first
	else if(type == 'M'){

		startingBlockArray[0] = extentBlock.c[3];
		startingBlockArray[1] = extentBlock.c[2];
		startingBlockArray[2] = extentBlock.c[1];
		startingBlockArray[3] = extentBlock.c[0];

		parentNumberArray[0] = parentNumber.c[1];
		parentNumberArray[1] = parentNumber.c[0];
	}


	char pathTableBytes[] = {

		1,								// length of directory identifier
		0,								// length of extended data

		// begin starting block number bytes
		startingBlockArray[0],
		startingBlockArray[1],
		startingBlockArray[2],
		startingBlockArray[3],

		// begin parent number bytes
		parentNumberArray[0],
		parentNumberArray[1],

		0,								// directory identifier, 0 == root dir
		0								// pad
	};


	memcpy( (mBytes+(tableBlock*mBlockSize) ), &pathTableBytes, sizeof(pathTableBytes));


	*tableSize = sizeof(pathTableBytes);
}


void ImageCreator::WriteBootCatalogue(const int sector){

	char validation[32];
	ZeroMemory(&validation, 32);

	validation[0] = 1;				// header id
	
	validation[28] = (char)0xAA;
	validation[29] = (char)0x55;
	validation[30] = (char)0x55;
	validation[31] = (char)0xAA;

	memcpy( (mBytes+(sector*SECTOR_SIZE)), &validation, sizeof(validation) );

	char initialEntry[32];
	ZeroMemory(&initialEntry, 32);

	initialEntry[0] = (char)0x88;			// bootable
	initialEntry[2] = (char)0xC0;
	initialEntry[3] = (char)0x07;

	initialEntry[6] = 4;

	initialEntry[8] = 20;

	memcpy( (mBytes+(sector*SECTOR_SIZE)+sizeof(validation)), &initialEntry, sizeof(initialEntry) );

}


void ImageCreator::CreateRootPath(const int block){


	DWORD_UNION startingBlock;
	startingBlock.i = block;

	DWORD_UNION entryLength;
	entryLength.i = SECTOR_SIZE;


	WORD_UNION volumeNum;
	volumeNum.s = 1;


	char rootPath[] = {
		
		0,					// skip first byte for length
		0,					// extended attribute record length

		// starting block number in mixed byte order
		startingBlock.c[0],
		startingBlock.c[1],
		startingBlock.c[2],
		startingBlock.c[3],
		startingBlock.c[3],
		startingBlock.c[2],
		startingBlock.c[1],
		startingBlock.c[0],
		
		// length of the directory in mixed byte order
		entryLength.c[0],
		entryLength.c[1],
		entryLength.c[2],
		entryLength.c[3],
		entryLength.c[3],
		entryLength.c[2],
		entryLength.c[1],
		entryLength.c[0],
		
		// unspecified date and time
		0,0,0,0,0,0,0,

		0x02,				// specify directory
		0,0,				// unused bytes

		// volume sequence number in mixed byte order
		volumeNum.c[0],
		volumeNum.c[1],
		volumeNum.c[1],
		volumeNum.c[0],

		1,					// file id length
		0					// file id, 0 = for root path
	};

	int pathSize = sizeof(rootPath);

	// set the size of the entry
	rootPath[0] = (char)pathSize;


	// copy to member array
	memcpy( &mRootPathEntry, &rootPath, 34 );


	memcpy( (mBytes + block*SECTOR_SIZE), &rootPath, pathSize );

	rootPath[pathSize-1] = 0x01;	// parent 

	memcpy( (mBytes + (block*SECTOR_SIZE)+pathSize), &rootPath, pathSize );
	
	mByteOffset = (block*SECTOR_SIZE)+(pathSize*2);

	int blockOffset = 0;
	const int startData = DATA_BLOCK;

	for(UINT i=0; i < mFileList.size(); ++i){

		ifstream file;
		file.open(mFileList[i].c_str(), ios::binary);

		file.seekg(0, ios::end);

		entryLength.i = file.tellg();

		int nameLength = strlen(mFileList[i].c_str());

		startingBlock.i = startData + blockOffset;


		char fileEntry[] = {

			0,					// skip first byte for length
			0,					// extended attribute record length

			// starting block number in mixed byte order
			startingBlock.c[0],
			startingBlock.c[1],
			startingBlock.c[2],
			startingBlock.c[3],
			startingBlock.c[3],
			startingBlock.c[2],
			startingBlock.c[1],
			startingBlock.c[0],

			// length of the directory in mixed byte order
			entryLength.c[0],
			entryLength.c[1],
			entryLength.c[2],
			entryLength.c[3],
			entryLength.c[3],
			entryLength.c[2],
			entryLength.c[1],
			entryLength.c[0],

			// unspecified date and time
			0,0,0,0,0,0,0,

			0,					// specify regular file
			0,0,				// unused bytes

			// volume sequence number in mixed byte order
			volumeNum.c[0],
			volumeNum.c[1],
			volumeNum.c[1],
			volumeNum.c[0],

			0			// temp file id length
		};


		int byteCount = 0;

		if(nameLength % 2 == 0)		// if filename is of even length
			byteCount = sizeof(fileEntry) + nameLength + 1;
		else
			byteCount = sizeof(fileEntry) + nameLength;


		fileEntry[0] = (char)byteCount;		// set byte count of the entry

		
		fileEntry[sizeof(fileEntry)-1] = (char)nameLength;


		memcpy( (mBytes+mByteOffset), &fileEntry, sizeof(fileEntry) );
		memcpy( (mBytes+mByteOffset+sizeof(fileEntry)), mFileList[i].c_str(), nameLength );

		mByteOffset += byteCount;


		if(entryLength.i > SECTOR_SIZE)
			blockOffset += (int)ceil( (float)entryLength.i / (float)SECTOR_SIZE );
		else
			++blockOffset;

	}


}



void ImageCreator::BuildImage(const char *filename){

	cout << "Building image:" << endl;

	int startingBlock   = 24; // start path at block 24
	int pathTableSize   = 0;


	if(mVerbose)
		cout << "->Creating Type L path table..." << endl;
	CreatePathTable('L', startingBlock, &pathTableSize);

	if(mVerbose)
		cout << "->Creating Type M path table..." << endl;
	CreatePathTable('M', startingBlock, &pathTableSize);


	if(mVerbose)
		cout << "->Creating root path..." << endl;
	CreateRootPath(startingBlock);



	if(mVerbose)
		cout << "->Creating primary volume descriptor..." << endl;
	WritePrimaryVolumeDescriptor(16, startingBlock, pathTableSize);


	int bootCatSector = 19;
	
	if(mVerbose)
		cout << "->Creating boot catalogue..." << endl;
	WriteBootCatalogue(bootCatSector);

	if(mVerbose)
		cout << "->Creating boot volume descriptor..." << endl;
	WriteBootVolumeDescriptor(17, bootCatSector);

	if(mVerbose)
		cout << "->Creating terminator volume descriptor..." << endl;
	WriteTerminatorVolumeDescriptor(18);

	if(mVerbose)
		cout << "->Creating boot loader sector..." << endl;
	WriteBootLoaderSector(20);


	ofstream out;

	out.open(filename, ios_base::binary);		// open the file for output


	if(!out.good()){
		out.close();
		cout << "Error opening file to save!" << endl;
		return;
	}
	

	// now write the first group of sectors
	if(mVerbose)
		cout << "->Writing information sectors..." << endl;
	out.write(mBytes, GetByteCount());


	if(mVerbose)
		cout << "->Writing " << mFileList.size() << " files..." << endl;
	WriteFiles(out);



	cout << "->ISO written successfully." << endl;

	out.close();



}


void ImageCreator::WriteFiles(ofstream &stream){



	int blockOffset = 0;

	for(UINT i=0; i < mFileList.size(); ++i){

		ifstream file;
		file.open(mFileList[i].c_str(), ios::binary);

		file.seekg(0, ios::end);

		int fileLength = file.tellg();

		int fileBlocks = (int)ceil( (float)fileLength / (float)SECTOR_SIZE );

		int emptyChars = ((blockOffset+fileBlocks)*mBlockSize) - ((blockOffset*mBlockSize)+fileLength);

		file.seekg(0, ios::beg);


		for(int j=0; j < fileLength; ++j){

			char c = file.get();
			stream.put(c);
		}

		file.close();


		for(int j=0; j < emptyChars; ++j){

			stream.put(0);
		}

		blockOffset += fileBlocks;
	}
}


void ImageCreator::WritePrimaryVolumeDescriptor(const int sector, int rootStart, int pathTableSize){


	AnyEndianNumber *AENum = 0;


	char *volume = new char[SECTOR_SIZE];
	ZeroMemory(volume, SECTOR_SIZE);


	volume[0] = 0x01;								// volume descriptor type

	memcpy( (volume + 1), "CD001", 5);				// standard identifier

	volume[6] = 0x01;								// volume descriptor version
	
	// system identifier
	memcpy( (volume + 8),  "BOOT DISK                       ", 32);

	// volume identifier
	memcpy( (volume + 40), "BOOT_DISK                       ", 32);



	// set the volume space size
	AENum = new AnyEndianNumber( (int)(mFileSize / mBlockSize), AnyEndianNumber::ORDER_MIXED );

	AENum->GetNumber( (volume+80) );

	delete AENum;



	
	
	AENum = new AnyEndianNumber( (short)1, AnyEndianNumber::ORDER_MIXED );

	// set volume set size
	AENum->GetNumber( (volume+120) );

	// and volume sequence number
	AENum->GetNumber( (volume+124) );

	delete AENum;
	


	AENum = new AnyEndianNumber( (short)SECTOR_SIZE, AnyEndianNumber::ORDER_MIXED );

	// set logical block size
	AENum->GetNumber( (volume+128) );

	delete AENum;



	AENum = new AnyEndianNumber( pathTableSize, AnyEndianNumber::ORDER_MIXED );

	// set path table size
	AENum->GetNumber( (volume+132) );

	delete AENum;



	DWORD_UNION pathTableLPos;
	pathTableLPos.i = 22;

	// set L path table position in little endian byte order
	volume[140] = pathTableLPos.c[0];
	volume[141] = pathTableLPos.c[1];
	volume[142] = pathTableLPos.c[2];
	volume[143] = pathTableLPos.c[3];


	DWORD_UNION pathTableMPos;
	pathTableMPos.i = 23;

	// set M path table position in big endian byte order
	volume[148] = pathTableMPos.c[3];
	volume[149] = pathTableMPos.c[2];
	volume[150] = pathTableMPos.c[1];
	volume[151] = pathTableMPos.c[0];


	// root path entry
	memcpy( (volume+156), &mRootPathEntry, 34 );
	

	// volume set identifier
	memset( (volume+190), '_', 128 );

	// publisher identifier
	memcpy( (volume + 318), "Mike Falcone                    ", 32);
	memcpy( (volume + 350), "mr.falcone@gmail.com            ", 32);
	memcpy( (volume + 382), "                                ", 32);
	memcpy( (volume + 414), "                                ", 32);


	// data preparer identifier
	memcpy( (volume + 446), "Mike Falcone                    ", 32);
	memcpy( (volume + 478), "                                ", 32);
	memcpy( (volume + 510), "                                ", 32);
	memcpy( (volume + 542), "                                ", 32);


	// data preparer identifier
	memset( (volume+574), 32, 239 );


	// file structure version
	*(volume+881) = 1;


	memcpy( (mBytes + sector*mBlockSize), volume, mBlockSize );

	delete [] volume;
}


void ImageCreator::WriteBootVolumeDescriptor(const int sector, const int bootCatSector){

	char bootVolume[SECTOR_SIZE];
	ZeroMemory(&bootVolume, SECTOR_SIZE);

	memcpy((bootVolume+1), "CD001", 5);

	bootVolume[6] = 1;

	memcpy((bootVolume+7), "EL TORITO SPECIFICATION", 23);

	bootVolume[71] = bootCatSector;


	memcpy( (mBytes+(sector*SECTOR_SIZE)), &bootVolume, SECTOR_SIZE);
}


void ImageCreator::WriteBootLoaderSector(const int sector){


	ifstream file;
	file.open("boot.bin", ios::binary);

	file.seekg(0, ios::end);

	int fileLength = file.tellg();

	file.seekg(0, ios::beg);


	for(int i=0; i < fileLength; ++i){

		char c = file.get();
		mBytes[(sector*SECTOR_SIZE)+i] = c;
	}

	file.close();

}


void ImageCreator::WriteTerminatorVolumeDescriptor(const int sector){

	char *volume = new char[SECTOR_SIZE];
	ZeroMemory(volume, SECTOR_SIZE);

	volume[0] = (char)255;							// terminator descriptor
	memcpy( (volume + 1), "CD001", 5);				// standard identifier
	volume[6] = 1;									// volume descriptor version

	memcpy( (mBytes+(sector*SECTOR_SIZE)), volume, SECTOR_SIZE );

	delete [] volume;
}




#endif // _IMAGECREATOR_H_