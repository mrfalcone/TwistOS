;========================================================================
; atapi_32.asm -- procedures for interfacing with ATAPI devices.
;
;
; PROCEDURES:
;-------------
;	ISR_ATA -- Called when the ATA IRQ is received.
;	ATAInit -- Initialize ATA devices to find the available ATAPI device.
;	ResetDevice -- Reset the current ATAPI device.
;	WaitForIRQ -- Wait for the ATAPI device to fire an interrupt.
;	WaitForReady -- Wait for the specified device ATAPI device to clear BSY bit.
;	IdentifyBus -- Find a present ATAPI device on the bus specified by EBX.
;	WaitForDRQ -- Waits for DRQ bit to be set in status register.
;	SendPacket -- Send the command packet to the ATAPI device.
;	ReadOneSector -- Reads one sector from the CD to the location specified by EAX.
;	ReadSectors -- Reads multiple contiguous sectors from the CD to the location specified by EAX.
;
;
;
; Updated: 04/12/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;------------------------------
; CONSTANTS
;------------------------------
ATA_WAIT_CYCLES			EQU 600		; number of loop cycles to wait for device to react to commands

ATA_TIMEOUT				EQU 6		; number of seconds before ATA device times out

ATA_ERROR_RETRY			EQU 50		; number of times to receive an error status before accepting it


;; bus 0 registers
REG_BUS0_DATAPORT		EQU 1F0h	; data port register for primary ATA bus
REG_BUS0_FEATURES		EQU 1F1h	; features / error info register for primary ATA bus
REG_BUS0_SECTORCOUNT	EQU 1F2h	; sector count register for primary ATA bus
REG_BUS0_LBA_L			EQU 1F3h	; low byte of sector address register for primary ATA bus
REG_BUS0_LBA_M			EQU 1F4h	; mid byte of sector address register for primary ATA bus
REG_BUS0_LBA_H			EQU 1F5h	; high byte of sector address register for primary ATA bus
REG_BUS0_DEVICE			EQU 1F6h	; device register for primary ATA bus
REG_BUS0_COMMAND		EQU 1F7h	; write commands/read status register for primary ATA bus
REG_BUS0_CONTROL		EQU 3F6h	; device control/alternate status register for primary ATA bus

;; bus 1 registers
REG_BUS1_DATAPORT		EQU 170h	; data port register for secondary ATA bus
REG_BUS1_FEATURES		EQU 171h	; features / error info register for secondary ATA bus
REG_BUS1_SECTORCOUNT	EQU 172h	; sector count register for secondary ATA bus
REG_BUS1_LBA_L			EQU 173h	; low byte of sector address register for secondary ATA bus
REG_BUS1_LBA_M			EQU 174h	; mid byte of sector address register for secondary ATA bus
REG_BUS1_LBA_H			EQU 175h	; high byte of sector address register for secondary ATA bus
REG_BUS1_DEVICE			EQU 176h	; device register for secondary ATA bus
REG_BUS1_COMMAND		EQU 177h	; write commands/read status register for secondary ATA bus
REG_BUS1_CONTROL		EQU 376h	; device control/alternate status register for secondary ATA bus
;------------------------------



;------------------------------
; PROGRAM DATA / STRINGS
;------------------------------

ATABus					DB 0		; this will store the ATA bus, 0=primary, 1=secondary
deviceRegValue			DB 0		; this will store the value of the device register for reading the drive

IRQReceived				DB 0		; this will be 1 after an IRQ is received
lastIRQFrom				DB 0		; this will be 1 if the last IRQ was received from the secondary bus


; register ports for the current device
regData					DW 0		; data register for current device
regFeatures				DW 0		; features / error info register for current device
regSectorCount			DW 0		; sector count register for current device
regLBA_L				DW 0		; low byte of lba register for current device
regLBA_M				DW 0		; mid byte of lba register for current device
regLBA_H				DW 0		; high byte of lba register for current device
regDevice				DW 0		; device register for current device
regCommand				DW 0		; commmand / status register for current device
regControl				DW 0		; control / alt status register for current device



;; command packet:
Packet:
	.com0	DB 0					; command 0 of data packet
	.com1	DB 0					; command 1 of data packet
	.com2	DB 0					; command 2 of data packet
	.com3	DB 0					; command 3 of data packet
	.com4	DB 0					; command 4 of data packet
	.com5	DB 0					; command 5 of data packet
	.com6	DB 0					; command 6 of data packet
	.com7	DB 0					; command 7 of data packet
	.com8	DB 0					; command 8 of data packet
	.com9	DB 0					; command 9 of data packet
	.com10	DB 0					; command 10 of data packet
	.com11	DB 0					; command 11 of data packet
	

