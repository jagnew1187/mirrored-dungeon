"""Run from repository root with Pillow. Extract existing production art."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[2]
src,out=root/'assets',root/'godot-poc/assets'
manifest=[]
def crop(file,r,name,size):
    im=Image.open(src/file).convert('RGBA');x,y,w,h=r
    im.crop((x,y,x+w,y+h)).resize(size,Image.Resampling.NEAREST).save(out/(name+'.png'))
    manifest.append(dict(output=name+'.png',source=file,dimensions=list(im.size),rect=r))
for hero in ['knight','mage','rogue']:
    data=json.loads((src/('knight-gait-v2.json' if hero=='knight' else 'class-gait-frames-v2.json')).read_text())
    art=json.loads((src/('knight-art.json' if hero=='knight' else 'class-gait-art.json')).read_text())
    if hero!='knight': data,art=data[hero],art[hero]
    for direction in ['left','right','up','down','southeast','southwest','northeast','northwest']:
        spec=data[direction]
        for i,f in enumerate(spec['frames'][:9]):
            im=Image.open(src/art[direction]['file']).convert('RGBA')
            part=im.crop((f['x'],f['y'],f['x']+f['w'],f['y']+f['h']))
            scale=72/spec['bodyHeight'];part=part.resize((round(f['w']*scale),round(f['h']*scale)),Image.Resampling.NEAREST)
            canvas=Image.new('RGBA',(160,128));canvas.paste(part,(round(80-f['anchorX']*scale),round(112-f['anchorY']*scale)))
            name=f'{hero}_{direction}_{i}.png';canvas.save(out/name)
            manifest.append(dict(output=name,source=art[direction]['file'],dimensions=list(im.size),frame=f,bodyHeight=spec['bodyHeight']))
for i,r in enumerate([[260,16,130,318],[559,16,132,318],[851,16,132,318],[1151,16,132,318]]): crop('mara-animation-v1.png',r,f'mara_{i}',(26,64))
crop('mara-portrait-v1.png',[0,0,1254,1254],'mara_portrait',(192,192))
for name,r,p in zip(['anja','oren','ves','tomas','boy'],[[40,66,263,535],[344,51,267,551],[680,68,219,532],[980,64,218,540],[1315,204,166,392]],[[22,636,286,338],[338,636,282,338],[641,636,281,338],[945,636,283,338],[1265,685,238,289]]):
    h=43 if name=='boy' else 64;crop('campaign-villagers-v1.png',r,name,(round(r[2]/r[3]*h),h));crop('campaign-villagers-v1.png',p,name+'_portrait',(140,168))
im=Image.open(src/'camp-materials-v1.png');w,h=im.size
for i in range(4):
    r=[i%2*w//2,i//2*h//2,w//2,h//2];crop('camp-materials-v1.png',r,f'tile_{i}',(64,64))
    x,y,cw,ch=r
    im.crop((x,y,x+cw,y+ch)).resize((64,64),Image.Resampling.BOX).save(out/f'tile_{i}.png')
im=Image.open(src/'journey-v1.png');w,h=im.size
for name,r in [('tent',[.635,.425,.365,.29]),('fire',[0,.71,.333,.275]),('crate',[.35,.755,.31,.22]),('table',[.665,.73,.335,.27])]:
    x,y,rw,rh=r;crop('journey-v1.png',[round(x*w),round(y*h),round((x+rw)*w)-round(x*w),round((y+rh)*h)-round(y*h)],name,(192,160))
mob=json.loads((src/'mob-motion-frames-v1.json').read_text())['cultist']['right']
for i,f in enumerate(mob['frames'][:9]): crop('cultist-motion-right-v1.png',[f['x'],f['y'],f['w'],f['h']],f'enemy_{i}',(round(f['w']/f['h']*64),64))
(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(f'Extracted {len(manifest)} isolated PNGs')
