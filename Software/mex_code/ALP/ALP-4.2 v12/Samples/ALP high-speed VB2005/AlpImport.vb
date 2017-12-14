' *********************************************************************************
' *                                                                               *
' *   Project:      alp (ALP DLL)                                                 *
' *   Filename:     AlpImport.vb : DLL Import Class for Visual Basic 2005         *
' *                                                                               *
' *********************************************************************************
' *                                                                               *
' *   © 2008 ViALUX GmbH. All rights reserved.                                    *
' *                                                                               *
' *                                                                               *
' *   This software is provided 'as-is', without any express or implied           *
' *   warranty.  In no event will the authors be held liable for any damages      *
' *   arising from the use of this software.                                      *
' *                                                                               *
' *   Permission to use this software is granted to anyone who has purchased      *
' *   an ALP-1, ALP-2, ALP-3 high-speed, or ALP-4 high-speed.                     *
' *   This permission includes to use this software for any purpose, including    *
' *   commercial applications, and to alter it freely. Redistribution of the      *
' *   source code is prohibited.                                                  *
' *                                                                               *
' *   Please always consult the ALP-4 high-speed API description when             *
' *   customizing this program. It contains a detailled specification             *
' *   of all Alp... functions.                                                    *
' *                                                                               *
' *********************************************************************************
' *                                                                               *
' *   Version:        5                                                           *
' *                                                                               *
' *********************************************************************************

' Required in order to call DLL functions
Imports System.Runtime.InteropServices