;; strings:
strDev1		DB " ¯ ATAPI device: bus ",0
strDev2		DB ", device ",0
strDev3		DB ".",10,0


errNoATA		DB " ¯ !!!! Error: no ATAPI devices found!",10,0
errReadSectors	DB " ¯ !!!! Error: could not read disk sectors!",10,0
errPacket		DB " ¯ !!!! Error: disk packet error!",10,0
errResetting	DB " ¯ !!!! Error: cannot reset the disk!",10,0



;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: ISR_ATA -- Called when the ATA IRQ is received. EBX=0 means primary bus. EBX=1 means
;						secondary bus.
ISR_ATA:

	MOV [IRQReceived],BYTE 1		; an IRQ was received
	MOV [lastIRQFrom],BYTE BL		; store bus from which IRQ came

RET


; PROCEDURE: ATAInit -- Initialize ATA devices to find the available ATAPI device.
;
ATAInit:
	
	;; attempt to find the disk to read
	;  finds the first ATAPI device and expects disk to be inside it
	
	.testBus0:						; test bus 0
	MOV EBX,0						; specify to identify on bus 0, primary
	CALL IdentifyBus				; identify devices on bus
	
	CMP EAX,1						; test to see if a device was found on bus	
	JE .foundDevice					; we found the device
	
	
	.testBus1:						; otherwise test bus 1
	MOV EBX,1						; specify to identify on bus 1, secondary
	CALL IdentifyBus				; identify devices on bus
	
	CMP EAX,1						; test to see if a device was found on bus
	JE .foundDevice					; if so, move on
	
	JMP .noDevice					; if not, jump to no device
	
	
	.foundDevice:					; jump here whenever we find the device
	MOV ESI,strDev1					; get string
	CALL PrintString				; print it
	
	MOV EAX,0						; clear EAX
	MOV AL,[ATABus]					; get bus number
	CALL PrintNumber				; and print it
	
	MOV ESI,strDev2					; get string
	CALL PrintString				; print it
	
	MOV EAX,0						; clear EAX
	
	MOV AL,[deviceRegValue]			; get device number
	
	TEST AL,10000b					; see if the slave device is set
	JNZ .slave						; if it is set, the device is a slave
	
	MOV EAX,0						; otherwise set EAX to 0 for master device
	JMP .printDev					; print it
	
	.slave:
	MOV EAX,1						; we will print 1 if the device is slave
	
	.printDev:						; jump here to print device number
	CALL PrintNumber				; print the number
	
	
	MOV ESI,strDev3					; get string
	CALL PrintString				; print it	
	
	
	
	MOV ECX,0						; clear ECX
	MOV CL,[ATABus]					; get bus number
	
	JECXZ .bus0						; if bus 0
	
	
	.bus1:							; otherwise it's on bus 1
	
	; store register i/o ports:
	MOV [regData],WORD REG_BUS1_DATAPORT
	MOV [regFeatures],WORD REG_BUS1_FEATURES
	MOV [regSectorCount],WORD REG_BUS1_SECTORCOUNT
	MOV [regLBA_L],WORD REG_BUS1_LBA_L
	MOV [regLBA_M],WORD REG_BUS1_LBA_M
	MOV [regLBA_H],WORD REG_BUS1_LBA_H
	MOV [regDevice],WORD REG_BUS1_DEVICE
	MOV [regCommand],WORD REG_BUS1_COMMAND
	MOV [regControl],WORD REG_BUS1_CONTROL
	
	JMP .return						; go ahead and return
	
	
	.bus0:							; jump here if device is on bus 0
	
	; store register i/o ports:
	MOV [regData],WORD REG_BUS0_DATAPORT
	MOV [regFeatures],WORD REG_BUS0_FEATURES
	MOV [regSectorCount],WORD REG_BUS0_SECTORCOUNT
	MOV [regLBA_L],WORD REG_BUS0_LBA_L
	MOV [regLBA_M],WORD REG_BUS0_LBA_M
	MOV [regLBA_H],WORD REG_BUS0_LBA_H
	MOV [regDevice],WORD REG_BUS0_DEVICE
	MOV [regCommand],WORD REG_BUS0_COMMAND
	MOV [regControl],WORD REG_BUS0_CONTROL
	
	JMP .return						; go ahead and return
	
	
	.noDevice:						; jump here if there is no device found
	MOV ESI,errNoATA				; get error string
	CALL PrintString				; print it
	
	.hang:
	JMP .hang						; hang the system on error
	

	.return:
	
	MOV ECX,256						; will read 256 words
	MOV DX,[regData]				; get data register
	REP IN AX,DX					; read the words
	
	CALL ResetDevice				; reset the device
	
	CALL SleepSecond				; sleep for a second
	
