// cl4d - a D wrapper for the Derelict OpenCL binding
// written in the D programming language
//
// Copyright: Andreas Hollandt 2009 - 2011,
//            MeinMein 2013-2014.
// License:   Boost License 1.0
//            (See accompanying file LICENSE_1_0.txt or copy at
//             http://www.boost.org/LICENSE_1_0.txt)
// Authors:   Andreas Hollandt,
//            Gerbrand Kamphuis (meinmein.com).

module cl4d.host;

import derelict.opencl.cl;
import cl4d.error;
import cl4d.platform;

///
struct CLHost
{
	/// get an array of all available platforms
	static CLPlatforms getPlatforms()
	{
		cl_uint numPlatforms;
		cl_errcode res;

		// get number of platforms
		res = clGetPlatformIDs(0, null, &numPlatforms);

		version(NO_CL_EXCEPTIONS) {} else
		if(res != CL_SUCCESS)
			throw new CLException(res, "couldn't retrieve number of platforms", __FILE__, __LINE__);

		// get platform IDs
		auto platformIDs = new cl_platform_id[numPlatforms];
		res = clGetPlatformIDs(cast(cl_uint) platformIDs.length, platformIDs.ptr, null);

		version(NO_CL_EXCEPTIONS) {} else
		if(res != CL_SUCCESS)
			throw new CLException(res, "couldn't get platform list", __FILE__, __LINE__);

		return CLPlatforms(platformIDs);
	}

	/**
	 * allows the implementation to release the resources allocated by the OpenCL compiler.  This is a
	 * hint from the application and does not guarantee that the compiler will not be used in the future
	 * or that the compiler will actually be unloaded by the implementation.  Calls to clBuildProgram
	 * after clUnloadCompiler will reload the compiler, if necessary, to build the appropriate program executable.
	 */
	static void unloadCompiler()
	{
		if(DerelictCL.loadedVersion >= CLVersion.CL12)
			throw new CLVersionException();

		cl_errcode res = void;
		res = clUnloadCompiler();
		if(res != CL_SUCCESS)
			throw new CLException(res, "failed unloading compiler, this shouldn't happen in OpenCL 1.0");
	}
}
