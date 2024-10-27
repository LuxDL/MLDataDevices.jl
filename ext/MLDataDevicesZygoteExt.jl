module MLDataDevicesZygoteExt

using Adapt: Adapt
using MLDataDevices: CPUDevice, GPU_DEVICES
using Zygote: OneElement

Adapt.adapt_storage(::CPUDevice, x::OneElement) = x

for Dev in GPU_DEVICES
    # use `@eval` to avoid ambiguity with adapt_storage(::CUDADevice, ::AbstractArray)
    @eval Adapt.adapt_storage(to::$Dev, x::OneElement) = Adapt.adapt(to, collect(x))
end

end
