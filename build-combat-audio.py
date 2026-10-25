"""Layer CC0 Foley and original spell textures into a compact, universal PCM bank."""
import json, wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parent/'assets/audio'
RATE=44100
rng=np.random.default_rng(7331)
def read(name):
 with wave.open(str(ROOT/'work'/(name+'.wav')),'rb') as f:a=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(float)/32768
 peak=np.max(np.abs(a));nz=np.flatnonzero(np.abs(a)>max(.001,peak*.018))
 if len(nz):a=a[max(0,nz[0]-88):min(len(a),nz[-1]+882)]
 return a/(max(np.max(np.abs(a)),.001))
sources={name:read(name) for name in json.loads((ROOT/'sources.json').read_text())}
def color(a,low=70,high=11000):
 f=np.fft.rfftfreq(len(a),1/RATE);response=(f/np.sqrt(f*f+low*low))**2/np.sqrt(1+(f/high)**6)
 return np.fft.irfft(np.fft.rfft(a)*response,n=len(a))
def sample(name,rate=1,low=70,high=11000,reverse=False):
 a=sources[name];a=a[::-1] if reverse else a
 a=np.interp(np.arange(0,len(a)-1,rate),np.arange(len(a)),a)
 return color(a,low,high)
def noise(seconds,low,high):
 a=color(rng.normal(size=int(seconds*RATE)),low,high);t=np.arange(len(a))/RATE
 return a*np.minimum(1,t/.018)*np.exp(-t/(seconds*.32))
def cloud(notes,seconds):
 t=np.arange(int(seconds*RATE))/RATE;a=np.zeros(len(t))
 for midi in notes:
  f=440*2**((midi-69)/12)
  for ratio,gain in [(1,1),(1.003,.35),(2.002,.17),(3.01,.065)]:a+=gain*np.sin(2*np.pi*f*ratio*t)
 return a/max(1,len(notes))*np.minimum(1,t/.055)*np.exp(-t/(seconds*.25))
