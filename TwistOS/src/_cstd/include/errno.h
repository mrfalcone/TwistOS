/* ==============================================================
 * errno.h  : Defines system-wide error numbers.
 * --------------------------------------------------------------
 *
 * Author   : Mike Falcone
 * Email    : mr.falcone@gmail.com
 * Modified : 4/29/09
 * ==============================================================
 */
 
#ifndef __ERRNO_H_
#define __ERRNO_H_


/* declare a reference to errno */
int _getErrno(void);
void _setErrno(int);
#define errno	_getErrno()



/* error codes */
#define EUNKNOW	1		/* unspecified error occurred */
#define EDOM	2		/* math function argument out of domain */
#define EILSEQ	3		/* illegal byte sequence */
#define ERANGE	4		/* result out of range */
#define EDIVZ	5		/* divide by zero error */
#define EOVRFL	6		/* overflow error */
#define EIOPC	7		/* invalid OPCode */
#define ENODEV	8		/* device not available */
#define EDBLFLT	9		/* double fault error */
#define ESTACKF	10		/* stack fault exception */
#define EGPF	11		/* general protection fault */
#define EPFE	12		/* could not recover from page fault exception */




#endif /* __ERRNO_H_ */
