#include <cuda_runtime.h>
#include <cublas_v2.h>
// CUDA and CUBLAS functions
#include "device_launch_parameters.h"
#include "helper_string.h"
#include "helper_cuda.h"
#include "mex.h"
#include <stdio.h>
#include <cuda.h>



#ifndef min
#define min(a,b) ((a < b) ? a : b)
#endif
#ifndef max
#define max(a,b) ((a > b) ? a : b)
#endif

typedef struct _matrixSize      // Optional Command-line multiplier for matrix sizes
{
	unsigned int uiWA, uiHA, uiWB, uiHB, uiWC, uiHC;
} sMatrixSize;


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
		mexPrintf("GPU Device %d: \"%s\" with compute capability %d.%d, %.0f/%.0f MB, need %.0f MB \n", devID, deviceProp.name, deviceProp.major, deviceProp.minor, (double)(avail) / 1e6, (double)(total) / 1e6, (double)needed / 1e6);

	return true;
}

void mexFunction(int nlhs, mxArray *plhs[],
	int nrhs, const mxArray *prhs[]) {
	cudaError_t cudaStatus;
	sMatrixSize matrix_size;
	cudaDeviceProp deviceProp;

	if (nrhs < 2 || nlhs != 1)
	{
		mexPrintf("Use: [C] = CudaFastMult(A,B);");
		return;
	}


	float *phaseBasis = (float*)mxGetData(prhs[0]);
	float *K = (float*)mxGetData(prhs[1]);
	const size_t *dimA = mxGetDimensions(prhs[0]);
	const size_t *dimB = mxGetDimensions(prhs[1]);

	if (!mxIsSingle(prhs[0]) || !mxIsSingle(prhs[1]))
	{
		mexPrintf("Currently supporting only single class variables\n");
		return;
	}

	matrix_size.uiWA = dimA[1];
	matrix_size.uiHA = dimA[0];
	matrix_size.uiWB = dimB[1];
	matrix_size.uiHB = dimB[0];
	matrix_size.uiWC = matrix_size.uiWB;
	matrix_size.uiHC = matrix_size.uiHA;

	plhs[0] = mxCreateNumericMatrix(dimA[0], dimB[1], mxSINGLE_CLASS, mxREAL);
	float *h_A = (float *)mxGetData(prhs[0]);
	float *h_B = (float *)mxGetData(prhs[1]);
	float *h_C = (float *)mxGetData(plhs[0]);

	size_t size_A = matrix_size.uiWA * matrix_size.uiHA;
	size_t mem_size_A = sizeof(float) * size_A;
	size_t size_B = matrix_size.uiWB * matrix_size.uiHB;
	size_t mem_size_B = sizeof(float) * size_B;
	size_t size_C = matrix_size.uiWC * matrix_size.uiHC;
	size_t mem_size_C = sizeof(float) * size_C;

	size_t availMemory;
	if (!initCuda(deviceProp, availMemory, mem_size_A + mem_size_B + mem_size_C))
		return;

	// matrix B is too big. Splitting it column wise.
	
	int maximumColumnsInMemory = floor(0.4 * (availMemory - mem_size_A) / (matrix_size.uiHC + matrix_size.uiHB) / sizeof(float));
		
		//floor(0.4*(availMemory - mem_size_A) / 2.0 / sizeof(float) / matrix_size.uiHC);


	size_t memorychunk_B = min(maximumColumnsInMemory * matrix_size.uiHB * sizeof(float), mem_size_B);
	size_t memorychunk_C = min(maximumColumnsInMemory * matrix_size.uiHC * sizeof(float), mem_size_C);
	int numIterations = ceil((float)matrix_size.uiWC / maximumColumnsInMemory);
	float *d_A, *d_B, *d_C;
	checkCudaErrors(cudaMalloc((void **)&d_A, mem_size_A));
	checkCudaErrors(cudaMemcpy(d_A, h_A, mem_size_A, cudaMemcpyHostToDevice));
	
	// A Always stays in memory

	checkCudaErrors(cudaMalloc((void **)&d_C, memorychunk_C));
	checkCudaErrors(cudaMalloc((void **)&d_B, memorychunk_B));

	cublasHandle_t handle;
	checkCudaErrors(cublasCreate(&handle));

	for (int iteration = 0; iteration < numIterations; iteration++)
	{

		int StartColumn = iteration*maximumColumnsInMemory;
		int EndColumn = min((iteration + 1)*maximumColumnsInMemory - 1, matrix_size.uiWC - 1);
		int numColumnstoCompute = EndColumn - StartColumn + 1;
		//mexPrintf("Iteration %d/%d, Columns [%d-%d] of %d\n", 1+iteration, numIterations, StartColumn, EndColumn, matrix_size.uiWC - 1);
		size_t mem_cropped_B = numColumnstoCompute * matrix_size.uiHB * sizeof(float);
		size_t mem_offset_B = matrix_size.uiHB *StartColumn;
		// Load sub-matrix of B into gpu memory

		checkCudaErrors(cudaMemcpy(d_B, h_B + mem_offset_B, mem_cropped_B, cudaMemcpyHostToDevice));

		const float alpha = 1.0f;
		const float beta = 0.0f;
		checkCudaErrors(cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, matrix_size.uiHA, numColumnstoCompute,
			matrix_size.uiWA, &alpha, d_A, matrix_size.uiHA, d_B, matrix_size.uiHB, &beta, d_C, matrix_size.uiHC));

		size_t mem_cropped_C = numColumnstoCompute * matrix_size.uiHC * sizeof(float);
		size_t mem_offset_C = matrix_size.uiHC *StartColumn;


		checkCudaErrors(cudaDeviceSynchronize());
		// copy result from device to host
		checkCudaErrors(cudaMemcpy(h_C + mem_offset_C, d_C, mem_cropped_C, cudaMemcpyDeviceToHost));
	}
	checkCudaErrors(cudaFree(d_A));
	checkCudaErrors(cudaFree(d_B));
	checkCudaErrors(cudaFree(d_C));
	// Destroy the handle
	checkCudaErrors(cublasDestroy(handle));

	cudaDeviceReset();



	return;
}
