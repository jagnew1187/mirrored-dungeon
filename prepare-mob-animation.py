"""Fit sixteen-pose mob atlases. Read artwork only; retain generated alpha."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parent
directions=['right','southeast','down','southwest','left','northwest','up','northeast']
result={}
for kind in ['cultist','skeleton','acolyte','hound']:
    result[kind]={}
    for direction in directions:
        file=root/'assets'/f'{kind}-motion-{direction}-v1.png'
        if not file.exists():continue
        image=Image.open(file).convert('RGBA');alpha=image.getchannel('A').point(lambda a:255 if a>140 else 0)
        cw,ch=image.width/4,image.height/4
        raw=[]
        for i in range(16):
            cw=image.width/4
            x,y=round(i%4*cw),round(i//4*ch);ex,ey=round((i%4+1)*cw),round((i//4+1)*ch)
            # This source has all sixteen poses, with its last eight arranged 5 + 3.
            # Explicit source rectangles adapt the artwork without changing pixels.
            if kind=='hound' and direction=='southeast' and i>=8:
                if i<13:
                    cw=image.width/5;x=round((i-8)*cw);ex=round((i-7)*cw);y=round(2*ch);ey=round(3*ch)
                else:
                    cw=image.width*.225;x=round(image.width*(.175+(i-13)*.225));ex=round(x+cw);y=round(3*ch);ey=image.height
            left=max(0,round(x-cw*.09));right=min(image.width,round(ex+cw*.09))
            local=alpha.crop((left,y,right,ey));box=local.getbbox();assert box,(kind,direction,i)
            # Start at the dense torso, so stray pixels from adjacent poses are excluded.
            target=(x+cw*.5-left,ch*.53)
            rows=range(max(box[1],round(ch*.35)),min(box[3],round(ch*.75)))
            candidates=[(px,py) for py in rows for px in range(max(box[0],round(x+cw*.25-left)),min(box[2],round(x+cw*.75-left))) if local.getpixel((px,py))]
            if not candidates:
                candidates=[(px,py) for py in range(box[1],box[3]) for px in range(box[0],box[2]) if local.getpixel((px,py))]
            assert candidates,(kind,direction,i,'torso missing')
            seed=min(candidates,key=lambda p:(p[0]-target[0])**2+(p[1]-target[1])**2)
            ImageDraw.floodfill(local,seed,128);local=local.point(lambda a:255 if a==128 else 0);own=local.getbbox()
            # Feet, not weapon tips, define the root. The broad hound region includes all paws.
            lx,rx=(.15,.85) if kind=='hound' else (.28,.72)
            body=local.crop((round(x+cw*lx-left),0,round(x+cw*rx-left),local.height)).getbbox();assert body,(kind,direction,i,'feet')
            baseline=body[3]
            raw.append(dict(x=left+own[0],y=y+own[1],w=own[2]-own[0],h=own[3]-own[1],anchorX=x+cw*.5-left-own[0],anchorY=baseline-own[1]))
            if i==8:
                head_top=own[1]
                if kind=='acolyte':
                    # Register hood height rather than the taller recurved bow/quiver.
                    for py in range(own[1],min(own[3],round(own[1]+ch*.5))):
                        count=0
                        for px in range(round(cw*.25),round(cw*.75)):
                            r,g,b,a=image.getpixel((x+px,y+py))
                            if a>140 and b>r*1.1 and b>g*1.25 and r>g*.8:count+=1
                        if count>cw*.07:
                            head_top=max(own[1],py-round(ch*.025));break
                if kind=='skeleton':
                    # A raised sword can extend above the skull in the standing pose.
                    for py in range(own[1],min(own[3],round(own[1]+ch*.5))):
                        count=0
                        for px in range(round(cw*.25),round(cw*.75)):
                            r,g,b,a=image.getpixel((x+px,y+py))
                            if a>140 and r>100 and g>90 and r>b*1.1:count+=1
                        if count>cw*.08:
                            head_top=max(own[1],py-round(ch*.025));break
                body_height=baseline-head_top
        assert body_height>20,(kind,direction,'body height')
        result[kind][direction]=dict(bodyHeight=body_height,idleFrame=8,frames=raw)
(root/'assets'/'mob-motion-frames-v1.json').write_text(json.dumps(result,indent=2)+'\n')
print('Prepared',sum(len(d) for d in result.values()),'mob direction sheets')