RET



; PROCEDURE: ResetDevice -- Reset the current ATAPI device.
;
ResetDevice:
	
	CLI								; disable interrupts
	
	MOV ECX,ATA_ERROR_RETRY			; number of times to try resetting
	
	.reset:							; jump here to start resetting
	JECXZ .error					; if device can't be reset after enough tries, give the error
	DEC ECX							; decrement error counter
	
	MOV AL,[deviceRegValue]			; get device register value
	MOV DX,[regDevice]				; get device port
	OUT DX,AL						; send byte
	
	CALL ATAWait					; wait for device to react
	
	MOV AL,08h						; reset device command
	MOV DX,[regCommand]				; get command port
	OUT DX,AL						; send byte
	
	CALL ATAWait					; wait for device to react
	
	MOV EBX,0						; clear EBX, it will specify bus number
	MOV BL,[ATABus]					; get bus number
	CALL WaitForReady				; wait for device to be ready
	
	CMP EAX,1						; see if device is ready
	JNE .reset						; if not, try resetting again

	
	JMP .return
	
	
	.error:
	MOV ESI,errResetting			; get error string
	CALL PrintString				; print it
	
	.hang:
	JMP .hang						; hang the system on error
	
	
	.return:
	STI								; enable interrupts
	
RET



; PROCEDURE: WaitForIRQ -- Wait for the ATAPI device to fire an interrupt. EBX specifies device, 0 for primary
;							and 1 for slave. Returns EAX=0 if there is no IRQ or if there is an error. Returns
;							EAX=1 if an IRQ is received.
WaitForIRQ:

	PUSHAD							; store registers on the stack
	
	JMP .start						; jump to start of code
	
	.statReg	DW 0				; this will store the status port for the current bus
	.errReg		DW 0				; this will store the error port for the current bus
	
	.start:							; start of code

	
	CMP EBX,0						; check to see if we're waiting for bus 0
	JNE .bus1						; if not, it's secondary bus
	
	
	
	; get status register for bus 0:
	MOV [.statReg],WORD REG_BUS0_CONTROL
	
	; get error register for bus 0:
	MOV [.errReg],WORD REG_BUS0_FEATURES
	
	JMP .wait						; start waiting for IRQ
	
	.bus1:							; secondary bus
	; get status register for bus 1:
	MOV [.statReg],WORD REG_BUS1_CONTROL
	
	; get error register for bus 1:
	MOV [.errReg],WORD REG_BUS1_FEATURES
	
	
	
	;; wait for the IRQ
	.wait:							; begin waiting
	 
	 ;; defined in 'timer_32.asm':
	 CALL StartSecCounter			; begin counting seconds
	 
	 
	 MOV ECX,ATA_ERROR_RETRY		; number of times to detect an error before accepting it
	 
	  .checkError:					; check if error bit is set
	  JECXZ .noIRQ					; we used up all the error tries, so there will not be an irq
	 
	  DEC ECX						; decrement error counter
	 
	  MOV DX,[.statReg]				; get port number into DX
	  IN AL,DX						; read the status of bus
	 
	  TEST AL,1						; test if bit 0 is set (error bit)
	  JNZ .checkError				; if it is set, keep checking until all the tries are used	
	 
	 
	 ;; now check to see if the command was aborted
	 MOV DX,[.errReg]				; get port number into DX
	 IN AL,DX						; read the status of bus
	 TEST AL,100b					; see if abort bit is set
	 JNZ .noIRQ						; if it is, we're done
	  
	 
	 .keepWaiting:					; continue to wait for IRQ
	 
	 CALL GetCounterValue			; get number of seconds passed into EAX
	 
	 CMP EAX,ATA_TIMEOUT			; see if the counter reached the timeout limit
	 JNB .noIRQ						; if counter isn't below the limit, we have timed out
	 
	 
	 CMP [IRQReceived],BYTE 1		; see if an IRQ has been received yet
	 JNE .keepWaiting				; if not, continue to wait
	 
	 CMP [lastIRQFrom],BL			; see if the IRQ came from the bus we are waiting for
	 JE .IRQ						; if it is, we found the IRQ
	 
	 
	 ; otherwise just ignore the detected IRQ and keep waiting
	 MOV [IRQReceived],BYTE 0		; clear IRQReceived
	 MOV [lastIRQFrom],BYTE 0		; clear variable storing source of last irq
	 
	 JMP .keepWaiting				; keep waiting
	
	
	
	.noIRQ:							; jump here if there is no IRQ
	POPAD							; restore registers
	MOV EAX,0						; clear EAX, it means there was no IRQ
	JMP .return						; return

	
	.IRQ:							; jump here when we find an IRQ
	POPAD							; restore registers
	MOV EAX,1						; 1 means an IRQ was found

	
	.return:
	CALL StopSecCounter				; stop the counter
	
	MOV [IRQReceived],BYTE 0		; clear IRQReceived
	MOV [lastIRQFrom],BYTE 0		; clear variable storing source of last irq
	
