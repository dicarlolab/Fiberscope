
/***********************************************************************************/
/**                                                                               **/
/**   Project:      alp   (ALP DLL)                                               **/
/**   Filename:     alp.h : Header File                                           **/
/**                                                                               **/
/***********************************************************************************/
/**                                                                               **/
/**   © 2004-2013 ViALUX GmbH. All rights reserved.                               **/
/**                                                                               **/
/***********************************************************************************/
/**                                                                               **/
/**   Version:        12                                                          **/
/**                                                                               **/
/***********************************************************************************/


#ifndef _ALP_H_INCLUDED
#define _ALP_H_INCLUDED


#ifndef ALP_API

#define ALP_ATTR

#ifdef __cplusplus
#define ALP_API extern "C" __declspec(dllimport)
#else /* __cplusplus */
#define ALP_API __declspec(dllimport)
#endif /* __cplusplus */

#endif

/* Configure the compiler to not add padding bytes to structures: */
#pragma pack(push, 1)

/* /////////////////////////////////////////////////////////////////////////// */

/*		standard parameter */

typedef unsigned long						ALP_ID;
#define ALP_INVALID_ID ((ALP_ID)-1)
	/* "New" ALP API versions set ALP_ID output parameters to this value on errors.
	On success, they avoid this code as valid ALP_ID (device, sequence, or queue ID).
	ALP_DEFAULT is 0, so it may be good to have a different special value */

#define ALP_DEFAULT							0L


/* /////////////////////////////////////////////////////////////////////////// */

/*		return codes */

#define ALP_OK				0x00000000L		/*	successfull execution */
#define ALP_NOT_ONLINE			1001L		/*	The specified ALP has not been found or is not ready. */
#define ALP_NOT_IDLE			1002L		/*	The ALP is not in idle state. */
#define ALP_NOT_AVAILABLE		1003L		/*	The specified ALP identifier is not valid. */
#define ALP_NOT_READY			1004L		/*	The specified ALP is already allocated. */
#define ALP_PARM_INVALID		1005L		/*	One of the parameters is invalid. */
#define ALP_ADDR_INVALID		1006L		/*	Error accessing user data. */
#define ALP_MEMORY_FULL			1007L		/*	The requested memory is not available. */
#define ALP_SEQ_IN_USE			1008L		/*	The sequence specified is currently in use. */
#define ALP_HALTED				1009L		/*	The ALP has been stopped while image data transfer was active. */
#define ALP_ERROR_INIT			1010L		/*	Initialization error. */
#define ALP_ERROR_COMM			1011L		/*	Communication error. */
#define ALP_DEVICE_REMOVED		1012L		/*	The specified ALP has been removed. */
#define ALP_NOT_CONFIGURED		1013L		/*	The onboard FPGA is unconfigured. */
#define ALP_LOADER_VERSION		1014L		/*	The function is not supported by this version of the driver file VlxUsbLd.sys. */
#define ALP_ERROR_POWER_DOWN	1018L		/*	waking up the DMD from PWR_FLOAT did not work (ALP_DMD_POWER_FLOAT) */


/* for ALP_DEV_STATE in AlpDevInquire */

#define ALP_DEV_BUSY			1100L		/*	the ALP is displaying a sequence or image data download is active */
#define ALP_DEV_READY			1101L		/*	the ALP is ready for further requests */
#define ALP_DEV_IDLE			1102L		/*	the ALP is in wait state */


/* for ALP_PROJ_STATE in AlpProjInquire */

#define ALP_PROJ_ACTIVE			1200L		/*	ALP projection active */
#define ALP_PROJ_IDLE			1201L		/*	no projection active */


/* /////////////////////////////////////////////////////////////////////////// */

/*		parameter */

/* AlpDevInquire */

#define ALP_DEVICE_NUMBER		2000L	/*	Serial number of the ALP device */
#define ALP_VERSION				2001L	/*	Version number of the ALP device */
#define ALP_DEV_STATE			2002L	/*	current ALP status, see above */
#define ALP_AVAIL_MEMORY		2003L	/*	ALP on-board sequence memory available for further sequence */
										/*	allocation (AlpSeqAlloc); number of binary pictures */
