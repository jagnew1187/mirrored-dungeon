// Decorative pixels never participate in collision. world.js owns all solid masks.
const ENVIRONMENTS={
 warlord:{gauntlet:'Armory',arena:'Throne Room',floor:'#283039',tile:'#35414b',accent:'#d6ac68'},
 pyro:{gauntlet:'Lava Cave',arena:'Fire Sanctuary',floor:'#211f28',tile:'#37313a',accent:'#ff9751'},
 necro:{gauntlet:'Halls of the Dead',arena:'Crypt',floor:'#19292c',tile:'#2b4143',accent:'#88d9ba'}
};
const environmentCache=new Map();
function environmentArt(id,arena=false){
 const key=id+':'+arena;if(environmentCache.has(key))return environmentCache.get(key);
 const p=ENVIRONMENTS[id],c=document.createElement('canvas');c.width=W;c.height=arena?H:512;const g=c.getContext('2d');
 const box=(x,y,w,h,color)=>{g.fillStyle=color;g.fillRect(Math.round(x),Math.round(y),w,h)};
 box(0,0,W,c.height,p.floor);
 for(let y=0;y<c.height;y+=32)for(let x=0;x<W;x+=32){box(x+1,y+1,30,30,p.tile);box(x+4,y+4,23,2,'#ffffff08');if((x/32+y/32)%5===0)box(x+17,y+18,10,2,'#00000030')}
 for(const side of [0,1]){const x=side?W-92:24;
  for(let y=arena?160:40;y<c.height-50;y+=160){
   box(x-4,y+6,68,78,'#00000055');
   if(id==='warlord'){
    box(x,y,60,10,'#8b6849');box(x,y+58,60,8,'#8b6849');
    for(let i=0;i<3;i++){box(x+9+i*18,y+12,4,44,'#c2c8c5');box(x+4+i*18,y+40,14,4,p.accent)}
    box(x+16,y+85,30,40,'#7b3440');box(x+29,y+88,4,28,p.accent);
   }else if(id==='pyro'){
    box(x,y,60,72,'#141820');box(x+4,y+10,44,9,'#5b342e');
    for(let i=0;i<4;i++){box(x+8+i*11,y+20+i*8,10,20,'#c94b32');box(x+10+i*11,y+23+i*8,4,14,p.accent)}
   }else{
    box(x,y,60,72,'#526363');box(x+6,y+8,48,58,'#101d25');box(x+20,y+22,20,18,'#b2ba9b');box(x+23,y+28,5,5,'#16252b');box(x+33,y+28,5,5,'#16252b');box(x+24,y+42,12,10,'#7a8980');
   }
  }
 }
 if(arena){
  // Outer dressing leaves the combat floor and every original spawn unobstructed.
  box(W/2-96,78,192,40,'#101820');box(W/2-90,80,180,4,p.accent);
  if(id==='warlord'){box(W/2-35,20,70,66,'#96724d');box(W/2-27,28,54,48,'#6c3040');box(W/2-46,68,92,18,'#d1a365');box(W/2-42,86,12,20,'#96724d');box(W/2+30,86,12,20,'#96724d');box(W/2-58,116,116,H-160,'#67333b55')}
  if(id==='pyro'){g.strokeStyle=p.accent+'55';g.lineWidth=4;for(const radius of [90,150]){g.beginPath();g.arc(W/2,H/2,radius,0,Math.PI*2);g.stroke()}box(W/2-40,28,80,56,'#544049');box(W/2-18,20,36,45,'#e16a38');box(W/2-8,13,16,40,'#ffcf7e')}
  if(id==='necro'){box(W/2-42,24,84,66,'#64726d');box(W/2-34,30,68,52,'#344c4a');box(W/2-3,36,6,37,p.accent);box(W/2-16,45,32,5,p.accent);g.strokeStyle=p.accent+'38';g.lineWidth=3;g.strokeRect(W/2-120,170,240,H-350)}
 }
 environmentCache.set(key,c);return c;
}
function drawThemedEnvironment(){
 const id=s.active;if(!ENVIRONMENTS[id]||!['gauntlet','boss'].includes(s.phase))return;
 if(id==='warlord'){drawWarlord();return}
 const arena=s.phase==='boss',art=environmentArt(id,arena),top=cameraY();
 if(arena)ctx.drawImage(art,0,0);else{for(let y=Math.floor(top/512)*512;y<top+H;y+=512)ctx.drawImage(art,0,y)}
 ctx.fillStyle='#0b1423dd';ctx.fillRect(W/2-132,top+12,264,29);ctx.fillStyle=ENVIRONMENTS[id].accent;ctx.font='bold 16px monospace';ctx.textAlign='center';ctx.fillText(ENVIRONMENTS[id][arena?'arena':'gauntlet'].toUpperCase(),W/2,top+32);
}
