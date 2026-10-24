// Mage/Rogue directional gait art is decoded once into compact 2x game atlases.
const classGait={mage:{},rogue:{}};
function cacheClassGait(image,data,cls,direction,targetBody=144){
 const factor=Math.min(1,targetBody/data.bodyHeight),atlas=document.createElement('canvas');
 atlas.width=Math.max(1,Math.round(image.naturalWidth*factor));atlas.height=Math.max(1,Math.round(image.naturalHeight*factor));
 const g=atlas.getContext('2d');g.imageSmoothingEnabled=false;g.drawImage(image,0,0,atlas.width,atlas.height);
 const sx=atlas.width/image.naturalWidth,sy=atlas.height/image.naturalHeight;
 atlas.gaitData={bodyHeight:data.bodyHeight*sy,idleFrame:data.idleFrame,frames:data.frames.map(r=>{
  const x=Math.round(r.x*sx),y=Math.round(r.y*sy),ex=Math.round((r.x+r.w)*sx),ey=Math.round((r.y+r.h)*sy);
  return{x,y,w:ex-x,h:ey-y,anchorX:(r.x+r.anchorX)*sx-x,anchorY:(r.y+r.anchorY)*sy-y};
 })};
 atlas.heroKey=cls+'-gait-'+direction;atlas.gaitClass=cls;atlas.gaitDirection=direction;
 atlas.sourcePixels=image.naturalWidth*image.naturalHeight;
 return atlas;
}
if(typeof HERO_CLASS_GAITS!=='undefined')for(const [cls,entry] of Object.entries(HERO_CLASS_GAITS))for(const [direction,source] of Object.entries(entry.images)){
 const image=new Image();image.onload=()=>{
  classGait[cls][direction]=cacheClassGait(image,entry.frames[direction],cls,direction);
  C.dataset[cls+'Gait'+direction]='ready';image.onload=null;image.onerror=null;image.src='';
 };
 image.onerror=()=>{C.dataset[cls+'Gait'+direction]='failed'};image.src=source;
}
function drawClassGait(cls,x,y,height,anim,facing,hit,actor){
 const direction=actor?.walkDirection||(facing<0?'left':'right'),image=classGait[cls]?.[direction];if(!image)return false;
 const frame=anim==='idle'?image.gaitData.idleFrame:animationIndex(cls,'walk',actor),r=image.gaitData.frames[frame];if(!r)return false;
 const scale=height*.88*HERO_WORLD_SCALE/image.gaitData.bodyHeight;
 ctx.save();ctx.translate(Math.round(x),Math.round(y));ctx.imageSmoothingEnabled=false;
 if(hit>0)ctx.filter='brightness(1.6) saturate(.65)';
 ctx.drawImage(image,r.x,r.y,r.w,r.h,-r.anchorX*scale,-r.anchorY*scale,r.w*scale,r.h*scale);ctx.restore();return true;
}