/* Temperatures. Data format: signed long with 1 LSB=1/256 °C */
#define ALP_DDC_FPGA_TEMPERATURE	2050L	/* V4100 Rev B: LM95231.
	External channel: DDC FPGAs Temperature Diode */
#define ALP_APPS_FPGA_TEMPERATURE	2051L	/* V4100 Rev B: LM95231.
	External channel: Application FPGAs Temperature Diode */
#define ALP_PCB_TEMPERATURE			2052L	/* V4100 Rev B: LM95231.
	Internal channel. "Board temperature" */

/*	AlpDevControl - ControlTypes & ControlValues */
#define ALP_SYNCH_POLARITY		2004L	/*  Select frame synch output signal polarity */
#define ALP_TRIGGER_EDGE		2005L	/*  Select active input trigger edge (slave mode) */
#define ALP_LEVEL_HIGH			2006L	/*  Active high synch output */
#define ALP_LEVEL_LOW			2007L	/*  Active low synch output */
#define ALP_EDGE_FALLING		2008L	/*  High to low signal transition */
#define ALP_EDGE_RISING 		2009L	/*  Low to high signal transition */

#define ALP_TRIGGER_TIME_OUT	2014L	/*	trigger time-out (slave mode) */
#define ALP_TIME_OUT_ENABLE 	   0L	/*	Time-out enabled (default) */
#define ALP_TIME_OUT_DISABLE 	   1L	/*	Time-out disabled */

#define ALP_USB_CONNECTION		2016L	/*	Re-connect after a USB interruption */

#define ALP_DEV_DMDTYPE			2021L	/*	Select DMD type; only allowed for a new allocated ALP-3 high-speed device */
#define ALP_DMDTYPE_XGA			   1L	/*	1024*768 mirror pixels (0.7" Type A, D3000) */
#define ALP_DMDTYPE_SXGA_PLUS	   2L	/*	1400*1050 mirror pixels (0.95" Type A, D3000) */
#define ALP_DMDTYPE_1080P_095A	   3L	/*	1920*1080 mirror pixels (0.95" Type A, D4x00) */
#define ALP_DMDTYPE_XGA_07A		   4L	/*	1024*768 mirror pixels (0.7" Type A, D4x00) */
#define ALP_DMDTYPE_XGA_055A	   5L	/*	1024*768 mirror pixels (0.55" Type A, D4x00) */
#define ALP_DMDTYPE_XGA_055X	   6L	/*	1024*768 mirror pixels (0.55" Type X, D4x00) */
#define ALP_DMDTYPE_WUXGA_096A	   7L	/*	1920*1200 mirror pixels (0.96" Type A, D4100) */
#define ALP_DMDTYPE_DISCONNECT	 255L	/*	behaves like 1080p (D4100) */

#define ALP_DEV_DISPLAY_HEIGHT	2057L	/* number of mirror rows on the DMD */
#define ALP_DEV_DISPLAY_WIDTH	2058L	/* number of mirror columns on the DMD */

#define ALP_DEV_DMD_MODE        2064L	/* query/set DMD PWR_FLOAT mode, valid options:
	ALP_DEFAULT (normal operation: "wake up DMD"), ALP_DMD_POWER_FLOAT */
#define ALP_DMD_POWER_FLOAT        1L	/* power down, release micro mirrors from deflected state */

#define ALP_PWM_LEVEL			2063L	/* PWM pin duty-cycle as percentage: 0..100%; after AlpDevAlloc: 0% */

/* AlpDevControlEx */
#define ALP_DEV_DYN_SYNCH_OUT1_GATE 2023L
#define ALP_DEV_DYN_SYNCH_OUT2_GATE 2024L
#define ALP_DEV_DYN_SYNCH_OUT3_GATE 2025L

