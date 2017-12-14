/*
Fast Lee Hologram computation using CUDA
Programmed by Shay Ohayon
DiCarlo Lab @ MIT

Revision History
Version 0.1 10/22/2014  
*/

#include <stdio.h>
#include "mex.h"
#include <Windows.h>
#include <math.h>

#define MIN(a,b) (a)<(b)?(a):(b)
#define M_PI 3.14159265358979323846

const int DMDwidth = 1024;
const int DMDheight = 768;
const int effectiveDMDwidth = DMDheight;



__global__ void computeCuda(double *inputPhases, bool *binaryPatterns, double *carrierWave, int patternSizeX, int patternSizeY, int numReferencePixels, int leeBlockSize) {
	int z = blockDim.x * blockIdx.x + threadIdx.x;

	long long output_offset = DMDwidth*DMDheight*z;
	long long input_offset = patternSizeX*patternSizeY*z;
	double phaseAngle = 0;


	for (int x = 0; x < DMDwidth; x++)
	{
		int sampleX = (x - numReferencePixels) / leeBlockSize;
		for (int y = 0; y < DMDheight; y++)
		{

			phaseAngle = 0.0;

			if (y >= numReferencePixels && y < DMDheight - numReferencePixels && x >= numReferencePixels && x < effectiveDMDwidth - numReferencePixels)
			{
				int sampleY = (y - numReferencePixels) / leeBlockSize;
				assert(sampleX >= 0 && sampleY >= 0 && sampleX < patternSizeX && sampleY < patternSizeY);
				phaseAngle = inputPhases[input_offset + sampleX*patternSizeY + sampleY];
			}
			binaryPatterns[output_offset + x*DMDheight + y] = (0.5 * (1 + cos(carrierWave[x*DMDheight + y] - phaseAngle))) > 0.5;
		}
	}
}

void compute(int z, double *inputPhases, bool *binaryPatterns, double *carrierWave, int patternSizeX, int patternSizeY, int numReferencePixels, int leeBlockSize)
{

	long long output_offset = DMDwidth*DMDheight*z;
	long long input_offset = patternSizeX*patternSizeY*z;
	double phaseAngle = 0;


	for (int x = 0; x < DMDwidth; x++)
	{
		int sampleX = (x - numReferencePixels) / leeBlockSize;
		for (int y = 0; y < DMDheight; y++)
		{

			phaseAngle = 0.0;

			if (y >= numReferencePixels && y < DMDheight - numReferencePixels && x >= numReferencePixels && x < effectiveDMDwidth - numReferencePixels)
			{
				int sampleY = (y - numReferencePixels) / leeBlockSize;
				assert(sampleX >= 0 && sampleY >= 0 && sampleX < patternSizeX && sampleY < patternSizeY);
				phaseAngle = inputPhases[input_offset + sampleX*patternSizeY + sampleY];
			}
			binaryPatterns[output_offset + x*DMDheight + y] = (0.5 * (1 + cos(carrierWave[x*DMDheight + y] - phaseAngle))) > 0.5;
		}
	}
}


void mexFunction(int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[]) {

	if (nrhs < 3 || nlhs != 1)
	{
		mexPrintf("Use: OutputBinaryPatterns = FastLeeHologram(inputPhases (NxNxM), numReferencePixels, leeBlockSize, selectedCarrier);");
		return;
	}

	double *inputPhases = (double*) mxGetData(prhs[0]);
	int numReferencePixels = *(double*)mxGetData(prhs[1]);
	int leeBlockSize = *(double*)mxGetData(prhs[2]);
	double selectedCarrier = *(double*) mxGetData(prhs[3]);

	const int numDim = mxGetNumberOfDimensions(prhs[0]);
	const int *dataSize = mxGetDimensions(prhs[0]);
	int numPatterns = 1;
	int patternSizeX = dataSize[0];
	int patternSizeY = dataSize[1];
	if (numDim > 2) 
	{
		numPatterns = dataSize[2];
	}

	// allocate memory for output
	const int outputDimSize[3] = { DMDheight, DMDwidth, numPatterns };
	plhs[0] = mxCreateLogicalArray(3, outputDimSize);
	bool* binaryPatterns = (bool*)mxGetData(plhs[0]);


	// allocate memory for the reference wave
	double *carrierWave = new double[DMDheight*DMDwidth];
	for (int x = 0; x < DMDwidth; x++)
	{
		for (int y = 0; y < DMDheight; y++)
		{
			carrierWave[x*DMDheight +y] = 2.0 * M_PI*(x - y)*selectedCarrier;
		}
	}
	

	double* d_inputPhases;
	long inputSize = sizeof(double) * patternSizeX * patternSizeY * numPatterns;
	cudaMalloc(&d_inputPhases, inputSize);
	cudaMemcpy(d_inputPhases, inputPhases, inputSize, cudaMemcpyHostToDevice);


	int maxThreadsPerBlock = 256;
	int numBlocks = numPatterns / maxThreadsPerBlock;
	computeCuda << <numBlocks, maxThreadsPerBlock >> >(inputPhases, binaryPatterns, carrierWave, patternSizeX, patternSizeY, numReferencePixels, leeBlockSize);

	/*
	for (int z = 0; z < numPatterns; z++)
	{
		compute(z, inputPhases, binaryPatterns, carrierWave, patternSizeX, patternSizeY, numReferencePixels, leeBlockSize);
	}
	*/

	delete carrierWave;
}

