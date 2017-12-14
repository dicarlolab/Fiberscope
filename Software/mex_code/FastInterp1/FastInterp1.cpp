/*
% Copyright (c) 2015 Shay Ohayon, Massachusetts Institute of Technology.
*/
#include <stdio.h>
#include "mex.h"
#define MAX(x,y)(x>y)?(x):(y)
#define MIN(x,y)(x<y)?(x):(y)

void mexFunction( int nlhs, mxArray *plhs[], 
				 int nrhs, const mxArray *prhs[] ) 
{
	double *Timestamp = (double*)mxGetData(prhs[0]);
	double *Values = (double*)mxGetData(prhs[1]);
	double *SampleTS = (double*)mxGetData(prhs[2]);

	const int *dim = mxGetDimensions(prhs[0]);
	int iNumInputs= MAX(dim[0],dim[1]);

	const int *dim1 = mxGetDimensions(prhs[2]);
	int numOutputSamples = MAX(dim1[0],dim1[1]);


	const int *dimValues = mxGetDimensions(prhs[1]);
	int numRows = dimValues[0];
	mwSize outputDim[2];
	outputDim[0] = numRows;
	outputDim[1] = numOutputSamples;

	plhs[0] = mxCreateNumericArray(2, outputDim, mxDOUBLE_CLASS, mxREAL);
	double *Out = (double*)mxGetPr(plhs[0]);


	mwSize     NStructElems;
	for (int k=0;k<=2;k++) {
		NStructElems = mxGetNumberOfElements(prhs[k]);
		if (NStructElems == 0)
			return;
	}
	
	for (int row = 0; row < numRows; row++)
	{


		double fPrevValue;
		int iCurrInput = 0;
		double fCurrTS;

		if (SampleTS[0] < Timestamp[0]){
			fPrevValue = Values[0]; // or NaN
			fCurrTS = Timestamp[0];
		}
		else {
			// find previous value
			while (iCurrInput < iNumInputs && SampleTS[0] > Timestamp[iCurrInput])
				iCurrInput++;
			// now Timestamp[iCurrInput] > SampleTS[0]
			fPrevValue = Values[iCurrInput - 1];
			fCurrTS = Timestamp[iCurrInput];
		}

		for (int k = 0; k < numOutputSamples; k++) {
			if (SampleTS[k] >= fCurrTS) {
				while (iCurrInput < iNumInputs && SampleTS[k] >= fCurrTS) {
					iCurrInput++;
					fCurrTS = Timestamp[iCurrInput];
				}
				fPrevValue = Values[iCurrInput - 1];
			}

			Out[k] = fPrevValue;
		}

	}

}