struct tAlpDynSynchOutGate {
	/* For ControlType ALP_DEV_DYN_TRIG_OUT[1..3]_GATE of function AlpDevControlEx */
	/* Configure compiler to not insert padding bytes! (e.g. #pragma pack) */
	char unsigned Period;	/* #Period=1..16 enables output; 0: tri-state */
	char unsigned Polarity;	/* 0: active pulse is low, 1: high */
	char unsigned Gate[16];	/* #Period number of bytes; each one is 0 or 1
		Only the first #Period bytes are used! */
};


/* AlpSeqControl - ControlTypes */
#define ALP_SEQ_REPEAT			2100L	/*	Non-continuous display of a sequence (AlpProjStart) allows */
										/*	for configuring the number of sequence iterations. */
#define ALP_SEQ_REPETE ALP_SEQ_REPEAT	/*  According to the typo made in primary documentation (ALP API description) */
#define ALP_FIRSTFRAME			2101L	/*	First image of this sequence to be displayed. */
#define ALP_LASTFRAME			2102L	/*	Last image of this sequence to be displayed. */

#define ALP_BITNUM				2103L	/*	A sequence can be displayed with reduced bit depth for faster speed. */
#define ALP_BIN_MODE			2104L	/*	Binary mode: select from ALP_BIN_NORMAL and ALP_BIN_UNINTERRUPTED (AlpSeqControl) */

#define ALP_BIN_NORMAL			2105L	/*	Normal operation with progammable dark phase */
#define ALP_BIN_UNINTERRUPTED	2106L	/*	Operation without dark phase */

#define ALP_PWM_MODE			2107L	/* ALP_DEFAULT, ALP_FLEX_PWM */
#define ALP_FLEX_PWM			   3L	/* ALP_PWM_MODE: all bit planes of the sequence are displayed as
	fast as possible in binary uninterrupted mode;
	use ALP_SLAVE mode to achieve a custom pulse-width modulation timing for generating gray-scale */

#define ALP_DATA_FORMAT			2110L	/*	Data format and alignment */
#define ALP_DATA_MSB_ALIGN		   0L	/*	Data is MSB aligned (default) */
#define ALP_DATA_LSB_ALIGN		   1L	/*	Data is LSB aligned */
#define ALP_DATA_BINARY_TOPDOWN	   2L	/*	Data is packed binary, top row first; bit7 of a byte = leftmost of 8 pixels */
#define ALP_DATA_BINARY_BOTTOMUP   3L	/*	Data is packed binary, bottom row first */
		/* XGA:   one pixel row occupies 128 byte of binary data. */
		/*        Byte0.Bit7 = top left pixel (TOPDOWN format) */
		/* 1080p and WUXGA: one pixel row occupies 256 byte of binary data. */
		/*        Byte0.Bit7 = top left pixel (TOPDOWN format) */
		/* SXGA+: one pixel row occupies 176 byte of binary data. First byte ignored. */
		/*        Byte1.Bit7 = top left pixel (TOPDOWN format) */

#define	ALP_SEQ_PUT_LOCK		2119L	/* ALP_DEFAULT: Lock Sequence Memory in AlpSeqPut;
	Not ALP_DEFAULT: do not lock, instead allow writing sequence image data even currently displayed */


#define ALP_FIRSTLINE			2111L	/*	Start line position at the first image */
#define ALP_LASTLINE			2112L	/*	Stop line position at the last image */
#define ALP_LINE_INC			2113L	/*	Line shift value for the next frame */
#define ALP_SCROLL_FROM_ROW		2123L	/*	combined value from ALP_FIRSTFRAME and ALP_FIRSTLINE */
#define ALP_SCROLL_TO_ROW		2124L	/*	combined value from ALP_LASTFRAME and ALP_LASTLINE */

/*	Frame Look Up Table (FLUT): sequence settings select how to use the FLUT.
	The look-up table itself is shared across all sequences.
	(use ALP_FLUT_SET_MEMORY controls for accessing it) */
