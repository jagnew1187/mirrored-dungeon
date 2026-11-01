"""Reproducible project-only crops/atlases. Never changes parent source artwork.
Generated artwork lives in art-source; original production sources remain in ../assets.
Nearest sampling and binary alpha keep the imported pixel silhouettes crisp.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import json, math
from collections import deque

def remove_small_islands(image, minimum=350):
    """Remove disconnected neighboring-sprite fragments, retain weapon components."""
    alpha=image.getchannel('A'); pixels=alpha.load(); seen=set()
    for y in range(image.height):
        for x in range(image.width):
            if not pixels[x,y] or (x,y) in seen: continue
            todo=deque([(x,y)]);seen.add((x,y));component=[]
            while todo:
                px,py=todo.popleft();component.append((px,py))
                for dx,dy in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(1,-1),(-1,1),(1,1)]:
                    nx,ny=px+dx,py+dy
                    if 0<=nx<image.width and 0<=ny<image.height and (nx,ny) not in seen and pixels[nx,ny]:
                        seen.add((nx,ny));todo.append((nx,ny))
            if len(component)<minimum:
                for px,py in component: pixels[px,py]=0
    image.putalpha(alpha)
    return image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/pass07'
OUT.mkdir(exist_ok=True)
manifest = []

def isolate(sheet, name, rect, root, height, canvas, origin):
    im = Image.open(ROOT / 'art-source' / sheet).convert('RGBA')
    part = im.crop(rect)
    alpha = part.getchannel('A').point(lambda v: 255 if v >= 120 else 0)
    part.putalpha(alpha)
    box = part.getbbox()
    if not box: raise ValueError(name)
    part = part.crop(box)
    scale = height / part.height
    size = (round(part.width * scale), height)
    part = part.resize(size, Image.Resampling.NEAREST)
    anchor = ((root[0]-rect[0]-box[0])*scale, (root[1]-rect[1]-box[1])*scale)
    dest = Image.new('RGBA', canvas)
    dest.alpha_composite(part, (round(origin[0]-anchor[0]), round(origin[1]-anchor[1])))
    dest.save(OUT / (name+'.png'))
    manifest.append(dict(asset=name,source=sheet,rect=rect,source_root=root,origin=origin,canvas=canvas,height=height))
    return dest

for args in [
 ('oak',(0,0,650,705),(330,680),256,(288,304),(144,288)),
 ('pine',(640,0,1080,720),(815,705),288,(256,320),(128,304)),
 ('birch',(1080,0,1536,720),(1290,705),270,(256,304),(128,288)),
 ('shrub',(0,710,480,1024),(240,1005),88,(144,104),(72,96)),
 ('rock',(485,725,965,1024),(740,1000),72,(144,88),(72,80)),
 ('log',(980,730,1536,1024),(1240,1000),68,(176,88),(88,80))]:
    isolate('woodland.png', *args)

# Directional interim: keep the genuine directional silhouette; a very small
# shoulder anticipation is combined with a separately drawn weapon/casting cue.
# These are adaptations, not a claim of 144 newly authored character poses.
dirs = ['right','southeast','down','southwest','left','northwest','up','northeast']
for hero in ['knight','mage','rogue']:
    atlas = Image.new('RGBA',(1280,1024))
    for row,direction in enumerate(dirs):
        angle=row*math.pi/4; ux,uy=math.cos(angle),math.sin(angle)
        for f in range(8):
            if direction in ['right','left']:
                frame=Image.open(ROOT/f'assets/{hero}_attack_{direction}_{f}.png').convert('RGBA')
                if direction=='left' and hero!='knight': frame=frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            else:
                key=f'knight_idle_{direction}' if hero=='knight' and direction in ['up','down'] else f'{hero}_{direction}_8'
                base=Image.open(ROOT/f'assets/{key}.png').convert('RGBA')
                frame=Image.new('RGBA',(160,128))
                # Lower legs stay anchored exactly. Upper body anticipates by 1px.
                lean=[0,-1,-1,0,1,1,0,0][f]
                frame.alpha_composite(base.crop((0,0,160,91)),(round(ux*lean),round(uy*lean)))
                frame.alpha_composite(base.crop((0,91,160,128)),(0,91))
                draw=ImageDraw.Draw(frame)
                hand=(80+ux*15,76+uy*12)
                release=3 if hero=='rogue' else 4
                if hero=='mage' and 1<=f<=5:
                    r=[0,2,3,4,6,3,0,0][f]
                    x,y=hand
                    draw.polygon([(x,y-r),(x+r,y),(x,y+r),(x-r,y)],fill='#61bbd7')
                    draw.rectangle((x-1,y-1,x+1,y+1),fill='#f2f7d1')
                elif f in [release-1,release,release+1]:
                    reach=24 if hero=='knight' else 16
                    x,y=hand; tip=(x+ux*reach,y+uy*reach*.65)
                    draw.line([hand,tip],fill='#27343b',width=5)
                    draw.line([hand,tip],fill='#bdd2d4',width=2)
                    draw.point(tip,fill='#fff2cb')
            if direction not in ['right','left'] and (ROOT/'art-source/hero-release-poses.png').exists() and f in [1,2,3,4,5,6]:
                # A painted directional key pose plus a small isolated weapon-arm rig.
                # Whole bodies/faces are never rotated. Feet retain the same origin.
                sheet=Image.open(ROOT/'art-source/hero-release-poses.png').convert('RGBA')
                col=['up','down','northeast','northwest','southeast','southwest'].index(direction)
                rr=['knight','mage','rogue'].index(hero);cw=sheet.width/6;ch=sheet.height/3
                pose=sheet.crop((round(col*cw),round(rr*ch),round((col+1)*cw),round((rr+1)*ch))).resize((300,300),Image.Resampling.NEAREST)
                pose.putalpha(pose.getchannel('A').point(lambda a:255 if a>=120 else 0))
                left=direction in ['northwest','southwest']
                if left: pose=pose.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                pivot={'knight':(171,145),'mage':(173,171),'rogue':(172,132)}[hero]
                mask=Image.new('L',(300,300));md=ImageDraw.Draw(mask)
                md.polygon([(pivot[0]-4,pivot[1]-15),(225,35),(299,35),(299,pivot[1]+12),(pivot[0],pivot[1]+12)],fill=255)
                import PIL.ImageChops
                arm=pose.copy();arm.putalpha(PIL.ImageChops.multiply(pose.getchannel('A'),mask))
                body=pose.copy();body.putalpha(PIL.ImageChops.subtract(pose.getchannel('A'),arm.getchannel('A')))
                angle={'up':45,'down':-135,'northeast':0,'northwest':0,'southeast':-90,'southwest':-90}[direction]
                release=3 if hero=='rogue' else 4
                anticipation=35 if f<release else (-12 if f>release else 0)
                if hero=='knight' and direction=='up':
                    factor=1/.86
                    arm=arm.transform(arm.size,Image.Transform.AFFINE,(factor,0,pivot[0]*(1-factor),0,factor,pivot[1]*(1-factor)),Image.Resampling.NEAREST)
                arm=arm.rotate(angle+anticipation,Image.Resampling.NEAREST,center=pivot)
                body.alpha_composite(arm)
                if left: body=body.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                # Explicit head-to-foot scales, excluding the raised sword/staff.
                scale=72/[180,185,185][rr]
                body=body.resize((round(300*scale),round(300*scale)),Image.Resampling.NEAREST)
                frame=Image.new('RGBA',(160,128))
                foot=[(150,291),(150,286),(150,276)][rr]
                frame.alpha_composite(body,(round(80-foot[0]*scale),round(112-foot[1]*scale)))
            atlas.alpha_composite(frame,(f*160,row*128))
    atlas.save(OUT/f'{hero}_attacks.png')
    manifest.append(dict(asset=hero+'_attacks',canvas=[1280,1024],cell=[160,128],origin=[80,112],rows=dirs,source='hero-release-poses.png plus original directional idle and side attack frames',provisional='Six directions use one generated key pose per direction with isolated weapon-arm rotation and original idle endpoints. Eight timed frames are not eight independently painted poses.'))

if (ROOT/'art-source/civilian-buildings.png').exists():
    for args in [
        ('bakery',(0,0,535,495),(274,475),330,(400,352),(200,340)),
        ('smithy',(540,0,1075,495),(805,475),300,(384,324),(192,312)),
        ('residence',(1075,0,1536,495),(1300,475),330,(368,352),(184,340)),
        ('ration',(0,505,535,1024),(280,950),280,(360,304),(180,292)),
        ('mill',(540,505,1075,1024),(800,970),320,(384,344),(192,332)),
        ('checkpoint',(1075,505,1536,1024),(1310,950),230,(328,256),(164,244))]:
        isolate('civilian-buildings.png',*args)
    # Reusable trim/material components, at the same density as the buildings.
    # These are source crops, not seamless terrain tiles or a house generator.
    source=Image.open(ROOT/'art-source/civilian-buildings.png').convert('RGBA')
    kit=Image.new('RGBA',(256,128));pieces={}
    for name,rect,size,at in [
        ('timber_door',(123,338,205,462),(54,80),(0,0)),
        ('shutter_window',(110,190,191,287),(54,64),(56,0)),
        ('roof_shingles',(296,89,395,144),(64,36),(112,0)),
        ('timber_wall',(355,237,406,310),(36,48),(178,0)),
        ('stone_foundation',(80,355,126,443),(30,58),(216,0)),
        ('bakery_sign',(24,262,77,310),(36,32),(0,84))]:
        part=source.crop(rect).resize(size,Image.Resampling.NEAREST)
        kit.alpha_composite(part,at);pieces[name]=dict(region=[*at,*size],source_rect=rect)
    kit.save(OUT/'civilian_kit.png');(OUT/'civilian_kit.json').write_text(json.dumps(pieces,indent=2))
    manifest.append(dict(asset='civilian_kit',source='civilian-buildings.png',components=pieces,seamless=False))

if (ROOT/'art-source/occupation-soldiers.png').exists():
    sheet=Image.open(ROOT/'art-source/occupation-soldiers.png').convert('RGBA')
    states=['idle','walk','windup','attack','recover','hurt','death']
    roles=['militia','archer','shield','raider','enforcer']
    roots=[[(145,480),(430,480),(730,490),(1030,485),(1350,490)],[(145,918),(418,916),(715,922),(1010,918),(1323,916)]]
    heads=[[155,155,137,170,105],[600,592,577,600,558]]
    for col,role in enumerate(roles):
        poses=[]
        for row in range(2):
            rect=[(0,0,300,500),(300,0,600,500),(600,0,900,500),(900,0,1220,500),(1220,0,1536,500)][col] if row==0 else [(0,505,320,960),(300,505,600,960),(560,505,965,960),(880,505,1270,960),(1180,505,1536,960)][col]
            part=sheet.crop(rect);part.putalpha(part.getchannel('A').point(lambda a:255 if a>=120 else 0))
            # Trim tiny neighboring edge fragments from overlapping release weapons.
            if row==1 and col in [0,1,2,3,4]:
                # Explicit polygons follow the visible gaps between adjacent figures.
                polygons=[[(0,505),(282,505),(282,650),(320,650),(320,700),(275,720),(275,960),(0,960)],
                  [(300,505),(600,505),(600,690),(575,710),(560,960),(300,960),(300,710),(322,690),(300,645)],
                  [(560,505),(895,505),(895,660),(965,670),(965,710),(870,710),(870,960),(560,960)],
                  [(880,505),(1170,505),(1170,640),(1270,680),(1270,740),(1165,730),(1165,960),(880,960)],
                  [(1180,505),(1536,505),(1536,960),(1180,960),(1180,750),(1240,730),(1240,700),(1180,670)]]
                mask=Image.new('L',part.size);ImageDraw.Draw(mask).polygon([(x-rect[0],y-rect[1]) for x,y in polygons[col]],fill=255)
                import PIL.ImageChops
                part.putalpha(PIL.ImageChops.multiply(part.getchannel('A'),mask))
            part=remove_small_islands(part)
            root=roots[row][col]; scale=(76 if role=='enforcer' else 66)/(root[1]-heads[row][col])
            part=part.resize((round(part.width*scale),round(part.height*scale)),Image.Resampling.NEAREST)
            frame=Image.new('RGBA',(128,128));frame.alpha_composite(part,(round(64-(root[0]-rect[0])*scale),round(116-(root[1]-rect[1])*scale)))
            poses.append(frame)
        unique_frames=[]; frame_lookup={}; state_indices={}
        for row,state in enumerate(states):
            state_indices[state]=[]
            for f in range(8):
                frame=poses[1 if state=='attack' or (state=='recover' and f<3) else 0].copy()
                if state in ['walk','windup','hurt']:
                    dx=([0,1,1,0,0,-1,-1,0][f] if state=='walk' else (-2 if state=='windup' else -3))
                    temp=Image.new('RGBA',frame.size)
                    temp.alpha_composite(frame.crop((0,0,128,98)),(dx,-1 if state=='walk' and f%4 in [1,2] else 0))
                    temp.alpha_composite(frame.crop((0,98,128,128)),(0,98));frame=temp
                if state=='death':
                    # Locally adapted collapse; unique painted death frames remain future art.
                    squashed=frame.resize((128,max(20,128-f*14)),Image.Resampling.NEAREST)
                    frame=Image.new('RGBA',(128,128));frame.alpha_composite(squashed,(0,116-round(116*squashed.height/128)))
                key=frame.tobytes()
                if key not in frame_lookup:
                    frame_lookup[key]=len(unique_frames);unique_frames.append(frame)
                state_indices[state].append(frame_lookup[key])
        atlas=Image.new('RGBA',(512,128*math.ceil(len(unique_frames)/4)))
        for i,frame in enumerate(unique_frames): atlas.alpha_composite(frame,((i%4)*128,(i//4)*128))
        atlas.save(OUT/f'enemy_{role}.png')
        (OUT/f'enemy_{role}.json').write_text(json.dumps(state_indices,indent=2))
        manifest.append(dict(asset='enemy_'+role,cell=[128,128],origin=[64,116],states=state_indices,unique_frames=len(unique_frames),source='occupation-soldiers.png',provisional='Two authored poses. Walk/windup/hurt/collapse are local limited-motion adaptations; eight-direction enemy art is not authored.'))

(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('Pass07 assets:',len(manifest))
