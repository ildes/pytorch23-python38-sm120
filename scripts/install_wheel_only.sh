#!/bin/bash
# Quick install script - just installs the pre-built wheel
# Use this if you already have a Python 3.8 environment set up

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "Installing pre-built PyTorch wheel for SM_120..."

WHEEL_FILE=$(ls "$REPO_DIR/wheels/"torch-*.whl 2>/dev/null | head -1)
if [ -z "$WHEEL_FILE" ]; then
    echo "ERROR: No wheel file found in $REPO_DIR/wheels/"
    exit 1
fi

echo "Wheel: $WHEEL_FILE"
pip install "$WHEEL_FILE"

echo ""
echo "Done! Verify with:"
echo "  python -c \"import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))\""
