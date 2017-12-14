/*
Accessory Light modulator Package Wrapper (ALPwrapper)
Programmed by Shay Ohayon
DiCarlo Lab @ MIT

Revision History
Version 0.1 7/16/2014  

*/
#include <stdio.h>
#include "mex.h"
#include <Windows.h>
#include <math.h>

#define PACK_OUTPUT 1
#define MULTI_THREAD 1

#define MIN(a,b) (a)<(b)?(a):(b)
#define M_PI 3.14159265358979323846
#define LEE(a,b) (unsigned char) ( (0.5 * (1 + cos(a - b))) > 0.5)

const int DMDwidth = 1024;
const int DMDheight = 768;
const int effectiveDMDwidth = DMDheight;



typedef struct
{
	float *inputPhases;
#if (PACK_OUTPUT)
	unsigned char *binaryPatterns;
	unsigned char *zeroPattern;

#else
	bool *binaryPatterns;
	bool *zeroPattern;

#endif
	float *carrierWave;
	int patternSizeX;
	int patternSizeY;
	int numReferencePixels;
	int leeBlockSize;
	int startZ;
	int endZ;
} ThreadParams, *pThreadParams;

void compute(int z, float *inputPhases, bool *binaryPatterns, float *carrierWave, bool *zeroPattern,int patternSizeX, int patternSizeY, int numReferencePixels, int leeBlockSize)
{

	long long output_offset = (long long)DMDwidth*(long long)DMDheight*(long long) z;
	long long input_offset = patternSizeX*patternSizeY*z;
	float phaseAngle = 0;
	memcpy(&binaryPatterns[ output_offset],zeroPattern, DMDwidth*DMDheight);


	for (int x = numReferencePixels; x < effectiveDMDwidth - numReferencePixels; x++)
	{
		int sampleX = (x - numReferencePixels) / leeBlockSize;
		for (int y = numReferencePixels; y < DMDheight - numReferencePixels; y++)
		{
			int sampleY = (y - numReferencePixels) / leeBlockSize;
//			assert(sampleX >= 0 && sampleY >= 0 && sampleX < patternSizeX && sampleY < patternSizeY);
			phaseAngle = inputPhases[input_offset + sampleX*patternSizeY + sampleY];
			binaryPatterns[output_offset + x*DMDheight + y] = (0.5 * (1 + cos(carrierWave[x*DMDheight + y] - phaseAngle))) > 0.5;
		}
	}
}


void computePacked(int z, float *inputPhases, unsigned char *binaryPatternsPacked, float *carrierWave, unsigned char *zeroPatternPacked, int patternSizeX, int patternSizeY, int numReferencePixels, int leeBlockSize)
{

	long long output_offset = (long long)DMDwidth / 8 * (long long)DMDheight*(long long)z;
	long long input_offset = patternSizeX*patternSizeY*z;
	float phaseAngle = 0;
	memcpy(&binaryPatternsPacked[output_offset], zeroPatternPacked, DMDwidth / 8 * DMDheight);

	int len = DMDwidth / 8;
	int stride = DMDwidth / 8;

	for (int y = numReferencePixels; y < DMDheight - numReferencePixels; y++)
	{
		int sampleY = (y - numReferencePixels) / leeBlockSize;
		for (int x = numReferencePixels / 8; x < (effectiveDMDwidth - numReferencePixels)/8; x++)
		{
			unsigned char b0 = (0.5 * (1 + cos(carrierWave[(x * 8 + 0)*DMDheight + y] - inputPhases[input_offset + (x * 8 + 0 - numReferencePixels) / leeBlockSize*patternSizeY + sampleY]))) > 0.5;
			unsigned char b1 = (0.5 * (1 + cos(carrierWave[(x * 8 + 1)*DMDheight + y] - inputPhases[input_offset + (x * 8 + 1 - numReferencePixels) / leeBlockSize*patternSizeY + sampleY]))) > 0.5;
			unsigned char b2 = (0.5 * (1 + cos(carrierWave[(x * 8 + 2)*DMDheight + y] - inputPhases[input_offset + (x * 8 + 2 - numReferencePixels) / leeBlockSize*patternSizeY + sampleY]))) > 0.5;
			unsigned char b3 = (0.5 * (1 + cos(carrierWave[(x * 8 + 3)*DMDheight + y] - inputPhases[input_offset + (x * 8 + 3 - numReferencePixels) / leeBlockSize*patternSizeY + sampleY]))) > 0.5;
			unsigned char b4 = (0.5 * (1 + cos(carrierWave[(x * 8 + 4)*DMDheight + y] - inputPhases[input_offset + (x * 8 + 4 - numReferencePixels) / leeBlockSize*patternSizeY + sampleY]))) > 0.5;
			unsigned char b5 = (0.5 * (1 + cos(carrierWave[(x * 8 + 5)*DMDheight + y] - inputPhases[input_offset + (x * 8 + 5 - numReferencePixels) / leeBlockSize*patternSizeY + sampleY]))) > 0.5;
			unsigned char b6 = (0.5 * (1 + cos(carrierWave[(x * 8 + 6)*DMDheight + y] - inputPhases[input_offset + (x * 8 + 6 - numReferencePixels) / leeBlockSize*patternSizeY + sampleY]))) > 0.5;
			unsigned char b7 = (0.5 * (1 + cos(carrierWave[(x * 8 + 7)*DMDheight + y] - inputPhases[input_offset + (x * 8 + 7 - numReferencePixels) / leeBlockSize*patternSizeY + sampleY]))) > 0.5;
			binaryPatternsPacked[output_offset+y * stride + x] = b0 * 128 | b1 * 64 | b2 * 32 |b3 * 16 | b4 * 8 | b5 * 4 |b6 * 2 |b7 * 1;
		}
	}
}

