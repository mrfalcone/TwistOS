#include "File.h"

#include "Directory.h"

#include <iostream>

File::File(const char *fileName, Directory *parent, int block)
: mParentDir(parent), mBlock(block){

	strcpy_s(mIdentifier, MAX_PATH, fileName);

	const char *parentPath = parent->GetAbsolutePath();


	strcpy_s(mAbsPath, MAX_PATH, parentPath);

	strcat_s(mAbsPath, MAX_PATH, GetId());

	//cout << mAbsPath << endl;
	
}

