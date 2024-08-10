using LuxDeviceUtils, Random, Test
using ArrayInterface: parameterless_type

@testset "CPU Fallback" begin
    @test !LuxDeviceUtils.functional(LuxAMDGPUDevice)
    @test cpu_device() isa LuxCPUDevice
    @test gpu_device() isa LuxCPUDevice
    @test_throws LuxDeviceUtils.LuxDeviceSelectionException gpu_device(;
        force_gpu_usage=true)
    @test_throws Exception default_device_rng(LuxAMDGPUDevice(nothing))
    @test_logs (:warn, "`AMDGPU.jl` hasn't been loaded. Ignoring the device setting.") LuxDeviceUtils.set_device!(
        LuxAMDGPUDevice, nothing, 1)
end

using AMDGPU

@testset "Loaded Trigger Package" begin
    @test LuxDeviceUtils.GPU_DEVICE[] === nothing

    if LuxDeviceUtils.functional(LuxAMDGPUDevice)
        @info "AMDGPU is functional"
        @test gpu_device() isa LuxAMDGPUDevice
        @test gpu_device(; force_gpu_usage=true) isa LuxAMDGPUDevice
    else
        @info "AMDGPU is NOT functional"
        @test gpu_device() isa LuxCPUDevice
        @test_throws LuxDeviceUtils.LuxDeviceSelectionException gpu_device(;
            force_gpu_usage=true)
    end
    @test LuxDeviceUtils.GPU_DEVICE[] !== nothing
end

using FillArrays, Zygote  # Extensions

@testset "Data Transfer" begin
    ps = (a=(c=zeros(10, 1), d=1), b=ones(10, 1), e=:c,
        d="string", mixed=[2.0f0, 3.0, ones(2, 3)],  # mixed array types
        range=1:10,
        rng_default=Random.default_rng(), rng=MersenneTwister(),
        one_elem=Zygote.OneElement(2.0f0, (2, 3), (1:3, 1:4)), farray=Fill(1.0f0, (2, 3)))

    device = gpu_device()
    aType = LuxDeviceUtils.functional(LuxAMDGPUDevice) ? ROCArray : Array
    rngType = LuxDeviceUtils.functional(LuxAMDGPUDevice) ? AMDGPU.rocRAND.RNG :
              Random.AbstractRNG

    ps_xpu = ps |> device
    @test get_device(ps_xpu) isa LuxAMDGPUDevice
    @test get_device_type(ps_xpu) <: LuxAMDGPUDevice
    @test ps_xpu.a.c isa aType
    @test ps_xpu.b isa aType
    @test ps_xpu.a.d == ps.a.d
    @test ps_xpu.mixed isa Vector
    @test ps_xpu.mixed[1] isa Float32
    @test ps_xpu.mixed[2] isa Float64
    @test ps_xpu.mixed[3] isa aType
    @test ps_xpu.range isa aType
    @test ps_xpu.e == ps.e
    @test ps_xpu.d == ps.d
    @test ps_xpu.rng_default isa rngType
    @test ps_xpu.rng == ps.rng

    if LuxDeviceUtils.functional(LuxAMDGPUDevice)
        @test ps_xpu.one_elem isa ROCArray
        @test ps_xpu.farray isa ROCArray
    else
        @test ps_xpu.one_elem isa Zygote.OneElement
        @test ps_xpu.farray isa Fill
    end

    ps_cpu = ps_xpu |> cpu_device()
    @test get_device(ps_cpu) isa LuxCPUDevice
    @test get_device_type(ps_cpu) <: LuxCPUDevice
    @test ps_cpu.a.c isa Array
    @test ps_cpu.b isa Array
    @test ps_cpu.a.c == ps.a.c
    @test ps_cpu.b == ps.b
    @test ps_cpu.a.d == ps.a.d
    @test ps_cpu.mixed isa Vector
    @test ps_cpu.mixed[1] isa Float32
    @test ps_cpu.mixed[2] isa Float64
    @test ps_cpu.mixed[3] isa Array
    @test ps_cpu.range isa Array
    @test ps_cpu.e == ps.e
    @test ps_cpu.d == ps.d
    @test ps_cpu.rng_default isa Random.TaskLocalRNG
    @test ps_cpu.rng == ps.rng

    if LuxDeviceUtils.functional(LuxAMDGPUDevice)
        @test ps_cpu.one_elem isa Array
        @test ps_cpu.farray isa Array
    else
        @test ps_cpu.one_elem isa Zygote.OneElement
        @test ps_cpu.farray isa Fill
    end

    ps_mixed = (; a=rand(2), b=device(rand(2)))
    @test_throws ArgumentError get_device(ps_mixed)

    dev = gpu_device()
    x = rand(Float32, 10, 2)
    x_dev = x |> dev
    @test get_device(x_dev) isa parameterless_type(typeof(dev))
    @test get_device_type(x_dev) <: parameterless_type(typeof(dev))

    if LuxDeviceUtils.functional(LuxAMDGPUDevice)
        dev2 = gpu_device(length(AMDGPU.devices()))
        x_dev2 = x_dev |> dev2
        @test get_device(x_dev2) isa typeof(dev2)
        @test get_device_type(x_dev2) <: parameterless_type(typeof(dev2))
    end

    @testset "get_device_type compile constant" begin
        x = rand(10, 10) |> device
        ps = (; weight=x, bias=x, d=(x, x))

        return_val(x) = Val(get_device_type(x))  # If it is a compile time constant then type inference will work
        @test @inferred(return_val(ps)) isa Val{parameterless_type(typeof(device))}
    end
end

@testset "Wrapped Arrays" begin
    if LuxDeviceUtils.functional(LuxAMDGPUDevice)
        x = rand(10, 10) |> LuxAMDGPUDevice()
        @test get_device(x) isa LuxAMDGPUDevice
        @test get_device_type(x) <: LuxAMDGPUDevice
        x_view = view(x, 1:5, 1:5)
        @test get_device(x_view) isa LuxAMDGPUDevice
        @test get_device_type(x_view) <: LuxAMDGPUDevice
    end
end

@testset "Multiple Devices AMDGPU" begin
    if LuxDeviceUtils.functional(LuxAMDGPUDevice)
        ps = (; weight=rand(Float32, 10), bias=rand(Float32, 10))
        ps_cpu = deepcopy(ps)
        cdev = cpu_device()
        for idx in 1:length(AMDGPU.devices())
            amdgpu_device = gpu_device(idx)
            @test typeof(amdgpu_device.device) <: AMDGPU.HIPDevice
            @test AMDGPU.device_id(amdgpu_device.device) == idx

            ps = ps |> amdgpu_device
            @test ps.weight isa ROCArray
            @test ps.bias isa ROCArray
            @test AMDGPU.device_id(AMDGPU.device(ps.weight)) == idx
            @test AMDGPU.device_id(AMDGPU.device(ps.bias)) == idx
            @test isequal(cdev(ps.weight), ps_cpu.weight)
            @test isequal(cdev(ps.bias), ps_cpu.bias)
        end

        ps = ps |> cdev
        @test ps.weight isa Array
        @test ps.bias isa Array
    end
end

@testset "setdevice!" begin
    if LuxDeviceUtils.functional(LuxAMDGPUDevice)
        for i in 1:10
            @test_nowarn LuxDeviceUtils.set_device!(LuxAMDGPUDevice, nothing, i)
        end
    end
end
