#ifndef _DIRECTORY_H_
#define _DIRECTORY_H_



#include <windows.h>

#include <vector>

#include "File.h"

using namespace std;

class Directory{


public:

	Directory(const char *dirName, Directory *parent, int block);

	vector<Directory*> mChildren;		// children dirs
	vector<File*> mFiles;		// files in this dir

	const char* GetId() const { return mIdentifier; }

	const char* GetAbsolutePath() const { return mAbsPath; }

	const short& GetPathEntry() const { return mPathTableEntry; }

	const int& GetBlock() const { return mBlock; }

	const Directory* GetParent() const { return mParentDir; }

	void SetPathEntry(short entryNum) { mPathTableEntry = entryNum; }

	void AddDirectory(Directory *dir);
	void AddFile(File *file);

	void CreatePathDescriptor(char *bytes, const bool& rootOnly);

private:

	enum recordType{

		RECTYPE_PARENT,
		RECTYPE_ROOT,
		RECTYPE_DIR
	};

	char mAbsPath[MAX_PATH];

	void BuildPath(char *path);

	char mIdentifier[MAX_PATH];

	int mIdLength;


	int mBlock;			// residing block

	short mPathTableEntry;


	void GetDirRecord(char *record, Directory *dir, int recordType);
	void GetFileRecord(char *record, File *file);

	void GetTime(char *bytes);
	
	Directory *mParentDir;				// parent directory


};




#endif // _DIRECTORY_H_