RET



; PROCEDURE: ATAWait -- Loop ATA_WAIT_CYCLES cycles to give ATAPI device some time to work.
;
ATAWait:
	PUSH ECX						; store current ECX
	
	MOV ECX,ATA_WAIT_CYCLES			; get number of wait cycles

	.wait:							; begin waiting
	JECXZ .return					; return if ECX reaches 0
	DEC ECX							; decrement ECX
	JMP .wait						; wait some more

	.return:						; jump here to return
	POP ECX							; restore ECX
RET



; PROCEDURE: WaitForReady -- Wait for the specified device ATAPI device to clear BSY bit. If EAX=0,
;							wait for primary device on bus. EAX=1 specifies slave device. EBX specifies
;							bus number 0 or 1. Returns EAX=1 if the device is ready before ATA_TIMEOUT
;							seconds. Otherwise returns EAX=0.
WaitForReady:

	JMP .start						; jump to start of code
	
	.statReg	DW 0				; this will store the status port for the current bus

	
	.start:							; start of code

	
	CMP EBX,0						; check to see if we're waiting for bus 0
	JNE .bus1						; if not, it's secondary bus
	
	
	
	; get status register for bus 0:
	MOV [.statReg],WORD REG_BUS0_COMMAND
	JMP .wait						; start waiting for IRQ
	
	.bus1:							; secondary bus
	; get status register for bus 1:
	MOV [.statReg],WORD REG_BUS1_COMMAND
	
	
	
	;; wait for bsy to clear
	.wait:							; begin waiting
	
	
	MOV ECX,ATA_ERROR_RETRY			; get retry count into ECX
	
	.checkError:					; check to see if the error bit is set
	 JECXZ .notReady				; if all the errors are used up the device is not ready
	 
	 DEC ECX						; decrement error counter
	 
	 MOV DX,[.statReg]				; get port number into DX
	 IN AL,DX						; read the status of bus
	 
	 TEST AL,1						; test if bit 0 is set (error bit)
	JNZ .checkError					; if it is set, keep checking until all the tries are used	
	
	
	;; defined in 'timer_32.asm':
	CALL StartSecCounter			; begin counting seconds
	
	.keepWaiting:					; continue to wait

	CALL GetCounterValue			; get number of seconds passed into EAX
	
	CMP EAX,ATA_TIMEOUT				; see if the counter reached the timeout limit
	JNB .notReady					; if counter isn't below the limit, we have timed out
	
	
	MOV DX,[.statReg]				; get status port
	IN AL,DX						; read the status of bus

	
	TEST AL,10000000b				; test the busy bit
	JNZ .keepWaiting				; if the bit is set, keep waiting
	

	JMP .ready						; otherwise, the device is ready
	
	
	.notReady:						; jump here if the device is not ready
	MOV EAX,0						; 0 means not ready
	JMP .return						; return
	
	
	.ready:							; jump here when device becomes ready
	MOV EAX,1						; 1 means ready
	

	.return:						; jump here to return
RET