#define	ALP_FLUT_MODE			2118L	/* Select Frame LookUp Table usage mode: */
#define	ALP_FLUT_NONE			   0L	/* linear addressing, do not use FLUT (default) */
#define	ALP_FLUT_9BIT			   1L	/* Use FLUT for frame addressing: 9-bit entries */
#define	ALP_FLUT_18BIT			   2L	/* Use FLUT for frame addressing: 18-bit entries */

#define	ALP_FLUT_ENTRIES9		2120L	/* Determine number of FLUT entries; default=1
	Entries: supports all values from 1 to ALP_FLUT_MAX_ENTRIES9 */
#define	ALP_FLUT_OFFSET9		2122L	/* Determine offset of FLUT index; default=0
	Offset supports multiples of 256;
	For ALP_FLUT_18BIT, the effective index is half of the 9-bit index.
	--> "ALP_FLUT_ENTRIES18" and "ALP_FLUT_FRAME_OFFSET18" are 9-bit settings divided by 2 */
/*	The API does not reject overflow! (FRAME_OFFSET+ENTRIES > MAX_ENTRIES).
	The user is responsible for correct settings. */

#define ALP_SEQ_DMD_LINES		2125L	// Area of Interest: Value = MAKELONG(StartRow, RowCount)


/* AlpSeqInquire */
#define ALP_BITPLANES			2200L	/*	Bit depth of the pictures in the sequence */
#define ALP_PICNUM				2201L	/*	Number of pictures in the sequence */
#define ALP_PICTURE_TIME		2203L	/*	Time between the start of consecutive pictures in the sequence in microseconds, */
										/*	the corresponding in frames per second is */
										/*	picture rate [fps] = 1 000 000 / ALP_PICTURE_TIME [µs] */
#define ALP_ILLUMINATE_TIME		2204L	/*	Duration of the display of one picture in microseconds */
#define ALP_SYNCH_DELAY			2205L	/*	Delay of the start of picture display with respect */
										/*	to the frame synch output (master mode) in microseconds */
#define ALP_SYNCH_PULSEWIDTH	2206L	/*	Duration of the active frame synch output pulse in microseconds */
#define ALP_TRIGGER_IN_DELAY	2207L	/*	Delay of the start of picture display with respect to the */
										/*	active trigger input edge in microseconds */
#define ALP_MAX_SYNCH_DELAY		2209L	/*	Maximal duration of frame synch output to projection delay in microseconds */
#define ALP_MAX_TRIGGER_IN_DELAY	2210L	/*	Maximal duration of trigger input to projection delay in microseconds */

#define ALP_MIN_PICTURE_TIME	2211L	/*	Minimum time between the start of consecutive pictures in microseconds */
#define ALP_MIN_ILLUMINATE_TIME	2212L	/*	Minimum duration of the display of one picture in microseconds */
										/*	depends on ALP_BITNUM and ALP_BIN_MODE */
#define ALP_MAX_PICTURE_TIME	2213L	/*	Maximum value of ALP_PICTURE_TIME */

										/*	ALP_PICTURE_TIME = ALP_ON_TIME + ALP_OFF_TIME */
										/*	ALP_ON_TIME may be smaller than ALP_ILLUMINATE_TIME */
#define ALP_ON_TIME				2214L	/*	Total active projection time */
#define ALP_OFF_TIME			2215L	/*	Total inactive projection time */


/*  AlpProjInquire & AlpProjControl & ...Ex - InquireTypes, ControlTypes & Values */
#define	ALP_PROJ_MODE			2300L	/*	Select from ALP_MASTER and ALP_SLAVE mode */
#define	ALP_MASTER				2301L	/*	The ALP operation is controlled by internal */
										/*	timing, a synch signal is sent out for any */
										/*	picture displayed */
#define	ALP_SLAVE				2302L	/*	The ALP operation is controlled by external */
										/*	trigger, the next picture in a sequence is */
										/*	displayed after the detection of an external */
										/*	input trigger signal. */
