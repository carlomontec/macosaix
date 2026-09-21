import os
import struct
import subprocess
import math

def create_bmp(filename, width, height, generator_fn):
    # BMP 24-bit uncompressed
    row_bytes = (width * 3 + 3) & ~3
    image_size = row_bytes * height
    file_size = 54 + image_size
    
    header = struct.pack(
        '<2sIHHI' 'IIIHHIIIIII',
        b'BM', file_size, 0, 0, 54,
        40, width, height, 1, 24, 0, image_size, 2835, 2835, 0, 0
    )
    
    with open(filename, 'wb') as f:
        f.write(header)
        for y in range(height): # BMP stores bottom to top
            row = bytearray()
            for x in range(width):
                r, g, b = generator_fn(x, y, width, height)
                row.extend([int(b), int(g), int(r)]) # BGR order
            # Padding
            padding = row_bytes - (width * 3)
            row.extend(b'\x00' * padding)
            f.write(row)

def main():
    test_dir = os.path.join(os.path.dirname(__file__), 'data')
    sources_dir = os.path.join(test_dir, 'sources')
    os.makedirs(sources_dir, exist_ok=True)
    
    # 1. Target image: colorful radial gradient with quadrants
    target_bmp = os.path.join(test_dir, 'target.bmp')
    def target_gen(x, y, w, h):
        cx, cy = w / 2.0, h / 2.0
        dx = (x - cx) / cx
        dy = (y - cy) / cy
        dist = math.sqrt(dx*dx + dy*dy)
        angle = math.atan2(dy, dx)
        r = (math.sin(angle) * 0.5 + 0.5) * 255
        g = (math.cos(angle) * 0.5 + 0.5) * 255
        b = (math.sin(dist * math.pi * 2) * 0.5 + 0.5) * 255
        return (min(255, max(0, r)), min(255, max(0, g)), min(255, max(0, b)))
        
    create_bmp(target_bmp, 600, 400, target_gen)
    target_png = os.path.join(test_dir, 'target.png')
    subprocess.run(['sips', '-s', 'format', 'png', target_bmp, '--out', target_png], check=True, stdout=subprocess.DEVNULL)
    os.remove(target_bmp)
    print(f"Generated target image: {target_png}")
    
    # 2. Generate 120 source images with various solid/pattern colors
    colors = []
    # Palette across hue spectrum
    for h_idx in range(24):
        hue = h_idx / 24.0 * 2.0 * math.pi
        r = int((math.sin(hue) * 0.5 + 0.5) * 255)
        g = int((math.sin(hue + 2.0*math.pi/3.0) * 0.5 + 0.5) * 255)
        b = int((math.sin(hue + 4.0*math.pi/3.0) * 0.5 + 0.5) * 255)
        colors.append((r, g, b))
    
    # Shades of gray / black / white
    for shade in [10, 40, 80, 128, 180, 220, 250]:
        colors.append((shade, shade, shade))
        
    idx = 0
    for r, g, b in colors:
        for variation in range(4):
            vr = min(255, max(0, r + (variation - 2) * 25))
            vg = min(255, max(0, g + (variation - 2) * 25))
            vb = min(255, max(0, b + (variation - 2) * 25))
            
            def tile_gen(x, y, w, h, cr=vr, cg=vg, cb=vb, v=variation):
                # add some texture
                tex = (x % (v + 3)) * 5
                return (min(255, cr + tex), min(255, cg + tex), min(255, cb + tex))
            
            bmp_path = os.path.join(sources_dir, f"tile_{idx:03d}.bmp")
            create_bmp(bmp_path, 120, 120, tile_gen)
            
            # Alternate between PNG, JPEG, and HEIC!
            if idx % 3 == 0:
                out_path = os.path.join(sources_dir, f"tile_{idx:03d}.heic")
                subprocess.run(['sips', '-s', 'format', 'heic', bmp_path, '--out', out_path], check=True, stdout=subprocess.DEVNULL)
            elif idx % 3 == 1:
                out_path = os.path.join(sources_dir, f"tile_{idx:03d}.jpg")
                subprocess.run(['sips', '-s', 'format', 'jpeg', bmp_path, '--out', out_path], check=True, stdout=subprocess.DEVNULL)
            else:
                out_path = os.path.join(sources_dir, f"tile_{idx:03d}.png")
                subprocess.run(['sips', '-s', 'format', 'png', bmp_path, '--out', out_path], check=True, stdout=subprocess.DEVNULL)
                
            os.remove(bmp_path)
            idx += 1
            
    print(f"Generated {idx} test source images in {sources_dir} (mix of HEIC, JPEG, PNG).")

if __name__ == '__main__':
    main()
