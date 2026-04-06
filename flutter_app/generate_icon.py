"""
Generates the SalamaRecover launcher icon (1024x1024 PNG).
Run once: python generate_icon.py
Requires: pip install pillow
"""
from PIL import Image, ImageDraw
import math, os

SIZE = 1024
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Blue gradient circle background (simulate with solid + lighter overlay)
draw.ellipse([0, 0, SIZE, SIZE], fill='#0077B6')

# Slightly lighter arc at top-left for depth
for r in range(60):
    alpha = int(60 * (1 - r / 60))
    draw.ellipse([r, r, SIZE // 2 + 80 - r, SIZE // 2 + 80 - r],
                 outline=(255, 255, 255, alpha), width=1)

# White heart outline
cx, cy = SIZE // 2, SIZE // 2 + 30
heart_scale = 3.2
pts = []
for angle in range(0, 360):
    t = math.radians(angle)
    x = heart_scale * 16 * (math.sin(t) ** 3)
    y = -heart_scale * (13 * math.cos(t) - 5 * math.cos(2*t)
                        - 2 * math.cos(3*t) - math.cos(4*t))
    pts.append((cx + x, cy + y))

draw.polygon(pts, fill='white')

# Blue medical cross over the heart
cross_color = '#0077B6'
bar_w = 80
bar_h = 260
draw.rectangle([cx - bar_w//2, cy - bar_h//2, cx + bar_w//2, cy + bar_h//2],
               fill=cross_color)
draw.rectangle([cx - bar_h//2, cy - bar_w//2, cx + bar_h//2, cy + bar_w//2],
               fill=cross_color)

# Green accent dot bottom-right
draw.ellipse([SIZE - 220, SIZE - 220, SIZE - 80, SIZE - 80], fill='#00B37E')

out = os.path.join('assets', 'icons', 'launcher_icon.png')
img.save(out)
print(f'Icon saved to {out}')
