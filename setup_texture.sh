#!/bin/bash
set -e

echo "=== Installing system deps ==="
apt-get update && apt-get install -y python3-dev

echo "=== Cleaning requirements.txt ==="
cd /workspace/hunyuan3d-2.1
sed -i '/mirrors.aliyun.com/d' requirements.txt
sed -i '/mirrors.cloud.tencent.com/d' requirements.txt
sed -i '/^bpy/d' requirements.txt

echo "=== Installing Python deps (no bpy, default PyPI) ==="
pip install -r requirements.txt --index-url https://pypi.org/simple/ --timeout 120

echo "=== Building custom_rasterizer ==="
cd hy3dpaint/custom_rasterizer
pip install -e .
cd ../..

echo "=== Building mesh_inpaint_processor ==="
pip install pybind11
cd hy3dpaint/DifferentiableRenderer
bash compile_mesh_painter.sh
cd ../..

echo "=== Downloading RealESRGAN (if needed) ==="
mkdir -p hy3dpaint/ckpt
if [ ! -f hy3dpaint/ckpt/RealESRGAN_x4plus.pth ]; then
  wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth -P hy3dpaint/ckpt
fi

echo "=== Setup complete! Run: python3 /tmp/runner/generate_textured.py ==="
