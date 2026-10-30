"""Original foley-like synthesis; no recorded voices or external samples."""
from pathlib import Path
import numpy as np
import wave

root=Path(__file__).resolve().parents[2]/'assets/audio'
rate=22050
rng=np.random.default_rng(7351)
clips={'breath':2.3,'creature_step':.45,'joint':.28,'listen':.8,'investigate':1.3,'attack':.75,'capture':.9,'chase':2.8,'exterior_wind':8,'basement_drips':6}
for name,duration in clips.items():
    t=np.arange(round(rate*duration))/rate; p=t/duration
    noise=rng.normal(0,1,len(t))
    smooth=np.convolve(noise,np.ones(9)/9,mode='same')
    phase=2*np.pi*(43*t+1.8*np.sin(t*2.1))
    voice=np.sin(phase)*.38+np.sin(phase*2.04)*.12+np.sin(phase*4.93)*.045
    envelope=np.sin(np.pi*p)**2
    if name=='breath': signal=(smooth*.65+voice*.16)*envelope*(.7+.3*np.sin(t*8))
    elif name=='creature_step': signal=(smooth*.5+np.sin(t*2*np.pi*67)*.45)*np.exp(-p*12)
    elif name=='joint': signal=(smooth*.4+np.sin(t*2*np.pi*270)*.13)*np.exp(-p*17)
    elif name=='listen':
        envelope=np.exp(-((p-.15)/.08)**2)*.35+np.exp(-((p-.48)/.10)**2)*.25+np.exp(-((p-.7)/.06)**2)*.22
        signal=(smooth*.5+np.sin(t*2*np.pi*164)*.13)*envelope
    elif name=='investigate': signal=(voice*.45+smooth*.15)*envelope
    elif name in ('attack','capture'): signal=(voice*.7+smooth*.32)*envelope
    elif name=='chase': signal=(voice*.8+smooth*.08)*(envelope*.7)*(1+.3*np.sin(t*14))
    elif name=='exterior_wind': signal=smooth*.23*(.75+.25*np.sin(t*2*np.pi/duration))
    else:
        signal=smooth*.015
        for moment in [.4,2.7,4.9]:
            q=np.maximum(t-moment,0)
            signal+=np.where(t>moment,np.sin(2*np.pi*(730*q-180*q*q))*np.exp(-q*38)*.2,0)
    signal=np.tanh(signal)*.65
    signal[:110]*=np.linspace(0,1,110); signal[-110:]*=np.linspace(1,0,110)
    with wave.open(str(root/(name+'.wav')),'wb') as wav:
        wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(rate)
        wav.writeframes((np.clip(signal,-.65,.65)*32767).astype('<i2').tobytes())
    print(name, 'peak',round(float(abs(signal).max()),3))
