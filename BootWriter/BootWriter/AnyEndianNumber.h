#ifndef _ANYENDIANNUMBER_H_
#define _ANYENDIANNUMBER_H_

#include <cstring>

#define INT_SIZE	4		// size in bytes of an int
#define SHORT_SIZE	2		// size in bytes of a short


// union used to create integer numbers
typedef union
{
	int   i;
	char c[INT_SIZE];
} INT_UNION;


// union used to create short numbers
typedef union
{
	short  s;
	char c[SHORT_SIZE];
} SHORT_UNION;



class AnyEndianNumber{

public:

	// byte ordering
	enum _order{

		ORDER_MOST,		// most significant byte is first
		ORDER_LEAST,	// least significant byte is first
		ORDER_MIXED		// mix both orderings as one number
	};


	// Constructor for 32 bit integers
	// --------
	// *Params:
	//  intNum	- number to use as integer
	//  order	- byte ordering
	AnyEndianNumber(int intNum, int order);


	// Constructor for 16 bit shorts
	// --------
	// *Params:
	//  shortNum	- number to use as short
	//  order		- byte ordering
	AnyEndianNumber(short shortNum, int order);


	// Destructor
	// --------
	~AnyEndianNumber();


	// Puts the number into the character array pointed to by destination
	// --------
	// *Params:
	//  destination - pointer to character array where the number will be copied
	void GetNumber(char *destination) { memcpy(destination, mBytes, mSize); }


	// Gets the size in bytes of the number
	// --------
	// *Returns:
	//  int - size of the number in bytes
	const int& GetSize() const { return mSize; }


private:

	int mSize;		// size of the array of bytes

	char *mBytes;	// array of bytes representing the number


	// copy the bytes from the union to mBytes in the specified order
	void MakeBytes(const char *numBytes, int size, int order);
};


#endif // _ANYENDIANNUMBER_H_