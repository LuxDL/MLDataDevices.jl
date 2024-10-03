# MLDataDevices

[![Join the chat at https://julialang.zulipchat.com #machine-learning](https://img.shields.io/static/v1?label=Zulip&message=chat&color=9558b2&labelColor=389826)](https://julialang.zulipchat.com/#narrow/stream/machine-learning)
[![Latest Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://lux.csail.mit.edu/dev/api/Accelerator_Support/MLDataDevices)
[![Stable Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://lux.csail.mit.edu/stable/api/Accelerator_Support/MLDataDevices)

[![CI](https://github.com/LuxDL/MLDataDevices.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/LuxDL/MLDataDevices.jl/actions/workflows/CI.yml)
[![Buildkite](https://badge.buildkite.com/b098d6387b2c69bd0ab684293ff66332047b219e1b8f9bb486.svg?branch=main)](https://buildkite.com/julialang/MLDataDevices-dot-jl)
[![codecov](https://codecov.io/gh/LuxDL/MLDataDevices.jl/branch/main/graph/badge.svg?token=1ZY0A2NPEM)](https://codecov.io/gh/LuxDL/MLDataDevices.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)

`MLDataDevices.jl` is a lightweight package defining rules for transferring data across
devices. It is used in deep learning frameworks such as [Lux.jl](https://lux.csail.mit.edu/).

Currently we provide support for the following backends:

1. `CPUDevice`: for CPUs -- no additional packages required.
2. `CUDADevice`: `CUDA.jl` for NVIDIA GPUs.
3. `AMDGPUDevice`: `AMDGPU.jl` for AMD ROCM GPUs.
4. `MetalDevice`: `Metal.jl` for Apple Metal GPUs. **(Experimental)**
5. `oneAPIDevice`: `oneAPI.jl` for Intel GPUs. **(Experimental)**
6. `XLADevice`: `Reactant.jl` for XLA Support. **(Experimental)**

## Updating to v1.0

  * Package was renamed from `LuxDeviceUtils.jl` to `MLDataDevices.jl`.
  * `Lux(***)Device` has been renamed to `(***)Device`.
  * `Lux(***)Adaptor` objects have been removed. Use `(***)Device` objects instead.
