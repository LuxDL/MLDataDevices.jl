module DeviceUtilsTrackerExt

using Adapt: Adapt
using DeviceUtils: DeviceUtils, AMDGPUDevice, CUDADevice, MetalDevice,
                      oneAPIDevice
using Tracker: Tracker

@inline function DeviceUtils.get_device(x::Tracker.TrackedArray)
    return DeviceUtils.get_device(Tracker.data(x))
end
@inline function DeviceUtils.get_device(x::AbstractArray{<:Tracker.TrackedReal})
    return DeviceUtils.get_device(Tracker.data.(x))
end

@inline DeviceUtils.__special_aos(::AbstractArray{<:Tracker.TrackedReal}) = true

for T in (AMDGPUDevice, AMDGPUDevice{Nothing}, CUDADevice,
    CUDADevice{Nothing}, MetalDevice, oneAPIDevice)
    @eval function Adapt.adapt_storage(to::$(T), x::AbstractArray{<:Tracker.TrackedReal})
        @warn "AbstractArray{<:Tracker.TrackedReal} is not supported for $(to). Converting \
               to Tracker.TrackedArray." maxlog=1
        return to(Tracker.collect(x))
    end
end

end
