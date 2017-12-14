using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace ALP_CSharp_DotNet
{
    public partial class AlpSampleForm : Form
    {
        UInt32 m_DevId, m_SeqId1, m_SeqId2;
        Int32 m_DmdWidth, m_DmdHeight;

        public AlpSampleForm()
        {
            InitializeComponent();

            m_DmdWidth = m_DmdHeight = 0;
            m_DevId = UInt32.MaxValue;
        }

        // Convert error string
        private string AlpErrorString(AlpImport.Result result)
        {
            return String.Format("{0}", result);
        }

        private void bnInit_Click(object sender, EventArgs e)
        {
            AlpImport.Result result;

            // allocate one ALP device
            result = AlpImport.DevAlloc(0, 0, ref m_DevId);
            txResult.Text = "DevAlloc " + AlpErrorString(result);
            if (AlpImport.Result.ALP_OK != result) return;  // error -> exit

            // determine image data size by DMD type
            Int32 DmdType=Int32.MaxValue;
            AlpImport.DevInquire(m_DevId, AlpImport.DevTypes.ALP_DEV_DMDTYPE, ref DmdType);
            switch ((AlpImport.DmdTypes)DmdType)
            {
                case AlpImport.DmdTypes.ALP_DMDTYPE_XGA:
                case AlpImport.DmdTypes.ALP_DMDTYPE_XGA_055A:
                case AlpImport.DmdTypes.ALP_DMDTYPE_XGA_055X:
                case AlpImport.DmdTypes.ALP_DMDTYPE_XGA_07A:
                    m_DmdWidth = 1024;
                    m_DmdHeight = 768;
                    break;
                case AlpImport.DmdTypes.ALP_DMDTYPE_1080P_095A:
                case AlpImport.DmdTypes.ALP_DMDTYPE_DISCONNECT:
                    m_DmdWidth = 1920;
                    m_DmdHeight = 1080;
                    break;
                case AlpImport.DmdTypes.ALP_DMDTYPE_SXGA_PLUS:
                    m_DmdWidth = 1400;
                    m_DmdHeight = 1050;
                    break;
                default:
                    txResult.Text = String.Format("Unknown DMD Type {0}", DmdType);
                    // Clean up... AlpImport.DevHalt(m_DevId); m_DevId = UInt32.MaxValue;
                    return;
            }

            // Allocate 2 sequences of 1 image, each
            result = AlpImport.SeqAlloc(m_DevId, 1, 1, ref m_SeqId1);
            txResult.Text = "SeqAlloc1 " + AlpErrorString(result);
            if (AlpImport.Result.ALP_OK != result) return;  // error -> exit

            result = AlpImport.SeqAlloc(m_DevId, 1, 1, ref m_SeqId2);
            txResult.Text = "SeqAlloc2 " + AlpErrorString(result);
            if (AlpImport.Result.ALP_OK != result) return;  // error -> exit

            // Example: pulse Synch Output 1 each first of three frames.
			// (Not available prior to ALP-4)
            result = AlpImport.DevControlEx_SynchGate(m_DevId, 1, true, 1,0,0);
            txResult.Text = "SynchGate1 " + AlpErrorString(result);
            if (AlpImport.Result.ALP_OK != result) return;  // error -> exit
        }

        private void bnSeq1_Click(object sender, EventArgs e)
        {
            Byte[] ChessBoard64 = new Byte[m_DmdWidth * m_DmdHeight];
            // Fill ChessBoard64 with a Chess Board pattern
            for (Int32 y = 0; y < m_DmdHeight; y++)
                for (Int32 x = 0; x < m_DmdWidth; x++)
                    if (((x & 64) == 0) ^ ((y&64)==0))
                        ChessBoard64[y * m_DmdWidth + x] = 0;
                    else
                        ChessBoard64[y * m_DmdWidth + x] = 255;   // >=128: white
            AlpImport.Result result;
            // Load image data from PC memory to ALP memory
            result = AlpImport.SeqPut(m_DevId, m_SeqId1, 0, 0, ref ChessBoard64);
            txResult.Text = "SeqPut " + AlpErrorString(result);
            // Start display
            if (AlpImport.Result.ALP_OK != result) return;  // error -> exit
            result = AlpImport.ProjStartCont(m_DevId, m_SeqId1);
            txResult.Text = "ProjStartCont " + AlpErrorString(result);
        }

        private void bnSeq2_Click(object sender, EventArgs e)
        {
            Byte[] Stripes32 = new Byte[m_DmdWidth * m_DmdHeight];
            // Fill Stripes32 with vertical stripes
            for (Int32 y = 0; y < m_DmdHeight; y++)
                for (Int32 x = 0; x < m_DmdWidth; x++)
                    if (((x & 32) == 0))
                        Stripes32[y * m_DmdWidth + x] = 0;
                    else
                        Stripes32[y * m_DmdWidth + x] = 255;   // >=128: white
            AlpImport.Result result;
            // Load image data from PC memory to ALP memory
            result = AlpImport.SeqPut(m_DevId, m_SeqId2, 0, 0, ref Stripes32);
            txResult.Text = "SeqPut " + AlpErrorString(result);
            // Start display
            if (AlpImport.Result.ALP_OK != result) return;  // error -> exit
            result = AlpImport.ProjStartCont(m_DevId, m_SeqId2);
            txResult.Text = "ProjStartCont " + AlpErrorString(result);
        }

        private void bnHalt_Click(object sender, EventArgs e)
        {
            AlpImport.Result result = AlpImport.ProjHalt(m_DevId);
            txResult.Text = "ProjHalt " + AlpErrorString(result);
        }

        private void bnCleanUp_Click(object sender, EventArgs e)
        {
            // Disable SynchGate1 output: Omit "Gate" parameter
			// (Not available prior to ALP-4)
            AlpImport.DevControlEx_SynchGate(m_DevId, 1, true);

            // Recommendation: always call DevHalt() before DevFree()
            AlpImport.Result result = AlpImport.DevFree(m_DevId);
            txResult.Text = "DevFree " + AlpErrorString(result);
            if (AlpImport.Result.ALP_OK != result) return;  // error -> exit
            m_DevId = UInt32.MaxValue;
        }
    }
}
