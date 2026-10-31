"""Original mono behavior banks. Reproducible synthesis; no voice recordings."""
from pathlib import Path
import json, wave
import numpy as np
root=Path(__file__).resolve().parents[2]
out=root/'assets/audio/creature_v2';out.mkdir(parents=True,exist_ok=True)
resource=root/'resources/horror/audio';resource.mkdir(parents=True,exist_ok=True)
rate=22050
manifest=[]
for kind,duration,interval in [('patrol',2.3,3.8),('joint',.32,2.0),('drag',.7,2.8),('alert',.8,1.2),('investigate',1.2,2.0),('search',1.6,2.8),('sniff',1.0,2.2),('chase',1.6,1.0),('attack',.65,.2),('capture',1.0,.1),('knock',.5,1.0),('creak',1.5,2.0)]:
    for variant in range(2):
        rng=np.random.default_rng(731+variant+sum(map(ord,kind)))
        t=np.arange(int(duration*rate))/rate;p=t/duration
        noise=rng.normal(0,1,len(t));grain=np.convolve(noise,np.ones(13)/13,mode='same')
        frequency=39+variant*7
        phase=2*np.pi*(frequency*t+2.3*np.sin(t*2.1))
        throat=np.sin(phase)*.21+np.sin(phase*2.07)*.09+np.sin(phase*3.9)*.035
        env=np.sin(np.pi*p)**2
        if kind in ['patrol','search','sniff']: signal=(grain*.45+throat*.2)*env*(.75+.25*np.sin(t*11))
        elif kind in ['joint','alert','knock']: signal=(grain*.35+np.sin(t*2*np.pi*(180+variant*31))*.15)*(np.exp(-p*16)+.35*np.exp(-((p-.4)/.06)**2))
        elif kind in ['drag','creak']: signal=(grain*.3+np.sin(t*2*np.pi*(120+70*p))*.07)*env
        elif kind=='investigate': signal=(grain*.12+throat*.65)*env
        else: signal=(grain*.28+throat*.95)*env
        signal=np.tanh(signal)*.72
        signal[:150]*=np.linspace(0,1,150);signal[-150:]*=np.linspace(1,0,150)
        path=out/f'{kind}_{variant}.wav'
        with wave.open(str(path),'wb') as w:
            w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes((np.clip(signal,-.65,.65)*32767).astype('<i2').tobytes())
        manifest.append({'file':str(path.relative_to(root)).replace('\\','/'),'peak':float(np.abs(signal).max()),'duration':duration})
    text='[gd_resource type="Resource" script_class="CreatureCue" load_steps=4 format=3]\n[ext_resource type="Script" path="res://scripts/horror/creature_cue.gd" id="1"]\n'
    for i in range(2):text+=f'[ext_resource type="AudioStream" path="res://assets/audio/creature_v2/{kind}_{i}.wav" id="{i+2}"]\n'
    text+='[resource]\nscript = ExtResource("1")\nsamples = Array[AudioStream]([ExtResource("2"), ExtResource("3")])\nmin_interval = '+str(interval)+'\n'
    (resource/f'{kind}.tres').write_text(text,encoding='utf-8')
t=np.arange(rate*4)/rate
signal=(np.sin(t*2*np.pi*50)*.04+np.sin(t*2*np.pi*100)*.018)*(0.8+.2*np.sin(t*np.pi))
with wave.open(str(root/'assets/audio/electric_hum.wav'),'wb') as w:
    w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes((signal*32767).astype('<i2').tobytes())
(out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