; PROCEDURE: IdentifyBus -- Find a present ATAPI device on the bus specified by EBX. Returns EAX=1 if an ATAPI
;							device is found and sets the deviceRegValue and ATABus variables to appropriate
;							values. Returns EAX=0 if no device is found.
IdentifyBus:

	JMP .start						; jump to start of code
	
	.idBus		DB 0				; this stores the number of bus on which we are looking for a device
	.devReg		DW 0				; this will store the device register port
	.comReg		DW 0				; this will store the command register port
	.ctrlReg	DW 0				; this will store the control register port
	.featReg	DW 0				; this will store the features register port
	
	
	.start:							; start of code
	
	MOV [.idBus],BL					; store the bus we are id'ing
	
	CMP EBX,0						; see if we are checking the primary bus
	JNE .secondaryBus				; if not, we must be checking secondary
	
	.primaryBus:					; jump here if on primary bus
	MOV [.devReg],WORD REG_BUS0_DEVICE
	MOV [.comReg],WORD REG_BUS0_COMMAND
	MOV [.ctrlReg],WORD REG_BUS0_CONTROL
	MOV [.featReg],WORD REG_BUS0_FEATURES
	JMP .beginChecking				; begin the check
	
	.secondaryBus:					; jump here if on secondary bus
	MOV [.devReg],WORD REG_BUS1_DEVICE
	MOV [.comReg],WORD REG_BUS1_COMMAND
	MOV [.ctrlReg],WORD REG_BUS1_CONTROL
	MOV [.featReg],WORD REG_BUS1_FEATURES
	
	
	
	.beginChecking:					; jump here to actually begin checking devices
	
	;; make sure device is attached to bus
	MOV DX,[.comReg]				; read status from this port
	IN AL,DX						; get the status byte
	CMP AL,0FFh						; if the value is 0xFF then the bus has no devices
	JNE .devAttached				; if not, move on
	JMP .notFound					; if so, return with not found status
	
	.devAttached:					; jump here if device is attached to bus
	MOV AL,0						; null byte to send to features register
	MOV DX,[.featReg]				; get features register of bus
	OUT DX,AL						; send byte to the control register
	
	.idPrimaryDevice:				; identify the primary device on the bus

	MOV EAX,0						; clear EAX, it will specify primary device
	
	MOV DX,[.devReg]				; get device register
	OUT DX,AL						; send the device selection to the device register
	CALL ATAWait					; wait for the command to take effect
	MOV [deviceRegValue],AL			; store the value of the device register
	
	
	MOV EBX,0						; clear EBX, it will specify bus number
	MOV BL,[.idBus]					; get bus number
	CALL WaitForReady				; wait for the device to be ready
	
	CMP EAX,1						; see if device is ready
	JNE .idSlaveDevice				; if not ready, check out slave device
	
	
	;; otherwise identify the device
	
	.identify:						; jump here to begin identifying device
	
	MOV AL,0A1h						; IDENTIFY PACKET DEVICE command byte

	
	MOV DX,[.comReg]				; get command register
	OUT DX,AL						; send byte to the command register
	CALL ATAWait					; wait for the command to take effect
	
	
	MOV AL,0						; null byte to send to control register
	
	MOV DX,[.ctrlReg]				; get control register of bus
	OUT DX,AL						; send byte to the control register
	
	
	MOV EBX,0						; clear EBX
	MOV BL,[.idBus]					; specify that we wait for IRQ from selected bus
	CALL WaitForIRQ					; wait for the IRQ
	
	CMP EAX,1						; see if an IRQ was received
	JNE .doneWithId					; if not, we're done with this ID
	
	JMP .found						; if an IRQ was received, an atapi device was found	
	
	
	.doneWithId:					; jump here when finished id'ing a device
	MOV EAX,0						; clear EAX
	MOV AL,[deviceRegValue]			; get the value of the device register
	TEST EAX,10000b					; if test passes we just finished checking the slave
	
	JNZ .notFound					; if done with the slave, nothing was found
	

	.idSlaveDevice:					; identify the slave device on the bus

	MOV EAX,10000b					; specify slave device
	
	MOV DX,[.devReg]				; get device register
	OUT DX,AL						; send the device selection to the device register
	CALL ATAWait					; wait for the command to take effect
	MOV [deviceRegValue],AL			; store the value of the device register
	

	MOV EBX,0						; clear EBX
	MOV BL,[.idBus]					; get bus number
	CALL WaitForReady				; wait for the device to be ready
	
	CMP EAX,1						; see if device is ready
	JNE .notFound					; if not ready, return specifying no device found
	
	JMP .identify					; try to identify the device
	
	
	.notFound:						; jump here if nothing is found
	MOV EAX,0						; means device was not found
	JMP .return						; return
	
	
	.found:							; jump here if device is found
	MOV BL,[.idBus]					; get the number of the bus we need to id
	MOV [ATABus],BL					; ata bus 0	
	MOV EAX,1						; means device was found
	
	.return:
RET



; PROCEDURE: WaitForDRQ -- Waits for DRQ bit to be set in status register. Waits until ATA_TIMEOUT
;							seconds before failing. Returns EAX=0 if DRQ was not received. Otherwise
;							EAX=1.
WaitForDRQ:


	;; defined in 'timer_32.asm':
	CALL StartSecCounter			; begin counting seconds
	
	
	.keepWaiting:					; continue to wait for IRQ
	
	CALL GetCounterValue			; get number of seconds passed into EAX
	
	CMP EAX,ATA_TIMEOUT				; see if the counter reached the timeout limit
	JNB .error						; if counter isn't below the limit, we have timed out
	
	
	MOV DX,[regCommand]				; get port number of status register into DX
	IN AL,DX						; read the status of bus
	
	TEST AL,10000000b				; test if BSY bit is set
	JNZ .keepWaiting				; if it is set, keep waiting
	
	TEST AL,00001000b				; test the drq bit
	JNZ .DRQ						; if it is set, and error isn't, and bsy isn't, everything is good
	
	
	MOV ECX,ATA_ERROR_RETRY			; number of times to detect an error before accepting it
	
	 .checkError:					; check if error bit is set
	 JECXZ .error					; we used up all the error tries, so there is an error
	 
	 DEC ECX						; decrement error counter
	 
	 MOV DX,[regControl]			; get port number of status register into DX
	 IN AL,DX						; read the status of bus
	 
	 TEST AL,1						; test if bit 0 is set (error bit)
	 JNZ .checkError				; if it is set, keep checking until all the tries are used	
	 
	
	JMP .keepWaiting				; keep waiting

	
	.error:							; jump here on error
	MOV EAX,0						; 0 means no DRQ set
	JMP .return						; return now
	
	
	.DRQ:							; jump here when drq is detected
	MOV EAX,1						; 1 means DRQ was set
	
	
	.return:
	CALL StopSecCounter				; stop the counter
