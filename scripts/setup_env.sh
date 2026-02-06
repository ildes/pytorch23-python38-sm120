#!/bin/bash
# Environment setup script for PyTorch SM_120 + Isaac Gym
#
# Creates a conda environment with Python 3.8 and installs the pre-built wheel

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

ENV_NAME="${ENV_NAME:-isaacgym-sm120}"
PYTHON_VERSION="3.8"

echo "========================================"
echo "PyTorch SM_120 Environment Setup"
echo "========================================"
echo "Environment name: $ENV_NAME"
echo "Python version: $PYTHON_VERSION"
echo "========================================"

# Check for conda
if ! command -v conda &> /dev/null; then
    echo "ERROR: conda not found. Please install miniconda or anaconda."
    exit 1
fi

# Create environment
echo "[1/4] Creating conda environment..."
if conda env list | grep -q "^$ENV_NAME "; then
    echo "  Environment '$ENV_NAME' already exists."
    read -p "  Recreate it? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        conda env remove -n "$ENV_NAME" -y
        conda create -n "$ENV_NAME" python=$PYTHON_VERSION -y
    fi
else
    conda create -n "$ENV_NAME" python=$PYTHON_VERSION -y
fi

# Activate environment
echo "[2/4] Activating environment..."
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

# Install wheel
echo "[3/4] Installing PyTorch wheel..."
WHEEL_FILE=$(ls "$REPO_DIR/wheels/"torch-*.whl 2>/dev/null | head -1)
if [ -z "$WHEEL_FILE" ]; then
    echo "ERROR: No wheel file found in $REPO_DIR/wheels/"
    echo "  Either download the pre-built wheel or run build_pytorch.sh first."
    exit 1
fi

pip install "$WHEEL_FILE"

# Install common dependencies
echo "[4/4] Installing common dependencies..."
pip install numpy scipy pillow matplotlib

echo ""
echo "========================================"
echo "Setup complete!"
echo ""
echo "To activate the environment:"
echo "  conda activate $ENV_NAME"
echo ""
echo "To verify PyTorch CUDA support:"
echo "  python -c \"import torch; print(f'CUDA: {torch.cuda.is_available()}, Device: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else None}')\""
echo "========================================"
