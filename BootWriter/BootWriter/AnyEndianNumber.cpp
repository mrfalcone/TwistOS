#include "AnyEndianNumber.h"



AnyEndianNumber::AnyEndianNumber(int intNum, int order){

	mSize = INT_SIZE;

	// if this is mixed endian, it will be twice as long
	if(order == ORDER_MIXED)
		mSize *= 2;

	mBytes = new char[mSize];

	INT_UNION num;
	num.i = intNum;

	MakeBytes(num.c, INT_SIZE, order);

}


AnyEndianNumber::AnyEndianNumber(short shortNum, int order){

	mSize = SHORT_SIZE;

	// if this is mixed endian, it will be twice as long
	if(order == ORDER_MIXED)
		mSize *= 2;

	mBytes = new char[mSize];

	SHORT_UNION num;
	num.s = shortNum;

	MakeBytes(num.c, SHORT_SIZE, order);

}


AnyEndianNumber::~AnyEndianNumber(){

	// free byte array
	delete [] mBytes;
}

void AnyEndianNumber::MakeBytes(const char *numBytes, int size, int order){

	int byteIndex = 0;

	// copy with least significant bit first
	if(order == ORDER_MIXED || order == ORDER_LEAST){

		memcpy(mBytes, numBytes, size);
		byteIndex += size;
	}


	// copy with most significant bit first
	if(order == ORDER_MIXED || order == ORDER_MOST){

		for(int i=size-1; i >= 0; --i){

			mBytes[byteIndex] = numBytes[i];
			++byteIndex;
		}
	}
}
