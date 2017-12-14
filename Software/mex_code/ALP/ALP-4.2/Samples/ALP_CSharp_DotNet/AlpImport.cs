/*
*******************************************************************************
*                                                                             *
*   Project:      alp (ALP DLL)                                               *
*   Filename:     AlpImport.cs : DLL Import Class for C#                      *
*                                                                             *
*******************************************************************************
*                                                                             *
*   © 2011 ViALUX GmbH. All rights reserved.                                  *
*                                                                             *
*                                                                             *
*   This software is provided 'as-is', without any express or implied         *
*   warranty.  In no event will the authors be held liable for any damages    *
*   arising from the use of this software.                                    *
*                                                                             *
*   Permission to use this software is granted to anyone who has purchased    *
*   an ALP-1, ALP-2, ALP-3 high-speed, or ALP-4 high-speed.                   *
*   This permission includes to use this software for any purpose, including  *
*   commercial applications, and to alter it freely. Redistribution of the    *
*   source code is prohibited.                                                *
*                                                                             *
*   Please always consult the ALP-4 high-speed API description when           *
*   customizing this program. It contains a detailled specification           *
*   of all Alp... functions.                                                  *
*                                                                             *
*******************************************************************************
*/

using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;


// Derived from alp.h version 9
	// Missing (to be done, when required):
	// LED functions (AlpLed...)
	// Frame LUT extension (ALP_FLUT_WRITE_9BIT, ALP_FLUT_WRITE_18BIT using AlpProjControlEx, Sequence Control Types)
	// Sequence Queue API Extension
class AlpImport
{
    private const string AlpDllName = "alpV42.dll";

    public const Int32 ALP_DEFAULT = 0;

	// "New" ALP API versions set ALP_ID output parameters to this value on errors:
    public const UInt32 ALP_INVALID_ID = UInt32.MaxValue;

    public enum Result : int
    {
		ALP_OK = 0x00000000,
		ALP_NOT_ONLINE = 1001,
		ALP_NOT_IDLE = 1002,
		ALP_NOT_AVAILABLE = 1003,
		ALP_NOT_READY = 1004,
		ALP_PARM_INVALID = 1005,
		ALP_ADDR_INVALID = 1006,
		ALP_MEMORY_FULL = 1007,
		ALP_SEQ_IN_USE = 1008,
		ALP_HALTED = 1009,
		ALP_ERROR_INIT = 1010,
		ALP_ERROR_COMM = 1011,
		ALP_DEVICE_REMOVED = 1012,
		ALP_NOT_CONFIGURED = 1013,
		ALP_LOADER_VERSION = 1014,
		ALP_ERROR_POWER_DOWN = 1018,
    }

	// ControlType and InquireType constants for AlpDevControl and AlpDevInquire
	public enum DevTypes : int {
		ALP_DEVICE_NUMBER = 2000,
		ALP_VERSION = 2001,
		ALP_DEV_STATE = 2002,
		ALP_AVAIL_MEMORY = 2003,
		ALP_DDC_FPGA_TEMPERATURE = 2050,
		ALP_APPS_FPGA_TEMPERATURE = 2051,
		ALP_PCB_TEMPERATURE = 2052,
		ALP_SYNCH_POLARITY = 2004,
		ALP_TRIGGER_EDGE = 2005,
		ALP_LEVEL_HIGH = 2006,
		ALP_LEVEL_LOW = 2007,
		ALP_EDGE_FALLING = 2008,
		ALP_EDGE_RISING = 2009,
		ALP_USB_CONNECTION = 2016,
		ALP_DEV_DMDTYPE = 2021,	// value type: DmdTypes
        ALP_DEV_DISPLAY_HEIGHT = 2057,
        ALP_DEV_DISPLAY_WIDTH = 2058,
		ALP_DEV_DMD_MODE = 2064,	// ALP_DMD_POWER_FLOAT: 1, default: 0
		ALP_PWM_LEVEL = 2063,
	}

