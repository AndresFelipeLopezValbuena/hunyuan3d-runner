#!/bin/bash
set -e

echo "=== Cloning Hunyuan3D 2.1 ==="
cd /workspace
git clone https://github.com/tencent-hunyuan/hunyuan3d-2.1.git
cd hunyuan3d-2.1

echo "=== Installing requirements ==="
pip install -r requirements.txt

echo "=== Building custom rasterizer ==="
cd hy3dpaint/custom_rasterizer
pip install -e .
cd ../..

echo "=== Building DifferentiableRenderer ==="
cd hy3dpaint/DifferentiableRenderer
bash compile_mesh_painter.sh
cd ../..

echo "=== Downloading RealESRGAN ==="
wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth -P hy3dpaint/ckpt

echo "=== Starting Gradio app on port 7860 ==="
python3 gradio_app.py \
  --model_path tencent/Hunyuan3D-2.1 \
  --subfolder hunyuan3d-dit-v2-1 \
  --texgen_model_path tencent/Hunyuan3D-2.1 \
  --low_vram_mode \
  --server_name 0.0.0.0 \
  --server_port 7860
