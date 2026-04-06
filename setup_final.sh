#!/bin/bash
# Hunyuan3D 2.1 — Complete setup for RunPod
# Pod: runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
# GPU: RTX A6000 (48GB), Driver 555+, CUDA 12.4
# DO NOT upgrade torch — 2.4.1+cu124 matches the driver
set -e

echo "=== System deps ==="
apt-get update && apt-get install -y python3-dev libopengl0

echo "=== Clone repo (if needed) ==="
cd /workspace
if [ ! -d "hunyuan3d-2.1" ]; then
  git clone --depth 1 https://github.com/tencent-hunyuan/hunyuan3d-2.1.git
fi
cd hunyuan3d-2.1

echo "=== Patch bpy import (not needed, skip it) ==="
python3 -c "
f = 'hy3dpaint/DifferentiableRenderer/mesh_utils.py'
lines = open(f).readlines()
out = open(f, 'w')
for line in lines:
    if line.strip() == 'import bpy':
        out.write('try:\n    import bpy\nexcept ImportError:\n    bpy = None\n')
    else:
        out.write(line)
out.close()
print('Patched bpy import')
"

echo "=== Strip bpy and Chinese mirrors from requirements ==="
sed -i '/mirrors.aliyun.com/d' requirements.txt
sed -i '/mirrors.cloud.tencent.com/d' requirements.txt
sed -i '/^bpy/d' requirements.txt
# Pin torch to what's already installed — DO NOT UPGRADE
sed -i '/^torch/d' requirements.txt
sed -i '/^torchvision/d' requirements.txt
sed -i '/^torchaudio/d' requirements.txt

echo "=== Install Python deps (pinned, no torch upgrade) ==="
pip install -r requirements.txt --timeout 120 2>&1 | tail -5

echo "=== Install extras ==="
pip install xatlas pybind11 opencv-python-headless trimesh pygltflib --timeout 120 2>&1 | tail -3

echo "=== Build custom_rasterizer ==="
cd hy3dpaint/custom_rasterizer
pip install -e . 2>&1 | tail -3
cd ../..

echo "=== Build mesh_inpaint_processor ==="
cd hy3dpaint/DifferentiableRenderer
bash compile_mesh_painter.sh 2>&1 || echo "mesh_inpaint build failed (non-critical, falls back to cv2)"
cd ../..

echo "=== Download RealESRGAN ==="
mkdir -p hy3dpaint/ckpt
if [ ! -f hy3dpaint/ckpt/RealESRGAN_x4plus.pth ]; then
  wget -q https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth -P hy3dpaint/ckpt
fi

echo "=== Copy input images ==="
mkdir -p input
if [ -d "/tmp/runner/input" ]; then
  cp /tmp/runner/input/* input/
fi

echo "=== Verify ==="
python3 -c "
import torch
print(f'torch={torch.__version__}, cuda={torch.cuda.is_available()}, gpu={torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"none\"}')
"

echo ""
echo "========================================="
echo "  SETUP COMPLETE"
echo "  Run: cd /workspace/hunyuan3d-2.1"
echo "  Then: export PYTHONPATH=/workspace/hunyuan3d-2.1/hy3dpaint:\$PYTHONPATH"
echo "  Then: python3 /tmp/runner/generate_textured.py"
echo "========================================="
