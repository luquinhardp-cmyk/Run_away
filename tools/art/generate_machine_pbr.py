"""Original tileable fine patina, avoiding oversized orange placeholder blotches."""
from pathlib import Path
import numpy as np, struct,zlib
root=Path(__file__).resolve().parents[2]
out=root/'assets/textures/pbr'
def png(path,a):
 def chunk(k,d):return struct.pack('>I',len(d))+k+d+struct.pack('>I',zlib.crc32(k+d)&0xffffffff)
 h,w=a.shape[:2];raw=b''.join(b'\0'+row.tobytes() for row in a)
 path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
rng=np.random.default_rng(801723)
n=512;y,x=np.mgrid[0:n,0:n]/n
def noise(bands):
 a=np.zeros((n,n))
 for freq,amp in bands:
  for i in range(4):
   k,l=rng.integers(1,freq+1,2);a+=np.sin((x*k+y*l)*np.pi*2+rng.random()*np.pi*2)*amp/4
 return a
grain=rng.normal(0,.012,(n,n));cloud=noise([(4,.3),(13,.18),(39,.08)])
rust=np.clip((cloud-.035)*8,0,1)
steel=np.array([.115,.145,.137])[None,None,:]+(grain+cloud*.06)[...,None]
oxide=np.array([.22,.105,.045])[None,None,:]+grain[...,None]
albedo=np.clip(steel*(1-rust[...,None]*.7)+oxide*rust[...,None]*.7,0,1)
height=grain*.1+rust*.015+noise([(73,.003)])
dx=(np.roll(height,1,1)-np.roll(height,-1,1))*8
dy=(np.roll(height,1,0)-np.roll(height,-1,0))*8
normal=np.dstack([dx,dy,np.ones_like(dx)]);normal/=np.linalg.norm(normal,axis=2)[...,None]
orm=np.dstack([np.clip(.94-rust*.12,.6,1),np.clip(.65+rust*.30+grain,.3,1),.73*(1-rust)])
for name,a in [('albedo',albedo),('normal',normal*.5+.5),('orm',orm)]:
 data=np.uint8(np.clip(a*255,0,255));png(out/f'weathered_iron_{name}.png',data)
 low=data.reshape(256,2,256,2,3).mean(axis=(1,3)).astype('uint8');png(out/f'weathered_iron_{name}_low.png',low)
(root/'assets/materials/weathered_iron.tres').write_text('''[gd_resource type="StandardMaterial3D" format=3]
[resource]
resource_name = "weathered_iron"
roughness = 1.0
metallic = 1.0
''',encoding='utf-8')
print('PBR_COMPLETE weathered_iron 512/256 albedo normal ORM')
