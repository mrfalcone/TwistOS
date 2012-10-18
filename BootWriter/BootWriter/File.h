#ifndef _FILE_H_
#define _FILE_H_

#include <windows.h>
#include <vector>

using namespace std;


class Directory;

class File{


public:

	File(const char *fileName, Directory *parent, int block);

	const char* GetId() const { return mIdentifier; }

	const char* GetAbsolutePath() const { return mAbsPath; }

	const int& GetBlock() const { return mBlock; }

	void SetFileSize(int& size) { mFileSize = size; }

	const int& GetFileSize() const { return mFileSize; }

private:

	char mIdentifier[MAX_PATH];

	int mIdLength;

	char mAbsPath[MAX_PATH];

	int mBlock;			// residing block

	int mFileSize;

	Directory *mParentDir;				// parent directory

};



#endif // _FILE_H_