#define ALP_PROJ_STEP			2329L	/*	ALP operation should run in ALP_MASTER mode,
											but each frame is repeatedly displayed
											until a trigger event is received.
											Values (conditions): ALP_LEVEL_HIGH |
											LOW, ALP_EDGE_RISING | FALLING.
											ALP_DEFAULT disables the trigger and
											makes the sequence progress "as usual".
											If an event is "stored" in edge mode due
											to a past edge, then it will be
											discarded during
											AlpProjControl(ALP_PROJ_STEP). */
#define	ALP_PROJ_SYNC			2303L	/*	Select from ALP_SYNCHRONOUS and ALP_ASYNCHRONOUS mode */
#define	ALP_SYNCHRONOUS			2304L	/*	The calling program gets control back after completion */
										/*	of sequence display. */
#define	ALP_ASYNCHRONOUS		2305L	/*	The calling program gets control back immediatelly. */

#define	ALP_PROJ_INVERSION		2306L	/*  Reverse dark into bright */
#define	ALP_PROJ_UPSIDE_DOWN	2307L	/*  Turn the pictures upside down */

#define ALP_PROJ_STATE			2400L	/* Inquire only */


#define	ALP_FLUT_MAX_ENTRIES9	2324L	/* Inquire FLUT size */
/* Transfer FLUT memory to ALP. Use AlpProjControlEx and pUserStructPtr of type tFlutWrite. */
#define ALP_FLUT_WRITE_9BIT		2325L	/* 9-bit look-up table entries */
#define ALP_FLUT_WRITE_18BIT	2326L	/* 18-bit look-up table entries  */

/* for ALP_FLUT_WRITE_9BIT, ALP_FLUT_WRITE_18BIT (both versions share the same data type),
	to be used with AlpProjControlEx */
struct tFlutWrite {
	/* first LUT entry to transfer (write FrameNumbers[0] to LUT[nOffset]): */
	long nOffset;
	/* number of 9-bit or 18-bit entries to transfer;
	For nSize=ALP_DEFAULT(0) the API sets nSize to its maximum value. This
	requires nOffset=0  */
	long nSize;
	/* nOffset+nSize must not exceed ALP_FLUT_MAX_ENTRIES9 (ALP_FLUT_WRITE_9BIT)
	or ALP_FLUT_MAX_ENTRIES9/2 (ALP_FLUT_WRITE_18BIT). */

	/* The ALP API reads only the first nSize entries from this array. It
	extracts 9 or 18 least significant bits from each entry. */
	long unsigned FrameNumbers[4096];
};


/* Sequence Queue API Extension: */
#define ALP_PROJ_QUEUE_MODE		2314L
#define ALP_PROJ_LEGACY			0L		/*  ALP_DEFAULT: emulate legacy mode: 1 waiting position. AlpProjStart replaces enqueued and still waiting sequences */
#define ALP_PROJ_SEQUENCE_QUEUE	1L		/*  manage active sequences in a queue */

#define ALP_PROJ_QUEUE_ID			2315L	/* provide the QueueID (ALP_ID) of the most recently enqueued sequence (or ALP_INVALID_ID) */
#define ALP_PROJ_QUEUE_MAX_AVAIL	2316L	/* total number of waiting positions in the sequence queue */
#define ALP_PROJ_QUEUE_AVAIL		2317L	/* number of available waiting positions in the queue */
	/* bear in mind that when a sequence runs, it is already dequeued and does not consume a waiting position any more */
#define ALP_PROJ_PROGRESS		2318L	/* (AlpProjInquireEx) inquire detailled progress of the running sequence and the queue */
#define ALP_PROJ_RESET_QUEUE	2319L	/* Remove all enqueued sequences from the queue. The currently running sequence is not affected. ControlValue must be ALP_DEFAULT */
#define ALP_PROJ_ABORT_SEQUENCE	2320L	/* abort the current sequence (ControlValue=ALP_DEFAULT) or a specific sequence (ControlValue=QueueID); abort after last frame of current iteration */
#define ALP_PROJ_ABORT_FRAME	2321L	/* similar, but abort after next frame */
	/*	Only one abort request can be active at a time. If it is requested to
		abort another sequence before the old request is completed, then
		AlpProjControl returns ALP_NOT_IDLE. (Please note, that AlpProjHalt
		and AlpDevHalt work anyway.) If the QueueID points to a sequence
		behind an indefinitely started one (AlpProjStartCont) then it returns
		ALP_PARM_INVALID in order to prevent dead-locks. */
