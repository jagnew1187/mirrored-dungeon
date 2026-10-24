"""Measure new Knight atlas frames; source pixels remain untouched."""
import json
import statistics
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent
result = {}
for kind, spec in json.loads((root / 'assets' / 'knight-art.json').read_text()).items():
    cols, rows, filename = spec['cols'], spec['rows'], spec['file']
    image = Image.open(root / 'assets' / filename).convert('RGBA')
    whole_mask = image.getchannel('A').point(lambda a: 255 if a > 150 else 0)
    frames, heights = [], []
    for i in range(rows * cols):
        x, ex = round(i % cols * image.width / cols), round((i % cols + 1) * image.width / cols)
        y, ey = round(i // cols * image.height / rows), round((i // cols + 1) * image.height / rows)
        alpha = image.crop((x, y, ex, ey)).getchannel('A').point(lambda a: 255 if a > 150 else 0)
        box = alpha.getbbox()
        assert box, (kind, i)
        heights.append(box[3] - box[1])
        # Register at the helmet, rather than a boot that changes each step.
        head = alpha.crop((0, box[1], ex-x, box[1] + max(3, round(heights[-1] * .17)))).getbbox()
        center = (head[0] + head[2]) / 2
        # Some generated blades cross an evenly divided cell boundary. Follow
        # the connected character from its helmet, storing bounds rather than
        # editing pixels or sampling an adjacent character's cape.
        head_y = box[1] + max(1, round(heights[-1] * .06))
        candidates = [px for px in range(ex-x) if alpha.getpixel((px, head_y))]
        seed_x = min(candidates, key=lambda px: abs(px-center))
        component = whole_mask.copy()
        ImageDraw.floodfill(component, (x+seed_x, y+head_y), 128)
        bounds = component.point(lambda a: 255 if a == 128 else 0).getbbox()
        assert bounds, (kind, i)
        padding = 2
        if bounds[2]-bounds[0] >= image.width/3:
            # Touching cape outlines must not merge adjacent sprites. Keep
            # their shared cell boundary as a hard sampling limit in this case.
            local_component = alpha.copy()
            ImageDraw.floodfill(local_component, (seed_x, head_y), 128)
            local = local_component.point(lambda a: 255 if a == 128 else 0).getbbox()
            bounds = (x+local[0], y+local[1], x+local[2], y+local[3])
            padding = 0
        left, top = max(0, bounds[0]-padding), max(0, bounds[1]-padding)
        right, bottom = min(image.width, bounds[2]+padding), min(image.height, bounds[3]+padding)
        frames.append(dict(x=left, y=top, w=right-left, h=bottom-top, anchorX=x+center-left, anchorY=bounds[3]-top))
    result[kind] = dict(bodyHeight=statistics.median(heights), frames=frames)
    if 'idleFrame' in spec:
        result[kind]['idleFrame'] = spec['idleFrame']
(root / 'assets' / 'knight-gait-v2.json').write_text(json.dumps(result, indent=2) + '\n')
print('Prepared Knight directional gait and standing frame metadata')
