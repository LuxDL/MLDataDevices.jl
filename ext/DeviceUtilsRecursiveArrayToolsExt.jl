module DeviceUtilsRecursiveArrayToolsExt

using Adapt: Adapt, adapt
using DeviceUtils: DeviceUtils, AbstractDevice
using RecursiveArrayTools: VectorOfArray, DiffEqArray

# We want to preserve the structure
function Adapt.adapt_structure(to::AbstractDevice, x::VectorOfArray)
    return VectorOfArray(map(Base.Fix1(adapt, to), x.u))
end

function Adapt.adapt_structure(to::AbstractDevice, x::DiffEqArray)
    # Don't move the `time` to the GPU
    return DiffEqArray(map(Base.Fix1(adapt, to), x.u), x.t)
end

function DeviceUtils.get_device(x::Union{VectorOfArray, DiffEqArray})
    return mapreduce(DeviceUtils.get_device, DeviceUtils.__combine_devices, x.u)
end

end