#define ALP_PROJ_WAIT_UNTIL		2323L	/* When does AlpProjWait complete regarding the last frame? or after picture time of last frame */
#define ALP_PROJ_WAIT_PIC_TIME	0L		/*  ALP_DEFAULT: AlpProjWait returns after picture time */
#define ALP_PROJ_WAIT_ILLU_TIME	1L		/*  AlpProjWait returns after illuminate time (except binary uninterrupted sequences, because an "illuminate time" is not applicable there) */

/* for AlpProjInquireEx(ALP_PROJ_PROGRESS): */
struct tAlpProjProgress {
	ALP_ID CurrentQueueId;
	ALP_ID SequenceId;		/* Consider that a sequence can be enqueued multiple times! */
	unsigned long nWaitingSequences;	/* number of sequences waiting in the queue */

	/* track iterations and frames: device-internal counters are incompletely
		reported; The API description contains more details on that. */
	unsigned long nSequenceCounter;		/* number of iterations to be done */
	unsigned long nSequenceCounterUnderflow;	/* nSequenceCounter can
		underflow (for indefinitely long Sequences: AlpProjStartCont);
		nSequenceCounterUnderflow is 0 before, and non-null afterwards */
	unsigned long nFrameCounter;	/* frames left inside current iteration */

	unsigned long nPictureTime;	/* micro seconds of each frame; this is
		reported, because the picture time of the original sequence could
		already have changed in between */
	unsigned long nFramesPerSubSequence;	/* Each sequence iteration
		displays this number of frames. It is reported to the user just for
		convenience, because it depends on different parameters. */

	unsigned long nFlags;	/* may be a combination of ALP_FLAG_SEQUENCE_ABORTING | SEQUENCE_INDEFINITE | QUEUE_IDLE | FRAME_FINISHED */
};
#define ALP_FLAG_QUEUE_IDLE				1UL
#define ALP_FLAG_SEQUENCE_ABORTING		2UL
#define ALP_FLAG_SEQUENCE_INDEFINITE	4UL	/* AlpProjStartCont: this loop runs indefinitely long, until aborted */
#define ALP_FLAG_FRAME_FINISHED			8UL	/* illumination of last frame finished, picture time still progressing */


/** COMPATIBILITY for old source code: ********************************************** */
#ifndef ALP_DISABLE_OLD_SYMBOLS

/* Rename TRIG to SYNCH, but preserve the "old" denominators for compatibility.
These controls handle output pins, not input, so "synch" is more appropriate than "trigger". */
#define ALP_DEV_DYN_TRIG_OUT1_GATE ALP_DEV_DYN_SYNCH_OUT1_GATE
#define ALP_DEV_DYN_TRIG_OUT2_GATE ALP_DEV_DYN_SYNCH_OUT2_GATE
#define ALP_DEV_DYN_TRIG_OUT3_GATE ALP_DEV_DYN_SYNCH_OUT3_GATE
typedef tAlpDynSynchOutGate tAlpDynTrigOutGate;
#define ALP_TRIGGER_POLARITY	ALP_SYNCH_POLARITY
#define ALP_VD_EDGE				ALP_TRIGGER_EDGE
#define ALP_VD_TIME_OUT			ALP_TRIGGER_TIME_OUT
#define ALP_TRIGGER_DELAY		ALP_SYNCH_DELAY
#define ALP_TRIGGER_PULSEWIDTH	ALP_SYNCH_PULSEWIDTH
#define ALP_VD_DELAY			ALP_TRIGGER_IN_DELAY
#define ALP_MAX_TRIGGER_DELAY	ALP_MAX_SYNCH_DELAY
#define ALP_MAX_VD_DELAY		ALP_MAX_TRIGGER_IN_DELAY
#define ALP_SLAVE_VD			ALP_SLAVE
#endif /* ALP_DISABLE_OLD_SYMBOLS */


