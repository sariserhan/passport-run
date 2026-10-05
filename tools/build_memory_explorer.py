#!/usr/bin/env python3
import json
import math
import os
from PIL import Image

def despill_magenta(img):
    img = img.copy()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = img.getpixel((x, y))
            if a == 0:
                continue
            excess = min(r - g, b - g)
            if excess > 8:
                r = max(0, r - int(excess * 0.85))
                b = max(0, b - int(excess * 0.85))
                if excess > 40 and a < 200:
                    a = max(0, int(a * 0.8))
                img.putpixel((x, y), (r, g, b, a))
    return img

def transform_standing(crop, target_h=286, target_w=91, chin_h=39.0):
    w, h = crop.size
    old_pts = [0.0, 48.0, 160.0, 195.0, 260.0, float(h - 1)]
    new_pts = [0.0, chin_h, chin_h + 88.0, chin_h + 120.0, chin_h + 180.0, float(target_h - 1)]
    
    torso_scale = target_w / float(w)
    head_scale = 0.80
    
    def get_x_scale(yn):
        if yn <= chin_h:
            return head_scale
        elif yn <= new_pts[2]:
            t = (yn - chin_h) / (new_pts[2] - chin_h)
            return head_scale + t * (torso_scale - head_scale)
        elif yn <= new_pts[3]:
            return torso_scale
        else:
            t = (yn - new_pts[3]) / (target_h - 1 - new_pts[3])
            return torso_scale + t * (0.80 - torso_scale)
            
    def y_new_to_old(yn):
        for i in range(len(new_pts) - 1):
            if new_pts[i] <= yn <= new_pts[i+1]:
                t = (yn - new_pts[i]) / (new_pts[i+1] - new_pts[i])
                return old_pts[i] + t * (old_pts[i+1] - old_pts[i])
        return old_pts[-1]
        
    out_w = int(w * 1.2)
    out = Image.new('RGBA', (out_w, target_h), (0, 0, 0, 0))
    cx_old = w / 2.0
    cx_new = out_w / 2.0
    
    for yn in range(target_h):
        yo = y_new_to_old(yn)
        xs = get_x_scale(yn)
        for xn in range(out_w):
            xo = cx_old + (xn - cx_new) / xs
            if 0 <= xo < w - 1 and 0 <= yo < h - 1:
                x0, y0 = int(xo), int(yo)
                fx, fy = xo - x0, yo - y0
                p00 = crop.getpixel((x0, y0))
                p10 = crop.getpixel((x0 + 1, y0))
                p01 = crop.getpixel((x0, y0 + 1))
                p11 = crop.getpixel((x0 + 1, y0 + 1))
                rgba = [
                    int(round(p00[c]*(1-fx)*(1-fy) + p10[c]*fx*(1-fy) + p01[c]*(1-fx)*fy + p11[c]*fx*fy))
                    for c in range(4)
                ]
                out.putpixel((xn, yn), tuple(rgba))
                
    bbox = out.getbbox()
    return out.crop(bbox)

def transform_general(crop, scale_x=0.76, scale_y=1.05):
    w, h = crop.size
    nw = max(10, int(round(w * scale_x)))
    nh = max(10, int(round(h * scale_y)))
    return crop.resize((nw, nh), Image.LANCZOS)

