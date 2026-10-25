// Necromancer art and architecture. Pixels are never consulted for collision.
function necroHall(room){
 for(let y=240;y<room.height-100;y+=400)for(const p of [
  {x:72,y,w:76,h:54,kind:'tomb'},
  {x:190,y:y+120,w:36,h:52,kind:'statue'},
  {x:room.mainX+100,y:y+100,w:42,h:48,kind:'coffin',hp:65}
 ]){
  p.hp??=-1;
  if(!room.obstacles.some(o=>o.hp!==0&&p.x<o.x+o.w+12&&p.x+p.w+12>o.x&&p.y<o.y+o.h+12&&p.y+p.h+12>o.y))room.obstacles.push(p);
 }
}
function necroArenaMask(){return [205,W-253].flatMap(x=>[265,420].map(y=>({x,y,w:48,h:58,kind:'pillar',hp:-1})))}
const necroMaterialAtlas=new Image(),necroPropAtlas=new Image(),necroCache=new Map();
function necroAssetReady(){return necroMaterialAtlas.naturalWidth>0&&necroPropAtlas.naturalWidth>0}
function necroLoaded(){necroCache.clear();if(necroAssetReady())C.dataset.necroAssets='ready'}
necroMaterialAtlas.onload=necroLoaded;necroPropAtlas.onload=necroLoaded;
if(typeof NECRO_MATERIALS!=='undefined')necroMaterialAtlas.src=NECRO_MATERIALS;
if(typeof NECRO_PROPS!=='undefined')necroPropAtlas.src=NECRO_PROPS;
function necroSprite(frame,x,y,w,h,g=ctx){
 if(!necroPropAtlas.naturalWidth)return false;const key='prop:'+frame+':'+w+':'+h;let tile=necroCache.get(key);
 if(!tile){tile=document.createElement('canvas');tile.width=w;tile.height=h;const t=tile.getContext('2d');t.imageSmoothingEnabled=false;
  const iw=necroPropAtlas.naturalWidth,ih=necroPropAtlas.naturalHeight;
  // Fit to actual silhouettes: generated rows and the broad sarcophagus differ from a perfect grid.
  const rects=[[0,0,.333,.222],[.333,0,.334,.222],[.667,0,.333,.222],[0,.228,.333,.27],[.333,.228,.334,.27],[.667,.23,.333,.25],[0,.50,.30,.24],[.30,.53,.42,.237],[.77,.48,.21,.29],[0,.74,.29,.26],[.29,.80,.335,.20],[.625,.765,.375,.235]];
  const [rx,ry,rw,rh]=rects[frame],sx=Math.round(rx*iw),sy=Math.round(ry*ih),ex=Math.round((rx+rw)*iw),ey=Math.round((ry+rh)*ih);
  t.drawImage(necroPropAtlas,sx,sy,ex-sx,ey-sy,0,0,w,h);necroCache.set(key,tile);
 }g.drawImage(tile,Math.round(x),Math.round(y));return true;
}
function necroMaterial(frame){
 const key='material:'+frame;let tile=necroCache.get(key);if(tile)return tile;
 tile=document.createElement('canvas');tile.width=tile.height=128;const g=tile.getContext('2d');g.imageSmoothingEnabled=false;g.fillStyle='#23373a';g.fillRect(0,0,128,128);
 if(necroMaterialAtlas.naturalWidth){const iw=necroMaterialAtlas.naturalWidth,ih=necroMaterialAtlas.naturalHeight;g.drawImage(necroMaterialAtlas,(frame%2)*iw/2,Math.floor(frame/2)*ih/2,iw/2,ih/2,0,0,128,128)}
 necroCache.set(key,tile);return tile;
}
function necroFill(g,frame,x,y,w,h){
 if(h<=0||w<=0)return;g.save();g.beginPath();g.rect(x,y,w,h);g.clip();
 const tile=necroMaterial(frame);for(let ty=Math.floor(y/128)*128;ty<y+h;ty+=128)for(let tx=frame===2?x:Math.floor(x/128)*128;tx<x+w;tx+=128)g.drawImage(tile,tx,ty);g.restore();
}
function necroFloor(arena){
 const key=arena?'crypt':'hall';let c=necroCache.get(key);if(c)return c;
 c=document.createElement('canvas');c.width=W;c.height=arena?H:512;const g=c.getContext('2d');g.imageSmoothingEnabled=false;
 necroFill(g,arena?3:0,0,0,W,c.height);for(const x of [0,W-30])necroFill(g,1,x,0,30,c.height);
 if(arena){necroFill(g,2,W/2-62,130,124,H-160);g.strokeStyle='#87ad9b';g.lineWidth=3;g.strokeRect(W/2-64,130,128,H-160);
  necroSprite(7,W/2-68,8,136,106,g);necroSprite(11,76,76,110,65,g);necroSprite(11,W-186,76,110,65,g);
 }
 necroCache.set(key,c);return c;
}
const necroGlow=document.createElement('canvas');necroGlow.width=necroGlow.height=96;
{const g=necroGlow.getContext('2d'),r=g.createRadialGradient(48,48,3,48,48,48);r.addColorStop(0,'#9bffd440');r.addColorStop(.5,'#58cda51c');r.addColorStop(1,'#58cda500');g.fillStyle=r;g.fillRect(0,0,96,96)}
function drawNecro(){
 const arena=s.phase==='boss',top=cameraY(),floor=necroFloor(arena);
 if(arena)ctx.drawImage(floor,0,0);else for(let y=Math.floor(top/512)*512;y<top+H;y+=512)ctx.drawImage(floor,0,y);
 for(let y=arena?150:Math.floor(top/240)*240+70;y<top+H;y+=240)for(const x of [44,W-82]){
  necroSprite(6,x,y,38,64);ctx.save();ctx.globalAlpha=.75+Math.sin(s.elapsed*5+y)*.15;ctx.drawImage(necroGlow,x-29,y-28);ctx.restore();
 }
 if(!arena){const room=s.gauntlet.room;ctx.fillStyle='#b3dac7';ctx.font='bold 15px monospace';ctx.textAlign='center';ctx.fillText('HALLS OF THE DEAD',room.mainX,room.startY+42);}
}
function drawNecroPath(room,top){
 const start=128,end=room.height-40;necroFill(ctx,2,room.mainX-62,Math.max(start,top),124,Math.min(end,top+H)-Math.max(start,top));
 ctx.fillStyle='#87ad9b';for(const x of [room.mainX-62,room.mainX+60])ctx.fillRect(x,Math.max(start,top),2,Math.max(0,Math.min(end,top+H)-Math.max(start,top)));
 // The optional wing remains burial stone so the direct ceremonial route reads clearly.
}
function drawNecroObstacle(o,top){
 if(s.active!=='necro'||!necroAssetReady())return false;
 if(o.kind==='masonry'){necroFill(ctx,1,o.x,Math.max(o.y,top),o.w,Math.min(o.y+o.h,top+H)-Math.max(o.y,top));return true}
 const frame=o.hp===0?5:['wood','coffin'].includes(o.kind)?o.hp<=30?4:3:o.kind==='pillar'?9:o.kind==='rubble'?10:o.kind==='statue'?8:7;
 return necroSprite(frame,o.x,o.y,o.w,o.h);
}
function drawNecroTrap(h,state){
 if(s.active!=='necro'||h.kind!=='rune'||!necroAssetReady())return false;
 necroSprite(state==='active'?2:state==='warning'?1:0,h.x-24,h.y-24,48,48);
 return true;
}
