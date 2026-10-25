// Decorative sprites and warm light only; no movement or projectile masks.
const warlordDecorAtlas=new Image(),warlordDecorCache=new Map();
warlordDecorAtlas.onload=()=>{warlordTiles.clear();C.dataset.warlordDecor='ready'};
if(typeof WARLORD_DECOR!=='undefined')warlordDecorAtlas.src=WARLORD_DECOR;
function warlordDecorReady(){return warlordDecorAtlas.complete&&warlordDecorAtlas.naturalWidth>0}
function warlordDecor(frame,x,y,w,h){
 if(!warlordDecorReady())return false;
 const key=frame+':'+w+':'+h;let tile=warlordDecorCache.get(key);
 if(!tile){tile=document.createElement('canvas');tile.width=w;tile.height=h;const g=tile.getContext('2d');g.imageSmoothingEnabled=false;
  // Hand-fit bounds keep the broad dais and weapon rack isolated from adjacent props.
  const rects=[[0,0,.333,.323],[.333,0,.334,.323],[.667,0,.333,.323],[0,.323,.31,.335],[.31,.323,.35,.335],[.667,.323,.333,.335],[0,.658,.265,.342],[.265,.685,.405,.26],[.67,.658,.33,.342]];
  const [rx,ry,rw,rh]=rects[frame],iw=warlordDecorAtlas.naturalWidth,ih=warlordDecorAtlas.naturalHeight;
  const sx=Math.round(rx*iw),sy=Math.round(ry*ih),ex=Math.round((rx+rw)*iw),ey=Math.round((ry+rh)*ih);
  g.drawImage(warlordDecorAtlas,sx,sy,ex-sx,ey-sy,0,0,w,h);warlordDecorCache.set(key,tile);
 }
 if(frame===3&&!reduceMotion.matches){
  // The fixed hanging point stays aligned to the wall; only the cloth ripples.
  for(let row=0;row<h;row+=3){const height=Math.min(3,h-row),sway=Math.round(Math.sin(s.elapsed*1.6+row*.055)*(row/h)*1.4);ctx.drawImage(tile,0,row,w,height,Math.round(x)+sway,Math.round(y)+row,w,height)}
 }else ctx.drawImage(tile,Math.round(x),Math.round(y));return true;
}
const warlordGlow=document.createElement('canvas');warlordGlow.width=warlordGlow.height=96;
{const g=warlordGlow.getContext('2d'),light=g.createRadialGradient(48,48,3,48,48,48);light.addColorStop(0,'#ffcb6245');light.addColorStop(.4,'#f7962922');light.addColorStop(1,'#f7962900');g.fillStyle=light;g.fillRect(0,0,96,96)}
function warlordLight(x,y,scale=1){
 ctx.save();ctx.globalAlpha=.75+Math.sin(s.elapsed*8+x)*.12+Math.sin(s.elapsed*13+y)*.06;
 ctx.drawImage(warlordGlow,Math.round(x-48*scale),Math.round(y-48*scale),96*scale,96*scale);ctx.restore();
}
function drawWarlordDecorObstacle(o){
 if(s.active!=='warlord'||o.hp===0||!warlordDecorReady())return false;
 const frames={rack:4,dummy:5,shield:6};
 return frames[o.kind]!==undefined&&warlordDecor(frames[o.kind],o.x,o.y,o.w,o.h);
}
