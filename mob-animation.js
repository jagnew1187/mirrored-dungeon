// Themed guards, waves, summons and campsite enemies share these four designs.
const MOB_BODY_HEIGHTS={cultist:54,skeleton:54,acolyte:54,hound:38};
const mobArt={cultist:{},skeleton:{},acolyte:{},hound:{}},mobArtLoading={};
function preloadMobArt(kind){
 if(typeof MOB_MOTION==='undefined'||!MOB_MOTION[kind]||mobArtLoading[kind])return;
 mobArtLoading[kind]=true;const entry=MOB_MOTION[kind];
 for(const [direction,source] of Object.entries(entry.images)){
  const image=new Image();image.onload=()=>{
   mobArt[kind][direction]=cacheClassGait(image,entry.frames[direction],kind,direction,MOB_BODY_HEIGHTS[kind]*2);
   mobArt[kind][direction].sourcePixels=entry.sourcePixels[direction];
   C.dataset['mobArt'+kind+direction]='ready';image.onload=null;image.onerror=null;image.src='';
  };image.onerror=()=>{C.dataset['mobArt'+kind+direction]='failed'};image.src=source;
 }
}
function drawMobSprite(kind,x,y,width,height,anim,facing,hit,seed,actor){
 if(!mobArt[kind]||!['idle','walk','attack'].includes(anim))return false;
 preloadMobArt(kind);
 const direction=(anim==='attack'?actor?.attackDirection:null)||actor?.walkDirection||(facing<0?'left':'right'),image=mobArt[kind][direction];if(!image)return false;
 const frame=anim==='idle'?8:anim==='walk'?Math.floor((actor?.walkCycle||0)*8)%8:9+Math.min(6,Math.floor(Math.max(0,Math.min(1,1-(actor?.attackAnim??.45)/.45))*7));
 const r=image.gaitData.frames[frame],scale=height/76*MOB_BODY_HEIGHTS[kind]/image.gaitData.bodyHeight,ground=actor?.r!=null?actor.r*.7-9:0;
 ctx.save();ctx.translate(Math.round(x),Math.round(y+ground));ctx.imageSmoothingEnabled=false;if(hit>0)ctx.filter='brightness(1.6) saturate(.65)';
 ctx.drawImage(image,r.x,r.y,r.w,r.h,-r.anchorX*scale,-r.anchorY*scale,r.w*scale,r.h*scale);ctx.restore();return true;
}
