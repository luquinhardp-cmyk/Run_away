"""Three original mono 22.05 kHz impact variants for each physical material bank."""
from pathlib import Path
import numpy as np
import wave,json
out=Path(__file__).resolve().parents[2]/'assets/audio/impacts'
out.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(60131);sr=22050;manifest=[]
for kind,base,decay in [('metal',650,8),('wood',170,18),('glass',1900,12),('rubber',110,22),('heavy',65,10),('chain',1150,14),('slide',240,9)]:
    for i in range(3):
        duration=.7 if kind in ['metal','heavy'] else .45
        t=np.arange(int(sr*duration))/sr
        noise=rng.uniform(-1,1,len(t));f=base*(.92+i*.08)
        v=(np.sin(2*np.pi*f*t)+.4*np.sin(2*np.pi*f*2.73*t)+noise*(.9 if kind in ['wood','slide'] else .3))*np.exp(-t*decay)
        v*=np.minimum(1,t/.002);v*=.65/max(1,float(abs(v).max()))
        p=out/f'{kind}_{i}.wav'
        with wave.open(str(p),'wb') as w:w.setparams((1,2,sr,0,'NONE','not compressed'));w.writeframes((v*32767).astype('<i2').tobytes())
        manifest.append(dict(file=p.name,duration=duration,peak=float(abs(v).max()),origin='original synthesis'))
(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('Generated',len(manifest),'impacts')
