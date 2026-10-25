// Narrative cues and campsite dressing do not change routes, gates or collision masks.
const journeyAtlas=new Image(),journeyCache=new Map();
const campPavilion=new Image();
campPavilion.onload=()=>{C.dataset.campPavilion='ready'};
if(typeof CAMP_PAVILION!=='undefined')campPavilion.src=CAMP_PAVILION;
// Golden-section anchors create an offset focal point and unequal camp clusters.
// These are visual/home positions only; the clearing stays fully walkable.
const CAMP_PHI=(Math.sqrt(5)-1)/2;
const CAMP_LAYOUT={
 fire:{x:Math.round(W*CAMP_PHI),y:Math.round(H*CAMP_PHI)},
 tents:[{x:W*(1-CAMP_PHI)**1.5,y:H*(1-CAMP_PHI)**1.5,w:186,h:144},
        {x:W*(1-(1-CAMP_PHI)**1.5),y:H*(1-CAMP_PHI),w:180,h:162,pavilion:true}],
 supplies:[{x:W*(1-CAMP_PHI)**2,y:H*.49,w:104,h:70},
           {x:W*.81,y:H*CAMP_PHI,w:88,h:60}],
 table:{x:W*.27,y:H*.73,w:148,h:90}
};
journeyAtlas.onload=()=>{journeyCache.clear();C.dataset.journeyAssets='ready'};
if(typeof JOURNEY_ATLAS!=='undefined')journeyAtlas.src=JOURNEY_ATLAS;
function journeySprite(frame,x,y,w,h){
 if(!journeyAtlas.naturalWidth)return false;const key=frame+':'+w+':'+h;let tile=journeyCache.get(key);
 if(!tile){tile=document.createElement('canvas');tile.width=w;tile.height=h;const g=tile.getContext('2d');g.imageSmoothingEnabled=false;
  const iw=journeyAtlas.naturalWidth,ih=journeyAtlas.naturalHeight;
  // Entrances occupy a taller row than camp props in the generated sheet.
  const rects=[[0,0,.346,.405],[.35,0,.31,.405],[.665,0,.335,.405],[0,.45,.333,.25],[.36,.49,.25,.22],[.635,.425,.365,.29],[0,.71,.333,.275],[.35,.755,.31,.22],[.665,.73,.335,.27]];
  const [rx,ry,rw,rh]=rects[frame],sx=Math.round(rx*iw),sy=Math.round(ry*ih),ex=Math.round((rx+rw)*iw),ey=Math.round((ry+rh)*ih);
  g.drawImage(journeyAtlas,sx,sy,ex-sx,ey-sy,0,0,w,h);journeyCache.set(key,tile);
 }ctx.drawImage(tile,Math.round(x),Math.round(y));return true;
}
const JOURNEY_LINES={warlord:['You have to stop him.','The royal arch leads to his throne.'],necro:['Stop him before more dead rise.','His crypt lies at the end of this path.'],pyro:['You have to stop the flames.','Find him beyond the carved pillars.']};
function journeyBubble(x,y,lines){
 ctx.save();ctx.font='bold 13px monospace';const width=Math.min(340,Math.max(...lines.map(t=>ctx.measureText(t).width))+20),left=clamp(x-width/2,34,W-width-34);
 ctx.fillStyle='#101d28ef';ctx.fillRect(left,y,width,lines.length*19+14);ctx.strokeStyle='#b7a383';ctx.lineWidth=1;ctx.strokeRect(left,y,width,lines.length*19+14);
 ctx.textAlign='left';lines.forEach((line,i)=>{ctx.fillStyle=i===0?'#f2d5a0':'#c4cdd1';ctx.fillText(line,left+10,y+20+i*19)});ctx.restore();
}
function drawJourneyCues(){
 if(s.phase!=='gauntlet')return;const r=s.gauntlet.room,top=cameraY(),sy=r.startY-40;
 const frame=r.id==='warlord'?0:r.id==='necro'?1:2;
 if(top<220)journeySprite(frame,r.mainX-110,0,220,190);
 if(sy>top-100&&sy<top+H+100){journeySprite(3,r.mainX-162,sy-44,64,76);
  if(Math.abs(s.hero.y-sy)<230)journeyBubble(r.mainX+15,sy-132,[...JOURNEY_LINES[r.id],'Supplies lie east, but guards hold them.']);
 }
 // A guarded cache on the branch and worn tracks toward the entrance replace floor labels.
 if(!s.gauntlet.claimed)journeySprite(4,r.wallX+38,r.junctionY+146,48,42);
 ctx.fillStyle='#c3bc9a48';
 for(let y=260;y<r.startY-230;y+=220)if(y>top&&y<top+H){ctx.fillRect(r.mainX-9,y,5,10);ctx.fillRect(r.mainX+3,y+15,5,10)}
}
function campGround(){
 let tile=journeyCache.get('camp');if(tile)return tile;
 tile=document.createElement('canvas');tile.width=W;tile.height=H;if(paintCampGround(tile)){journeyCache.set('camp',tile);return tile}const g=tile.getContext('2d'),rng=seeded(7331);
 g.fillStyle='#2a342d';g.fillRect(0,0,W,H);
 for(let y=0;y<H;y+=8)for(let x=0;x<W;x+=8){const clearing=((x-W*.53)/(W*.45))**2+((y-H*.53)/(H*.44))**2<1;
  g.fillStyle=clearing?['#484036','#514638','#3e3b32'][Math.floor(rng()*3)]:['#253a31','#304238','#26362f'][Math.floor(rng()*3)];g.fillRect(x,y,8,8);
  if(rng()<.15){g.fillStyle=clearing?'#85765b':'#667652';g.fillRect(x+2,y+3,3,2)}
 }journeyCache.set('camp',tile);return tile;
}
function drawHeroCamp(){
 if(s.phase!=='vault')return;ctx.save();ctx.imageSmoothingEnabled=false;ctx.drawImage(campGround(),0,0);
 for(const tent of CAMP_LAYOUT.tents){
  const x=Math.round(tent.x-tent.w/2),y=Math.round(tent.y-tent.h/2);
  if(tent.pavilion&&campPavilion.naturalWidth)ctx.drawImage(campPavilion,x,y,tent.w,tent.h);else journeySprite(5,x,y,tent.w,tent.h);
 }
 for(const pack of CAMP_LAYOUT.supplies)journeySprite(7,pack.x-pack.w/2,pack.y-pack.h/2,pack.w,pack.h);
 const table=CAMP_LAYOUT.table,fire=CAMP_LAYOUT.fire;
 journeySprite(8,table.x-table.w/2,table.y-table.h/2,table.w,table.h);journeySprite(6,fire.x-53,fire.y-58,106,112);
 ctx.globalAlpha=.65+Math.sin(s.elapsed*7)*.12;ctx.drawImage(warlordGlow,fire.x-78,fire.y-80,156,156);ctx.globalAlpha=1;
 drawCampCompanions();
 ctx.fillStyle='#e8c58d';ctx.font='bold 18px Georgia';ctx.textAlign='center';if(!s.lobby)ctx.fillText('HEROES’ CAMP',W/2,42);ctx.restore();
}
