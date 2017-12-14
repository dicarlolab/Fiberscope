
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "mex.h"
#include <stdio.h>
#include <cuda.h>

#define MIN(a,b) (a)<(b)?(a):(b)
#define M_PI 3.14159265358979323846

#define DMDwidth  1024
#define DMDheight 768
#define effectiveDMDwidth  DMDheight

__global__ void cudaKernel(bool *dev_binaryPatterns, double *dev_carrierWave, double *dev_inputPhases, int *patternSizeX, int *patternSizeY, int *numReferencePixels, int *leeBlockSize)
{
	int pattern = threadIdx.x;
 
	long long output_offset = DMDwidth*DMDheight*pattern;
	long long input_offset = (*patternSizeX) * (*patternSizeY)*pattern;
	double phaseAngle = 0;


	for (int x = 0; x < DMDwidth; x++)
	{
		int sampleX = (x - (*numReferencePixels)) / (*leeBlockSize);
		for (int y = 0; y < DMDheight; y++)
		{

			phaseAngle = 0.0;

			if (y >= (*numReferencePixels) && y < DMDheight - (*numReferencePixels) && x >= (*numReferencePixels) && x < effectiveDMDwidth - (*numReferencePixels))
			{
				int sampleY = (y - (*numReferencePixels)) / (*leeBlockSize);
				assert(sampleX >= 0 && sampleY >= 0 && sampleX < patternSizeX && sampleY < patternSizeY);
				phaseAngle = dev_inputPhases[input_offset + sampleX*(*patternSizeY) + sampleY];
			}
			dev_binaryPatterns[output_offset + x*DMDheight + y] = (0.5 * (1 + cos(dev_carrierWave[x*DMDheight + y] - phaseAngle))) > 0.5;
		}
	}

}



void mexFunction(int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[]) {
	cudaError_t cudaStatus;

	if (nrhs < 3 || nlhs != 1)
	{
		mexPrintf("Use: OutputBinaryPatterns = CudaProject(inputPhases (NxNxM), numReferencePixels, leeBlockSize, selectedCarrier);");
		return;
	}

	double *inputPhases = (double*)mxGetData(prhs[0]);
	int numReferencePixels = *(double*)mxGetData(prhs[1]);
	int leeBlockSize = *(double*)mxGetData(prhs[2]);
	double selectedCarrier = *(double*)mxGetData(prhs[3]);

	const int numDim = mxGetNumberOfDimensions(prhs[0]);
	const size_t *dataSize = mxGetDimensions(prhs[0]);
	int numPatterns = 1;
	int patternSizeX = dataSize[0];
	int patternSizeY = dataSize[1];
	if (numDim > 2)
	{
		numPatterns = dataSize[2];
	}

	// allocate memory for output on host computer
	const size_t outputDimSize[3] = { DMDheight, DMDwidth, numPatterns };
	plhs[0] = mxCreateLogicalArray(3, outputDimSize);
	bool* binaryPatterns = (bool*)mxGetData(plhs[0]);
	double *carrierWave = new double[DMDwidth*DMDheight];
	for (int x = 0; x < DMDwidth; x++)
	{
		for (int y = 0; y < DMDheight; y++)
		{
			carrierWave[x*DMDheight + y] = 2.0 * M_PI*(x - y)*selectedCarrier;
		}
	}
	// allocate memory on GPU
	double *dev_carrierWave = 0;
	bool *dev_binaryPatterns = 0;
	double *dev_inputPhases = 0;
	int *dev_patternSizeX = 0;
	int *dev_patternSizeY = 0;
	int *dev_numReferencePixels = 0;
	int *dev_leeBlockSize = 0;

	cudaStatus = cudaMalloc((void**)&dev_patternSizeX,  sizeof(int));
	cudaStatus = cudaMalloc((void**)&dev_patternSizeY, sizeof(int));
	cudaStatus = cudaMalloc((void**)&dev_numReferencePixels, sizeof(int));
	cudaStatus = cudaMalloc((void**)&dev_leeBlockSize, sizeof(int));


	cudaStatus = cudaMalloc((void**)&dev_carrierWave, DMDheight*DMDwidth * sizeof(double));
	if (cudaStatus != cudaSuccess) {
		mexPrintf("cudaMalloc failed!");
		goto Error;
	}
	cudaStatus = cudaMalloc((void**)&dev_binaryPatterns, DMDheight*DMDwidth * numPatterns* sizeof(bool));
	if (cudaStatus != cudaSuccess) {
		mexPrintf( "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_inputPhases, patternSizeX*patternSizeY * numPatterns* sizeof(double));
	if (cudaStatus != cudaSuccess) {
		mexPrintf("cudaMalloc failed!");
		goto Error;
	}


	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(dev_carrierWave, carrierWave, DMDheight*DMDwidth * sizeof(double), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		mexPrintf("cudaMemcpy failed!");
		goto Error;
	}
	cudaStatus = cudaMemcpy(dev_inputPhases, inputPhases, patternSizeX*patternSizeY * numPatterns* sizeof(double), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		mexPrintf("cudaMemcpy failed!");
		goto Error;
	}


	cudaStatus = cudaMemcpy(dev_patternSizeX, &patternSizeX, sizeof(int), cudaMemcpyHostToDevice);
	cudaStatus = cudaMemcpy(dev_patternSizeY, &patternSizeY, sizeof(int), cudaMemcpyHostToDevice);
	cudaStatus = cudaMemcpy(dev_leeBlockSize, &leeBlockSize, sizeof(int), cudaMemcpyHostToDevice);
	cudaStatus = cudaMemcpy(dev_numReferencePixels, &numReferencePixels, sizeof(int), cudaMemcpyHostToDevice);


	// Launch a kernel on the GPU with one thread for each element.
	cudaKernel <<< 1, numPatterns >>>(dev_binaryPatterns, dev_carrierWave, dev_inputPhases, dev_patternSizeX, dev_patternSizeY, dev_numReferencePixels, dev_leeBlockSize);

	// Check for any errors launching the kernel
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		mexPrintf("addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	// cudaDeviceSynchronize waits for the kernel to finish, and returns
	// any errors encountered during the launch.
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		mexPrintf("cudaDeviceSynchronize returned error code %d after launching Kernel!\n", cudaStatus);
		goto Error;
	}

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(binaryPatterns, dev_binaryPatterns, DMDheight*DMDwidth * numPatterns* sizeof(bool), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		mexPrintf("cudaMemcpy failed!");
		goto Error;
	}


	/*
    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
		return;
    }
	*/
	delete carrierWave;
Error:
	cudaFree(dev_carrierWave);
	cudaFree(dev_binaryPatterns);
	cudaFree(dev_inputPhases);

	cudaFree(dev_patternSizeX);
	cudaFree(dev_patternSizeY);
	cudaFree(dev_numReferencePixels);
	cudaFree(dev_leeBlockSize);


	return;
}
