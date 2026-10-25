"""Read sprite alpha to generate frame/foot-anchor metadata; never modifies PNG art."""
import json
import statistics
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent
specs = {
    'mage-right': ('mage-animation-v1.png', [0, 280, 520, 770, 1024], 210),
    'rogue-right': ('rogue-animation-v1.png', [0, 280, 520, 770, 1024], 210),
    'knight-right': ('knight-animation-v1.png', [0, 295, 590, 920, 1199], 275),
    'knight-left': ('knight-left-animation-v1.png', None, 255),
    'knight-strike': ('knight-left-strike-v1.png', None, None),
    'mage-between': ('mage-walk-between-v1.png', None, 210),
    'rogue-between': ('rogue-walk-between-v1.png', None, 210),
    'knight-between': ('knight-walk-between-v1.png', None, 275),
    'knight-leftbetween': ('knight-left-walk-between-v1.png', None, 255),
}
result = {}
def main_component_box(mask):
    """Find the body component so a neighboring cape sliver cannot enter the frame."""
    width, height = mask.size
    data = list(mask.tobytes())
    seen = set()
    best = (0, None)
    for start, value in enumerate(data):
        if not value or start in seen:
            continue
        stack = [start]
        seen.add(start)
        count = 0
        left = top = 10**9
        right = bottom = 0
        while stack:
            at = stack.pop()
            x, y = at % width, at // width
            count += 1
            left, top = min(left, x), min(top, y)
            right, bottom = max(right, x + 1), max(bottom, y + 1)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    nxt = ny * width + nx
                    if 0 <= nx < width and 0 <= ny < height and data[nxt] and nxt not in seen:
                        seen.add(nxt)
                        stack.append(nxt)
        if count > best[0]:
            best = (count, (left, top, right, bottom))
    return best[1]

for key, (filename, bands, body_height) in specs.items():
    im = Image.open(root / 'assets' / filename).convert('RGBA')
    cols = 1 if key == 'knight-strike' else 4
    rows = 1 if key == 'knight-strike' else 2 if 'between' in key else 4
    if bands is None:
        bands = [round(i * im.height / rows) for i in range(rows + 1)]
    assert bands[-1] == im.height, (filename, im.size)
    frames = []
    for frame in range(cols * rows):
        col, row = frame % cols, frame // cols
        x, ex = round(col * im.width / cols), round((col + 1) * im.width / cols)
        y, ey = bands[row], bands[row + 1]
        alpha = im.crop((x, y, ex, ey)).getchannel('A')
        mask = alpha.point(lambda a: 255 if a > 150 else 0)
        bbox = mask.getbbox()
        assert bbox, (filename, frame)
        if body_height is None:
            body_height = bbox[3] - bbox[1]
        bottom = bbox[3]
        # Median pixels near the boots stabilize body location without centering on weapon arcs.
        points = []
        for py in range(max(0, bottom - 28), bottom):
            for px in range(ex - x):
                if mask.getpixel((px, py)):
                    points.append(px)
        points.sort()
        trim = (0, 0, ex-x, ey-y)
        if key == 'knight-left':
            component = main_component_box(mask)
            trim = (max(0, component[0]-2), max(0, component[1]-2), min(ex-x, component[2]+2), min(ey-y, component[3]+2))
        frames.append(dict(x=x+trim[0], y=y+trim[1], w=trim[2]-trim[0], h=trim[3]-trim[1], anchorX=points[len(points)//2]-trim[0], anchorY=bottom-trim[1]))
    if 'between' in key:
        reference_key = key.replace('-leftbetween', '-left').replace('-between', '-right')
        reference_image = Image.open(root / 'assets' / specs[reference_key][0]).convert('RGBA')
        def occupied_height(image, frame):
            bounds = image.crop((frame['x'], frame['y'], frame['x']+frame['w'], frame['y']+frame['h'])).getchannel('A').point(lambda a: 255 if a > 150 else 0).getbbox()
            return bounds[3]-bounds[1]
        old_height = statistics.median(occupied_height(reference_image, f) for f in result[reference_key]['frames'][:8])
        new_height = statistics.median(occupied_height(im, f) for f in frames)
        body_height *= new_height / old_height
    # Keep the torso root fixed during gait instead of re-centering each planted boot.
    if rows >= 2:
        root_x = round(statistics.median(f['x'] - round((i % cols) * im.width / cols) + f['anchorX'] for i, f in enumerate(frames[:8])))
        for i in range(8):
            frames[i]['anchorX'] = root_x - (frames[i]['x'] - round((i % cols) * im.width / cols))
    # Deliberate anticipation/follow-through holds avoid a generated hand-swap pose
    # and a neighboring slash fragment; all actions still have eight timed frames.
    if key == 'knight-right':
        frames[13] = dict(frames[12])
    if key == 'knight-left':
        frames[10] = dict(frames[9])
        frames[13] = dict(frames[14])
    if key == 'knight-strike':
        # This separately authored impact has a much wider stance. Its rear boot
        # dominates the bottom-pixel median, shifting the whole body forward.
        # Register to the pelvis/stance root and match the surrounding sheet's
        # helmet scale, rather than sizing from the crouched silhouette height.
        body_height = 850
        frames[0]['anchorX'] = 800
    result[key] = dict(bodyHeight=body_height, frames=frames)
(root / 'assets' / 'hero-frames-v1.json').write_text(json.dumps(result, indent=2) + '\n')
print('Prepared foot anchors for', len(result), 'directional sheets')
