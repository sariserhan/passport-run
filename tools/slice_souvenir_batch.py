import csv
import sys
import os
from PIL import Image

import numpy as np
from scipy import ndimage

def key_cell(cell):
    arr = np.array(cell.convert('RGB')).astype(float)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    diff_rb = (r + b) / 2.0 - g
    
    # 1. Candidate magenta background (no white key, preserves subtle glass highlights)
    is_mag = (diff_rb > 80) & (r > 130) & (b > 130) & (g < 130)
    
    alpha = np.ones(diff_rb.shape, dtype=float) * 255.0
    alpha[is_mag & (diff_rb > 95)] = 0.0
    trans = is_mag & (diff_rb <= 95)
    alpha[trans] = np.clip(255.0 * (95.0 - diff_rb[trans]) / 15.0, 0, 255)
    
    # 2. Despill magenta excess on any pixel with residual magenta tint
    r_out = r.copy()
    b_out = b.copy()
    excess = np.minimum(r - g, b - g)
    apply_despill = (alpha > 0) & (excess > 10)
    r_out[apply_despill] = np.maximum(0, r[apply_despill] - excess[apply_despill] * 0.85)
    b_out[apply_despill] = np.maximum(0, b[apply_despill] - excess[apply_despill] * 0.85)
    
    result = np.zeros((arr.shape[0], arr.shape[1], 4), dtype=np.uint8)
    result[:, :, 0] = np.clip(r_out, 0, 255).astype(np.uint8)
    result[:, :, 1] = np.clip(g, 0, 255).astype(np.uint8)
    result[:, :, 2] = np.clip(b_out, 0, 255).astype(np.uint8)
    result[:, :, 3] = np.clip(alpha, 0, 255).astype(np.uint8)
    return Image.fromarray(result)

def slice_batch(batch_img_path, batch_index, csv_file='docs/souvenir-art-todo.csv'):
    if not os.path.exists(csv_file):
        csv_file = 'docs/souvenir-list.csv'
    with open(csv_file, 'r') as f:
        rows = list(csv.DictReader(f))
    
    batch_rows = rows[batch_index * 16 : (batch_index + 1) * 16]
    img = Image.open(batch_img_path).convert('RGB')
    w, h = img.size
    
    cols = 4
    cell_w = w / 4.0
    cell_h = h / 4.0
    
    out_dir = 'assets/realistic/souvenirs'
    os.makedirs(out_dir, exist_ok=True)
    
    processed = []
    for idx, r in enumerate(batch_rows):
        dest_id = r['id']
        # Do not overwrite Round-2 redone items when re-slicing Round-1 batches
        if batch_index < 12 and dest_id in ['GE', 'MOON', 'KY', 'HT', 'KM', 'KP']:
            print(f'Skipping {dest_id} (preserved from Round 2 redo)')
            continue

        row_idx = idx // cols
        col_idx = idx % cols
        
        left = int(col_idx * cell_w + 4)
        top = int(row_idx * cell_h + 4)
        right = int((col_idx + 1) * cell_w - 4)
        bottom = int((row_idx + 1) * cell_h - 4)
        
        cell = img.crop((left, top, right, bottom))
        keyed = key_cell(cell)
        arr = np.array(keyed)
        alpha = arr[:, :, 3]
        labels, count = ndimage.label(alpha > 10)
        if count > 1:
            sizes = ndimage.sum(np.ones_like(alpha), labels, range(1, count + 1))
            main = int(np.argmax(sizes)) + 1
            main_bot = np.where(labels == main)[0].max()
            
            # Remove disconnected bottom text (e.g. Dan text under LR, bottom captions)
            for index, box in enumerate(ndimage.find_objects(labels), start=1):
                if index == main:
                    continue
                if dest_id == 'LR' and box[0].start >= 195:
                    arr[labels == index, 3] = 0
                elif box[0].start >= 215 and box[0].start >= main_bot:
                    arr[labels == index, 3] = 0
                    
            # Remove disconnected top text for Moldova
            if dest_id == 'MD':
                for index, box in enumerate(ndimage.find_objects(labels), start=1):
                    if index != main and box[0].stop <= 35:
                        arr[labels == index, 3] = 0
                        
            # Remove isolated tiny sensor noise specks (size <= 5)
            for index, box in enumerate(ndimage.find_objects(labels), start=1):
                if index != main and sizes[index - 1] <= 5:
                    arr[labels == index, 3] = 0

        cleaned_keyed = Image.fromarray(arr)
        bbox = cleaned_keyed.getbbox()
        if bbox:
            obj = cleaned_keyed.crop(bbox)
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
        print('Usage: python3 slice_souvenir_batch.py <image_path> <batch_index_0_based> [csv_path]')
        sys.exit(1)
    csv_arg = sys.argv[3] if len(sys.argv) > 3 else 'docs/souvenir-art-todo.csv'
    slice_batch(sys.argv[1], int(sys.argv[2]), csv_arg)