    public enum DmdTypes : int {
	    ALP_DMDTYPE_XGA = 1,
	    ALP_DMDTYPE_SXGA_PLUS = 2,
	    ALP_DMDTYPE_1080P_095A = 3,
	    ALP_DMDTYPE_XGA_07A = 4,
	    ALP_DMDTYPE_XGA_055A = 5,
	    ALP_DMDTYPE_XGA_055X = 6,
	    ALP_DMDTYPE_DISCONNECT = 255,
	}
	public enum SeqTypes : int {
		ALP_SEQ_REPEAT = 2100,
		ALP_FIRSTFRAME = 2101,
		ALP_LASTFRAME = 2102,
		ALP_BITNUM = 2103,
		ALP_BIN_MODE = 2104,
		ALP_BIN_NORMAL = 2105,
		ALP_BIN_UNINTERRUPTED = 2106,
		ALP_PWM_MODE = 2107,
		ALP_FLEX_PWM = 3,
		ALP_DATA_FORMAT = 2110,	// value type: SeqDataFormat
		ALP_SEQ_PUT_LOCK = 2119,
		ALP_FIRSTLINE = 2111,
		ALP_LASTLINE = 2112,
		ALP_LINE_INC = 2113,
		ALP_SCROLL_FROM_ROW = 2123,
		ALP_SCROLL_TO_ROW = 2124,
		ALP_BITPLANES = 2200,
		ALP_PICNUM = 2201,
		ALP_PICTURE_TIME = 2203,
		ALP_ILLUMINATE_TIME = 2204,
		ALP_SYNCH_DELAY = 2205,
		ALP_SYNCH_PULSEWIDTH = 2206,
		ALP_TRIGGER_IN_DELAY = 2207,
		ALP_MAX_SYNCH_DELAY = 2209,
		ALP_MAX_TRIGGER_IN_DELAY = 2210,
		ALP_MIN_PICTURE_TIME = 2211,
		ALP_MIN_ILLUMINATE_TIME = 2212,
		ALP_MAX_PICTURE_TIME = 2213,
		ALP_ON_TIME = 2214,
		ALP_OFF_TIME = 2215,
	}
    public enum SeqDataFormat : int
    {
		ALP_DATA_MSB_ALIGN = 0,
		ALP_DATA_LSB_ALIGN = 1,
		ALP_DATA_BINARY_TOPDOWN = 2,
		ALP_DATA_BINARY_BOTTOMUP = 3,
	}
    public enum ProjTypes : int
    {
		ALP_PROJ_MODE = 2300,	// value type: ProjModes
		ALP_PROJ_INVERSION = 2306,
		ALP_PROJ_UPSIDE_DOWN = 2307,
		ALP_PROJ_STEP = 2329,
	}
    public enum ProjModes : int
    {
		ALP_MASTER = 2301,
		ALP_SLAVE = 2302,
	}


    // Wrap the unsafe ALP DLL function calls
    public static Result DevAlloc(Int32 DeviceNum, Int32 InitFlag, ref UInt32 DeviceId)
    {
        unsafe {
            fixed (UInt32* DeviceIdPtr = &DeviceId) {   // fixed output pointer!
                // Known Errors:
                // System.DllNotFoundException -> ALP DLL must be available, e.g. in the same directory as this exe file
                // System.BadImageFormatException -> ALP DLL platform does not match. Try the Win32 (x86) or the x64 version.
                return (Result) AlpDevAlloc(DeviceNum, InitFlag, DeviceIdPtr);
            }
        }
    }
	public static Result DevControl( UInt32 DeviceId, DevTypes ControlType, Int32 ControlValue) {
		unsafe {
            return (Result) AlpDevControl(DeviceId, (Int32) ControlType, ControlValue);
		}
	}

    // Example of how an ALP API function with a *UserStructPtr parameter can be called.
    // Wrap ALP_DEV_DYN_SYNCH_OUTx_GATE setup in this member function.
    public static Result DevControlEx_SynchGate(
        UInt32 DeviceId,
        UInt32 GateNum, // 1..3
        bool PolarityHigh, // true=high active
        params Byte[] Gate) // the size of this array is used as the Period
    {
        unsafe
        {
            if (Gate.Length > 16) return Result.ALP_PARM_INVALID;

            Int32 GateNumControlType = 0;
            tSynchGateFixed GateApi;
            GateApi.Period = (byte) Gate.Length;
            GateApi.Polarity = (byte) (PolarityHigh?1:0);
            for (Int32 i = 0; i < Math.Min(GateApi.Period, 16u); i++) GateApi.Gate[i] = Gate[i];
            for (Int32 i = GateApi.Period; i < 16; i++) GateApi.Gate[i] = 0;
            switch (GateNum)
            {
                case 1: GateNumControlType = 2023; break; // ALP_DEV_DYN_SYNCH_OUT1_GATE
                case 2: GateNumControlType = 2024; break; // ALP_DEV_DYN_SYNCH_OUT2_GATE
                case 3: GateNumControlType = 2025; break; // ALP_DEV_DYN_SYNCH_OUT3_GATE
            }
            if (0 == GateNumControlType)
                return Result.ALP_PARM_INVALID;
            else
                return (Result)AlpDevControlEx(DeviceId, GateNumControlType, &GateApi);
        }
    }
	unsafe private struct tSynchGateFixed
	{
		public byte Period;
		public byte Polarity;
		public fixed byte Gate[16];
	}

