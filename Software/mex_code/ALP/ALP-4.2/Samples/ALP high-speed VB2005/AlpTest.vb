Imports VB2005Sample.AlpImport

Public Class AlpTest
    Private Function AlpErrorString(ByVal nRet As Int32) As String
        ' See also the C header file "alp.h" for values of the return codes.
        ' This file also contains the values of other control types and
        ' special values.
        Select Case nRet
            Case AlpReturnCodes.ALP_OK
                AlpErrorString = "ALP_OK"
            Case AlpReturnCodes.ALP_NOT_ONLINE
                AlpErrorString = "ALP_NOT_ONLINE"
            Case AlpReturnCodes.ALP_NOT_IDLE
                AlpErrorString = "ALP_NOT_IDLE"
            Case AlpReturnCodes.ALP_NOT_AVAILABLE
                AlpErrorString = "ALP_NOT_AVAILABLE"
            Case AlpReturnCodes.ALP_NOT_READY
                AlpErrorString = "ALP_NOT_READY"
            Case AlpReturnCodes.ALP_PARM_INVALID
                AlpErrorString = "ALP_PARM_INVALID"
            Case AlpReturnCodes.ALP_ADDR_INVALID
                AlpErrorString = "ALP_ADDR_INVALID"
            Case AlpReturnCodes.ALP_MEMORY_FULL
                AlpErrorString = "ALP_MEMORY_FULL"
            Case AlpReturnCodes.ALP_SEQ_IN_USE
                AlpErrorString = "ALP_SEQ_IN_USE"
            Case AlpReturnCodes.ALP_HALTED
                AlpErrorString = "ALP_HALTED"
            Case AlpReturnCodes.ALP_ERROR_INIT
                AlpErrorString = "ALP_ERROR_INIT"
            Case AlpReturnCodes.ALP_ERROR_COMM
                AlpErrorString = "ALP_ERROR_COMM"
            Case AlpReturnCodes.ALP_DEVICE_REMOVED
                AlpErrorString = "ALP_DEVICE_REMOVED"
            Case AlpReturnCodes.ALP_NOT_CONFIGURED
                AlpErrorString = "ALP_NOT_CONFIGURED"
            Case AlpReturnCodes.ALP_LOADER_VERSION
                AlpErrorString = "ALP_LOADER_VERSION"
            Case AlpReturnCodes.ALP_ERROR_POWER_DOWN
                AlpErrorString = "ALP_ERROR_POWER_DOWN"
            Case Else
				AlpErrorString = "(unknown error" & Format(nRet) & ")"
        End Select
    End Function


    Private m_AlpDeviceId As Int32, m_AlpSeqId1 As Int32, m_AlpSeqId2 As Int32
    Private m_nDmdType As AlpDevValues, m_nSizeX As Int32, m_nSizeY As Int32
    Private Sub Alloc_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Alloc.Click
        Dim nRet As Int32

        ' Allocate ALP device (no precautions if already allocated!)

        ' Known Errors:
        ' System.DllNotFoundException -> ALP DLL must be available, e.g. in the same directory as this exe file
        ' System.BadImageFormatException -> ALP DLL platform does not match. Try the Win32 (x86) or the x64 version.
        nRet = AlpDevAlloc(0, 0, m_AlpDeviceId)
        If nRet <> 0 Then
            MessageBox.Show("AlpDevAlloc Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If

        ' Inquire the DMD type in order to retrieve data size information
        nRet = AlpDevInquire(m_AlpDeviceId, AlpDevTypes.ALP_DEV_DMDTYPE, m_nDmdType)
        If nRet <> 0 Then
            MessageBox.Show("AlpDevInquire (DMD TYPE) Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If
        Select Case m_nDmdType
            Case AlpDevValues.ALP_DMDTYPE_XGA_055A, _
                AlpDevValues.ALP_DMDTYPE_XGA_055X, _
                AlpDevValues.ALP_DMDTYPE_XGA_07A
                m_nSizeX = 1024
                m_nSizeY = 768
            Case AlpDevValues.ALP_DMDTYPE_1080P_095A, _
                AlpDevValues.ALP_DMDTYPE_DISCONNECT
                m_nSizeX = 1920
                m_nSizeY = 1080
            Case AlpDevValues.ALP_DMDTYPE_WUXGA_096A
                m_nSizeX = 1920
                m_nSizeY = 1200
            Case Else
                MessageBox.Show("Unknown DMD type: " & Format(m_nDmdType))
                Exit Sub
        End Select

        ' Allocate 2 ALP sequences: 1 bit, 1 picture each
        nRet = AlpSeqAlloc(m_AlpDeviceId, 1, 1, m_AlpSeqId1)
        If nRet <> 0 Then
            MessageBox.Show("AlpSeqAlloc(1) Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If
        nRet = AlpSeqAlloc(m_AlpDeviceId, 1, 1, m_AlpSeqId2)
        If nRet <> 0 Then
            MessageBox.Show("AlpSeqAlloc(2) Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If

        ' Send image data of sequence 1 (checkered pattern, 64x64 squares)
        Dim Pattern(m_nSizeX * m_nSizeY) As Byte, x As Int32, y As Int32
        For y = 0 To m_nSizeY - 1 Step 1
            For x = 0 To m_nSizeX - 1 Step 1
                If ((x Xor y) And 64) = 0 Then
                    Pattern(y * m_nSizeX + x) = 128
                Else
                    Pattern(y * m_nSizeX + x) = 0
                End If
            Next
        Next
        nRet = AlpSeqPut(m_AlpDeviceId, m_AlpSeqId1, 0, 1, Pattern)
        If nRet <> 0 Then
            MessageBox.Show("AlpSeqPut(1) Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If

        ' Send image data of sequence 2 (checkered pattern, 128x128 squares)
        For y = 0 To m_nSizeY - 1 Step 1
            For x = 0 To m_nSizeX - 1 Step 1
                If ((x Xor y) And 128) = 0 Then
                    Pattern(y * m_nSizeX + x) = 128
                Else
                    Pattern(y * m_nSizeX + x) = 0
                End If
            Next
        Next
        nRet = AlpSeqPut(m_AlpDeviceId, m_AlpSeqId2, 0, 1, Pattern)
        If nRet <> 0 Then
            MessageBox.Show("AlpSeqPut(2) Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If

        ' Example: pulse Synch Output 1 each first of three frames.
		' (Not available prior to ALP-4)
        nRet = AlpDevControlEx_SynchGate(m_AlpDeviceId, 1, True, New Byte() {1, 0, 0})
        If nRet <> 0 Then
            MessageBox.Show("AlpDevControlEx_SynchGate Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If

        MessageBox.Show("Success." & vbCrLf & _
            "Allocated ALP device and 2 sequences." & vbCrLf & _
            "Sent image data of 2 sequences.")
    End Sub

    Private Sub Free_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Free.Click
        Dim nRet As Int32

        ' Disable SynchGate1 output: Omit "Gate" parameter
  		' (Not available prior to ALP-4)
        nRet = AlpDevControlEx_SynchGate(m_AlpDeviceId, 1, True, New Byte() {})

        ' Halt ALP device (no precautions if not allocated!)
        nRet = AlpDevHalt(m_AlpDeviceId)
        If nRet <> 0 Then
            MessageBox.Show("AlpDevHalt Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If
        ' Free ALP device
        nRet = AlpDevFree(m_AlpDeviceId)
        If nRet <> 0 Then
            MessageBox.Show("AlpDevFree Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If
        MessageBox.Show("Success." & vbCrLf & _
            "Halted and released ALP device.")
    End Sub

    Private Sub Pattern1_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Pattern1.Click
        Dim nRet As Int32

        ' Display sequence 1 (no precautions if not allocated!)
        nRet = AlpProjStartCont(m_AlpDeviceId, m_AlpSeqId1)
        If nRet <> 0 Then
            MessageBox.Show("AlpProjStartCont(1) Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If
    End Sub

    Private Sub Pattern2_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Pattern2.Click
        Dim nRet As Int32

        ' Display sequence 2 (no precautions if not allocated!)
        nRet = AlpProjStartCont(m_AlpDeviceId, m_AlpSeqId2)
        If nRet <> 0 Then
            MessageBox.Show("AlpProjStartCont(2) Error" & _
                vbCrLf & AlpErrorString(nRet))
            Exit Sub
        End If
    End Sub
End Class
