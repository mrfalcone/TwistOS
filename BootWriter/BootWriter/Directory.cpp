#include "Directory.h"
#include "MakeImage.h"

#include <iostream>
#include <time.h>

#define GMT_OFFSET		0xF0	// not sure what this means but I don't know how to calculate it


Directory::Directory(const char *dirName, Directory *parent, int block)
: mParentDir(parent), mBlock(block), mPathTableEntry(0){


	strcpy_s(mIdentifier, MAX_PATH, dirName);

	BuildPath(mAbsPath);

	//cout << GetId() << endl;
}


void Directory::BuildPath(char *path){

	if(mParentDir != 0){
		mParentDir->BuildPath(path);

		strcat_s(path, MAX_PATH, GetId());
		strcat_s(path, MAX_PATH, "\\");
	}

	else
		strcpy_s(path, MAX_PATH, GetId());

	

}


void Directory::AddFile(File *file){

	mFiles.push_back(file);

}

void Directory::AddDirectory(Directory *dir){

	mChildren.push_back(dir);

}


// called recursively from makeimage to get array of bytes to write as
// directory descriptor
void Directory::CreatePathDescriptor(char *bytes, const bool& rootOnly){

	char sector[SECTOR_SIZE];
	ZeroMemory(&sector, SECTOR_SIZE);

	int offset = 0;

	GetDirRecord( (sector+offset), this, RECTYPE_ROOT);
	offset += (int)*(sector+offset);

	if(rootOnly){
		memcpy( bytes, &sector, offset);
		return;
	}


	if(strncmp(GetId(), "\\", 1) == 0) // if root dir, parent is self
		GetDirRecord( (sector+offset), this, RECTYPE_PARENT);
	else
		GetDirRecord( (sector+offset), mParentDir, RECTYPE_PARENT);

	offset += (int)*(sector+offset);



	for(UINT i=0; i < mChildren.size(); ++i){

		Directory *curDir = mChildren[i];

		GetDirRecord( (sector+offset), curDir, RECTYPE_DIR);
		offset += (int)*(sector+offset);

	}

	for(UINT i=0; i < mFiles.size(); ++i){

		File *curFile = mFiles[i];

		GetFileRecord( (sector+offset), curFile);
		offset += (int)*(sector+offset);
	}

	memcpy( bytes, &sector, offset);
}




void Directory::GetDirRecord(char *record, Directory *dir, int recordType){

	char sector[SECTOR_SIZE];
	ZeroMemory(&sector, SECTOR_SIZE);

	int offset = 2;		// start at 2 to skip first 2 bytes


	AnyEndianNumber entryLength((int)SECTOR_SIZE, AnyEndianNumber::ORDER_MIXED);
	AnyEndianNumber startBlock(dir->GetBlock(), AnyEndianNumber::ORDER_MIXED);
	AnyEndianNumber volumeNum((short)1, AnyEndianNumber::ORDER_MIXED);

	int entrySize = 0;


	startBlock.GetNumber( (sector+offset) );
	offset += startBlock.GetSize();

	entryLength.GetNumber( (sector+offset) );
	offset += entryLength.GetSize();


	GetTime( (sector+offset) );
	offset += 7;	// add 7 for timestamp


	*(sector+offset) = (char)0x02;
	++offset;


	offset += 2;	// skip 2 unused bytes

	volumeNum.GetNumber( (sector+offset) );
	offset += volumeNum.GetSize();

	if(recordType == RECTYPE_ROOT){
		*(sector+offset) = 1;
		++offset;
		*(sector+offset) = 0;
		++offset;
	}

	else if(recordType == RECTYPE_PARENT){
		*(sector+offset) = 1;
		++offset;
		*(sector+offset) = 1;
		++offset;
	}

	else if(recordType == RECTYPE_DIR){
		*(sector+offset) = strlen(dir->GetId());
		++offset;
		memcpy( (sector+offset), dir->GetId(), strlen(dir->GetId()) );
		offset += strlen(dir->GetId());
	}

	if(offset % 2 != 0)
		++offset;

	sector[0] = (char)offset;

	memcpy( record, &sector, offset);
}



void Directory::GetFileRecord(char *record, File *file){

	char sector[SECTOR_SIZE];
	ZeroMemory(sector, SECTOR_SIZE);

	int offset = 2;		// start at 2 to skip first 2 bytes


	AnyEndianNumber entryLength(file->GetFileSize(), AnyEndianNumber::ORDER_MIXED);
	AnyEndianNumber startBlock(file->GetBlock(), AnyEndianNumber::ORDER_MIXED);
	AnyEndianNumber volumeNum((short)1, AnyEndianNumber::ORDER_MIXED);

	int entrySize = 0;


	startBlock.GetNumber( (sector+offset) );
	offset += startBlock.GetSize();

	entryLength.GetNumber( (sector+offset) );
	offset += entryLength.GetSize();


	GetTime( (sector+offset) );
	offset += 7;	// add 7 for timestamp


	*(sector+offset) = 0x00;
	++offset;


	offset += 2;	// skip 2 unused bytes

	volumeNum.GetNumber( (sector+offset) );
	offset += volumeNum.GetSize();

	

	*(sector+offset) = strlen(file->GetId());
	++offset;
	memcpy( (sector+offset), file->GetId(), strlen(file->GetId()) );
	offset += strlen(file->GetId());


	if(offset % 2 != 0)
		++offset;

	sector[0] = (char)offset;

	memcpy( record, &sector, offset);
}



void Directory::GetTime(char *bytes){


	time_t timer;
	time(&timer);

	tm lTime;

	localtime_s(&lTime, &timer);

	bytes[0] = (char)lTime.tm_year;
	bytes[1] = (char)lTime.tm_mon+1;
	bytes[2] = (char)lTime.tm_mday;
	bytes[3] = (char)lTime.tm_hour;
	bytes[4] = (char)lTime.tm_min;
	bytes[5] = (char)lTime.tm_sec;
	bytes[6] = (char)GMT_OFFSET;

}