#include <stdio.h>
#include <math.h>
#include "mex.h"

/* This function takes as input an NxM image.
The image is assumed to have values only at [dx*i + offset_x, dy*j + offsetY]
The returned image is a smooth interpolation 
*/

#define BILINEAR(x,y,V00,V10,V01,V11)((V00*(1-x)*(1-y)+V10*(x)*(1-y)+V01*(1-x)*(y)+V11*(x)*(y)))
#define MAX(x,y)(x>y)?(x):(y)

#define ACCESS_IMAGE(imag, indx, maxindx,NaNValue)(indx>=0 && indx<maxindx) ? imag[indx] : NaNValue;


template<class T> void CalcInterpolation(T* input_image, float *output, 
										 int in_rows, int in_cols, int offsetX, int offsetY, int dX, int dY) {
	float V00,V01,V10,V11;
	int num_input_voxels = in_rows * in_cols;
	int NaNValue = 0;

	for (int x = offsetX; x < in_cols; x++)
	{
		for (int y = offsetY; y < in_rows; y++)
		{
			int index = x*in_rows + y;
			if ((dX == 1 && dY == 1) ||  ( ((x-offsetX) % dX == 0)  &&	((y-offsetY) % dY == 0) ) )
			{
				// output = input.
				output[index] = input_image[index];
				continue;
			}
			// otherwise, we interpolate!

			float rx = (x-offsetX) / (float)dX;
			float ry = (y-offsetY) / (float)dY;

			float sx = ((x-offsetX) % dX) / (float)dX;
			float sy = ((y-offsetY) % dY) / (float)dY;

			int p00x = offsetX+floor(rx)*dX;
			int p00y = offsetY+floor(ry)*dY;

			int index00 = p00x*in_rows + p00y;

			V00 = ACCESS_IMAGE(input_image,index00+0, num_input_voxels,NaNValue);
			V01 = ACCESS_IMAGE(input_image,index00+dY, num_input_voxels,NaNValue);
			V10 = ACCESS_IMAGE(input_image,index00+dX*in_rows, num_input_voxels,NaNValue);
			V11 = ACCESS_IMAGE(input_image,index00+dY+dX*in_rows, num_input_voxels,NaNValue);

			output[index] = float(BILINEAR(sx, sy, V00,V10,V01,V11));
		}
	}
}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
	if (nlhs != 1 || nrhs < 5) {
		mexErrMsgTxt("Usage: [InterpolatedImage] = fnFastUpSampling(Image, startX, startY, dX, dY");
		return;
	} 
	/* Get the number of dimensions in the input argument. */
	if (mxGetNumberOfDimensions(prhs[0]) != 2) {
		mexErrMsgTxt("Input volume must be 2D. ");
		return;
	}

	const int *input_dim_array = mxGetDimensions(prhs[0]);
	int in_rows = input_dim_array[0];
	int in_cols = input_dim_array[1];

	int offsetX = (int) *(double *)mxGetData(prhs[1]);
	int offsetY = (int) *(double *)mxGetData(prhs[2]);
	int dX = (int) *(double *)mxGetData(prhs[3]);
	int dY = (int) *(double *)mxGetData(prhs[4]);

	plhs[0] = mxCreateNumericArray(2, input_dim_array, mxSINGLE_CLASS, mxREAL);
	float *output = (float*)mxGetPr(plhs[0]);

	if (mxIsSingle(prhs[0])) {
		float *input_image = (float*)mxGetData(prhs[0]);
		CalcInterpolation(input_image, output, in_rows, in_cols, offsetX, offsetY, dX,dY);
	}

	if (mxIsDouble(prhs[0])) {
		double *input_image = (double*)mxGetData(prhs[0]);
		CalcInterpolation(input_image, output, in_rows, in_cols, offsetX, offsetY, dX,dY);
	}

	if (mxIsUint16(prhs[0]) || mxIsInt16(prhs[0])) {
		short *input_image = (short*)mxGetData(prhs[0]);
		CalcInterpolation(input_image, output, in_rows, in_cols, offsetX, offsetY, dX,dY);
	}

	if (mxIsUint8(prhs[0])) {
		unsigned char *input_image = (unsigned char *)mxGetData(prhs[0]);
		CalcInterpolation(input_image, output, in_rows, in_cols, offsetX, offsetY, dX,dY);
	}

}