	public static Result DevInquire( UInt32 DeviceId, DevTypes InquireType, ref Int32 UserVar) {
		unsafe {
			fixed (Int32* UserVarPtr = &UserVar) {
                return (Result) AlpDevInquire(DeviceId, (Int32) InquireType, UserVarPtr);
			}
		}
	}
    public static Result DevHalt(UInt32 DeviceId)
    {
		unsafe {
            return (Result) AlpDevHalt(DeviceId);
		}
	}
    public static Result DevFree(UInt32 DeviceId)
    {
		unsafe {
            return (Result) AlpDevFree(DeviceId);
		}
	}
    public static Result SeqAlloc(UInt32 DeviceId, Int32 BitPlanes, Int32 PicNum, ref UInt32 SequenceId)
    {
        unsafe {
            fixed (UInt32* SequenceIdPtr = &SequenceId) {   // fixed output pointer!
                return (Result) AlpSeqAlloc(DeviceId, BitPlanes, PicNum, SequenceIdPtr);
            }
        }
    }
    public static Result SeqControl(UInt32 DeviceId, UInt32 SequenceId, SeqTypes ControlType, Int32 ControlValue)
    {
		unsafe {
            return (Result) AlpSeqControl(DeviceId, SequenceId, (Int32) ControlType, ControlValue);
		}
	}
    public static Result SeqTiming(UInt32 DeviceId, UInt32 SequenceId, Int32 IlluminateTime, Int32 PictureTime, Int32 SynchDelay, Int32 SynchPulseWidth, Int32 TriggerInDelay)
    {
		unsafe {
            return (Result) AlpSeqTiming(DeviceId, SequenceId, IlluminateTime, PictureTime, SynchDelay, SynchPulseWidth, TriggerInDelay);
		}
	}
    public static Result SeqInquire(UInt32 DeviceId, UInt32 SequenceId, SeqTypes InquireType, ref Int32 UserVar)
    {
		unsafe {
			fixed (Int32* UserVarPtr = &UserVar) {
                return (Result)AlpSeqInquire(DeviceId, SequenceId, (Int32)InquireType, UserVarPtr);
			}
		}
	}
    public static Result SeqPut(UInt32 DeviceId, UInt32 SequenceId, Int32 PicOffset, Int32 PicLoad, ref Byte[] UserArray)
    {
        unsafe {
            return (Result) AlpSeqPut(DeviceId, SequenceId, PicOffset, PicLoad, UserArray);
        }
    }
    public static Result SeqFree(UInt32 DeviceId, UInt32 SequenceId)
    {
		unsafe {
            return (Result) AlpSeqFree(DeviceId, SequenceId);
		}
	}
    public static Result ProjControl(UInt32 DeviceId, ProjTypes ControlType, Int32 ControlValue)
    {
		unsafe {
            return (Result)AlpProjControl(DeviceId, (Int32)ControlType, ControlValue);
		}
	}
    public static Result ProjInquire(UInt32 DeviceId, ProjTypes InquireType, ref Int32 UserVar)
    {
		unsafe {
			fixed (Int32* UserVarPtr = &UserVar) {
                return (Result)AlpProjInquire(DeviceId, (Int32)InquireType, UserVarPtr);
			}
		}
	}
    public static Result ProjStart(UInt32 DeviceId, UInt32 SequenceId)
    {
		unsafe {
            return (Result) AlpProjStart(DeviceId, SequenceId);
		}
	}
    public static Result ProjStartCont(UInt32 DeviceId, UInt32 SequenceId)
    {
		unsafe {
            return (Result) AlpProjStartCont(DeviceId, SequenceId);
		}
	}
    public static Result ProjHalt(UInt32 DeviceId)
    {
		unsafe {
            return (Result) AlpProjHalt(DeviceId);
		}
	}
    public static Result ProjWait(UInt32 DeviceId)
    {
		unsafe {
            return (Result) AlpProjWait(DeviceId);
		}
	}

    // Import native function calls, but protect them from direct calls (private scope)
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
    unsafe private static extern Int32 AlpDevAlloc ( Int32 DeviceNum, Int32 InitFlag, UInt32* DeviceIdPtr);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpDevControl( UInt32 DeviceId, Int32 ControlType, Int32 ControlValue);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpDevControlEx( UInt32 DeviceId, Int32 ControlType, void *UserStructPtr);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpDevInquire( UInt32 DeviceId, Int32 InquireType, Int32 *UserVarPtr);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpDevHalt( UInt32 DeviceId);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpDevFree( UInt32 DeviceId);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpSeqAlloc( UInt32 DeviceId, Int32 BitPlanes, Int32 PicNum,  UInt32 *SequenceIdPtr);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpSeqControl( UInt32 DeviceId, UInt32 SequenceId,  Int32 ControlType, Int32 ControlValue);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpSeqTiming( UInt32 DeviceId, UInt32 SequenceId,  Int32 IlluminateTime, Int32 PictureTime, Int32 TriggerDelay, Int32 TriggerPulseWidth, Int32 VdDelay);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpSeqInquire( UInt32 DeviceId, UInt32 SequenceId,  Int32 InquireType, Int32 *UserVarPtr);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpSeqPut( UInt32 DeviceId, UInt32 SequenceId, Int32 PicOffset, Int32 PicLoad, Byte[] UserArrayPtr);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpSeqFree( UInt32 DeviceId, UInt32 SequenceId);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpProjControl( UInt32 DeviceId, Int32 ControlType, Int32 ControlValue);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpProjInquire( UInt32 DeviceId, Int32 InquireType, Int32 *UserVarPtr);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpProjStart( UInt32 DeviceId, UInt32 SequenceId);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpProjStartCont( UInt32 DeviceId, UInt32 SequenceId);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpProjHalt( UInt32 DeviceId);
    [DllImport(AlpDllName, CallingConvention = CallingConvention.Cdecl)]
	unsafe private static extern Int32 AlpProjWait( UInt32 DeviceId);

}