RET



; PROCEDURE: SendPacket -- Send the command packet to the ATAPI device. EAX must contain the count
;							of maximum bytes to read. Hangs system on error.
SendPacket:

	JMP .start						; jump to start of code
	
	.sendRetries	DB 0			; this will store the retry counter for sending the packet
	.comRetries		DB 0			; this will store the retry counter for sending the command data
	
	
	.start:							; start of code

	PUSH EAX						; push byte count on to stack

	; setup the send retry counter
	MOV [.sendRetries],BYTE ATA_ERROR_RETRY
	
	
	.startSending:					; start sending packet data
	
	DEC BYTE [.sendRetries]			; decrement the retry counter
	
	
	; setup the send retry counter
	MOV [.comRetries],BYTE ATA_ERROR_RETRY
	
	.startCommand:					; jump here to start sending commands
	
	CMP [.comRetries],BYTE 0		; see if retry counter has reached 0
	JNE .send						; if not, send the command
	JMP .error						; if it is, there's an error
	
	
	.send:							; jump here to begin sending
	DEC BYTE [.comRetries]			; decrement the retry counter
	

	MOV AL,[deviceRegValue]			; get device register value
	MOV DX,[regDevice]				; get device port
	OUT DX,AL						; send byte
	
	CALL ATAWait					; wait for device to react
	

	MOV AL,0						; specify PIO transfer
	MOV DX,[regFeatures]			; get features port
	OUT DX,AL						; send byte


	MOV AL,0						; sector count is unused
	MOV DX,[regSectorCount]			; get sec count port
	OUT DX,AL						; send byte
	
	
	MOV AL,0						; low byte of lba is unused
	MOV DX,[regLBA_L]				; get low lba port
	OUT DX,AL						; send byte
	

	;; set byte count limit
	MOV EAX,[ESP]					; get byte count limit from stack but keep it there
	
	MOV DX,[regLBA_M]				; get mid lba port
	OUT DX,AL						; send low byte of byte count

	
	MOV AL,AH						; put high byte into AL
	MOV DX,[regLBA_H]				; get mid lba port
	OUT DX,AL						; send high byte of byte count

	
	MOV AL,0A0h						; PACKET command byte
	MOV DX,[regCommand]				; get command port
	OUT DX,AL						; send byte
	
	
	CALL WaitForDRQ					; wait for drq bit to be set
	
	CMP EAX,1						; see if returned with DRQ set
	JNE .startCommand				; if not, retry
	
	
	MOV DX,[regSectorCount]			; get interrupt reason port
	IN AL,DX						; get interrupt reason
	
	TEST AL,1						; see if bit 0 is set
	JZ .error						; if not, there is an error

	TEST AL,2						; see if bit 1 is set
	JNZ .error						; if it is, there is an error
	
	;; now send the packet data
	
	
	
	MOV ESI,Packet					; get packet address into ESI

	MOV EDX,[regData]				; get data register
	
	
	MOV ECX,6						; we are going to send 6 words
	
	;REP OUTSW						; send the words
	
	
	CALL ATAWait					; let device react
	
	
	.sendPacket:						; begin sending the packet
	JECXZ .doneSending				; if we have sent all the words, we're done
	
	DEC ECX							; decrement word counter
	
	OUTSW							; send the word
	
	CALL ATAWait					; let device react
	
	JMP .sendPacket					; loop back and send more
	
	.doneSending:					; jump here when done sending
	
	
	MOV EBX,0						; clear EBX
	MOV BL,[ATABus]					; get bus number to wait for IRQ
	
	;CALL WaitForIRQ					; now wait for the IRQ from device
	
	CALL WaitForReady				; wait for device to be ready with data
	
	CMP EAX,1						; see if device is ready
	JNE .error						; if not, there's an error
	
	CALL ATAWait					; let device react
	

	MOV DX,[regSectorCount]			; get interrupt reason port
	IN AL,DX						; get interrupt reason
	
	TEST AL,10b						; see if bit 1 is set indicating transfer to host
	JZ .error						; if not, there is an error
	
	TEST AL,1						; see if bit 0 is set
	JNZ .error						; if it is, there is an error
	

	;; test sense key
	MOV EAX,0						; clear EAX
	MOV DX,[regFeatures]			; error register
	IN AL,DX						; read error byte
	
	SHR AL,4						; shift 4 bits so only sense key is left
	CMP AL,1						; see if sense key is 0 or 1
	JA .error						; if it's not, there's an error
	

	JMP .return						; return
	
	
	.error:							; jump here on error
	
	CMP BYTE [.sendRetries],0		; see if retry counter has reached 0
	JNE .startSending				; if it hasn't, try sending the packet again
	
	
	MOV ESI,errPacket				; get error string
	CALL PrintString				; and print it
	
	MOV EAX,0						; clear EAX
	MOV DX,[regFeatures]			; error register
	IN AL,DX						; read error byte
	
	CALL PrintNumber				; print the value
	
	
	.hang:
	JMP .hang						; hang system on error
	
	.return:
	
	POP EAX							; be sure to get EAX off the stack
