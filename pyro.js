// Pyromancer art and architecture. Pixels are never consulted for collision.
function pyroHall(room){
 for(let y=240;y<room.height-100;y+=400)for(const p of [
  {x:72,y,w:76,h:54,kind:'altar'},
  {x:190,y:y+120,w:36,h:52,kind:'obsidian'},
  {x:room.mainX+100,y:y+100,w:42,h:48,kind:'barricade',hp:65}
 ]){
  p.hp??=-1;
  if(!room.obstacles.some(o=>o.hp!==0&&p.x<o.x+o.w+12&&p.x+p.w+12>o.x&&p.y<o.y+o.h+12&&p.y+p.h+12>o.y))room.obstacles.push(p);
 }
}
function pyroArenaMask(){return [205,W-253].flatMap(x=>[265,420].map(y=>({x,y,w:48,h:58,kind:'pillar',hp:-1})))}
const pyroMaterialAtlas=new Image(),pyroPropAtlas=new Image(),pyroCache=new Map();
function pyroAssetReady(){return pyroMaterialAtlas.naturalWidth>0&&pyroPropAtlas.naturalWidth>0}
function pyroLoaded(){pyroCache.clear();if(pyroAssetReady())C.dataset.pyroAssets='ready'}
pyroMaterialAtlas.onload=pyroLoaded;pyroPropAtlas.onload=pyroLoaded;
if(typeof PYRO_MATERIALS!=='undefined')pyroMaterialAtlas.src=PYRO_MATERIALS;
if(typeof PYRO_PROPS!=='undefined')pyroPropAtlas.src=PYRO_PROPS;
function pyroSprite(frame,x,y,w,h,g=ctx){
 if(!pyroPropAtlas.naturalWidth)return false;const key='prop:'+frame+':'+w+':'+h;let tile=pyroCache.get(key);
 if(!tile){tile=document.createElement('canvas');tile.width=w;tile.height=h;const t=tile.getContext('2d');t.imageSmoothingEnabled=false;
  const iw=pyroPropAtlas.naturalWidth,ih=pyroPropAtlas.naturalHeight;
  // Fit to actual silhouettes: generated rows and the broad altar differ from a perfect grid.
  const rects=[[0,0,.333,.22],[.333,0,.334,.22],[.667,0,.333,.22],[0,.25,.333,.20],[.333,.25,.334,.20],[.667,.30,.333,.15],[0,.46,.30,.24],[.31,.46,.39,.245],[.72,.46,.28,.25],[0,.70,.29,.30],[.29,.80,.41,.20],[.72,.70,.28,.30]];
  const [rx,ry,rw,rh]=rects[frame],sx=Math.round(rx*iw),sy=Math.round(ry*ih),ex=Math.round((rx+rw)*iw),ey=Math.round((ry+rh)*ih);
  t.drawImage(pyroPropAtlas,sx,sy,ex-sx,ey-sy,0,0,w,h);pyroCache.set(key,tile);
 }g.drawImage(tile,Math.round(x),Math.round(y));return true;
}
function pyroMaterial(frame){
 const key='material:'+frame;let tile=pyroCache.get(key);if(tile)return tile;
 tile=document.createElement('canvas');tile.width=tile.height=128;const g=tile.getContext('2d');g.imageSmoothingEnabled=false;g.fillStyle='#2c2729';g.fillRect(0,0,128,128);
 if(pyroMaterialAtlas.naturalWidth){const iw=pyroMaterialAtlas.naturalWidth,ih=pyroMaterialAtlas.naturalHeight;g.drawImage(pyroMaterialAtlas,(frame%2)*iw/2,Math.floor(frame/2)*ih/2,iw/2,ih/2,0,0,128,128)}
 pyroCache.set(key,tile);return tile;
}
function pyroFill(g,frame,x,y,w,h){
 if(h<=0||w<=0)return;g.save();g.beginPath();g.rect(x,y,w,h);g.clip();
 const tile=pyroMaterial(frame);for(let ty=Math.floor(y/128)*128;ty<y+h;ty+=128)for(let tx=frame===2?x:Math.floor(x/128)*128;tx<x+w;tx+=128)g.drawImage(tile,tx,ty);g.restore();
}
function pyroFloor(arena){
 const key=arena?'sanctuary':'hall';let c=pyroCache.get(key);if(c)return c;
 c=document.createElement('canvas');c.width=W;c.height=arena?H:512;const g=c.getContext('2d');g.imageSmoothingEnabled=false;
 pyroFill(g,arena?3:0,0,0,W,c.height);for(const x of [0,W-30])pyroFill(g,1,x,0,30,c.height);
 if(arena){g.strokeStyle='#ba794f';g.lineWidth=3;for(const radius of [108,154]){g.beginPath();g.arc(W/2,H/2,radius,0,Math.PI*2);g.stroke()}g.fillStyle='#e7a66a';for(let i=0;i<8;i++){const angle=i*Math.PI/4;g.fillRect(Math.round(W/2+132*Math.cos(angle))-3,Math.round(H/2+132*Math.sin(angle))-3,6,6)}
  pyroSprite(7,W/2-68,8,136,106,g);pyroSprite(11,76,76,110,65,g);pyroSprite(11,W-186,76,110,65,g);
 }
 pyroCache.set(key,c);return c;
}
const pyroGlow=document.createElement('canvas');pyroGlow.width=pyroGlow.height=96;
{const g=pyroGlow.getContext('2d'),r=g.createRadialGradient(48,48,3,48,48,48);r.addColorStop(0,'#ffbf6840');r.addColorStop(.5,'#ff7b301c');r.addColorStop(1,'#ff7b3000');g.fillStyle=r;g.fillRect(0,0,96,96)}
function drawPyro(){
 const arena=s.phase==='boss',top=cameraY(),floor=pyroFloor(arena);
 if(arena)ctx.drawImage(floor,0,0);else for(let y=Math.floor(top/512)*512;y<top+H;y+=512)ctx.drawImage(floor,0,y);
 for(let y=arena?150:Math.floor(top/240)*240+70;y<top+H;y+=240)for(const x of [44,W-82]){
  pyroSprite(6,x,y,38,64);ctx.save();ctx.globalAlpha=.75+Math.sin(s.elapsed*5+y)*.15;ctx.drawImage(pyroGlow,x-29,y-28);ctx.restore();
 }
 if(!arena){const room=s.gauntlet.room;ctx.fillStyle='#e8bb8d';ctx.font='bold 15px monospace';ctx.textAlign='center';ctx.fillText('LAVA CAVE',room.mainX,room.startY+42);}
}
function drawPyroPath(room,top){
 const start=128,end=room.height-40;pyroFill(ctx,2,room.mainX-62,Math.max(start,top),124,Math.min(end,top+H)-Math.max(start,top));
 ctx.fillStyle='#b78860';for(const x of [room.mainX-62,room.mainX+60])ctx.fillRect(x,Math.max(start,top),2,Math.max(0,Math.min(end,top+H)-Math.max(start,top)));
 // The optional wing remains volcanic stone so the direct ceremonial route reads clearly.
}
function drawPyroObstacle(o,top){
 if(s.active!=='pyro'||!pyroAssetReady())return false;
 if(o.kind==='masonry'){pyroFill(ctx,1,o.x,Math.max(o.y,top),o.w,Math.min(o.y+o.h,top+H)-Math.max(o.y,top));return true}
 const frame=o.hp===0?5:['wood','barricade'].includes(o.kind)?o.hp<=30?4:3:o.kind==='pillar'?9:o.kind==='rubble'?10:o.kind==='obsidian'?8:7;
 return pyroSprite(frame,o.x,o.y,o.w,o.h);
}
function drawPyroTrap(h,state){
 if(s.active!=='pyro'||!['fire','burn'].includes(h.kind)||!pyroAssetReady())return false;
 pyroSprite(state==='active'?2:state==='warning'?1:0,h.x-24,h.y-24,48,48);
 return true;
}
