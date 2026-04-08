from PIL import Image, ImageDraw
from pathlib import Path
base = Path('/var/minis/workspace/minesweeper-ipa/Resources/Assets.xcassets/LaunchLogo.imageset')
base.mkdir(parents=True, exist_ok=True)
size = 512
img = Image.new('RGBA', (size, size), (0,0,0,0))
d = ImageDraw.Draw(img)
for i in range(120, 0, -1):
    alpha = int(1.8 * i)
    r = 180 - i
    d.ellipse([r, r, size-r, size-r], fill=(80,170,255, min(alpha,120)))
card = [96,96,416,416]
d.rounded_rectangle(card, radius=92, fill=(255,255,255,235))
cell=88
gap=14
sx=120
sy=120
for rr in range(3):
    for cc in range(3):
        x0=sx+cc*(cell+gap)
        y0=sy+rr*(cell+gap)
        x1=x0+cell
        y1=y0+cell
        fill=(232,240,255,255)
        if (rr,cc)==(1,1):
            fill=(255,110,110,255)
        d.rounded_rectangle([x0,y0,x1,y1], radius=20, fill=fill)
px=sx+2*(cell+gap)+28
py=sy+18
d.rounded_rectangle([px,py,px+6,py+54], radius=3, fill=(255,149,0,255))
d.polygon([(px+6,py+4),(px+44,py+18),(px+6,py+31)], fill=(255,149,0,255))
img.save(base/'launch-logo.png')
print('launch logo generated')