RET


; PROCEDURE: ReadOneSector -- Reads one sector from the CD to the location specified by EAX.
;								EBX specifies the block number to read. Hangs system on error.
ReadOneSector:

	PUSH EAX						; store read location
	PUSH EBX						; store block
	
	CALL ResetDevice				; reset the device

	POP EBX							; get block off stack

	;; setup packet bytes
	MOV [Packet.com0],BYTE 28h		; Read(10) command
	
	MOV [Packet.com1],BYTE 0		; null second byte
	
	
	MOV [Packet.com5],BL			; store least significant byte of lba

	MOV [Packet.com4],BH			; store next byte
	
	SHR EBX,16						; shift next word into BX
	
	MOV [Packet.com3],BL			; store next byte
	
	MOV [Packet.com2],BH			; store most significant byte of lba
	
	
	MOV [Packet.com6],BYTE 0		; byte must be 0
	
	
	MOV EAX,1						; number of blocks to transfer
	
	MOV [Packet.com8],AL			; store most significant byte of transfer size
	MOV [Packet.com7],AH			; store next byte
	
	
	; the rest of the bytes are 0
	MOV [Packet.com9],BYTE 0		; set null byte
	MOV [Packet.com10],BYTE 0		; set null byte
	MOV [Packet.com11],BYTE 0		; set null byte
	
	
	
	; setup packet bytes
	; MOV [Packet.com0],BYTE 0BEh		; Read CD command
	
	; MOV [Packet.com1],BYTE 1000b	; set sector type to mode 1 (2048 bytes)
	
	
	; MOV [Packet.com5],BL			; store most significant byte of lba
	
	; MOV [Packet.com4],BH			; store next byte
	
	; SHR EBX,16						; shift next word into BX
	
	; MOV [Packet.com3],BL			; store next byte
	
	; MOV [Packet.com2],BH			; store least significant byte of lba

	
	; MOV EAX,1						; number of blocks to transfer
	
	; MOV [Packet.com8],AL			; store most significant byte of transfer size
	; MOV [Packet.com7],AH			; store next byte
	
	; SHR EAX,16						; shift next word into AX
	; MOV [Packet.com6],AL			; store least significant byte of transfer size
	
	
	; MOV [Packet.com9],BYTE 10h		; set main channel selection to user data
	
	; ; the rest of the bytes are 0
	; MOV [Packet.com10],BYTE 0		; set null byte
	; MOV [Packet.com11],BYTE 0		; set null byte
	
	

	MOV EAX,2048					; byte count limit of packet transfer
	CALL SendPacket					; send the packet to the device
	

	;; read the data in now
	
	CLI								; disable interrupts
	
	
	;; get the number of bytes read
	MOV EAX,0						; clear EAX to store byte count
	
	MOV DX,[regLBA_H]				; this register contains the high byte of the byte count
	IN AL,DX						; read the high byte into AL
	MOV AH,AL						; move it to AH

	MOV DX,[regLBA_M]				; this register contains the mid byte of the byte count
	IN AL,DX						; read the low byte into AL	
	
	MOV ECX,EAX						; move the byte count into ECX
	
	
	POP EBX							; get read location off stack into EBX
	

	.readSector:					; read the sector
	CMP ECX,0						; see if we have read all the bytes
	JNA .doneWithSector				; if so, we're done reading
	
	MOV DX,[regData]				; get data port
	IN AX,DX						; get the data word into AX
	
	MOV BYTE [EBX],AL				; move first byte to store location
	INC EBX							; increment store location
	DEC ECX							; decrement byte count
	
	MOV BYTE [EBX],AH				; move second byte to store location
	INC EBX							; increment store location
	DEC ECX							; decrement byte count
	
	JMP .readSector					; loop back to keep reading
	
	.doneWithSector:				; jump here when done reading the sector
	
	
	STI								; re-enable interrupts
	
	JMP .return						; return successfully
	
	
	.error:							; jump here on error
	MOV ESI,errReadSectors			; get error string
	CALL PrintString				; and print it
	
	.hang:
	JMP .hang						; hang system on error	
	
	
	.return:
	CALL SleepSecond				; give device some time
