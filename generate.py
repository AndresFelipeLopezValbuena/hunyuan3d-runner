import sys
sys.path.insert(0, './hy3dshape')

from PIL import Image
from hy3dshape.pipelines import Hunyuan3DDiTFlowMatchingPipeline
import os, glob

pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained('tencent/Hunyuan3D-2.1')

# Generate from all images in input/ folder
os.makedirs('output', exist_ok=True)

input_dir = 'input'
if not os.path.exists(input_dir):
    # Use demo image as test
    print("No input/ folder found. Testing with demo image...")
    img = Image.open('assets/demo.png').convert('RGBA')
    mesh = pipe(image=img)[0]
    mesh.export('output/test.glb')
    print("Success! Exported to output/test.glb")
else:
    for f in sorted(glob.glob(f'{input_dir}/*')):
        name = os.path.splitext(os.path.basename(f))[0]
        print(f"Generating: {name}...")
        img = Image.open(f).convert('RGBA')
        mesh = pipe(image=img)[0]
        mesh.export(f'output/{name}.glb')
        print(f"  -> output/{name}.glb")

print("All done!")
