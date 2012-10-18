#include "PathTable.h"

#include "MakeImage.h"
#include "AnyEndianNumber.h"
#include "Directory.h"


PathTable::PathTable(Directory *root){

	mTableSize = 0;

	mSectorBytes = 0;
	mSectorBytes = new char[SECTOR_SIZE];

	MakeList(root);

}

PathTable::~PathTable(){

	if(mSectorBytes != 0)
		delete [] mSectorBytes;

}



void PathTable::MakeList(Directory *root){

	mDirlist.push_back(root);

	for(UINT i=0; i < root->mChildren.size(); ++i){

		MakeList(root->mChildren[i]);
	}
}


void PathTable::MakeTable(char *bytes, int type){

	AnyEndianNumber *startBlock = 0;
	AnyEndianNumber *parentNum = 0;


	short pathEntry = 1;

	int offset = 0;

	for(UINT i=0; i < mDirlist.size(); ++i){

		Directory *curDir = mDirlist[i];

		curDir->SetPathEntry(pathEntry);
		++pathEntry;

		*(bytes+offset) = (char)strlen(curDir->GetId());
		offset++;

		*(bytes+offset) = 0;
		offset++;


		if(type == TYPE_L){

			startBlock = new AnyEndianNumber(curDir->GetBlock(), AnyEndianNumber::ORDER_LEAST);

			if(strncmp(curDir->GetId(), "\\", 1) == 0)
				parentNum = new AnyEndianNumber((short)1, AnyEndianNumber::ORDER_LEAST);
			else
				parentNum = new AnyEndianNumber(curDir->GetParent()->GetPathEntry(), AnyEndianNumber::ORDER_LEAST);
		}

		else if(type == TYPE_M){

			startBlock = new AnyEndianNumber(curDir->GetBlock(), AnyEndianNumber::ORDER_MOST);

			if(strncmp(curDir->GetId(), "\\", 1) == 0)
				parentNum = new AnyEndianNumber((short)1, AnyEndianNumber::ORDER_MOST);
			else
				parentNum = new AnyEndianNumber(curDir->GetParent()->GetPathEntry(), AnyEndianNumber::ORDER_MOST);
		}



		startBlock->GetNumber((bytes+offset));
		offset += startBlock->GetSize();

		if(startBlock != 0)
			delete startBlock;


		parentNum->GetNumber((bytes+offset));
		offset += parentNum->GetSize();

		if(parentNum != 0)
			delete parentNum;



		int idLength = strlen(curDir->GetId());


		if(strncmp(curDir->GetId(), "\\", 1) == 0){
			*(bytes+offset) = 0;
			++offset;
		}

		else{
			memcpy( (bytes+offset), curDir->GetId(), idLength);
			offset += idLength;
		}

		if(idLength % 2 != 0){
			*(bytes+offset) = 0;
			++offset;
		}
	}

	mTableSize = offset;

}