DWORD WINAPI MyThreadFunction(LPVOID lpParam)
{
	pThreadParams pData = (pThreadParams)lpParam;

#if (PACK_OUTPUT)
	for (int z = pData->startZ; z <= pData->endZ; z++)
		computePacked(z, pData->inputPhases, pData->binaryPatterns, pData->carrierWave, pData->zeroPattern, pData->patternSizeX, pData->patternSizeY, pData->numReferencePixels, pData->leeBlockSize);
#else
	for (int z = pData->startZ; z <= pData->endZ; z++)
		compute(z, pData->inputPhases, pData->binaryPatterns, pData->carrierWave, pData->zeroPattern, pData->patternSizeX, pData->patternSizeY, pData->numReferencePixels, pData->leeBlockSize);
#endif

	return 0;
}

#define MAX_THREADS 8

void mexFunction(int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[]) {

	if (nrhs < 3 || nlhs != 1)
	{
		mexPrintf("Use: OutputBinaryPatterns = FastLeeHologram(inputPhases (NxNxM), numReferencePixels, leeBlockSize, selectedCarrier);");
		return;
	}
	if (!mxIsSingle(prhs[0]))
	{
		mexPrintf("inputPhases needs to be single class");
		return;
	}

	float *inputPhases = (float*)mxGetData(prhs[0]);
	int numReferencePixels = (int)*(double*)mxGetData(prhs[1]);
	int leeBlockSize = (int)*(double*)mxGetData(prhs[2]);
	float selectedCarrier = (float)*(double*) mxGetData(prhs[3]);

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
	// allocate memory for the reference wave
	float *carrierWave = new float[DMDheight*DMDwidth];


#if (PACK_OUTPUT)
	const int outputDimSize[3] = { DMDheight, DMDwidth/8, numPatterns };
	plhs[0] = mxCreateNumericArray(3, outputDimSize, mxUINT8_CLASS, mxREAL);
	unsigned char* binaryPatterns = (unsigned char*)mxGetData(plhs[0]);

	unsigned char *zeroPattern = new unsigned char[DMDheight*DMDwidth/8];


	for (int x = 0; x < DMDwidth; x++)
	{
		for (int y = 0; y < DMDheight; y++)
		{
			carrierWave[x*DMDheight + y] = 2.0f * (float)M_PI*(x - y)*selectedCarrier;
		}
	}

	int len = DMDwidth / 8;
	int stride = DMDwidth / 8;

	for (int y = 0; y < DMDheight; y++)
	{
		for (int x = 0; x < len; x++)
		{
			unsigned char b0 = (0.5 * (1.0 + cos(carrierWave[(x * 8 + 0)*DMDheight + y]))) > 0.5;
			unsigned char b1 = (0.5 * (1.0 + cos(carrierWave[(x * 8 + 1)*DMDheight + y]))) > 0.5;
			unsigned char b2 = (0.5 * (1.0 + cos(carrierWave[(x * 8 + 2)*DMDheight + y]))) > 0.5;
			unsigned char b3 = (0.5 * (1.0 + cos(carrierWave[(x * 8 + 3)*DMDheight + y]))) > 0.5;
			unsigned char b4 = (0.5 * (1.0 + cos(carrierWave[(x * 8 + 4)*DMDheight + y]))) > 0.5;
			unsigned char b5 = (0.5 * (1.0 + cos(carrierWave[(x * 8 + 5)*DMDheight + y]))) > 0.5;
			unsigned char b6 = (0.5 * (1.0 + cos(carrierWave[(x * 8 + 6)*DMDheight + y]))) > 0.5;
			unsigned char b7 = (0.5 * (1.0 + cos(carrierWave[(x * 8 + 7)*DMDheight + y]))) > 0.5;
			zeroPattern[y * stride + x] = b0 * 128 |b1 * 64 | b2 * 32 | b3 * 16 | b4 * 8 | b5 * 4 |b6 * 2 |b7 * 1;
		}
	}



#else
	const int outputDimSize[3] = { DMDheight, DMDwidth, numPatterns };
	plhs[0] = mxCreateLogicalArray(3, outputDimSize);
	bool* binaryPatterns = (bool*)mxGetData(plhs[0]);

	bool *zeroPattern = new bool[DMDheight*DMDwidth];

	for (int x = 0; x < DMDwidth; x++)
	{
		for (int y = 0; y < DMDheight; y++)
		{
			carrierWave[x*DMDheight + y] = 2.0f * M_PI*(x - y)*selectedCarrier;
			zeroPattern[x*DMDheight + y] = (0.5 * (1 + cos(carrierWave[x*DMDheight + y]))) > 0.5;
		}
	}

#endif

	
	// serial...
	/*
	for (int z = 0; z < numPatterns; z++)
	{
		compute(z, inputPhases, binaryPatterns, carrierWave, zeroPattern,patternSizeX, patternSizeY, numReferencePixels, leeBlockSize);
	}
	*/

	// parallel
	int chunkSize = (int)ceil((double)numPatterns / MAX_THREADS);

	pThreadParams pThreadInput[MAX_THREADS];
	DWORD   dwThreadIdArray[MAX_THREADS];
	HANDLE  hThreadArray[MAX_THREADS];
	//mexPrintf("Submitting %d threads, each running %d patterns\n", MAX_THREADS, chunkSize);

	for (int i = 0; i < MAX_THREADS; i++)
	{
		// Allocate memory for thread data.
		pThreadInput[i] = (pThreadParams)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, sizeof(ThreadParams));
		pThreadInput[i]->binaryPatterns = binaryPatterns;
		pThreadInput[i]->carrierWave = carrierWave;
		pThreadInput[i]->inputPhases = inputPhases;
		pThreadInput[i]->leeBlockSize = leeBlockSize;
		pThreadInput[i]->numReferencePixels = numReferencePixels;
		pThreadInput[i]->patternSizeX = patternSizeX;
		pThreadInput[i]->patternSizeY = patternSizeY;
		pThreadInput[i]->zeroPattern = zeroPattern;

		
		pThreadInput[i]->startZ = (i)*chunkSize;
		pThreadInput[i]->endZ = MIN(numPatterns-1, (i + 1)*chunkSize -1);
		//mexPrintf("Thread %d: %d - %d\n", i, pThreadInput[i]->startZ, pThreadInput[i]->endZ);


#if (MULTI_THREAD)
		hThreadArray[i] = CreateThread(
			NULL,                   // default security attributes
			0,                      // use default stack size  
			MyThreadFunction,       // thread function name
			pThreadInput[i],          // argument to thread function 
			0,                      // use default creation flags 
			&dwThreadIdArray[i]);   // returns the thread identifier 
#else		
		MyThreadFunction(pThreadInput[i]);
#endif
	}

#if (MULTI_THREAD)
	WaitForMultipleObjects(MAX_THREADS, hThreadArray, TRUE, INFINITE);
#endif
	// Close all thread handles and free memory allocations.

	for (int i = 0; i<MAX_THREADS; i++)
	{
		#if (MULTI_THREAD)
			CloseHandle(hThreadArray[i]);
		#endif
		if (pThreadInput[i] != NULL)
		{
			HeapFree(GetProcessHeap(), 0, pThreadInput[i]);
			pThreadInput[i] = NULL;    // Ensure address is not reused.
		}
	}

	delete zeroPattern;
	delete carrierWave;
}

