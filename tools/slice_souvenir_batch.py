import csv
import sys
import os
from PIL import Image

def slice_batch(batch_img_path, batch_index):
    with open('docs/souvenir-list.csv', 'r') as f:
        rows = list(csv.DictReader(f))
    
    batch_rows = rows[batch_index * 16 : (batch_index + 1) * 16]
    img = Image.open(batch_img_path).convert('RGBA')
    w, h = img.size
    
    # Usually 4x4 grid
    cols = 4
    rows_count = 4 if len(batch_rows) > 12 else (3 if len(batch_rows) > 8 else 2)
    cell_w = w / 4.0
    cell_h = h / 4.0
    
    out_dir = 'assets/realistic/souvenirs'
    os.makedirs(out_dir, exist_ok=True)
    
    processed = []
    for idx, r in enumerate(batch_rows):
        dest_id = r['id']
        row_idx = idx // cols
        col_idx = idx % cols
        
        left = int(col_idx * cell_w + 5)
        top = int(row_idx * cell_h + 5)
        right = int((col_idx + 1) * cell_w - 5)
        bottom = int((row_idx + 1) * cell_h - 5)
        
        cell = img.crop((left, top, right, bottom))
        cw, ch = cell.size
        raw = bytearray(cell.tobytes())
        
        for i in range(0, len(raw), 4):
            x = (i // 4) % cw
            y = (i // 4) // cw
            
            # Mask out any bottom label text area (bottom 40px)
            if y > ch - 40:
                raw[i+3] = 0
                continue
                
            r_c, g_c, b_c = raw[i], raw[i+1], raw[i+2]
            diff_rb = (r_c + b_c) / 2.0 - g_c
            
            # White or near-white grid line
            if r_c > 225 and g_c > 225 and b_c > 225:
                raw[i+3] = 0
                continue
                
            # Magenta key
            if diff_rb > 65 and r_c > 130 and b_c > 130 and g_c < 130:
                if diff_rb > 85:
                    raw[i+3] = 0
                else:
                    raw[i+3] = int(255 * (85 - diff_rb) / 20.0)
                    
            # Despill
            excess = min(r_c - g_c, b_c - g_c)
            if excess > 10:
                raw[i] = max(0, r_c - int(excess * 0.8))
                raw[i+2] = max(0, b_c - int(excess * 0.8))
                
        keyed = Image.frombytes('RGBA', (cw, ch), bytes(raw))
        bbox = keyed.getbbox()
        if bbox:
            obj = keyed.crop(bbox)
            ow, oh = obj.size
            scale = 410.0 / max(ow, oh)
            nw, nh = int(round(ow * scale)), int(round(oh * scale))
            obj_res = obj.resize((nw, nh), Image.LANCZOS)
            
            canvas = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
            px = (512 - nw) // 2
            py = (512 - nh) // 2
            canvas.paste(obj_res, (px, py), obj_res)
            out_path = os.path.join(out_dir, f'{dest_id}.png')
            canvas.save(out_path)
            processed.append(dest_id)
        else:
            print(f'Warning: empty bbox for {dest_id}')
            
    print(f'Batch {batch_index+1}: Processed {len(processed)} items -> {processed}')

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: python3 slice_souvenir_batch.py <image_path> <batch_index_0_based>')
        sys.exit(1)
    slice_batch(sys.argv[1], int(sys.argv[2]))
