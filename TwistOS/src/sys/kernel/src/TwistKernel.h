/***************************************************************************
 * TwistKernel.h
 * -------------------------
 * Main operating system kernel class.
 *
 *
 * Author   : Mike Falcone
 * E-mail   : mr.falcone@gmail.com
 * Modified : 05/08/2009
 ***************************************************************************/

#ifndef _TWISTKERNEL_H_
#define _TWISTKERNEL_H_

#include <Twist.h>


class TwistKernel{

public:

	/* Constructor - constructs kernel object. Initialize() must be called after creating object.
	 * --------------
	 */
	TwistKernel();

	
	/* Initialize - initializes the kernel. Must be called after creating the kernel object.
	 * --------------
	 */
	void Initialize();
	
	
	
private:
	
	// make the kernel die with the specified reason
	void Die(const char *reason);
	
	
	
	// declare interrupt interface object. make class friend so we can pass private functions
	// to constructor
	friend class InterruptInterface;
	InterruptInterface *mInterruptInterface;
	
	// pointers to these functions will be sent to the InterruptInterface constructor
	BOOL OnPageFault();				// returns TRUE when page fault is fixed, FALSE otherwise
	void OnInterrupt(int intCode);	// called on hardware and software interrupts

};


#endif // _TWISTKERNEL_H_

