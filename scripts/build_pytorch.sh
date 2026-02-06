#!/bin/bash
# PyTorch 2.3 build script for SM_120 (RTX 5080/5090) + Python 3.8 (Isaac Gym compatibility)
#
# This script clones PyTorch, applies patches for CUDA 12.x/SM_120 support,
# and builds a wheel compatible with Python 3.8

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PATCH_FILE="$REPO_DIR/patches/sm120-cuda12-py38.patch"
PYTORCH_COMMIT="63d5e9221bedd1546b7d364b5ce4171547db12a9"

# Configuration
BUILD_DIR="${BUILD_DIR:-$HOME/pytorch-build-sm120}"
NUM_JOBS="${NUM_JOBS:-$(nproc)}"
CUDA_ARCH_LIST="${CUDA_ARCH_LIST:-12.0}"

echo "========================================"
echo "PyTorch SM_120 Build Script"
echo "========================================"
echo "Build directory: $BUILD_DIR"
echo "Jobs: $NUM_JOBS"
echo "CUDA architectures: $CUDA_ARCH_LIST"
echo "========================================"

# Check prerequisites
check_prereqs() {
    echo "[1/6] Checking prerequisites..."

    if ! command -v nvcc &> /dev/null; then
        echo "ERROR: nvcc not found. Please install CUDA toolkit."
        exit 1
    fi

    CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]*\.[0-9]*\).*/\1/')
    echo "  CUDA version: $CUDA_VERSION"

    if ! command -v python &> /dev/null; then
        echo "ERROR: python not found."
        exit 1
    fi

    PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2)
    echo "  Python version: $PYTHON_VERSION"

    if ! command -v cmake &> /dev/null; then
        echo "ERROR: cmake not found."
        exit 1
    fi

    if ! command -v ninja &> /dev/null; then
        echo "WARNING: ninja not found. Build will be slower without it."
    fi
}

# Clone or update PyTorch
clone_pytorch() {
    echo "[2/6] Setting up PyTorch source..."

    if [ -d "$BUILD_DIR/pytorch" ]; then
        echo "  PyTorch directory exists, checking out correct commit..."
        cd "$BUILD_DIR/pytorch"
        git fetch origin
        git checkout "$PYTORCH_COMMIT"
    else
        mkdir -p "$BUILD_DIR"
        cd "$BUILD_DIR"
        echo "  Cloning PyTorch..."
        git clone --recursive https://github.com/pytorch/pytorch.git
        cd pytorch
        git checkout "$PYTORCH_COMMIT"
        git submodule sync
        git submodule update --init --recursive
    fi
}

# Apply patches
apply_patches() {
    echo "[3/6] Applying SM_120/CUDA 12.x patches..."

    cd "$BUILD_DIR/pytorch"

    # Check if patch already applied
    if git diff --quiet && git diff --cached --quiet; then
        echo "  Applying patch..."
        git apply "$PATCH_FILE"
        echo "  Patch applied successfully."
    else
        echo "  Working directory has changes, checking if patch is already applied..."
        if git apply --check --reverse "$PATCH_FILE" 2>/dev/null; then
            echo "  Patch already applied."
        else
            echo "  Resetting and applying patch..."
            git checkout .
            git apply "$PATCH_FILE"
        fi
    fi
}

# Install Python dependencies
install_deps() {
    echo "[4/6] Installing Python build dependencies..."

    pip install -r "$BUILD_DIR/pytorch/requirements.txt" || true
    pip install cmake ninja pyyaml typing_extensions numpy
}

# Build PyTorch
build_pytorch() {
    echo "[5/6] Building PyTorch..."

    cd "$BUILD_DIR/pytorch"

    # Clean previous build
    python setup.py clean || true

    # Set environment variables for build
    # Target SM_120 ONLY - no other architectures
    export TORCH_CUDA_ARCH_LIST="$CUDA_ARCH_LIST"
    export TORCH_NVCC_FLAGS="-Xfatbin -compress-all -allow-unsupported-compiler"
    export CMAKE_PREFIX_PATH="${CONDA_PREFIX:-$(dirname $(which python))/..}"

    # Core CUDA support
    export USE_CUDA=1

    # Disabled features (reduces build time, not needed for Isaac Gym)
    export USE_CUDNN=OFF
    export USE_NCCL=OFF
    export USE_DISTRIBUTED=OFF
    export USE_QNNPACK=OFF
    export USE_XNNPACK=OFF
    export USE_NNPACK=OFF
    export USE_MKLDNN=OFF
    export BUILD_TEST=OFF

    export MAX_JOBS=$NUM_JOBS

    # Build wheel
    echo "  Starting build with $NUM_JOBS parallel jobs..."
    echo "  This may take 1-4 hours depending on your system."

    python setup.py bdist_wheel

    echo "  Build complete!"
}

# Copy wheel to output
copy_wheel() {
    echo "[6/6] Copying wheel to output directory..."

    mkdir -p "$REPO_DIR/wheels"
    cp "$BUILD_DIR/pytorch/dist/"*.whl "$REPO_DIR/wheels/"

    echo ""
    echo "========================================"
    echo "Build complete!"
    echo "Wheel location: $REPO_DIR/wheels/"
    ls -la "$REPO_DIR/wheels/"*.whl
    echo "========================================"
}

# Main
main() {
    check_prereqs
    clone_pytorch
    apply_patches
    install_deps
    build_pytorch
    copy_wheel
}

# Allow running individual steps
case "${1:-all}" in
    prereqs) check_prereqs ;;
    clone) clone_pytorch ;;
    patch) apply_patches ;;
    deps) install_deps ;;
    build) build_pytorch ;;
    copy) copy_wheel ;;
    all) main ;;
    *)
        echo "Usage: $0 [prereqs|clone|patch|deps|build|copy|all]"
        exit 1
        ;;
esac
