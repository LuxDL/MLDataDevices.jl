module MLDataDevicesOpenCLExt

using Adapt: Adapt
using MLDataDevices: MLDataDevices, Internal, OpenCLDevice, reset_gpu_device!
using GPUArrays: GPUArrays
using OpenCL: OpenCL, CLArray

__init__() = reset_gpu_device!()

MLDataDevices.loaded(::Union{OpenCLDevice, Type{<:OpenCLDevice}}) = true
# TODO: Check if OpenCL can provide a `functional` function.
MLDataDevices.functional(::Union{OpenCLDevice, Type{<:OpenCLDevice}}) = true

# Default RNG
MLDataDevices.default_device_rng(::OpenCLDevice) = GPUArrays.default_rng(CLArray)

# Query Device from Array
Internal.get_device(::CLArray) = OpenCLDevice()

Internal.get_device_type(::CLArray) = OpenCLDevice

# unsafe_free!
function Internal.unsafe_free_internal!(::Type{OpenCLDevice}, ::AbstractArray)
    # TODO: Implement this
    @warn "Support for `unsafe_free!` for OpenCL is not implemented yet. This is a no-op." maxlog=1
    return
end

# Device Transfer
Adapt.adapt_storage(::OpenCLDevice, x::AbstractArray) = CLArray(x)

# TODO: Eventually we want to do robust device management, since it is possible users
#       change the device after creating the OpenCLDevice and that might cuase unwanted
#       behavior.

end
