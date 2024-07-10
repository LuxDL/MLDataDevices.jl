module DeviceUtilsReverseDiffExt

using DeviceUtils: DeviceUtils
using ReverseDiff: ReverseDiff

@inline function DeviceUtils.get_device(x::ReverseDiff.TrackedArray)
    return DeviceUtils.get_device(ReverseDiff.value(x))
end
@inline function DeviceUtils.get_device(x::AbstractArray{<:ReverseDiff.TrackedReal})
    return DeviceUtils.get_device(ReverseDiff.value.(x))
end

end
