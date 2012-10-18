#include <iostream>
#include <fstream>
#include <string>
#include <time.h>

#include "MakeImage.h" // define SECTOR_SIZE

#include "Directory.h"
#include "File.h"


// this is the block where the data (files and directories) will start
// on the disk. it must be after the descriptors and path tables
// the file at the first block will be the file loaded by the boot sector
#define DATA_START_BLOCK	23

#define BOOT_FILE			"TKLD.ebc"


using namespace std;

void BuildFiles(Directory *root);
void ClearFiles(Directory *root);
void PrintFiles(Directory *root);


int curDataBlock = DATA_START_BLOCK+3;		// +3 to reserve some blocks for kernel loader


int main(int argc, char *argv[]){


	const char *filename = "cd.iso";		// name of the output iso file

	cout << "**** Boot Disk Maker ****" << endl << endl;


	cout << "Scanning directory.......";
	Directory *rootDir = new Directory("\\", 0, curDataBlock);
	++curDataBlock;

	BuildFiles(rootDir);

	cout << "done!" << endl;



	MakeImage *make = new MakeImage();

	cout << "Making image.............";

	make->Build(rootDir, filename, curDataBlock);

	cout << "done!" << endl << endl;

	//PrintFiles(rootDir);


	ClearFiles(rootDir);
	
	delete make;


	//system("pause");

	return EXIT_SUCCESS;


}


void ClearFiles(Directory *root){

	while(!root->mChildren.empty()){

		Directory *child = root->mChildren.back();
		root->mChildren.pop_back();

		ClearFiles(child);
	}

	while(!root->mFiles.empty()){

		File *file = root->mFiles.back();
		root->mFiles.pop_back();

		delete file;
	}

	delete root;
}

void PrintFiles(Directory *root){


	cout << "inside " << root->GetId() << " :" << endl;
	cout << root->mChildren.size() << " dirs" << endl;

	for(UINT i=0; i < root->mFiles.size(); ++i){

		cout << "   " << root->mFiles[i]->GetId() << " - " << root->mFiles[i]->GetBlock() << endl;
		//cout << "   " << root->mFiles[i]->GetAbsolutePath() << endl;
	}
	cout << endl;


	for(UINT i=0; i < root->mChildren.size(); ++i){

		Directory *child = root->mChildren[i];

		PrintFiles(child);
	}
}


void BuildFiles(Directory *root){

	WIN32_FIND_DATAA fd;
	HANDLE hFind = INVALID_HANDLE_VALUE;

	char path[MAX_PATH];

	strcpy_s(path, MAX_PATH, "cd_root");
	strcat_s(path, MAX_PATH, root->GetAbsolutePath());
	strcat_s(path, MAX_PATH, "*");

	hFind = FindFirstFileA(path, &fd);
	
	do{

		if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY){

			if(fd.cFileName[0] != '.'){
				// create a new directory and add it to this dir's list of children
				Directory *newDir = new Directory(fd.cFileName, root, curDataBlock);
				++curDataBlock;

				root->AddDirectory(newDir);

				BuildFiles(newDir);				

			}
		}
		
		else{

			File *newFile = 0;

			// if this is the file the boot sector is to boot, add it at the specified sector
			if(strncmp(BOOT_FILE, fd.cFileName, strlen(fd.cFileName)) == 0){
				newFile = new File(fd.cFileName, root, DATA_START_BLOCK);

				char filePath[MAX_PATH];

				strcpy_s(filePath, MAX_PATH, "cd_root");
				strcat_s(filePath, MAX_PATH, newFile->GetAbsolutePath());

				ifstream file;
				file.open(filePath, ios::binary);

				file.seekg(0, ios::end);

				int fileLength = file.tellg();

				file.close();

				int fileBlocks = (int)( (float)fileLength / (float)SECTOR_SIZE ) + 1;

				newFile->SetFileSize(fileLength);
			}

			else{

				newFile = new File(fd.cFileName, root, curDataBlock);

				char filePath[MAX_PATH];

				strcpy_s(filePath, MAX_PATH, "cd_root");
				strcat_s(filePath, MAX_PATH, newFile->GetAbsolutePath());

				ifstream file;
				file.open(filePath, ios::binary);

				file.seekg(0, ios::end);

				int fileLength = file.tellg();

				file.close();

				int fileBlocks = (int)( (float)fileLength / (float)SECTOR_SIZE ) + 1;

				newFile->SetFileSize(fileLength);

				curDataBlock += fileBlocks;
			}

			root->AddFile(newFile);

		}

	}
	while (FindNextFileA(hFind, &fd) != 0);

}

