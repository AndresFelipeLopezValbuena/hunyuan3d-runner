import sys
import os
import glob

sys.path.insert(0, './hy3dshape')
sys.path.insert(0, './hy3dpaint')

from PIL import Image
from hy3dshape.pipelines import Hunyuan3DDiTFlowMatchingPipeline
from hy3dpaint.textureGenPipeline import Hunyuan3DPaintPipeline, Hunyuan3DPaintConfig
from hy3dpaint.convert_utils import create_glb_with_pbr_materials

# --- Load shape pipeline ---
print("Loading shape pipeline...")
shape_pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained('tencent/Hunyuan3D-2.1')

# --- Load texture pipeline ---
print("Loading texture pipeline...")
conf = Hunyuan3DPaintConfig(max_num_view=6, resolution=512)
conf.realesrgan_ckpt_path = "hy3dpaint/ckpt/RealESRGAN_x4plus.pth"
conf.multiview_cfg_path = "hy3dpaint/cfgs/hunyuan-paint-pbr.yaml"
conf.custom_pipeline = "hy3dpaint/hunyuanpaintpbr"
tex_pipe = Hunyuan3DPaintPipeline(conf)

os.makedirs('output', exist_ok=True)

input_dir = 'input'
for f in sorted(glob.glob(f'{input_dir}/*')):
    name = os.path.splitext(os.path.basename(f))[0]
    print(f"\n{'='*50}")
    print(f"Processing: {name}")
    print(f"{'='*50}")

    # Load and convert to RGBA (rembg handles background removal)
    img = Image.open(f).convert('RGBA')

    # Step 1: Shape generation
    print(f"  [1/3] Generating shape...")
    mesh = shape_pipe(image=img)[0]
    obj_path = f'output/{name}_white.obj'
    mesh.export(obj_path)
    print(f"  -> {obj_path}")

    # Save the input image as PNG for texture pipeline
    img_path = f'output/{name}_input.png'
    img.save(img_path)

    # Step 2: Texture generation
    print(f"  [2/3] Generating texture...")
    textured_obj = f'output/{name}_textured.obj'
    tex_pipe(
        mesh_path=obj_path,
        image_path=img_path,
        output_mesh_path=textured_obj,
        save_glb=False
    )

    # Step 3: Convert to GLB with PBR materials
    print(f"  [3/3] Converting to GLB...")
    base = textured_obj.replace('.obj', '')
    textures = {}
    for tex_type, suffix in [('albedo', '.jpg'), ('metallic', '_metallic.jpg'), ('roughness', '_roughness.jpg')]:
        path = f'{base}{suffix}'
        if os.path.exists(path):
            textures[tex_type] = path

    glb_path = f'output/{name}.glb'
    if textures:
        create_glb_with_pbr_materials(textured_obj, textures, glb_path)
    else:
        # Fallback: export white mesh as GLB
        mesh.export(glb_path)

    print(f"  -> {glb_path}")

print(f"\n{'='*50}")
print("All done!")
print(f"{'='*50}")
for g in sorted(glob.glob('output/*.glb')):
    size_mb = os.path.getsize(g) / (1024 * 1024)
    print(f"  {g} ({size_mb:.1f} MB)")