/*  ********************************************************************************* */

ALP_API long ALP_ATTR AlpDevAlloc( long DeviceNum, long InitFlag, ALP_ID* DeviceIdPtr);
ALP_API long ALP_ATTR AlpDevHalt( ALP_ID DeviceId);
ALP_API long ALP_ATTR AlpDevFree( ALP_ID DeviceId);

/* /////////////////////////////////////////////////////////////////////////// */

ALP_API long ALP_ATTR AlpDevControl( ALP_ID DeviceId, long ControlType, long ControlValue);
ALP_API long ALP_ATTR AlpDevControlEx( ALP_ID DeviceId, long ControlType, void *UserStructPtr );
ALP_API long ALP_ATTR AlpDevInquire( ALP_ID DeviceId, long InquireType, long *UserVarPtr);



/* /////////////////////////////////////////////////////////////////////////// */

ALP_API long ALP_ATTR AlpSeqAlloc( ALP_ID DeviceId, long BitPlanes, long PicNum,  ALP_ID *SequenceIdPtr);
ALP_API long ALP_ATTR AlpSeqFree( ALP_ID DeviceId, ALP_ID SequenceId);


/* /////////////////////////////////////////////////////////////////////////// */

ALP_API long ALP_ATTR AlpSeqControl( ALP_ID DeviceId, ALP_ID SequenceId,  long ControlType, long ControlValue);
ALP_API long ALP_ATTR AlpSeqTiming( ALP_ID DeviceId, ALP_ID SequenceId,  long IlluminateTime, 
		long PictureTime, long SynchDelay, long SynchPulseWidth, long TriggerInDelay);
ALP_API long ALP_ATTR AlpSeqInquire( ALP_ID DeviceId, ALP_ID SequenceId,  long InquireType, 
		long *UserVarPtr);

/* /////////////////////////////////////////////////////////////////////////// */

ALP_API long ALP_ATTR AlpSeqPut( ALP_ID DeviceId, ALP_ID SequenceId, long PicOffset, long PicLoad, 
	    void *UserArrayPtr);

/* /////////////////////////////////////////////////////////////////////////// */

ALP_API long ALP_ATTR AlpProjStart( ALP_ID DeviceId, ALP_ID SequenceId);
ALP_API long ALP_ATTR AlpProjStartCont( ALP_ID DeviceId, ALP_ID SequenceId);
ALP_API long ALP_ATTR AlpProjHalt( ALP_ID DeviceId);
ALP_API long ALP_ATTR AlpProjWait( ALP_ID DeviceId);

ALP_API long ALP_ATTR AlpProjControl( ALP_ID DeviceId, long ControlType, long ControlValue);
ALP_API long ALP_ATTR AlpProjControlEx( ALP_ID DeviceId, long ControlType, void *pUserStructPtr );
ALP_API long ALP_ATTR AlpProjInquire( ALP_ID DeviceId, long InquireType, long *UserVarPtr);
ALP_API long ALP_ATTR AlpProjInquireEx( ALP_ID DeviceId, long InquireType, void *UserStructPtr );


/*****************************************************************************/
/* LED API */

/* Find a free LED Driver, and set it up according to LedType and *UserStructPtr */
ALP_API long ALP_ATTR AlpLedAlloc( ALP_ID DeviceId, long LedType, void *UserStructPtr, ALP_ID *LedId );
/* Valid LedTypes for AlpLedAlloc: */
	/* LED Driver: HLD, LED: red/green/blue/near-UV PT120, see API
	   documentation for compatible types */
	/* UserStructPtr is optional and can be NULL */
