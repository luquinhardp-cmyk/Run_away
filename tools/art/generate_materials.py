"""Deterministic, tileable PBR authoring. Requires NumPy; no downloaded imagery."""
from pathlib import Path
import json, math, struct, zlib
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/textures/pbr"
OUT.mkdir(parents=True, exist_ok=True)
SIZE = 512
rng = np.random.default_rng(197804)
Y, X = np.mgrid[0:SIZE, 0:SIZE] / SIZE

def png(path, pixels):
    pixels = np.clip(pixels, 0, 255).astype(np.uint8)
    height, width, channels = pixels.shape
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
    raw = b''.join(b'\0' + row.tobytes() for row in pixels)
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2 if channels == 3 else 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 8)) + chunk(b'IEND', b''))

def noise(cells):
    grid = rng.random((cells, cells))
    gx, gy = X * cells, Y * cells
    ix, iy = gx.astype(int), gy.astype(int)
    tx, ty = gx - ix, gy - iy
    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
    a = grid[iy % cells, ix % cells] * (1 - tx) + grid[iy % cells, (ix + 1) % cells] * tx
    b = grid[(iy + 1) % cells, ix % cells] * (1 - tx) + grid[(iy + 1) % cells, (ix + 1) % cells] * tx
    return a * (1 - ty) + b * ty

def crack_field():
    nearest = np.full((SIZE, SIZE), 10.0)
    second = nearest.copy()
    for px, py in rng.random((27, 2)):
        dx = np.minimum(abs(X-px), 1-abs(X-px)); dy = np.minimum(abs(Y-py), 1-abs(Y-py))
        distance = np.sqrt(dx*dx + dy*dy)
        second = np.minimum(second, np.maximum(nearest, distance))
        nearest = np.minimum(nearest, distance)
    return np.exp(-(second-nearest)*450)

specs = [
    ('aged_concrete', (101, 103, 93), 0.9, 'concrete'),
    ('damp_concrete', (76, 81, 70), 0.63, 'wet'),
    ('cracked_floor', (84, 81, 69), 0.86, 'floor'),
    ('peeling_plaster', (126, 122, 99), 0.94, 'plaster'),
    ('rusted_iron', (93, 73, 54), 0.72, 'rust'),
    ('rotten_wood', (77, 59, 42), 0.92, 'wood'),
    ('mud_leaves', (63, 57, 39), 0.82, 'soil'),
    ('torn_fabric', (90, 83, 63), 0.97, 'cloth'),
    ('organic_residue', (77, 49, 37), 0.6, 'organic'),
    ('creature_skin', (110, 103, 88), 0.72, 'skin'),
]
manifest = []
swatches = []
for name, base, rough, kind in specs:
    broad, mid, fine = noise(5), noise(24), noise(105)
    pores = noise(190)
    cracks = crack_field()
    h = broad * .15 + mid * .12 + fine * .08
    stain = np.clip((broad - .45) * 3, 0, 1)
    color = np.array(base)[None, None, :] * (0.75 + mid[..., None] * .35 + fine[..., None] * .16)
    color = np.broadcast_to(color, (SIZE, SIZE, 3)).copy()
    metal = np.zeros((SIZE, SIZE))
    wet = np.zeros((SIZE, SIZE))
    if kind in ('concrete', 'wet', 'floor', 'plaster'):
        # Broken, sparse hairlines instead of a continuous stone/Voronoi pattern.
        cracks *= np.clip((noise(7)-.42)*3, 0, 1)
        h -= cracks * (.09 if kind != 'floor' else .15)
        color *= (1 - cracks[..., None] * (.25 if kind != 'floor' else .38))
        if kind == 'plaster':
            peel = np.clip((mid - .53) * 14, 0, 1)
            color = color * (1 - peel[..., None] * .65) + np.array([53, 49, 38]) * peel[..., None] * .65
            h += (1-peel)*.09
        streaks = (np.sin(2*math.pi*(X*13 + noise(3)*.15))*.5+.5)**16 * stain
        color *= 1 - streaks[..., None]*.4
        wet = stain * (.8 if kind == 'wet' else .15)
    elif kind == 'rust':
        rust = np.clip((mid - .34) * 3.4, 0, 1)
        color = np.array([72, 78, 72]) * (1-rust[..., None]) + np.array([113, 62, 35]) * rust[..., None]
        color *= .65 + fine[..., None] * .7
        h = rust*.12 + pores*.06
        metal = (1-rust)*.85
        # Seamless fastener grid, dark oxidation halos.
        dx = np.minimum(X % .5, .5-X % .5); dy = np.minimum(Y % .5, .5-Y % .5)
        bolt = np.exp(-(dx*dx+dy*dy)/.00007)
        h += bolt*.15; color *= 1-bolt[...,None]*.45
    elif kind == 'wood':
        grain = np.sin(2*math.pi*(X*65 + noise(6)*2 + np.sin(2*math.pi*Y)*.35))
        seam = np.exp(-np.sin(X*math.pi*5)**2*900)
        h = grain*.04 + fine*.025 - seam*.18
        color *= .8 + grain[...,None]*.18 + mid[...,None]*.25
        color *= 1-seam[...,None]*.7
    elif kind == 'soil':
        leaves = (fine > .72).astype(float) * np.clip((mid-.35)*2,0,1)
        color += leaves[...,None] * np.array([28,18,3])
        h += leaves*.09; wet = stain*.45
    elif kind == 'cloth':
        weave = np.sin(X*2*math.pi*128)*np.sin(Y*2*math.pi*128)
        h = weave*.015 + broad*.1
        color *= 1 - cracks[...,None]*.22
    else:
        folds = np.sin(2*math.pi*(X*8 + broad))**8
        veins = np.exp(-(mid-.5)**2*1600)
        h = fine*.05 + pores*.018 + folds*.06 - cracks*.09
        color *= .85 + fine[...,None]*.3
        color = color*(1-veins[...,None]*.16) + np.array([48,25,20])*veins[...,None]*.16
        color *= 1-stain[...,None]*.22
        wet = np.clip((mid-.6)*4,0,.55)
    ao = np.clip(1-cracks*.3-(1-fine)*.12, .35, 1)
    roughness = np.clip(rough + (fine-.5)*.15 - wet*.38, .26, .98)
    orm = np.stack([ao, roughness, metal], axis=2)*255
    dx = (np.roll(h,-1,1)-np.roll(h,1,1))*7
    dy = (np.roll(h,-1,0)-np.roll(h,1,0))*7
    normal = np.stack([-dx, dy, np.ones_like(h)],axis=2)
    normal /= np.linalg.norm(normal,axis=2)[...,None]
    normal = (normal*.5+.5)*255
    images = {'albedo': color, 'normal': normal, 'orm': orm}
    for suffix, image in images.items():
        png(OUT / f'{name}_{suffix}.png', image)
        low = image.reshape(256,2,256,2,3).mean((1,3))
        png(OUT / f'{name}_{suffix}_low.png', low)
    swatches.append(np.clip(color[::4,::4],0,255).astype(np.uint8))
    manifest.append({'name':name,'size':512,'low_size':256,'maps':['albedo','normal','orm'],'orm_channels':{'R':'AO','G':'roughness','B':'metallic'},'tileable':True,'seed':197804,'source':'tools/art/generate_materials.py','origin':'original procedural authoring; no third-party source pixels'})
    print('PBR', name)
png(OUT / 'contact_sheet.png', np.concatenate([np.concatenate(swatches[:5],axis=1),np.concatenate(swatches[5:],axis=1)],axis=0))
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print('Generated 60 maps, 10 materials, two resolutions.')
