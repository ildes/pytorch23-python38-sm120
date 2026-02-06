#!/bin/bash
# Torchvision build script for SM_120 + Python 3.8
#
# Requires PyTorch SM_120 wheel to be installed first

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TORCHVISION_COMMIT="126fc22ce33e6c2426edcf9ed540810c178fe9ce"

# Configuration
BUILD_DIR="${BUILD_DIR:-$HOME/pytorch-build-sm120}"
NUM_JOBS="${NUM_JOBS:-$(nproc)}"

echo "========================================"
echo "Torchvision SM_120 Build Script"
echo "========================================"
echo "Build directory: $BUILD_DIR"
echo "Jobs: $NUM_JOBS"
echo "========================================"

# Check PyTorch is installed
check_pytorch() {
    echo "[1/4] Checking PyTorch installation..."

    if ! python -c "import torch; print(f'PyTorch {torch.__version__}')" 2>/dev/null; then
        echo "ERROR: PyTorch not found. Install the SM_120 wheel first:"
        echo "  pip install wheels/torch-*_sm120_*.whl"
        exit 1
    fi

    echo "  $(python -c "import torch; print(f'PyTorch {torch.__version__}, CUDA {torch.version.cuda}')")"
}

# Clone torchvision
clone_torchvision() {
    echo "[2/4] Setting up torchvision source..."

    if [ -d "$BUILD_DIR/vision" ]; then
        echo "  Torchvision directory exists, checking out correct commit..."
        cd "$BUILD_DIR/vision"
        git fetch origin
        git checkout "$TORCHVISION_COMMIT"
    else
        mkdir -p "$BUILD_DIR"
        cd "$BUILD_DIR"
        echo "  Cloning torchvision..."
        git clone https://github.com/pytorch/vision.git
        cd vision
        git checkout "$TORCHVISION_COMMIT"
    fi
}

# Build torchvision
build_torchvision() {
    echo "[3/4] Building torchvision..."

    cd "$BUILD_DIR/vision"

    # Clean previous build
    rm -rf build/ dist/ *.egg-info/

    # Set environment
    export FORCE_CUDA=1
    export TORCH_CUDA_ARCH_LIST="12.0"
    export MAX_JOBS=$NUM_JOBS

    echo "  Starting build with $NUM_JOBS parallel jobs..."

    python setup.py bdist_wheel

    echo "  Build complete!"
}

# Copy wheel
copy_wheel() {
    echo "[4/4] Copying wheel to output directory..."

    mkdir -p "$REPO_DIR/wheels"
    cp "$BUILD_DIR/vision/dist/"*.whl "$REPO_DIR/wheels/"

    echo ""
    echo "========================================"
    echo "Build complete!"
    echo "Wheel location: $REPO_DIR/wheels/"
    ls -la "$REPO_DIR/wheels/"torchvision*.whl
    echo "========================================"
}

# Main
main() {
    check_pytorch
    clone_torchvision
    build_torchvision
    copy_wheel
}

case "${1:-all}" in
    check) check_pytorch ;;
    clone) clone_torchvision ;;
    build) build_torchvision ;;
    copy) copy_wheel ;;
    all) main ;;
    *)
        echo "Usage: $0 [check|clone|build|copy|all]"
        exit 1
        ;;
esac
