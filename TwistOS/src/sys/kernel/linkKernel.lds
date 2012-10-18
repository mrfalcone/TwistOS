


/* necessary general linking options */
OUTPUT_FORMAT("binary")


ENTRY(ExecutionPoint)		/* entry point of program */



origin		= 0xC0000000;	/* where program is loaded into memory */
alignment	= 4096;			/* byte count of each section's alignment boundary */



SECTIONS
{

	/*.ebcHeader*/
	

	.text origin : AT(origin)
	{
		textStart = .;
		*(.text)
		*(.rodata)
		. = ALIGN(alignment);
	}


	.data  : AT( origin + (ctorsStart - textStart) ) 
	{
		ctorsStart = .;
		*(.ctor*)
		ctorsEnd = .;
		dtorsStart = .;
		*(.dtor*)
		dtorsEnd = .;
		
		dataStart = .;
		*(.data)
		. = ALIGN(alignment);
	}

	
	.bss  : AT( origin + (bssStart - textStart) ) 
	{
		bssStart = .;
		*(.bss)
		. = ALIGN(alignment);
	}

	
	end = .;
}
