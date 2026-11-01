"""Extract supplied production animation/props/audio; no original file is modified."""
from pathlib import Path
from PIL import Image
import json,wave,shutil
root=Path(__file__).resolve().parents[2];src=root/'assets';out=root/'godot-poc/assets'
metadata=json.loads((src/'hero-frames-v1.json').read_text());manifest=[]
def framed(file,spec,f,name):
 im=Image.open(src/file).convert('RGBA');part=im.crop((f['x'],f['y'],f['x']+f['w'],f['y']+f['h']))
 scale=72/spec['bodyHeight'];part=part.resize((round(f['w']*scale),round(f['h']*scale)),Image.Resampling.NEAREST)
 canvas=Image.new('RGBA',(160,128));canvas.paste(part,(round(80-f['anchorX']*scale),round(112-f['anchorY']*scale)))
 canvas.save(out/(name+'.png'));manifest.append(dict(output=name,source=file,frame=f,bodyHeight=spec['bodyHeight']))
for hero in ['knight','mage','rogue']:
 for side in ['right','left']:
  key=hero+'-'+(side if hero=='knight' else 'right');spec=metadata[key]
  file=('knight-left-animation-v1.png' if key=='knight-left' else hero+'-animation-v1.png')
  for i in range(8):
   frame=spec['frames'][i+8]
   if hero=='knight' and side=='left' and i==4: framed('knight-left-strike-v1.png',metadata['knight-strike'],metadata['knight-strike']['frames'][0],f'{hero}_attack_{side}_{i}')
   else: framed(file,spec,frame,f'{hero}_attack_{side}_{i}')
idle=json.loads((src/'knight-gait-v2.json').read_text())['idle']
for i,d in enumerate(['right','left','down','up']):framed('knight-idle-v2.png',idle,idle['frames'][i],f'knight_idle_{d}')
def crop(file,rect,name,size):
 im=Image.open(src/file).convert('RGBA');x,y,w,h=rect
 part=im.crop((x,y,x+w,y+h));box=part.getbbox()
 if box: part=part.crop(box)
 part.thumbnail(size,Image.Resampling.NEAREST);part.save(out/(name+'.png'));manifest.append(dict(output=name,source=file,rect=rect))
im=Image.open(src/'journey-v1.png');w,h=im.size
for name,r,size in [('chest',[.36,.49,.25,.22],(100,85)),('arch',[0,0,.346,.405],(240,300))]:
 x,y,rw,rh=r;crop('journey-v1.png',(round(x*w),round(y*h),round(rw*w),round(rh*h)),name,size)
im=Image.open(src/'camp-pavilion-v1.png');crop('camp-pavilion-v1.png',(0,0,*im.size),'pavilion',(285,245))
im=Image.open(src/'warlord-props-v1.png');w,h=im.size
for name,col,row in [('supply_crate',0,2),('barrel',1,2),('masonry',2,2),('barricade',0,1),('rubble',2,1)]:crop('warlord-props-v1.png',(col*w//3,row*h//3,w//3,h//3),name,(100,100))
im=Image.open(src/'warlord-decor-v1.png');w,h=im.size
for name,col,row in [('banner',0,1),('dummy',2,1),('brazier',1,0)]:crop('warlord-decor-v1.png',(col*w//3,row*h//3,w//3,h//3),name,(90,130))
with wave.open(str(src/'audio/combat-v2.wav'),'rb') as bank:
 params=bank.getparams();audio=bank.readframes(bank.getnframes())
 clips=json.loads((src/'audio/combat-v2.json').read_text())['clips']
 for name in ['sword-swing','dagger-throw','arcane-cast','hit-metal','hit-flesh','hit-arcane']:
  clip=clips[name][0];a=round(clip['offset']*params.framerate)*2;b=a+round(clip['duration']*params.framerate)*2
  with wave.open(str(out/(name+'.wav')),'wb') as target: target.setparams(params);target.writeframes(audio[a:b])
shutil.copyfile(src/'audio/CREDITS.md',out/'AUDIO_CREDITS.md')
(out/'pass02-manifest.json').write_text(json.dumps(manifest,indent=2))
inventory=[]
for p in src.glob('*.png'):
 im=Image.open(p);inventory.append(dict(file=p.name,size=list(im.size),mode=im.mode))
(out/'source-inventory.json').write_text(json.dumps(inventory,indent=2))
print('Pass02:',len(manifest),'extra frames and props, 6 audio cues;',len(inventory),'source images inventoried')
