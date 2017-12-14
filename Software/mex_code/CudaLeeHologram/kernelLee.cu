#include <cuda_runtime.h>
#include <cublas_v2.h>
// CUDA and CUBLAS functions
#include "device_launch_parameters.h"
#include <math_constants.h>
#include "helper_string.h"
#include "helper_cuda.h"
#include <mex.h>
#include <stdio.h>
#include <cuda.h>


#ifndef min
#define min(a,b) ((a < b) ? a : b)
#endif
#ifndef max
#define max(a,b) ((a > b) ? a : b)
#endif


#define numColumnsPerFrame 128
#define numRowsPerFrame  768
#define stride 128
#define frameSizeInBytes (size_t(128) * 768)


__global__ void LeeKernel3(float *phases, unsigned char *out, int numReferencePixels, int leeBlockSize, float* carrierFreq, int patternSizeX, int patternSizeY, float *rot)
{
	size_t column_global = blockIdx.x*blockDim.x + threadIdx.x;
	long y = blockIdx.y*blockDim.y + threadIdx.y;
	long x = column_global % numColumnsPerFrame;
	//size_t z_global = inputOffsetPlane + (column_global / numColumnsPerFrame);
	size_t z_local = column_global / numColumnsPerFrame;

	float alpha[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
	unsigned char B[8];

	
	if ((y >= numReferencePixels) && (y < numRowsPerFrame - numReferencePixels) && (x * 8 >= numReferencePixels) && (x * 8 < 768 - numReferencePixels))
	{
		// query inputs!
		int sampleY = (y - numReferencePixels) / leeBlockSize;
		for (int k = 0; k<8; k++)
		{
			int sampleX = (8 * x - numReferencePixels + k) / leeBlockSize;
			alpha[k] = phases[z_local*patternSizeY*patternSizeX + sampleX*patternSizeY + sampleY];
		}
	}

			for (int k = 0; k<8; k++)
		{
			//float carrierWave = (x * 8 + k) - y; // old version rotation
			float carrierWave = cos(rot[z_local])*(x * 8 + k) + sin(rot[z_local])*y; // carrier wave rotation
			B[k] = (0.5 * (1 + cos(2.0f * (float)CUDART_PI_F*(carrierWave)* (carrierFreq[z_local])-alpha[k]))) > 0.5;
		}

	
	out[frameSizeInBytes*z_local + y * stride + x] = B[0] * 128 | B[1] * 64 | B[2] * 32 | B[3] * 16 | B[4] * 8 | B[5] * 4 | B[6] * 2 | B[7] * 1;
}




bool initCuda(cudaDeviceProp &deviceProp, size_t &avail, size_t needed)
{
	// Initialize CUDA
	int devID;
	cudaError_t error;
	error = cudaGetDevice(&devID);
	if (error != cudaSuccess)
	{
		mexPrintf("cudaGetDevice returned error code %d, line(%d)\n", error, __LINE__);
		return false;
	}
	error = cudaGetDeviceProperties(&deviceProp, devID);
	if (error != cudaSuccess)
	{
		mexPrintf("cudaGetDeviceProperties returned error code %d, line(%d)\n", error, __LINE__);
		return false;
	}


	size_t total;
	error = cudaMemGetInfo(&avail, &total);
	if (error != cudaSuccess)
		printf("GPU Device %d: \"%s\" with compute capability %d.%d, %.0f/%.0f MB, allocating %.0f \n", devID, deviceProp.name, deviceProp.major, deviceProp.minor, (double)(avail) / 1e6, (double)(total) / 1e6, (double)needed/1e6);

	return true;
}

void mexFunction(int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[]) {
	cudaError_t cudaStatus;
	cudaDeviceProp deviceProp;


	if (nrhs < 5 || nlhs != 1)
	{
		mexPrintf("Use: [Output:768x128xN] = CudaLeeHologram(Inputs [MxMxN], numReferencePixels, leeBlockSize, carrierFreq, rotation);");
		return;
	}

	
	float *phases  = (float*)mxGetData(prhs[0]);
	int numReferencePixels = *(double*)mxGetData(prhs[1]);
	int leeBlockSize = *(double*)mxGetData(prhs[2]);
	double *carrierFreq = (double*)mxGetData(prhs[3]);
	double *rot = (double*)mxGetData(prhs[4]);
	
	const size_t *dimF = mxGetDimensions(prhs[3]);
	bool varyingCarrier = dimF[0] > 1 || dimF[1] > 1;

	const size_t *dim = mxGetDimensions(prhs[0]);
	int numDim = mxGetNumberOfDimensions(prhs[0]);
	int N = numDim == 2 ? 1 : dim[2];
	
	if (!mxIsSingle(prhs[0]) )
	{
		mexPrintf("Currently supporting only single class variables of size 64x64 \n");
		return;
	}
	
	const size_t output_dim[3] = {768,128,N};

	plhs[0] = mxCreateNumericArray(3, output_dim, mxUINT8_CLASS, mxREAL);
	unsigned char  *out  = (unsigned char *)mxGetData(plhs[0]);

	int patternSizeX = dim[1];
	int patternSizeY = dim[0];
	//|| dim[0] != 64 || dim[1] != 64

	size_t total_mem_size_phases = dim[0]*dim[1]*N * sizeof(float);
	size_t desired_outputSize = size_t(128*768)*N * sizeof(unsigned char);

	size_t availMemory;
	if (!initCuda(deviceProp, availMemory, total_mem_size_phases+desired_outputSize))
		return;

	size_t max_planesInMemory = 14000; // more causes failues due to number of blocks in the grid(!!!)
	int numIterations = ceil((double)N/max_planesInMemory);

	size_t input_phases_in_memory = min(dim[0]*dim[1]*N * sizeof(float),
										dim[0]*dim[1]*max_planesInMemory * sizeof(float));


	size_t mem_size_out = min(	max_planesInMemory*(768*128), desired_outputSize);

	float *f_freq = new float[N];
	float *f_rot = new float[N];
	for (int k=0;k<N;k++)
	{
		f_freq[k] = varyingCarrier ? carrierFreq[k] : carrierFreq[0];
		f_rot[k] =  varyingCarrier ? rot[k] : rot[0];
	}


	float *d_phases;
	float *d_freq;
	float *d_rot;

	unsigned char *d_out;
	checkCudaErrors(cudaMalloc((void **)&d_freq, N*sizeof(float)));
	checkCudaErrors(cudaMalloc((void **)&d_rot, N*sizeof(float)));
	checkCudaErrors(cudaMemcpy(d_freq, f_freq, N*sizeof(float), cudaMemcpyHostToDevice));
	checkCudaErrors(cudaMemcpy(d_rot, f_rot, N*sizeof(float), cudaMemcpyHostToDevice));
	delete f_freq;
	delete f_rot;

	checkCudaErrors(cudaMalloc((void **)&d_phases, input_phases_in_memory));
	checkCudaErrors(cudaMalloc((void **)&d_out, mem_size_out));
	checkCudaErrors(cudaMemset(d_out, 0, mem_size_out));


	int blockSize = 32;
	
	for (int iteration=0;iteration<numIterations;iteration++)
	{
		int startPlane = max_planesInMemory*iteration;
		int endPlane = min((iteration + 1)*max_planesInMemory - 1, N - 1);
		int numPlanes = endPlane-startPlane+1;
		size_t bytesToCopy =  size_t(768*128)*numPlanes;

		size_t input_offset = patternSizeX*patternSizeY*startPlane;
		size_t numBytesOfPhasePatternsToCopy = patternSizeX*patternSizeY*sizeof(float)*numPlanes;
		checkCudaErrors(cudaMemcpy(d_phases, phases + input_offset, numBytesOfPhasePatternsToCopy, cudaMemcpyHostToDevice));



		// think about the input phases as a concatation of matrices along the column direction.
		// Then, the analysis is done by computing how many block are nedded.
		int numBlocksX = numPlanes*128 / blockSize;
		int numBlocksY = 768 / blockSize;
		
		dim3 dimGrid(numBlocksX, numBlocksY);
		dim3 dimBlock(blockSize, blockSize);
		LeeKernel3 << <dimGrid, dimBlock >> >(d_phases, d_out, numReferencePixels, leeBlockSize, d_freq, patternSizeX, patternSizeY,d_rot);
		checkCudaErrors(cudaDeviceSynchronize());

		size_t bytesToCopyOut =  size_t(768*128)*numPlanes;
		size_t out_offset = size_t(startPlane) * size_t(768 * 128);
		checkCudaErrors(cudaMemcpy(out+out_offset, d_out, bytesToCopyOut, cudaMemcpyDeviceToHost));
	}
	
	// Destroy the handle
	checkCudaErrors(cudaFree(d_phases));
	checkCudaErrors(cudaFree(d_out));

	checkCudaErrors(cudaFree(d_freq));
	checkCudaErrors(cudaFree(d_rot));

	cudaDeviceReset();
	return;
}
