# PyTorch 2.3 + Torchvision 0.18 for SM_120 (Blackwell) + Python 3.8

> **Auto-generated repository** - Created with Claude Code

Pre-built PyTorch and Torchvision wheels targeting **SM_120 only** (RTX 5080/5090 Blackwell architecture) with Python 3.8 support.

## Why This Exists

**Isaac Gym** only supports Python 3.8, but modern Blackwell GPUs (SM_120) require patched PyTorch builds. Official wheels don't include SM_120 support, and CUDA 12.8 introduces breaking API changes. This repo bridges that gap.

## Quick Install

```bash
# Download wheels from releases
wget https://github.com/ildes/pytorch23-python38-sm120/releases/download/v2.3.0-sm120-cu128/torch-2.3.0a0_sm120_cu128-cp38-cp38-linux_x86_64.whl
wget https://github.com/ildes/pytorch23-python38-sm120/releases/download/v2.3.0-sm120-cu128/torchvision-0.18.1a0_sm120_cu128-cp38-cp38-linux_x86_64.whl

# Install (PyTorch first)
pip install torch-2.3.0a0_sm120_cu128-cp38-cp38-linux_x86_64.whl
pip install torchvision-0.18.1a0_sm120_cu128-cp38-cp38-linux_x86_64.whl
```

Verify:
```bash
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
python -c "import torchvision; print(torchvision.__version__)"
```

## Build from Source

```bash
# PyTorch (requires patches)
./scripts/build_pytorch.sh

# Torchvision (no patches needed, but requires PyTorch installed first)
./scripts/build_torchvision.sh
```

| Variable | Default | Description |
|----------|---------|-------------|
| `BUILD_DIR` | `~/pytorch-build-sm120` | Build location |
| `NUM_JOBS` | `$(nproc)` | Parallel jobs |

**Build time:** ~3 hours PyTorch + ~20 min Torchvision on 32-thread server

## PyTorch Patches Applied

| File | Change |
|------|--------|
| `cmake/public/cuda.cmake` | Skip nvToolsExt check (removed in CUDA 12.x), disable version mismatch error |
| `cmake/.../select_compute_arch.cmake` | Default unknown arch to SM_120 |
| `aten/.../CuFFTUtils.h` | Guard removed cuFFT error codes with `#ifdef` |
| `caffe2/utils/string_utils.cc` | Add missing `<cstdint>` include |

**Torchvision:** No patches required - builds cleanly against patched PyTorch.

## Build Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| `TORCH_CUDA_ARCH_LIST` | `12.0` | SM_120 only, no other architectures |
| `USE_CUDA` | `ON` | Core CUDA support |
| `USE_CUDNN` | `OFF` | Disabled - not required for Isaac Gym |
| `USE_NCCL` | `OFF` | Disabled - multi-GPU communication |
| `USE_DISTRIBUTED` | `OFF` | Disabled - distributed training |
| `USE_QNNPACK` | `OFF` | Disabled - quantized CPU ops |
| `USE_XNNPACK` | `OFF` | Disabled - optimized CPU ops |
| `USE_NNPACK` | `OFF` | Disabled - neural network CPU ops |
| `USE_MKLDNN` | `OFF` | Disabled - Intel MKL-DNN |
| `BUILD_TEST` | `OFF` | Disabled - unit tests |

NVCC flags: `-Xfatbin -compress-all -allow-unsupported-compiler`

## Requirements

**Pre-built wheels:**
- Linux x86_64, Python 3.8, CUDA 12.x runtime, Driver 550+

**Building from source:**
- CUDA 12.8+, CMake 3.18+, GCC 14+, ~50GB disk

## Tested On

- CUDA 12.8
- PyTorch commit `63d5e92`
- Torchvision commit `126fc22`
- Python 3.8

## License

Patches provided under PyTorch's BSD-style license.