#define ALP_HLD_PT120_RED	0x0101l
#define ALP_HLD_PT120_GREEN	0x0102l
#define ALP_HLD_PT120_BLUE	0x0103l
#define ALP_HLD_PT120_390	ALP_HLD_CBT120_UV	/* Alias for compatibility of "old" source code */
#define ALP_HLD_CBT120_UV	0x0104l
#define ALP_HLD_CBT90_WHITE	0x0106l
#define ALP_HLD_PT120TE_BLUE	0x0107l	/* thermally enhanced package */
#define ALP_HLD_CBT140_WHITE	0x0108l	/* 14mm² round emitting aperture;
	absolute maximum = continuous drive current = 21A */

struct tAlpHldPt120AllocParams {
	/* Type of *UserStructPtr for AlpLedAlloc when
	   LedType is one of the ALP_HLD_PT120_* types.
	   These LedTypes have DEFAULT alloc parameters, so
	   UserStructPtr is allowed to be NULL. */
	long I2cDacAddr;
	long I2cAdcAddr;
};

/* switch LED off and release LED instance */
ALP_API long ALP_ATTR AlpLedFree( ALP_ID DeviceId, ALP_ID LedId );



/* change LED state / behaviour */
ALP_API long ALP_ATTR AlpLedControl( ALP_ID DeviceId, ALP_ID LedId, long ControlType, long Value );
/* Valid ControlTypes for AlpLedControl */
#define ALP_LED_SET_CURRENT	1001l	/* set up nominal LED current. Value = milli amperes */
#define ALP_LED_BRIGHTNESS	1002l	/* set up brightness on base of ALP_LED_CURRENT.
	Value = percent (0..133%) */
#define ALP_LED_FORCE_OFF	1003l	/* HLD: A small LED current could flow even if set to zero.
	This could be forced off by explicitly disabling the LED driver.
	But it takes several milli-seconds to enable again. */
#define ALP_LED_AUTO_OFF	0l		/* Default: Disable the LED driver if, and only if, SET_CURRENT*BRIGHTNESS==0. */
#define ALP_LED_OFF			1l		/* Disable LED driver. This ensures that no current is output to the LED. */
#define ALP_LED_ON			2l		/* Enable LED driver. Use this if it is required to wake up quickly. */

/* query LED state, setup values, and measured values */
ALP_API long ALP_ATTR AlpLedInquire( ALP_ID DeviceId, ALP_ID LedId, long InquireType, long *UserVarPtr );
/* Valid InquireTypes for AlpLedInquire */
/* ALP_LED_SET_CURRENT: actually set-up value; it may slightly differ from the Value used in AlpLedControl */
/* ALP_LED_BRIGHTNESS: value as in AlpLedControl */
#define ALP_LED_TYPE					1101l	/* LedType of this LedId */
#define ALP_LED_MEASURED_CURRENT		1102l	/* measured LED current in milli amperes */
#define ALP_LED_TEMPERATURE_REF			1103l	/* measured LED temperature at the NTC temperature sensor */
#define ALP_LED_TEMPERATURE_JUNCTION	1104l	/* calculated LED junction temperature on base of
	ALP_LED_TEMPERATURE_REF and a default (?) thermal model */



/* Extended function: like AlpLedControl, but for adjustments whose parameters do not fit into a scalar long value */
ALP_API long ALP_ATTR AlpLedControlEx( ALP_ID DeviceId, ALP_ID LedId, long ControlType, void *UserStructPtr);
/* Valid ControlTypes for AlpLedControlEx: */
/* currently none. */

/* Extended function: like AlpLedInquire, but for inquiries whose results do not fit into a scalar long value */
ALP_API long ALP_ATTR AlpLedInquireEx( ALP_ID DeviceId, ALP_ID LedId, long InquireType, void *UserStructPtr);
/* Valid InquireTypes for AlpLedInquireEx: */
#define ALP_LED_ALLOC_PARAMS	2101l	/* retrieve actual alloc parameters; especially useful if omitted in the AlpLedAlloc call */
	/* Note: UserStructPtr must point to a structure according to ALP_LED_TYPE, e.g. tAlpHldPt120AllocParams */


#pragma pack(pop)

/* /////////////////////////////////////////////////////////////////////////// */
#endif  /* _ALP_H_INCLUDED */

