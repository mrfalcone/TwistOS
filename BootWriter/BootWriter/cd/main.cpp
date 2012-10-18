#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>

#include "ImageCreator.h"


using namespace std;


int main(int argc, char *argv[]){

	vector<string> addFiles;

	ifstream in;
	in.open("filelist.txt");

	if(!in.good()){
		cout << "filelist.txt not found" << endl;
		in.close();
		system("pause");
		return 0;
	}


	do{
		string str;
		in >> str;
		addFiles.push_back(str);

	} while(!in.eof());

	in.close();


	const char *filename = "cd.iso";		// name of the output iso file


	cout << "****Creating boot disk****" << endl << endl;

	// initialize the image creator to create an image with 21 sectors
	ImageCreator *creator = new ImageCreator(addFiles, true);


	// build the cd image and get the pointer to the array of bytes to write
	creator->BuildImage(filename);


	delete creator;


	cout << endl << endl;

	system("pause");

	return EXIT_SUCCESS;
}