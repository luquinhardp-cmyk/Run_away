"""Original crater map and spatial night/winged audio. No third party imagery/audio."""
from pathlib import Path
import numpy as np
import math, json, wave, struct,zlib
root=Path(__file__).resolve().parents[2]
textures=root/'assets/textures/night';textures.mkdir(parents=True,exist_ok=True)
audio=root/'assets/audio/night';audio.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(7312026)
n=512;y,x=np.mgrid[-1:1:complex(n),-1:1:complex(n)]
surface=.48+np.sin(x*7+np.sin(y*8))*.07+np.sin(x*21+y*13)*.035+rng.random((n,n))*.08
for i in range(90):
    cx,cy=rng.uniform(-1,1,2);r=rng.uniform(.018,.18)
    d=np.sqrt((x-cx)**2+(y-cy)**2)/r
    surface+=np.exp(-((d-1)/.09)**2)*.12-np.exp(-(d/.75)**4)*.16
for cx,cy,r in [(-.4,.2,.35),(.25,-.4,.3),(.2,.4,.22)]:surface-=np.exp(-(((x-cx)**2+(y-cy)**2)/r**2)**2)*.15
pixels=np.repeat(np.clip(surface*255,0,255).astype('uint8')[...,None],3,axis=2)
def chunk(k,d):return struct.pack('>I',len(d))+k+d+struct.pack('>I',zlib.crc32(k+d)&0xffffffff)
raw=b''.join(b'\0'+row.tobytes() for row in pixels)
(textures/'moon_craters.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',n,n,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
sr=22050;manifest=[]
def save(name,v):
    v=np.tanh(v);v*=.55/max(.55,float(abs(v).max()))
    v*=np.minimum(1,np.arange(len(v))/int(sr*.03))*np.minimum(1,np.arange(len(v))[::-1]/int(sr*.15))
    with wave.open(str(audio/(name+'.wav')),'wb') as w:w.setparams((1,2,sr,0,'NONE','none'));w.writeframes((v*32767).astype('<i2').tobytes())
    manifest.append(dict(file=name+'.wav',duration=len(v)/sr,peak=float(abs(v).max()),origin='original synthesis'))
for i in range(3):
    t=np.arange(int(sr*3.6))/sr
    frequency=430+170*np.sin(t*.9+i)+420*np.exp(-((t-.6)/.3)**2)
    phase=np.cumsum(frequency)/sr*math.tau
    envelope=np.sin(np.minimum(t/3.6,1)*np.pi)**1.3
    v=(np.sin(phase)+.3*np.sin(phase*2.03)+.4*np.sin(t*math.tau*(43+i*3))+rng.normal(0,.12,len(t)))*envelope*.35
    for delay,gain in [(.11,.17),(.23,.09)]:v[int(delay*sr):]+=v[:-int(delay*sr)]*gain
    save('scream_'+str(i),v)
    t=np.arange(int(sr*1.3))/sr
    noise=rng.normal(0,1,len(t));soft=np.convolve(noise,np.ones(18)/18,mode='same')
    save('wing_'+str(i),soft*np.exp(-((t-.45)/.2)**2)*1.5+np.sin(t*math.tau*48)*np.exp(-t*7)*.12)
    save('whoosh_'+str(i),soft*np.sin(t/1.3*np.pi)**2*.8)
for name,duration in [('wind',16),('leaves',11),('insects',13),('branch',7),('animal',8)]:
    t=np.arange(sr*duration)/sr;noise=rng.normal(0,1,len(t));soft=np.convolve(noise,np.ones(90)/90,mode='same')
    if name=='wind':v=soft*(.4+.3*np.sin(t*.7))*1.3
    elif name=='leaves':v=np.convolve(noise,np.ones(5)/5,mode='same')*(np.sin(t*1.4)**12)*.14
    elif name=='insects':v=np.sin(t*math.tau*3200)*np.maximum(0,np.sin(t*math.tau*3.7))**15*(.3+.7*np.sin(t*.31)**2)*.065
    elif name=='branch':v=(np.sin(t*math.tau*(115+np.sin(t*2)*25))+noise*.2)*np.exp(-((t-2)/.8)**2)*.13
    else:v=np.sin(t*math.tau*(280+np.sin(t*5)*70))*np.exp(-((t-3)/.65)**2)*.11
    save('forest_'+name,v)
(audio/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('NIGHT_ASSETS',len(manifest),'mono clips; crater map 512')
