// High-detail art only. Rewards and camp collision remain independent of pixels.
const campMaterialAtlas=new Image(),buffArtAtlas=new Image(),campRewardCache=new Map();
campMaterialAtlas.onload=()=>{campRewardCache.clear();journeyCache.delete('camp');C.dataset.campMaterials='ready'};
buffArtAtlas.onload=()=>{
 campRewardCache.clear();C.dataset.buffArt='ready';
 // Existing UI cards may have been created while the atlas was decoding.
 document.querySelectorAll('canvas[data-reward-icon]').forEach(icon=>paintRewardCanvas(icon,icon.dataset.rewardIcon));
};
if(typeof CAMP_MATERIALS!=='undefined')campMaterialAtlas.src=CAMP_MATERIALS;
if(typeof BUFF_ART!=='undefined')buffArtAtlas.src=BUFF_ART;
function campMaterial(frame){
 const key='ground:'+frame;let tile=campRewardCache.get(key);if(tile)return tile;
 tile=document.createElement('canvas');tile.width=tile.height=128;const g=tile.getContext('2d');g.imageSmoothingEnabled=false;
 const iw=campMaterialAtlas.naturalWidth,ih=campMaterialAtlas.naturalHeight;g.drawImage(campMaterialAtlas,frame%2*iw/2,Math.floor(frame/2)*ih/2,iw/2,ih/2,0,0,128,128);campRewardCache.set(key,tile);return tile;
}
function paintCampGround(canvas){
 if(!campMaterialAtlas.naturalWidth)return false;const g=canvas.getContext('2d');g.imageSmoothingEnabled=false;
 g.fillStyle=g.createPattern(campMaterial(0),'repeat');g.fillRect(0,0,W,H);
 // Overlapping translucent rims soften the grass/clearing boundary without per-frame work.
 g.fillStyle=g.createPattern(campMaterial(1),'repeat');
 for(const [size,alpha]of [[1,.28],[.97,.45],[.93,1]]){g.globalAlpha=alpha;g.beginPath();g.ellipse(W/2,H/2,W*.46*size,H*.44*size,0,0,Math.PI*2);g.fill()}g.globalAlpha=1;
 g.fillStyle=g.createPattern(campMaterial(2),'repeat');g.fillRect(W/2-44,H/2+75,88,H/2-75);
 // Leaf-litter perimeter keeps tents grounded in a woodland clearing.
 g.fillStyle=g.createPattern(campMaterial(3),'repeat');g.fillRect(0,0,26,H);g.fillRect(W-26,0,26,H);return true;
}
function buffSprite(frame){
 if(!buffArtAtlas.naturalWidth)return null;const key='buff:'+frame;let tile=campRewardCache.get(key);if(tile)return tile;
 tile=document.createElement('canvas');tile.width=frame<4?96:192;tile.height=frame<4?96:96;const g=tile.getContext('2d');g.imageSmoothingEnabled=false;
 const iw=buffArtAtlas.naturalWidth,ih=buffArtAtlas.naturalHeight,col=frame%3,row=Math.floor(frame/3);
 const sx=Math.round(col*iw/3),sy=Math.round(row*ih/2),ex=Math.round((col+1)*iw/3),ey=Math.round((row+1)*ih/2);
 g.drawImage(buffArtAtlas,sx,sy,ex-sx,ey-sy,0,0,tile.width,tile.height);campRewardCache.set(key,tile);return tile;
}
function drawDetailedReward(g,id,x,y,scale){
 const frame={edge:0,ward:1,crystal:2,surge:3}[id],tile=buffSprite(frame);if(!tile)return false;
 g.save();g.imageSmoothingEnabled=false;g.translate(Math.round(x),Math.round(y));g.scale(scale,scale);g.drawImage(tile,-20,-20,40,40);g.restore();return true;
}
function paintRewardCanvas(icon,id){
 const g=icon.getContext('2d');g.clearRect(0,0,icon.width,icon.height);drawRewardIcon(g,id,40,40,2);
 if(rewardConfig(id).drawback?.amount>0){g.save();g.scale(2,2);drawRiskBadge(g);g.restore()}
}
function drawRewardShrine(){
 const room=s.gauntlet.room,x=room.rewardX,y=room.rewardY,claimed=s.gauntlet.claimed,tile=buffSprite(claimed?5:4);
 if(tile)ctx.drawImage(tile,x-64,y-20,128,64);else{ctx.fillStyle='#37505b';ctx.fillRect(x-62,y-20,124,48)}
 if(claimed)return;s.gauntlet.options.forEach((id,i)=>drawRewardIcon(ctx,id,x-36+i*36,y-13,.8));
 ctx.fillStyle='#ffe0a3';ctx.font='bold 12px monospace';ctx.textAlign='center';ctx.fillText('CHOOSE ONE',x,y+55);
}
