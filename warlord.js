// Warlord-only architecture. All coordinates are gameplay masks, independent of art.
function warlordArmory(room){
 const props=[];const add=(x,y,w,h,kind,hp=-1)=>props.push({x,y,w,h,kind,hp});
 for(let y=240;y<room.junctionY-180;y+=320){
  add(64,y,72,34,'rack');add(170,y+100,34,42,'dummy');
  add(room.mainX-148,y+80,52,42,'crate',65);
  add(room.mainX+104,y+80,36,44,'barrel',65);
  add(room.rewardX+45,y,34,48,'shield');
 }
 // Opposing fortifications narrow the approach but keep a 192px open spine.
 for(const y of [room.junctionY-520,room.junctionY-1160]){
  add(210,y,room.mainX-306,38,'wall');
  add(room.mainX+96,y,room.wallX-room.mainX-96,38,'wood',90);
 }
 add(room.rewardX+38,room.rewardY+270,36,30,'wood',90);
 add(110,room.startY-100,72,34,'rack');add(190,room.startY-140,34,42,'dummy');
 add(110,room.startY+5,52,42,'crate',65);add(room.rewardX+40,room.junctionY+160,36,44,'barrel',65);
 room.obstacles.push(...props);room.props=props;
}
function warlordArenaMask(){return [
 {x:205,y:265,w:42,h:56,kind:'pillar',hp:-1},
 {x:W-247,y:265,w:42,h:56,kind:'pillar',hp:-1},
 {x:205,y:420,w:42,h:56,kind:'pillar',hp:-1},
 {x:W-247,y:420,w:42,h:56,kind:'pillar',hp:-1}
]}
const warlordTiles=new Map();
const warlordAtlas=new Image();
warlordAtlas.onload=()=>{warlordTiles.clear();C.dataset.warlordTiles='ready'};
if(typeof WARLORD_ATLAS!=='undefined')warlordAtlas.src=WARLORD_ATLAS;
function warlordMaterial(g,panel,x,y,w,h){
 if(!warlordAtlas.complete||!warlordAtlas.naturalWidth)return;
 const sw=warlordAtlas.naturalWidth/2,sh=warlordAtlas.naturalHeight/2;
 g.save();g.imageSmoothingEnabled=false;g.beginPath();g.rect(x,y,w,h);g.clip();
 for(let ty=y;ty<y+h;ty+=128)for(let tx=x;tx<x+w;tx+=128)g.drawImage(warlordAtlas,(panel%2)*sw,Math.floor(panel/2)*sh,sw,sh,tx,ty,128,128);
 g.restore();
}
function warlordFloor(arena){
 const key=arena?'arena':'armory';if(warlordTiles.has(key))return warlordTiles.get(key);
 const c=document.createElement('canvas');c.width=W;c.height=arena?H:512;const g=c.getContext('2d'),rng=seeded(718);
 g.fillStyle='#202830';g.fillRect(0,0,W,c.height);
 for(let y=0;y<c.height;y+=32)for(let x=0;x<W;x+=48){
  const offset=(y/32)%2*24,px=x-offset;g.fillStyle=['#39434c','#35414a','#404a53'][Math.floor(rng()*3)];g.fillRect(px+1,y+1,46,30);
  g.fillStyle='#667077';g.fillRect(px+3,y+3,41,2);g.fillStyle='#18212a';g.fillRect(px+3,y+28,41,2);
  for(let i=0;i<4;i++){g.fillStyle=rng()<.5?'#b1b5ac14':'#00000030';g.fillRect(px+4+Math.floor(rng()*38),y+6+Math.floor(rng()*19),3,2)}
 }
 warlordMaterial(g,arena?3:0,0,0,W,c.height);
 for(const x of [0,W-30])for(let y=0;y<c.height;y+=40){g.fillStyle='#111b25';g.fillRect(x,y,30,40);g.fillStyle='#677078';g.fillRect(x+2,y+2,26,4);g.fillStyle='#3c4853';g.fillRect(x+3,y+7,24,29)}
 if(arena){
  g.fillStyle='#652b36';g.fillRect(W/2-66,112,132,H-138);g.fillStyle='#c69d62';g.fillRect(W/2-66,112,4,H-138);g.fillRect(W/2+62,112,4,H-138);
  warlordMaterial(g,2,W/2-62,112,124,H-138);
  if(!warlordDecorReady()){for(let i=0;i<3;i++){g.fillStyle=['#515861','#636971','#787b7c'][i];g.fillRect(W/2-112+i*12,112-i*12,224-i*24,12)}
  g.fillStyle='#ad8550';g.fillRect(W/2-40,25,80,67);g.fillStyle='#572733';g.fillRect(W/2-29,35,58,47);g.fillStyle='#d8b97c';g.fillRect(W/2-51,79,102,17);}
 }
 warlordTiles.set(key,c);return c;
}
function drawWarlord(){
 const arena=s.phase==='boss',top=cameraY(),floor=warlordFloor(arena);
 if(arena)ctx.drawImage(floor,0,0);else for(let y=Math.floor(top/512)*512;y<top+H;y+=512)ctx.drawImage(floor,0,y);
 if(arena&&warlordDecorReady()){warlordDecor(7,W/2-122,65,244,72);warlordDecor(2,W/2-66,0,132,116)}
 const box=(x,y,w,h,c)=>{ctx.fillStyle=c;ctx.fillRect(Math.round(x),Math.round(y),w,h)};
 for(let y=arena?145:Math.floor(top/240)*240+80;y<top+H;y+=240)for(const x of [44,W-68]){
  if(warlordDecorReady()){warlordDecor(3,x-8,y-6,40,78);warlordDecor(0,x-6,y+61,36,54);warlordLight(x+12,y+75);continue}
  box(x,y,24,60,'#702d3a');box(x+10,y+7,4,35,'#d8b97c');box(x-4,y-5,32,5,'#b29360');
  box(x+7,y+75,10,24,'#644b36');box(x+3,y+69,18,7,'#d0a56b');
  const flicker=Math.floor(s.elapsed*7+y)%3;box(x+5,y+57-flicker,14,16,'#e67e3f');box(x+9,y+54-flicker,6,16,'#ffe7a0');
  ctx.fillStyle='#ffb7530c';ctx.fillRect(x-22,y+36,68,68);
 }
 if(arena)for(const x of [128,W-152]){if(warlordDecorReady()){warlordDecor(1,x-14,64,52,76);warlordLight(x+12,85,1.3);continue}box(x,100,24,32,'#4b4140');box(x-5,96,34,7,'#be9d68');box(x,80,24,17,'#e9823c');box(x+6,72,12,24,'#ffe0a0')}
 if(!arena){const r=s.gauntlet.room;ctx.textAlign='center';ctx.font='bold 16px monospace';ctx.fillStyle='#e6c58a';ctx.fillText('ARMORY ENTRANCE',r.mainX,r.startY+42);}
}
function drawWarlordProp(o){
 if(s.active!=='warlord'||o.hp===0)return;if(['rack','dummy','shield'].includes(o.kind)&&warlordDecorReady())return;if(['wood','crate','barrel','wall','pillar','rubble'].includes(o.kind)&&warlordPropAtlas.complete&&warlordPropAtlas.naturalWidth)return;const x=o.x,y=o.y;
 const b=(a,c,w,h,color)=>{ctx.fillStyle=color;ctx.fillRect(x+a,y+c,w,h)};
 if(['masonry','wall','pillar'].includes(o.kind)){warlordMaterial(ctx,1,x,y,o.w,o.h);b(0,0,o.w,4,'#9da7a2')}
 if(o.kind==='rack'){b(0,0,o.w,o.h,'#4a352b');for(let i=0;i<4;i++){b(7+i*16,3,4,26,'#bdc7c5');b(2+i*16,23,14,3,'#d0ad70')}b(0,0,o.w,5,'#9e7953')}
 if(o.kind==='dummy'){b(14,20,6,22,'#8a6743');b(6,0,22,24,'#aa9060');b(0,13,34,5,'#806445');b(10,5,14,12,'#6f4f3d')}
 if(o.kind==='crate'){b(2,5,o.w-4,o.h-7,'#85603e');for(let i=8;i<o.w;i+=12)b(i,5,2,o.h-7,'#392e28');b(2,6,o.w-4,4,'#b4915e');b(2,o.h-8,o.w-4,4,'#b4915e')}
 if(o.kind==='barrel'){b(4,2,o.w-8,o.h-3,'#8d6841');b(1,10,o.w-2,5,'#899091');b(1,o.h-12,o.w-2,5,'#899091');b(10,3,3,o.h-4,'#b8935c')}
 if(o.kind==='shield'){b(2,0,o.w-4,o.h-6,'#a79974');b(6,4,o.w-12,o.h-14,'#723846');b(o.w/2-2,6,4,o.h-17,'#d6c18b');b(8,16,o.w-16,4,'#d6c18b')}
}
function drawWarlordPath(room,top){
 // A world-anchored repeating runner: scrolling must not slide the weave.
 let runner=warlordTiles.get('runner');
 if(!runner){runner=document.createElement('canvas');runner.width=124;runner.height=128;const g=runner.getContext('2d');
  g.fillStyle='#652b36';g.fillRect(0,0,124,128);warlordMaterial(g,2,4,0,116,128);
  g.fillStyle='#c69d62';g.fillRect(0,0,3,128);g.fillRect(121,0,3,128);
  g.fillStyle='#593c32';g.fillRect(4,0,2,128);g.fillRect(118,0,2,128);warlordTiles.set('runner',runner);
 }
 const start=128,end=room.height-40;ctx.save();ctx.beginPath();ctx.rect(room.mainX-62,start,124,end-start);ctx.clip();
 for(let y=Math.floor(Math.max(top,start)/128)*128;y<Math.min(top+H,end);y+=128)ctx.drawImage(runner,room.mainX-62,y);
 ctx.restore();
}
