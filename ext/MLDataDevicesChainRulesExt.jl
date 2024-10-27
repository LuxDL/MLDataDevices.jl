module MLDataDevicesChainRulesExt

using Adapt: Adapt
using ChainRules: OneElement
using MLDataDevices: GPU_DEVICES, CPUDevice

Adapt.adapt_storage(::CPUDevice, x::OneElement) = x
for Dev in GPU_DEVICES
    # use `@eval` to avoid ambiguity with adapt_storage(::CUDADevice, ::AbstractArray)
    @eval Adapt.adapt_storage(to::$Dev, x::OneElement) = Adapt.adapt(to, collect(x))
end

end
