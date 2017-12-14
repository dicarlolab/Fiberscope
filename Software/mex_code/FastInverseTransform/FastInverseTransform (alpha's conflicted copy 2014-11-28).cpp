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

#define MIN(a,b) (a)<(b)?(a):(b)
#define M_PI 3.14159265358979323846

const int DMDwidth = 1024;
const int DMDheight = 768;
const int effectiveDMDwidth = DMDheight;



typedef struct
{
	double *phaseBasis;
	double *K;
	double *output;
	double *cacheSin;
	double *cacheCos;
	int N;
	int startZ;
	int endZ;
} ThreadParams, *pThreadParams;

void compute(int z, double *phaseBasis, double *Ksin, double *Kcos, double *output, int N)
{
	// compute column "z" of the output matrix.
	long long outputoffset = z * N;
	for (int row = 0; row < N; row++)
	{
		// output[row, z] = atan2(phasesBasis[row,:] * Ksin', phasesBasis[row,:] * Kcos'

		//Sk = dmd.phaseBasisReal*sin(K);
		//Ck = dmd.phaseBasisReal*cos(K);
		//Ein_all = atan2(Sk, Ck);
		long long inputoffset = row * N;

		double sumSin = 0;
		double sumCos = 0;
		double value;
		for (int k = 0; k < N; k++)
		{
			value = phaseBasis[inputoffset + k];
			sumSin += value * Ksin[k];
			sumCos += value * Ksin[k];
		}
		output[outputoffset + row] = atan2(sumSin, sumCos);
	}
}


DWORD WINAPI MyThreadFunction(LPVOID lpParam)
{
	pThreadParams pData = (pThreadParams)lpParam;
	long long offset;
	for (int z = pData->startZ; z <= pData->endZ; z++)
	{
		offset = pData->N * z;
		for (int row = 0; row < pData->N; row++)
		{
			pData->cacheSin[row] = sin(pData->K[offset + row]);
			pData->cacheCos[row] = cos(pData->K[offset + row]);
		}
		compute(z, pData->phaseBasis, pData->cacheSin, pData->cacheCos, pData->output, pData->N);
	}

	return 0;
}

#define MAX_THREADS 8

void mexFunction(int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[]) {

	if (nrhs < 2 || nlhs != 1)
	{
		mexPrintf("Use: phases_out = FastInverseTransform(phaseBasis (NxN) - TRANSPOSED!, K (NxM));");
		return;
	}

	double *phaseBasis = (double*)mxGetData(prhs[0]);
	double *K= (double*)mxGetData(prhs[1]);

	const int *dataSize = mxGetDimensions(prhs[1]);

	int N = dataSize[0];
	int M = dataSize[1];

	// allocate memory for output
	const int outputDimSize[2] = { N,M};
	plhs[0] = mxCreateDoubleMatrix(N, M, mxREAL);
	double* output= (double*)mxGetData(plhs[0]);

	// parallel
	int chunkSize = ceil((double)M / MAX_THREADS);

	pThreadParams pThreadInput[MAX_THREADS];
	DWORD   dwThreadIdArray[MAX_THREADS];
	HANDLE  hThreadArray[MAX_THREADS];
	//mexPrintf("Submitting %d threads, each running %d patterns\n", MAX_THREADS, chunkSize);

	for (int i = 0; i < MAX_THREADS; i++)
	{
		// Allocate memory for thread data.
		pThreadInput[i] = (pThreadParams)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, sizeof(ThreadParams));
		pThreadInput[i]->phaseBasis = phaseBasis;
		pThreadInput[i]->K = K;
		pThreadInput[i]->N = N;
		pThreadInput[i]->cacheSin = new double[N];
		pThreadInput[i]->cacheCos = new double[N];
		pThreadInput[i]->output = output;
		pThreadInput[i]->startZ = (i)*chunkSize;
		pThreadInput[i]->endZ = MIN(M-1, (i + 1)*chunkSize -1);
		//mexPrintf("Thread %d: %d - %d\n", i, pThreadInput[i]->startZ, pThreadInput[i]->endZ);
		/*
		hThreadArray[i] = CreateThread(
			NULL,                   // default security attributes
			0,                      // use default stack size  
			MyThreadFunction,       // thread function name
			pThreadInput[i],          // argument to thread function 
			0,                      // use default creation flags 
			&dwThreadIdArray[i]);   // returns the thread identifier 
			*/
			MyThreadFunction(pThreadInput[i]);
	}


	//WaitForMultipleObjects(MAX_THREADS, hThreadArray, TRUE, INFINITE);

	// Close all thread handles and free memory allocations.

	for (int i = 0; i<MAX_THREADS; i++)
	{
		//CloseHandle(hThreadArray[i]);
		if (pThreadInput[i] != NULL)
		{
			delete pThreadInput[i]->cacheSin;
			delete pThreadInput[i]->cacheCos;
			HeapFree(GetProcessHeap(), 0, pThreadInput[i]);
			pThreadInput[i] = NULL;    // Ensure address is not reused.
		}
	}

}

