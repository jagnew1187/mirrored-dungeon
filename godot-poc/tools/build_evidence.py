"""Assemble comparisons from unchanged running-engine captures, not mockups."""
from pathlib import Path
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]/'tests/pass02'
sheet=Image.new('RGB',(8*210,6*180),(15,24,23));draw=ImageDraw.Draw(sheet)
for row,(hero,action) in enumerate((h,a) for h in ['knight','mage','rogue'] for a in ['walk','attack']):
    sequence=[]
    for i in range(8):
        frame=Image.open(p/f'{hero}-{action}-{i:02d}.png').convert('RGB')
        center=round(430+{'knight':204,'mage':225,'rogue':280}[hero]*(4*(i+1))/60)
        box=(center-95,340,center+115,490) if action=='walk' else (470,245,680,395)
        sheet.paste(frame.crop(box),(i*210,row*180+25))
        draw.text((i*210+6,row*180+5),f'{hero} {action} / {i+1}',fill=(232,214,172))
        sequence.append(frame)
    sequence[0].save(p/f'{hero}-{action}.gif',save_all=True,append_images=sequence[1:],duration=67 if action=='walk' else 34,loop=0)
sheet.save(p/'animation-sheet.png')
print('Six animated runtime sequences and labeled contact sheet created')
