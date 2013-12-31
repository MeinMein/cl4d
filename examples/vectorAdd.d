module vectorAdd;

import std.stdio;
import cl4d.all;

public
{
	CLVersion clVersion;
	CLPlatform platform;
	CLDevice device;
}

void main()
{
	// Load the OpenCL library.
	DerelictCL.load();

	// Query platforms and devices
	clVersion = CLVersion.CL10;
	platform = CLHost.getPlatforms()[0];
	device = platform.allDevices[0];

	// Reload the OpenCL library.
	DerelictCL.reload(clVersion);

	// Load OpenCL official extensions.
	DerelictCL.loadEXT(platform.handle);

	// Now OpenCL functions can be called.
	vectorAdd();

	// Unload the OpenCL library
	DerelictCL.unload();
}

void vectorAdd()
{
	// Create context
	auto context = CLContext(CLDevices(device));
	// Create commandqueue
	auto commandqueue = CLCommandQueue(context, device);

	// Create a program
	auto program = context.createProgram( CL_PROGRAM_STRING_DEBUG_INFO(__LINE__, __FILE__) ~ q{
			__kernel void sum(	__global const int* a,
								__global const int* b,
								__global int* c)
			{
				int i = get_global_id(0);
				c[i] = a[i] + b[i];
			} });
	program.build("-w -Werror");
	writeln(program.buildLog(device));
	
	// Create kernel
	auto kernel = CLKernel(program, "sum");
	
	// Create input vectors
	immutable VECTOR_SIZE = 100;
	int[VECTOR_SIZE] va = void; foreach(int i,e; va) va[i] = i;
	int[VECTOR_SIZE] vb = void; foreach(int i,e; vb) vb[i] = cast(int) vb.length - i;
	int[VECTOR_SIZE] vc;

	// Create buffers
	auto bufferA = CLBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, va.sizeof, va.ptr);
	auto bufferB = CLBuffer(context, CL_MEM_READ_ONLY | CL_MEM_USE_HOST_PTR, vb.sizeof, vb.ptr);
	auto bufferC = CLBuffer(context, CL_MEM_WRITE_ONLY | CL_MEM_USE_HOST_PTR, vc.sizeof, vc.ptr);

	// Copy lists A and B to the memory buffers (not needed because of CL_MEM_USE_HOST_PTR)
	//commandqueue.enqueueWriteBuffer(bufferA, CL_TRUE, 0, va.sizeof, va.ptr);
	//commandqueue.enqueueWriteBuffer(bufferB, CL_TRUE, 0, vb.sizeof, vb.ptr);

	// Set arguments to kernel
	kernel.setArgs(bufferA, bufferB, bufferC);

	// Run the kernel on specific ND range
	auto global	= NDRange(VECTOR_SIZE);
	auto local	= NDRange(1);
	CLEvent execEvent = commandqueue.enqueueNDRangeKernel(kernel, global, local);

	// Flush all commands in the commandqueue to the device
	commandqueue.flush();

	// Wait for the kernel to be executed
	execEvent.wait();

	// Read buffer vc into a local list (not needed because of CL_MEM_USE_HOST_PTR)
	//commandqueue.enqueueReadBuffer(bufferC, CL_TRUE, 0, vc.sizeof, vc.ptr);

	// Output results
	foreach(i,e; vc)
		writef("%d + %d = %d\n", va[i], vb[i], vc[i]);
}