RET



; PROCEDURE: ReadSectors -- Reads multiple contiguous sectors from the CD to the location specified by EAX.
;								EBX specifies the block number to start. ECX specifies number of block to read.
;								Hangs system on error.
ReadSectors:
	PUSH EAX						; store read location
	PUSH ECX						; store number of blocks
	PUSH EBX						; store block
	
	CALL ResetDevice				; reset the device

	POP EBX							; get block off stack

	;; setup packet bytes
	MOV [Packet.com0],BYTE 28h		; Read(10) command
	
	MOV [Packet.com1],BYTE 0		; null second byte
	
	
	MOV [Packet.com5],BL			; store least significant byte of lba

	MOV [Packet.com4],BH			; store next byte
	
	SHR EBX,16						; shift next word into BX
	
	MOV [Packet.com3],BL			; store next byte
	
	MOV [Packet.com2],BH			; store most significant byte of lba
	
	
	MOV [Packet.com6],BYTE 0		; byte must be 0
	
	
	POP ECX							; get number of blocks to transfer from the stack
	
	MOV [Packet.com8],CL			; store most significant byte of transfer size
	MOV [Packet.com7],CH			; store next byte
	
	
	; the rest of the bytes are 0
	MOV [Packet.com9],BYTE 0		; set null byte
	MOV [Packet.com10],BYTE 0		; set null byte
	MOV [Packet.com11],BYTE 0		; set null byte
	
	
	; get byte count limit of packet transfer into EAX
	MOV EAX,2048					; size of a block
	MUL ECX							; multiply it by number of blocks to transfer
	
	PUSH EAX						; store byte count on stack
	
	CALL SendPacket					; send the packet to the device
	

	;; read the data in now
	
	CLI								; disable interrupts
	
	
	POP EAX							; get total byte count off stack
	POP EBX							; get read location off stack into EBX
	
	
	.startRead:						; begin reading data
	PUSH EAX						; store total byte count on stack

	;; get the number of bytes read
	MOV EAX,0						; clear EAX to store byte count
	
	MOV DX,[regLBA_H]				; this register contains the high byte of the byte count
	IN AL,DX						; read the high byte into AL
	MOV AH,AL						; move it to AH

	MOV DX,[regLBA_M]				; this register contains the mid byte of the byte count
	IN AL,DX						; read the low byte into AL	
	
	MOV ECX,EAX						; move the byte count into ECX
	PUSH EAX						; store read byte count on stack


	.readSectors:					; read the sectors
	CMP ECX,0						; see if we have read all the bytes
	JNA .doneWithSectors			; if so, we're done reading
	
	MOV DX,[regData]				; get data port
	IN AX,DX						; get the data word into AX
	
	MOV BYTE [EBX],AL				; move first byte to store location
	INC EBX							; increment store location
	DEC ECX							; decrement byte count
	
	MOV BYTE [EBX],AH				; move second byte to store location
	INC EBX							; increment store location
	DEC ECX							; decrement byte count
	
	JMP .readSectors				; loop back to keep reading
	
	.doneWithSectors:				; jump here when done reading the sectors
	POP ECX							; get read byte count off stack
	POP EAX							; get total byte count off stack
	
	SUB EAX,ECX						; subtract read byte count from total count
	
	CMP EAX,0						; compare total bytes left to 0
	JBE .doneReading				; if not above 0, we're done reading
	
	PUSH EAX						; store total bytes
	
	STI
	CALL WaitForDRQ					; wait for more data to be ready
	CMP EAX,1						; make sure the DRQ was received
	JNE .error						; if not, there's an error
	CLI
	
	POP EAX							; get total bytes off stack
	
	JMP .startRead					; go back to read more bytes
	
	
	
	.doneReading:					; jump here when done reading all bytes
	
	STI								; re-enable interrupts
	
	JMP .return						; return successfully
	
	
	.error:							; jump here on error
	MOV ESI,errReadSectors			; get error string
	CALL PrintString				; and print it
	
	.hang:
	JMP .hang						; hang system on error	
	
	
	.return:
	CALL SleepSecond				; give device some time
RET