' Derived from alp.h version 9
' Missing (to be done, when required):
' - LED functions (AlpLed...)
' - Frame LUT extension (ALP_FLUT_WRITE_9BIT, ALP_FLUT_WRITE_18BIT using AlpProjControlEx, Sequence Control Types)
' - Sequence Queue API Extension
Public Class AlpImport
    ' Type ALP_ID is Int32

    Private Const DllFileName As String = "alpV42.dll"
    Private Const DllCallingConvention As CallingConvention = CallingConvention.Cdecl

    Public Const ALP_DEFAULT As Int32 = 0

    ' "New" ALP API versions set ALP_ID output parameters to this value on errors:
    Public Const ALP_INVALID_ID As UInt32 = UInt32.MaxValue

    Enum AlpReturnCodes As Int32
        ALP_OK = 0                      ' successfull execution
        ALP_NOT_ONLINE = 1001           ' The specified ALP has not been found or is not ready.
        ALP_NOT_IDLE = 1002             ' The ALP is not in idle state.
        ALP_NOT_AVAILABLE = 1003        ' The specified ALP identifier is not valid.
        ALP_NOT_READY = 1004            ' The specified ALP is already allocated.
        ALP_PARM_INVALID = 1005         ' One of the parameters is invalid.
        ALP_ADDR_INVALID = 1006         ' Error accessing user data.
        ALP_MEMORY_FULL = 1007          ' The requested memory is not available.
        ALP_SEQ_IN_USE = 1008           ' The sequence specified is currently in use.
        ALP_HALTED = 1009               ' The ALP has been stopped while image data transfer was active.
        ALP_ERROR_INIT = 1010           ' Initialization error.
        ALP_ERROR_COMM = 1011           ' Communication error.
        ALP_DEVICE_REMOVED = 1012       ' The specified ALP has been removed.
        ALP_NOT_CONFIGURED = 1013       ' The onboard FPGA is unconfigured.
        ALP_LOADER_VERSION = 1014       ' The function is not supported by this version of the driver file VlxUsbLd.sys.
        ALP_ERROR_POWER_DOWN = 1018     ' failed to "wake-up" the DMD
    End Enum


    Enum AlpDevTypes As Int32           ' AlpDevInquire and AlpDevControl - ControlTypes
        ALP_DEVICE_NUMBER = 2000        ' Serial number of the ALP device
        ALP_VERSION = 2001              ' Version number of the ALP device
        ALP_DEV_STATE = 2002            ' current ALP status, see above
        ALP_AVAIL_MEMORY = 2003         ' ALP on-board sequence memory available for further sequence allocation (AlpSeqAlloc); number of binary pictures
        ALP_SYNCH_POLARITY = 2004       ' Select synch output signal polarity
        ALP_TRIGGER_EDGE = 2005         ' Select active input trigger edge (slave mode)
        ALP_USB_CONNECTION = 2016       ' Re-connect after a USB interruption
        ALP_DEV_DMDTYPE = 2021          ' Select DMD type; only allowed for a new allocated ALP-3 high-speed device
        ALP_DEV_DISPLAY_HEIGHT = 2057   ' number of mirror rows on the DMD
        ALP_DEV_DISPLAY_WIDTH = 2058    ' number of mirror columns on the DMD
        ALP_DDC_FPGA_TEMPERATURE = 2050 ' DDC FPGAs Temperature Diode
        ALP_APPS_FPGA_TEMPERATURE = 2051 ' Application FPGAs Temperature Diode
        ALP_PCB_TEMPERATURE = 2052      ' V4100 "Board temperature"
		ALP_DEV_DMD_MODE = 2064			' ALP_DMD_POWER_FLOAT: 1, default: 0
		ALP_PWM_LEVEL = 2063			' PWM output pin: duty-cycle [percent]
    End Enum

    Enum AlpDevValues As Int32          ' AlpDevInquire and AlpDevControl - ControlValues
        ' ALP_DEV_STATE:
        ALP_DEV_BUSY = 1100             ' the ALP is displaying a sequence or image data download is active
        ALP_DEV_READY = 1101            ' the ALP is ready for further requests
        ALP_DEV_IDLE = 1102             ' the ALP is in wait state

        ' ALP_SYNCH_POLARITY:
        ALP_LEVEL_HIGH = 2006           ' Active high synch output
        ALP_LEVEL_LOW = 2007            ' Active low synch output

        ' ALP_TRIGGER_EDGE:
        ALP_EDGE_FALLING = 2008         ' High to low signal transition
        ALP_EDGE_RISING = 2009          ' Low to high signal transition

        ' ALP_DEV_DMDTYPE:
        ALP_DMDTYPE_XGA = 1             ' 1024*768 mirror pixels (0.7" Type A, D1100 and D3000)
        ALP_DMDTYPE_SXGA_PLUS = 2       ' 1400*1050 mirror pixels (0.95" Type A, D3000)
        ALP_DMDTYPE_1080P_095A = 3      ' 1920*1080 mirror pixels (0.95" Type A, D4x00)
        ALP_DMDTYPE_XGA_07A = 4         ' 1024*768 mirror pixels (0.7" Type A, D4x00)
        ALP_DMDTYPE_XGA_055A = 5        ' 1024*768 mirror pixels (0.55" Type A, D4x00)
        ALP_DMDTYPE_XGA_055X = 6        ' 1024*768 mirror pixels (0.55" Type X, D4x00)
        ALP_DMDTYPE_WUXGA_096A = 7      ' 1920*1200 mirror pixels (0.96" Type A, D4100)
        ALP_DMDTYPE_DISCONNECT = 255    ' behaves like 1080p (V4100)
    End Enum


    Enum AlpSeqTypes As Int32           ' AlpSeqInquire and AlpSeqControl - ControlTypes
        ALP_SEQ_REPEAT = 2100           ' Non-continuous display of a sequence (AlpProjStart) allows for configuring the number of sequence iterations.

        ALP_FIRSTFRAME = 2101           ' First image of this sequence to be displayed.
        ALP_LASTFRAME = 2102            ' Last image of this sequence to be displayed.
        ALP_BITNUM = 2103               ' A sequence can be displayed with reduced bit depth for faster speed.
        ALP_BIN_MODE = 2104             ' Binary mode: select from ALP_BIN_NORMAL and ALP_BIN_UNINTERRUPTED (AlpSeqControl)
		ALP_PWM_MODE = 2107				' default or ALP_FLEX_PWM
        ALP_DATA_FORMAT = 2110          ' Data format and alignment
		ALP_SEQ_PUT_LOCK = 2119
        ALP_BITPLANES = 2200            ' Bit depth of the pictures in the sequence
        ALP_PICNUM = 2201               ' Number of pictures in the sequence

        ALP_PICTURE_TIME = 2203         ' Time between the start of consecutive pictures in the sequence in microseconds; the corresponding in frames per second is picture rate [fps] = 1 000 000 / ALP_PICTURE_TIME [µs]
        ALP_ILLUMINATE_TIME = 2204      ' Duration of the display of one picture in microseconds
        ALP_SYNCH_DELAY = 2205          ' Delay of the start of picture display with respect to the synch output (master mode) in microseconds
        ALP_SYNCH_PULSEWIDTH = 2206     ' Duration of the active synch output pulse in microseconds
        ALP_TRIGGER_IN_DELAY = 2207     ' Delay of the start of picture display with respect to the active trigger input edge in microseconds

        ALP_MAX_SYNCH_DELAY = 2209      ' Maximal duration of synch output to projection delay in microseconds
        ALP_MAX_TRIGGER_IN_DELAY = 2210 ' Maximal duration of trigger input to projection delay in microseconds
        ALP_MIN_PICTURE_TIME = 2211     ' Minimum time between the start of consecutive pictures in microseconds
        ALP_MIN_ILLUMINATE_TIME = 2212  ' Minimum duration of the display of one picture in microseconds; depends on ALP_BITNUM and ALP_BIN_MODE
        ALP_MAX_PICTURE_TIME = 2213     ' Maximum value of ALP_PICTURE_TIME

        ' ALP_PICTURE_TIME = ALP_ON_TIME + ALP_OFF_TIME
        ' ALP_ON_TIME may be smaller than ALP_ILLUMINATE_TIME
        ALP_ON_TIME = 2214              ' Total active projection time
        ALP_OFF_TIME = 2215             ' Total inactive projection time

        ALP_FIRSTLINE = 2111            ' Start line position at the first image
        ALP_LASTLINE = 2112             ' Stop line position at the last image
        ALP_LINE_INC = 2113             ' Line shift value for the next frame
        ALP_SCROLL_FROM_ROW = 2123      ' combined value from ALP_FIRSTFRAME and ALP_FIRSTLINE
        ALP_SCROLL_TO_ROW = 2124        ' combined value from ALP_LASTFRAME and ALP_LASTLINE
    End Enum

    Enum AlpSeqValues                   ' AlpSeqInquire and AlpSeqControl - ControlValues
        ' ALP_BIN_MODE:
        ALP_BIN_NORMAL = 2105           ' Normal operation with progammable dark phase
        ALP_BIN_UNINTERRUPTED = 2106    ' Operation without dark phase

		' ALP_PWM_MODE:
		ALP_FLEX_PWM=3

        ' ALP_DATA_FORMAT:
        ALP_DATA_MSB_ALIGN = 0          ' Data is MSB aligned (default)
        ALP_DATA_LSB_ALIGN = 1          ' Data is LSB aligned
        ALP_DATA_BINARY_TOPDOWN = 2     ' Data is packed binary, top row first; bit7 of a byte = leftmost of 8 pixels
        ALP_DATA_BINARY_BOTTOMUP = 3    ' Data is packed binary, bottom row first
        ' XGA:   one pixel row occupies 128 byte of binary data.
        '        Byte0.Bit7 = top left pixel (TOPDOWN format)
        ' SXGA+: one pixel row occupies 176 byte of binary data. First byte ignored.
        '        Byte1.Bit7 = top left pixel (TOPDOWN format)
    End Enum


    Enum AlpProjTypes As Int32          ' AlpProjInquire and AlpProjControl - ControlTypes
        ALP_PROJ_MODE = 2300            ' Select from ALP_MASTER and ALP_SLAVE mode
        ALP_PROJ_INVERSION = 2306       ' Reverse dark into bright
        ALP_PROJ_UPSIDE_DOWN = 2307     ' Turn the pictures upside down
        ALP_PROJ_STATE = 2400
		ALP_PROJ_STEP = 2329
    End Enum

    Enum AlpProjValues As Int32         ' AlpProjInquire and AlpProjControl - ControlValues
        ' ALP_PROJ_MODE:
        ALP_MASTER = 2301               ' The ALP operation is controlled by internal timing, a synch pulse is sent out for any picture displayed
        ALP_SLAVE = 2302                ' The ALP operation is controlled by external trigger, the next picture in a sequence is displayed after the detection of an external input trigger signal.

        ' ALP_PROJ_STATE:
        ALP_PROJ_ACTIVE = 1200          ' ALP projection active
        ALP_PROJ_IDLE = 1201            ' no projection active
    End Enum


    ' Declare a prototype for each DLL function you want to use

	' Known Errors:
    ' System.DllNotFoundException -> ALP DLL must be available, e.g. in the same directory as this exe file
    ' System.BadImageFormatException -> ALP DLL platform does not match. Try the Win32 (x86) or the x64 version.
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpDevAlloc")> Public Shared Function AlpDevAlloc _
        (ByVal DeviceNum As Int32, ByVal InitFlag As Int32, _
        ByRef DeviceIdPtr As Int32) As AlpReturnCodes
    End Function
    ' depending on ControlType the ControlValue is Int32 or one of AlpDevValues
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpDevControl")> Public Shared Function AlpDevControl _
        (ByVal DeviceId As Int32, ByVal ControlType As AlpDevTypes, _
        ByVal ControlValue As Int32) As AlpReturnCodes
    End Function

    ' Example of how an ALP API function with a *UserStructPtr parameter can be called.
    ' Wrap ALP_DEV_DYN_SYNCH_OUTx_GATE setup in this member function.
    Public Shared Function AlpDevControlEx_SynchGate( _
        ByVal DeviceId As Int32, _
        ByVal GateNum As UInt32, _
        ByVal PolarityHigh As Boolean, _
        ByVal Gate As Byte()) _
        As AlpReturnCodes ' TODO *************** paramarray als letzten Parameter?

        If Gate.GetLength(0) > 16 Then Return AlpReturnCodes.ALP_PARM_INVALID
        Dim Gate16(15)
        For i As Byte = 1 To Math.Min(Gate.Length, 16) : Gate16(i - 1) = Gate(i - 1) : Next i
        For i As Byte = Gate.Length To 15 : Gate16(i) = 0 : Next i

        Dim GateNumControlType As Int32 = 0
        Dim GateApi As tSynchGateFixed
        GateApi.Period = Gate.Length
        If PolarityHigh Then GateApi.Polarity = 1 Else GateApi.Polarity = 0
        GateApi.Gate0 = Gate16(0) : GateApi.Gate1 = Gate16(1)
        GateApi.Gate2 = Gate16(2) : GateApi.Gate3 = Gate16(3)
        GateApi.Gate4 = Gate16(4) : GateApi.Gate5 = Gate16(5)
        GateApi.Gate6 = Gate16(6) : GateApi.Gate7 = Gate16(7)
        GateApi.Gate8 = Gate16(8) : GateApi.Gate9 = Gate16(9)
        GateApi.Gate10 = Gate16(10) : GateApi.Gate11 = Gate16(11)
        GateApi.Gate12 = Gate16(12) : GateApi.Gate13 = Gate16(13)
        GateApi.Gate14 = Gate16(14) : GateApi.Gate15 = Gate16(15)

        Select Case GateNum
            Case 1 : GateNumControlType = 2023 ' ALP_DEV_DYN_SYNCH_OUT1_GATE
            Case 2 : GateNumControlType = 2024 ' ALP_DEV_DYN_SYNCH_OUT2_GATE
            Case 3 : GateNumControlType = 2025 ' ALP_DEV_DYN_SYNCH_OUT3_GATE
        End Select
        If 0 = GateNumControlType Then
            Return AlpReturnCodes.ALP_PARM_INVALID
        Else
            Return AlpDevControlEx(DeviceId, GateNumControlType, GateApi)
        End If
    End Function
    <StructLayout(LayoutKind.Sequential)> Structure tSynchGateFixed
        Public Period As Byte
        Public Polarity As Byte
        'public Gate as Byte(15)    ' Error BC30638: Array bounds cannot appear in type specifiers.
        ' --> I have to unroll the array or flatten the structure to an array of bytes.
        Public Gate0, Gate1, Gate2, Gate3, Gate4, Gate5, Gate6, Gate7, Gate8, Gate9, Gate10, Gate11, Gate12, Gate13, Gate14, Gate15 As Byte
    End Structure
    ' Type of UserStructPtr depends on ControlType
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpDevControlEx")> Public Overloads Shared Function AlpDevControlEx _
        (ByVal DeviceId As Int32, ByVal ControlType As Int32, _
        ByRef UserStructPtr As tSynchGateFixed) As AlpReturnCodes
    End Function
    ' Type of UserStructPtr depends on ControlType
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpDevControlEx")> Public Overloads Shared Function AlpDevControlEx _
        (ByVal DeviceId As Int32, ByVal ControlType As Int32, _
        ByRef UserStructPtr As Byte()) As AlpReturnCodes
    End Function

    ' depending on ControlType the UserVarPtr becomes Int32 or one of AlpDevValues
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpDevInquire")> Public Shared Function AlpDevInquire _
        (ByVal DeviceId As Int32, ByVal InquireType As AlpDevTypes, _
        ByRef UserVarPtr As Int32) As AlpReturnCodes
    End Function
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpDevHalt")> Public Shared Function AlpDevHalt _
        (ByVal DeviceId As Int32) As AlpReturnCodes
    End Function
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpDevFree")> Public Shared Function AlpDevFree _
        (ByVal DeviceId As Int32) As AlpReturnCodes
    End Function

    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpSeqAlloc")> Public Shared Function AlpSeqAlloc _
        (ByVal DeviceId As Int32, ByVal BitPlanes As Int32, _
        ByVal PicNum As Int32, ByRef SequenceIdPtr As Int32) As AlpReturnCodes
    End Function
    ' depending on ControlType the ControlValue is Int32 or one of AlpSeqValues
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpSeqControl")> Public Shared Function AlpSeqControl _
        (ByVal DeviceId As Int32, ByVal SequenceId As Int32, _
        ByVal ControlType As AlpSeqTypes, ByVal ControlValue As Int32) As AlpReturnCodes
    End Function
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpSeqTiming")> Public Shared Function AlpSeqTiming _
        (ByVal DeviceId As Int32, ByVal SequenceId As Int32, _
        ByVal IlluminateTime As Int32, ByVal PictureTime As Int32, _
        ByVal SynchDelay As Int32, ByVal SynchPulseWidth As Int32, _
        ByVal TriggerInDelay As Int32) As AlpReturnCodes
    End Function
    ' depending on ControlType the UserVarPtr becomes Int32 or one of AlpSeqValues
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpSeqInquire")> Public Shared Function AlpSeqInquire _
        (ByVal DeviceId As Int32, ByVal SequenceId As Int32, _
        ByVal InquireType As AlpSeqTypes, ByRef UserVarPtr As Int32) As AlpReturnCodes
    End Function
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpSeqPut")> Public Shared Function AlpSeqPut _
        (ByVal DeviceId As Int32, ByVal SequenceId As Int32, _
        ByVal PicOffset As Int32, ByVal PicLoad As Int32, _
        ByVal UserArrayPtr As Byte()) As AlpReturnCodes
    End Function
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpSeqFree")> Public Shared Function AlpSeqFree _
        (ByVal DeviceId As Int32, ByVal SequenceId As Int32) As AlpReturnCodes
    End Function

    ' depending on ControlType the ControlValue is Int32 or one of AlpProjValues
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpProjControl")> Public Shared Function AlpProjControl _
        (ByVal DeviceId As Int32, ByVal ControlType As AlpProjTypes, _
        ByVal ControlValue As Int32) As AlpReturnCodes
    End Function
    ' depending on ControlType the UserVarPtr becomes Int32 or one of AlpProjValues
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpProjInquire")> Public Shared Function AlpProjInquire _
        (ByVal DeviceId As Int32, ByVal InquireType As AlpProjTypes, _
        ByRef UserVarPtr As Int32) As AlpReturnCodes
    End Function
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpProjStart")> Public Shared Function AlpProjStart _
        (ByVal DeviceId As Int32, ByVal SequenceId As Int32) As AlpReturnCodes
    End Function
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpProjStartCont")> Public Shared Function AlpProjStartCont _
        (ByVal DeviceId As Int32, ByVal SequenceId As Int32) As AlpReturnCodes
    End Function
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpProjHalt")> Public Shared Function AlpProjHalt _
        (ByVal DeviceId As Int32) As AlpReturnCodes
    End Function
    <DllImport(DllFileName, CallingConvention:=DllCallingConvention, _
    EntryPoint:="AlpProjWait")> Public Shared Function AlpProjWait _
        (ByVal DeviceId As Int32) As AlpReturnCodes
    End Function
End Class
