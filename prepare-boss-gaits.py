"""Fit generated boss walk/stand sheets; never modify source artwork."""
import json
import statistics
from pathlib import Path
from PIL import Image, ImageDraw

root=Path(__file__).resolve().parent
manifest=json.loads((root/'assets'/'boss-gait-art.json').read_text())
result={}
for boss,directions in manifest.items():
    result[boss]={}
    for direction,spec in directions.items():
        image=Image.open(root/'assets'/spec['file']).convert('RGBA')
        frames,heights=[],[]
        for frame in range(9):
            x,ex=round(frame%3*image.width/3),round((frame%3+1)*image.width/3)
            y,ey=round(frame//3*image.height/3),round((frame//3+1)*image.height/3)
            cell=image.crop((x,y,ex,ey));mask=cell.getchannel('A').point(lambda a:255 if a>150 else 0)
            box=mask.getbbox();assert box,(boss,direction,frame)
            height=box[3]-box[1];head_top=box[1]
            if boss in ['pyro','necro']:
                pixels=cell.load();rows={}
                for py in range(box[1],min(box[3],box[1]+round(height*.6))):
                    points=[]
                    for px in range(box[0],box[2]):
                        r,g,b,a=pixels[px,py]
                        hood=(r>g*1.5 and r>b*1.4 and r<190 and g<70 and b<90) if boss=='pyro' else (b>g*1.25 and b>r*.9 and r>g*.85)
                        if a>150 and hood:points.append(px)
                    rows[py]=points
                dense=next((py for py,points in rows.items() if len(points)>height*.09),None)
                assert dense is not None,('hood not found',boss,direction,frame)
                head_top=max(box[1],dense-round(height*.035))
                points=[px for py,points in rows.items() if dense<=py<dense+height*.18 for px in points]
                center=(min(points)+max(points))/2
            else:
                head=mask.crop((0,box[1],ex-x,box[1]+max(3,round(height*.17)))).getbbox()
                center=(head[0]+head[2])/2
            seed_y=min(ey-y-1,round(head_top+height*.1))
            candidates=[px for px in range(ex-x) if mask.getpixel((px,seed_y))]
            if not candidates:
                seed_y=min((py for py in range(box[1],box[3]) if any(mask.getpixel((px,py)) for px in range(ex-x))),key=lambda py:abs(py-seed_y))
                candidates=[px for px in range(ex-x) if mask.getpixel((px,seed_y))]
            seed_x=min(candidates,key=lambda px:abs(px-center));component=mask.copy()
            ImageDraw.floodfill(component,(seed_x,seed_y),128)
            component=component.point(lambda a:255 if a==128 else 0);own=component.getbbox()
            body=component.crop((max(0,round(center-height*.3)),box[1],min(ex-x,round(center+height*.3)),box[3])).getbbox()
            assert body,(boss,direction,frame)
            baseline=box[1]+body[3];heights.append(baseline-head_top)
            # Include the top flame/skull even when a tiny alpha gap detaches it.
            left=max(0,min(own[0],box[0])-2);top=max(0,min(own[1],box[1])-2)
            right=min(ex-x,max(own[2],box[2])+2);bottom=min(ey-y,own[3]+2,baseline+3)
            if boss=='warlord':
                left=max(0,own[0]-2);top=max(0,own[1]-2);right=min(ex-x,own[2]+2)
            frames.append(dict(x=x+left,y=y+top,w=right-left,h=bottom-top,anchorX=center-left,anchorY=baseline-top))
        result[boss][direction]=dict(bodyHeight=statistics.median(heights),idleFrame=8,frames=frames)
(root/'assets'/'boss-gait-frames-v2.json').write_text(json.dumps(result,indent=2)+'\n')
print('Prepared eight-direction walking and standing metadata for all three bosses')
