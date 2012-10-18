/***************************************************************************
 * InterruptInterface.h
 * -------------------------
 * Installs the Interrupt Descriptor Table and provides a routine for
 * aborting the system.
 *
 * Implemented in assembly.
 *
 *
 * Author   : Mike Falcone
 * E-mail   : mr.falcone@gmail.com
 * Modified : 05/08/2009
 ***************************************************************************/

#ifndef _INTERRUPTINTERFACE_H_
#define _INTERRUPTINTERFACE_H_


#include <Twist.h>

// defines interrupt codes:
#include "InterruptCodes.h"


class TwistKernel;


class InterruptInterface{

public:
	
	/* Constructor - sets up the IDT.
	 * --------------
	 * Params
	 *  @in : onPageFault - pointer to function in class TwistKernel to call when page fault occurs
	 *  @in : onInterrupt - pointer to function in class TwistKernel to call when an interrupt occurs
	 */
	InterruptInterface(BOOL (TwistKernel::*onPageFault)(void), void (TwistKernel::*onInterrupt)(int));

	
	
	/* Abort - aborts the OS and halts the system, displaying an error screen.
	 * --------------
	 * Params
	 *  @in : reason - C string explaining the reason for aborting
	 */
	void Abort(const char *reason);
	
	
	
	/* GetVecLINT0 - get number of interrupt to call when an interrupt is signaled at the LINT0 pin.
	 * -Used by the APIC.
	 * --------------
	 * Return
	 *  int - interrupt to call when an interrupt is signaled at the LINT0 pin
	 */
	int GetVecLINT0();
	

	
	/* GetVecLINT1 - get number of interrupt to call when an interrupt is signaled at the LINT1 pin.
	 * -Used by the APIC.
	 * --------------
	 * Return
	 *  int - interrupt to call when an interrupt is signaled at the LINT1 pin
	 */
	int GetVecLINT1();
	
	
	
	/* GetVecAPICError - get number of interrupt to call when the APIC detects an error
	 * -Used by the APIC.
	 * --------------
	 * Return
	 *  int - interrupt to call when the APIC detects an error
	 */
	int GetVecAPICError();
	
	
	
	/* GetVecThermalSensor - get number of interrupt to call when the thermal sensor generates an interrupt
	 * -Used by the APIC.
	 * --------------
	 * Return
	 *  int - interrupt to call when the thermal sensor generates an interrupt
	 */
	int GetVecThermalSensor();
	
	
	
	/* GetVecAPICTimer - get number of interrupt to call when the APIC timer signals an interrupt
	 * -Used by the APIC.
	 * --------------
	 * Return
	 *  int - interrupt to call when the APIC timer signals an interrupt
	 */
	int GetVecAPICTimer();

};


#endif // _INTERRUPTINTERFACE_H_
