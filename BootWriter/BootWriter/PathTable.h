#ifndef _PATHTABLE_H_
#define _PATHTABLE_H_

#include <deque>
#include <iostream>

using namespace std;

class Directory;

class PathTable{

public:

	enum _tableType{

		TYPE_L,
		TYPE_M
	};


	PathTable(Directory *root);
	~PathTable();

	void MakeTable(char *bytes, int type);

	const int& GetSize() const { return mTableSize; }

private:

	void MakeList(Directory *root);

	deque<Directory*> mDirlist;
	
	char *mSectorBytes;

	int mTableSize;

};



#endif // _PATHTABLE_H_