def compose(layers,seconds):
 a=np.zeros(int(seconds*RATE))
 for data,gain,delay in layers:
  start=int(delay*RATE);n=min(len(data),len(a)-start)
  if n>0:a[start:start+n]+=data[:n]*gain
 # Preserve recorded transients; aggressive RMS boosting made quiet cloth/noise dominate.
 a=color(a);a*=min(1.25,.62/max(np.max(np.abs(a)),.001))
 fade=min(220,len(a)//10);a[:fade]*=np.linspace(0,1,fade);a[-min(2646,len(a)):]*=np.linspace(1,0,min(2646,len(a)))
 return a
def spell_tone(seconds,start,end,level=.3,attack=.012):
 # Smooth, single-voice pitch movement avoids the beating of detuned glass layers.
 t=np.arange(round(seconds*RATE))/RATE
 f=start+(end-start)*(1-np.exp(-t/.06))
 phase=2*np.pi*np.cumsum(f)/RATE
 envelope=(1-np.exp(-t/attack))*np.exp(-t/(seconds*.24))
 envelope*=np.minimum(1,(seconds-t)/.035)
 return level*(np.sin(phase)+.08*np.sin(2*phase))*envelope

def mage_recipe(key,v):
 pitch=1+v*.025
 if key=='arcane-cast':return [(spell_tone(.24,430*pitch,760*pitch,.42),1,0)],.24
 if key=='hit-arcane':return [(spell_tone(.16,900*pitch,560*pitch,.28,.004),1,0)],.16
 if key in ['fire-cast','hit-fire']:
  seconds=.3 if key=='fire-cast' else .18
  t=np.arange(round(seconds*RATE))/RATE
  air=color(np.random.default_rng(812+v).normal(size=len(t)),180,1800)
  air*=.045*(1-np.exp(-t/.018))*np.exp(-t/.065)
  return [(spell_tone(seconds,210*pitch,95*pitch,.23),1,0),(air,1,0)],seconds
 if key in ['frost-cast','hit-frost']:
  seconds=.32 if key=='frost-cast' else .2
  return [(spell_tone(seconds,1180*pitch,1050*pitch,.27),1,0)],seconds
 if key=='heal':
  return [(spell_tone(.4,f,f,.19),1,i*.075) for i,f in enumerate([523.25,659.25,783.99])],.6
 return None

def recipe(key,v):
 s=lambda name,rate=1,**kw:sample(name,rate,**kw)
 pick=lambda prefix:prefix+f'_{v:03}'
 knife=s('knifeSlice' if v==0 else 'knifeSlice2',1.1)
 cloth=s('cloth1' if v==0 else 'cloth2',1.35,high=4500)
 metal=s(pick('impactMetal_medium'),1.06,high=8500)
 punch=s(pick('impactPunch_heavy'),.96,high=4000)
 glass=s(pick('impactGlass_light'),1.25,high=9500)
 if key=='sword-swing':return [(knife,.85,0),(cloth,.4,0)],.38
 if key=='dagger-throw':return [(s('drawKnife1' if v==0 else 'drawKnife2',1.6),.65,0),(knife,.28,0)],.3
 if key=='twin-daggers':return [(knife,.65,0),(s('drawKnife2' if v==0 else 'drawKnife1',1.5),.55,.065)],.42
 if key=='enemy-swing':return [(cloth,.75,0),(knife,.2,.01)],.3
 if key=='cleave':return [(s('knifeSlice' if v==0 else 'knifeSlice2',.8),.85,0),(s('cloth2',.85,high=3000),.45,.01)],.52
 if key=='shield':return [(s(pick('impactMetal_heavy'),1.2),.65,0),(punch,.55,0)],.7
 if key=='hit-metal':return [(metal,.9,0),(s('metalClick',.9),.23,.006)],.65
 if key=='hit-flesh':return [(punch,.85,0),(s(pick('impactSoft_medium'),.8,high=2200),.4,0)],.3
 if key=='hurt':return [(s(pick('impactPunch_heavy'),.8,high=1800),.7,0),(s(pick('impactSoft_medium'),1.1),.4,0)],.32
 if key=='bite':return [(punch,.55,0),(s('chop',1.3+v*.08,high=3800),.45,0)],.3
 if key=='hit-wood':return [(s(pick('impactWood_medium')),.9,0),(punch,.15,0)],.42
 if key=='hit-stone':return [(s(pick('impactMining'),1.15),.8,0),(punch,.3,0)],.48
 if key=='break-wood':return [(s(pick('impactWood_heavy')),.8,0),(s('creak1' if v==0 else 'creak2',1.3),.27,.02),(s(pick('impactWood_medium'),1.2),.45,.085)],.9
 if key=='break-stone':return [(s(pick('impactMining'),.8),.85,0),(s(pick('impactWood_heavy'),.7,high=2200),.4,.015),(s(pick('impactMining'),1.6),.3,.1)],.8
 if key=='boss-slam':return [(s(pick('impactMining'),.65),.7,0),(s(pick('impactWood_heavy'),.6),.65,0),(noise(.6,30,800),.12,0)],.85
 if key in ['fire-cast','hit-fire']:return [(noise(.6,65,2300),.32,0),(cloth,.3,0),(s(pick('impactSoft_medium'),.65,high=1100),.2,0)],.6 if key=='fire-cast' else .32
 if key in ['frost-cast','hit-frost']:return [(s(pick('impactGlass_heavy'),1.4),.65,0),(glass,.3,.025),(noise(.55,3200,10000),.055,0)],.7 if key=='frost-cast' else .4
 if key in ['arcane-cast','hit-arcane']:return [(s(pick('impactGlass_light'),.95,reverse=True),.4,0),(glass,.24,.02),(cloud([62,69,74],.65),.09,0),(cloth,.12,0)],.7 if key=='arcane-cast' else .38
 if key=='heal':return [(glass,.25,0),(cloud([60,64,67,72],1),.22,0),(s(pick('impactGlass_light'),.75,reverse=True),.18,0)],1
 if key=='guard':return [(metal,.25,0),(cloud([48,55,60],.8),.2,0),(cloth,.15,0)],.8
 if key=='shadow':return [(s('cloth1' if v==0 else 'cloth2',.7,reverse=True),.6,0),(noise(.6,180,1800),.12,0),(cloud([45,52],.65),.08,0)],.65
 if key=='smoke':return [(cloth,.6,0),(noise(.6,200,2600),.16,0)],.6
 if key=='necro-cast':return [(s(pick('impactGlass_heavy'),.65,high=2000,reverse=True),.3,0),(cloud([38,45,50],1),.2,0),(noise(.9,100,1000),.11,0)],1
 if key.startswith('foot-'):
  material={'foot-grass':'grass','foot-stone':'concrete','foot-carpet':'carpet','foot-lava':'concrete'}.get(key)
  if key=='foot-metal':return [(s('metalClick',1.2+v*.06),.55,0)],.16
  return [(s(pick('footstep_'+material),1,high=3800 if key=='foot-lava' else 9000),.8,0)],.35
 raise ValueError(key)
keys=['sword-swing','dagger-throw','twin-daggers','arcane-cast','fire-cast','frost-cast','cleave','shield','heal','guard','shadow','smoke','necro-cast','boss-slam','enemy-swing','bite','hit-metal','hit-flesh','hit-arcane','hit-fire','hit-frost','hit-stone','hit-wood','break-wood','break-stone','hurt','foot-grass','foot-stone','foot-carpet','foot-lava','foot-metal']
clips={};parts=[];cursor=0
for key in keys:
 clips[key]=[]
 for variant in range(2):
  layers,seconds=recipe(key,variant)
  # Physical cues use their clean primary recording; magic keeps one quiet texture.
  if key not in ['fire-cast','hit-fire','heal','guard','shadow','smoke','necro-cast','arcane-cast','hit-arcane']:
   layers=layers[:1]
  else:
   layers=[(data,gain*(1 if i==0 else .35),delay) for i,(data,gain,delay) in enumerate(layers[:2])]
  mage=mage_recipe(key,variant)
  if mage is not None:layers,seconds=mage
  pcm=compose(layers,seconds);clips[key].append({'offset':cursor/RATE,'duration':len(pcm)/RATE});parts.extend([pcm,np.zeros(882)]);cursor+=len(pcm)+882
audio=np.concatenate(parts);output=ROOT/'combat-v2.wav'
with wave.open(str(output),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(np.round(audio*32767).astype('<i2').tobytes())
metadata={'sampleRate':RATE,'channels':1,'seconds':len(audio)/RATE,'bytes':output.stat().st_size,'clips':clips,'peak':float(np.max(np.abs(audio)))}
(ROOT/'combat-v2.json').write_text(json.dumps(metadata,indent=2)+'\n')
print('Built',len(keys)*2,'layered sound variants;',round(len(audio)/RATE,2),'seconds;',round(output.stat().st_size/1048576,2),'MiB PCM; peak',round(metadata['peak'],3))
