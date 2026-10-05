#!/usr/bin/env python3
import csv
import json

def get_batches():
    with open('docs/souvenir-art-todo.csv', 'r') as f:
        rows = list(csv.DictReader(f))
    
    batches = []
    for b in range(6):
        batch_rows = rows[b * 16 : (b + 1) * 16]
        ids = [r['id'] for r in batch_rows]
        prompt_items = []
        for i, r in enumerate(batch_rows):
            desc = r['prompt_description'].strip('"')
            prompt_items.append(f"{i+1}. {desc}")
            
        full_prompt = (
            "A 4x4 grid of sixteen separate travel souvenir objects, each photographed as a realistic studio product photo: "
            "soft even lighting, slight three-quarter front view, natural materials and textures, true-to-life colors, "
            "no hands, no people, no text, no labels, no price tags. Each object is centered in its own equal square cell, "
            "fully visible with generous empty margin, all objects a similar size within their cells. The ENTIRE background "
            "of the whole image, behind and between every object, is flat solid pure magenta (#FF00FF) with no gradients, "
            "no shadows on the background, no reflections, no floor, no grid lines. Absolutely no words, labels, letters, or subtitles. "
            "Order, left to right, top to bottom: " + "; ".join(prompt_items) + "."
        )
        batches.append({
            "batch_index": b,
            "ids": ids,
            "prompt": full_prompt
        })
    return batches

if __name__ == '__main__':
    batches = get_batches()
    for b in batches:
        print(f"=== BATCH {b['batch_index'] + 1} ({len(b['ids'])} items) ===")
        print(f"IDs: {', '.join(b['ids'])}")
        print(f"Prompt Length: {len(b['prompt'])} chars")
        print(f"Prompt snippet: {b['prompt'][:180]}...")
        print()
