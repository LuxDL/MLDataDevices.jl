using MLDataDevices, MLUtils

const BACKEND_GROUP = lowercase(get(ENV, "BACKEND_GROUP", "none"))

if BACKEND_GROUP == "cuda" || BACKEND_GROUP == "all"
    using LuxCUDA
end

if BACKEND_GROUP == "amdgpu" || BACKEND_GROUP == "all"
    using AMDGPU
end

if BACKEND_GROUP == "metal" || BACKEND_GROUP == "all"
    using Metal
end

if BACKEND_GROUP == "oneapi" || BACKEND_GROUP == "all"
    using oneAPI
end

DEVICES = [CPUDevice, CUDADevice, AMDGPUDevice, MetalDevice, oneAPIDevice]

freed_if_can_be_freed(x) = freed_if_can_be_freed(get_device_type(x), x)
freed_if_can_be_freed(::Type{CPUDevice}, x) = true
function freed_if_can_be_freed(::Type, x)
    try
        Array(x)
        return false
    catch err
        err isa ArgumentError && return true
        rethrow()
    end
end

@testset "Device Iterator: $(dev_type)" for dev_type in DEVICES
    dev = dev_type()

    !MLDataDevices.functional(dev) && continue

    @info "Testing Device Iterator for $(dev)..."

    @testset "Basic Device Iterator" begin
        datalist = [rand(10) for _ in 1:10]

        prev_batch = nothing
        for data in DeviceIterator(dev, datalist)
            prev_batch === nothing || @test freed_if_can_be_freed(prev_batch)
            prev_batch = data
            @test size(data) == (10,)
            @test get_device_type(data) == dev_type
        end
    end

    @testset "DataLoader: parallel=$parallel" for parallel in (true, false)
        X = rand(Float64, 3, 33)
        pre = DataLoader(dev(X); batchsize=13, shuffle=false)
        post = DataLoader(X; batchsize=13, shuffle=false) |> dev

        for epoch in 1:2
            prev_pre, prev_post = nothing, nothing
            for (p, q) in zip(pre, post)
                @test get_device_type(p) == dev_type
                @test get_device_type(q) == dev_type
                @test p ≈ q

                dev_type === CPUDevice && continue

                prev_pre === nothing || @test !freed_if_can_be_freed(prev_pre)
                prev_pre = p

                prev_post === nothing || @test freed_if_can_be_freed(prev_post)
                prev_post = q
            end
        end

        Y = rand(Float64, 1, 33)
        pre = DataLoader((; x=dev(X), y=dev(Y)); batchsize=13, shuffle=false)
        post = DataLoader((; x=X, y=Y); batchsize=13, shuffle=false) |> dev

        for epoch in 1:2
            prev_pre, prev_post = nothing, nothing
            for (p, q) in zip(pre, post)
                @test get_device_type(p.x) == dev_type
                @test get_device_type(p.y) == dev_type
                @test get_device_type(q.x) == dev_type
                @test get_device_type(q.y) == dev_type
                @test p.x ≈ q.x
                @test p.y ≈ q.y

                dev_type === CPUDevice && continue

                if prev_pre !== nothing
                    @test !freed_if_can_be_freed(prev_pre.x)
                    @test !freed_if_can_be_freed(prev_pre.y)
                end
                prev_pre = p

                if prev_post !== nothing
                    @test freed_if_can_be_freed(prev_post.x)
                    @test freed_if_can_be_freed(prev_post.y)
                end
                prev_post = q
            end
        end
    end
end
