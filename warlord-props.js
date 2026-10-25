// Rendering only: geometry, trap timers and breakable HP remain in world.js.
const warlordPropAtlas=new Image(),warlordPropCache=new Map();
warlordPropAtlas.onload=()=>{warlordPropCache.clear();C.dataset.warlordProps='ready'};
if(typeof WARLORD_PROPS!=='undefined')warlordPropAtlas.src=WARLORD_PROPS;
function warlordPropSprite(frame,x,y,w,h){
 if(!warlordPropAtlas.complete||!warlordPropAtlas.naturalWidth)return false;
 const key=frame+':'+w+':'+h;let tile=warlordPropCache.get(key);
 if(!tile){tile=document.createElement('canvas');tile.width=w;tile.height=h;const g=tile.getContext('2d');g.imageSmoothingEnabled=false;
  // Integer cell edges avoid sampling a neighboring sprite on non-divisible atlas dimensions.
  const col=frame%3,row=Math.floor(frame/3),iw=warlordPropAtlas.naturalWidth,ih=warlordPropAtlas.naturalHeight;
  const sx=Math.round(col*iw/3),sy=Math.round(row*ih/3),ex=Math.round((col+1)*iw/3),ey=Math.round((row+1)*ih/3);
  g.drawImage(warlordPropAtlas,sx,sy,ex-sx,ey-sy,0,0,w,h);warlordPropCache.set(key,tile);
 }
 ctx.drawImage(tile,Math.round(x),Math.round(y));return true;
}
function drawWarlordBarrier(o){
 if(s.active!=='warlord'||!['wood','crate','barrel','wall','pillar','rubble'].includes(o.kind))return false;
 const frame=o.hp===0?5:o.kind==='wood'?(o.hp<=30?4:3):o.kind==='crate'?6:o.kind==='barrel'?7:8;
 if(!warlordPropSprite(frame,o.x,o.y,o.w,o.h))return false;
 if(o.hp>0&&o.hp<=30){ctx.strokeStyle='#d6ac68';ctx.lineWidth=1;ctx.strokeRect(Math.round(o.x)+2,Math.round(o.y)+2,o.w-4,o.h-4)}
 return true;
}
function drawWarlordTrap(h,state){
 if(s.active!=='warlord'||h.kind!=='spike')return false;
 if(!warlordPropSprite(state==='active'?2:state==='warning'?1:0,h.x-24,h.y-24,48,48))return false;
 return true;
}