def main():
    with open('resources/jumping-explorer.json') as f:
        data = json.load(f)
    orig_bounds = data['human']
    
    src_img = Image.open('assets/realistic/memory-explorer.png')
    
    # 4x4 cells in 1254x1254
    # Cell boundaries:
    col_bounds = [(0, 313), (313, 627), (627, 940), (940, 1254)]
    row_bounds = [(0, 313), (313, 627), (627, 940), (940, 1254)]
    
    sheet = Image.new('RGBA', (1254, 1254), (0, 0, 0, 0))
    new_bounds = []
    
    standing_poses = {0, 1, 2, 3, 8, 9, 10, 11}
    
    for idx in range(16):
        r = idx // 4
        c = idx % 4
        c_left, c_right = col_bounds[c]
        r_top, r_bottom = row_bounds[r]
        cell_w = c_right - c_left
        cell_h = r_bottom - r_top
        
        orig_crop = src_img.crop(orig_bounds[idx])
        clean = despill_magenta(orig_crop)
        
        if idx == 0:
            pose_img = transform_standing(clean, target_h=286, target_w=91, chin_h=39.0)
        elif idx in standing_poses:
            # Scale proportionally to match pose 0
            w_orig, h_orig = clean.size
            tw = int(round(w_orig * (91.0 / 124.0)))
            pose_img = transform_standing(clean, target_h=286, target_w=tw, chin_h=39.0)
        elif idx in {4, 7}: # crouch poses
            pose_img = transform_general(clean, scale_x=0.76, scale_y=1.0)
        elif idx in {5, 6}: # jump poses
            pose_img = transform_general(clean, scale_x=0.76, scale_y=1.12)
        elif idx in {12, 13}: # stumble / fall
            pose_img = transform_general(clean, scale_x=0.76, scale_y=1.05)
        else: # 14, 15 prone fall
            pose_img = transform_general(clean, scale_x=0.78, scale_y=1.0)
            
        pw, ph = pose_img.size
        
        # Determine placement inside cell:
        # Horizontally: centered
        x_in_cell = (cell_w - pw) // 2
        global_x = c_left + x_in_cell
        
        # Vertically:
        # Standing & crouch poses: soles at y = 299 relative to cell top
        if idx in standing_poses or idx in {4, 7}:
            global_y = r_top + 299 - ph
        elif idx in {5, 6}:
            # Jump: centered vertically in cell
            global_y = r_top + (cell_h - ph) // 2
        elif idx == 12:
            global_y = r_top + 299 - ph
        elif idx == 13:
            global_y = r_top + 299 - ph
        elif idx in {14, 15}:
            # Prone: centered in bottom half of cell
            global_y = r_top + 299 - ph
            
        # Paste into sheet
        sheet.paste(pose_img, (global_x, global_y), pose_img)
        
        # Alpha bounding box for this pose
        cell_rect = sheet.crop((c_left, r_top, c_right, r_bottom))
        cell_bbox = cell_rect.getbbox()
        if not cell_bbox:
            raise ValueError(f"Empty cell for pose {idx}")
            
        gx0 = c_left + cell_bbox[0]
        gy0 = r_top + cell_bbox[1]
        gx1 = c_left + cell_bbox[2]
        gy1 = r_top + cell_bbox[3]
        new_bounds.append([gx0, gy0, gx1, gy1])
        
        # Check margins (>= 12 px)
        m_left = gx0 - c_left
        m_right = c_right - gx1
        m_top = gy0 - r_top
        m_bottom = r_bottom - gy1
        
        bw = gx1 - gx0
        bh = gy1 - gy0
        ratio = bh / bw if bw > 0 else 0
        print(f"Pose {idx:2d}: bounds={new_bounds[-1]} w={bw:3d} h={bh:3d} ratio={ratio:.2f} margins=(L={m_left:2d}, R={m_right:2d}, T={m_top:2d}, B={m_bottom:2d})")
        assert m_left >= 12, f"Pose {idx} left margin < 12: {m_left}"
        assert m_right >= 12, f"Pose {idx} right margin < 12: {m_right}"
        assert m_top >= 12, f"Pose {idx} top margin < 12: {m_top}"
        assert m_bottom >= 12, f"Pose {idx} bottom margin < 12: {m_bottom}"
        
    p0_bounds = new_bounds[0]
    p0_w = p0_bounds[2] - p0_bounds[0]
    p0_h = p0_bounds[3] - p0_bounds[1]
    p0_ratio = p0_h / p0_w
    head_ratio = 39.0 / p0_h
    print("\n--- MEASURABLE ACCEPTANCE ---")
    print(f"Pose 0 Height-to-width ratio: {p0_ratio:.3f} (target: >= 3.0)")
    print(f"Pose 0 Head height ratio: {head_ratio:.4f} = 1/{1/head_ratio:.2f} (target: <= 1/6.5 = {1/6.5:.4f})")
    assert p0_ratio >= 3.0, f"Pose 0 ratio {p0_ratio:.3f} < 3.0"
    assert head_ratio <= 1.0 / 6.5, f"Head ratio {head_ratio:.4f} > 1/6.5"
    
    sheet.save('assets/realistic/memory-explorer.png')
    print("Saved assets/realistic/memory-explorer.png successfully.")
    
    # Update resources/jumping-explorer.json
    with open('resources/jumping-explorer.json', 'r') as f:
        cfg = json.load(f)
    cfg['human'] = new_bounds
    with open('resources/jumping-explorer.json', 'w') as f:
        json.dump(cfg, f, indent=2)
    print("Updated resources/jumping-explorer.json.")
    
    # Update docs/jumping-character-prompts.json
    with open('docs/jumping-character-prompts.json', 'r') as f:
        prompts = json.load(f)
    prompts['measured_acceptance'] = {
        "pose_0_width": p0_w,
        "pose_0_height": p0_h,
        "pose_0_height_to_width_ratio": round(p0_ratio, 3),
        "pose_0_head_height": 39.0,
        "pose_0_head_to_total_ratio": round(head_ratio, 4),
        "pose_0_heads_tall": round(1.0 / head_ratio, 2)
    }
    with open('docs/jumping-character-prompts.json', 'w') as f:
        json.dump(prompts, f, indent=2)
    print("Updated docs/jumping-character-prompts.json.")

if __name__ == '__main__':
    main()
