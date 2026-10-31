"""Small-prop PBR library: deterministic 256/128 maps, packed ORM, original synthesis."""
from pathlib import Path
import numpy as np
import json, struct, zlib
root=Path(__file__).resolve().parents[2]
out=root/'assets/textures/pbr'
rng=np.random.default_rng(60131)
n=256
y,x=np.mgrid[0:n,0:n]/n
def png(path,a):
    a=np.clip(a,0,255).astype('uint8'); h,w,c=a.shape
    def chunk(k,v): return struct.pack('>I',len(v))+k+v+struct.pack('>I',zlib.crc32(k+v)&0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(b'\0'+row.tobytes() for row in a),9))+chunk(b'IEND',b''))
specs=[('brushed_metal',(111,110,99),.42,.8),('wet_steel',(74,80,73),.3,.65),('dirty_glass',(72,92,78),.35,0),('cracked_glass',(87,100,90),.5,0),('aged_plastic',(73,67,46),.72,0),('worn_rubber',(39,42,36),.9,0),('damp_wood',(66,49,32),.7,0),('industrial_sheet',(94,84,65),.68,.7),('moss',(52,65,35),.98,0),('old_upholstery',(72,58,42),.94,0)]
manifest=[]
for name,base,rough,metal in specs:
    noise=rng.random((n,n)); broad=(np.sin(x*12.57)*np.sin(y*18.85)+1)/2
    height=noise*.08+broad*.12
    pattern=np.zeros_like(x)
    if name=='brushed_metal': pattern=np.sin(y*850)*.04
    if name=='industrial_sheet': pattern=(np.cos(x*100)>0.8)*.1
    if name=='damp_wood': pattern=np.sin(x*130+np.sin(y*12)*2)*.13
    if name=='old_upholstery': pattern=(np.sin(x*800)+np.sin(y*800))*.05
    if name=='cracked_glass': pattern=-np.exp(-abs(np.sin(x*17+y*9))*130)*.5
    if name=='moss': pattern=noise**4*.3
    height+=pattern
    color=np.array(base)[None,None,:]*(.75+broad[...,None]*.3+noise[...,None]*.2+pattern[...,None])
    dx=np.roll(height,-1,1)-np.roll(height,1,1);dy=np.roll(height,-1,0)-np.roll(height,1,0)
    normal=np.stack((-dx*2,-dy*2,np.ones_like(x)),axis=2);normal/=np.linalg.norm(normal,axis=2,keepdims=True)
    orm=np.stack((.8+noise*.2,np.clip(rough+noise*.12-.06,.1,1),np.full_like(x,metal)),axis=2)*255
    for suffix,pixels in [('albedo',color),('normal',(normal*.5+.5)*255),('orm',orm)]:
        png(out/f'{name}_{suffix}.png',pixels)
        png(out/f'{name}_{suffix}_low.png',pixels.reshape(128,2,128,2,3).mean(axis=(1,3)))
    s='[gd_resource type="StandardMaterial3D" load_steps=4 format=3]\n'
    for i,suffix in enumerate(['albedo','normal','orm'],1):s+=f'[ext_resource type="Texture2D" path="res://assets/textures/pbr/{name}_{suffix}.png" id="{i}"]\n'
    s+=f'[resource]\nresource_name = "{name}"\nalbedo_texture = ExtResource("1")\nnormal_enabled = true\nnormal_texture = ExtResource("2")\nroughness = 1.0\nroughness_texture = ExtResource("3")\nroughness_texture_channel = 1\nmetallic = 1.0\nmetallic_texture = ExtResource("3")\nmetallic_texture_channel = 2\nao_enabled = true\nao_texture = ExtResource("3")\nao_texture_channel = 0\n'
    (root/'assets/materials'/f'{name}.tres').write_text(s,encoding='utf-8')
    manifest.append(dict(id=name,size=256,low=128,roughness=rough,metallic=metal,origin='original deterministic synthesis',glass_note='opaque dirty surface, no refraction or destruction shader' if 'glass' in name else ''))
(out/'physics_materials_manifest.json').write_text(json.dumps(manifest,indent=2))
print('Generated',len(manifest),'prop materials')
