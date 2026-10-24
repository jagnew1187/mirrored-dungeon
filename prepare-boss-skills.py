"""Extract skill frame rectangles and boot anchors; source PNGs stay unchanged."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parent
result={}
for kind in ['warlord','pyro','necro']:
    result[kind]={}
    for side in ['left','right']:
        image=Image.open(root/'assets'/f'{kind}-skill-{side}-v1.png').convert('RGBA')
        alpha=image.getchannel('A').point(lambda a:255 if a>160 else 0)
        cw,ch=image.width/3,image.height/3
        frames=[]
        for i in range(9):
            col,row=i%3,i//3;x,y=round(col*cw),round(row*ch)
            # Narrow body region excludes the axe head and staff tip from boot anchors.
            body=alpha.crop((round(x+cw*.29),y,round(x+cw*.71),round(y+ch))).getbbox()
            assert body,(kind,side,i)
            baseline=y+body[3]
            # Small expanded gutters retain weapons extending beyond nominal grid lines.
            left=max(0,round(x-cw*.055));right=min(image.width,round(x+cw*1.055))
            top=max(0,round(y-ch*.035));bottom=min(image.height,round(y+ch*1.035))
            # Split on transparent gutters, rather than including the next pose's flame.
            for edge in ['top','bottom']:
                nominal=y if edge=='top' else round(y+ch)
                blanks=[py for py in range(max(0,round(nominal-ch*.055)),min(image.height,round(nominal+ch*.055))) if alpha.crop((left,py,right,py+1)).getbbox() is None]
                if blanks:
                    split=min(blanks,key=lambda py:abs(py-nominal))
                    if edge=='top':top=split
                    else:bottom=split
            local=alpha.crop((left,top,right,bottom))
            seed_y=round(y+ch*.55)-top
            candidates=[px for px in range(local.width) if local.getpixel((px,seed_y))]
            assert candidates,(kind,side,i,'torso')
            seed_x=min(candidates,key=lambda px:abs(px-(x+cw*.5-left)))
            ImageDraw.floodfill(local,(seed_x,seed_y),128)
            local=local.point(lambda a:255 if a==128 else 0)
            box=local.getbbox();assert box
            boots=local.crop((round(x+cw*.29)-left,0,round(x+cw*.71)-left,local.height)).getbbox()
            baseline=top+boots[3]
            l,t,r,b=box;l+=left;t+=top;r+=left;b+=top
            frames.append(dict(x=l,y=t,w=r-l,h=b-t,anchorX=x+cw*.5-l,anchorY=baseline-t))
            if i==8:
                head_top=t
                if kind!='warlord':
                    for py in range(t,min(b,round(t+ch*.5))):
                        count=0
                        for px in range(round(x+cw*.25),round(x+cw*.75)):
                            red,green,blue,a=image.getpixel((px,py))
                            hood=(red>green*1.5 and red>blue*1.4 and red<190 and green<70 and blue<90) if kind=='pyro' else (blue>green*1.25 and blue>red*.9 and red>green*.85)
                            if a>160 and hood:count+=1
                        if count>cw*.08:
                            head_top=max(t,py-round(ch*.025));break
                body_height=baseline-head_top
        # Last frame is the neutral recovery pose, with no raised weapon above the head.
        result[kind][side]=dict(bodyHeight=body_height,idleFrame=8,frames=frames)
(root/'assets'/'boss-skill-frames-v1.json').write_text(json.dumps(result,indent=2)+'\n')
print('Prepared six boss skill sheets (54 action frames)')
