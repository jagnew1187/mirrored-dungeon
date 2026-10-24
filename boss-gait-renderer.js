// Only the selected boss's new gait textures are decoded; combat art stays intact.
const BOSS_GAIT_HEIGHTS={warlord:92,pyro:84,necro:84};
const bossGait={warlord:{},pyro:{},necro:{}},bossGaitLoading={};
function preloadBossGait(kind){
 preloadBossSkills(kind);
 if(typeof BOSS_GAITS==='undefined'||!BOSS_GAITS[kind]||bossGaitLoading[kind])return;
 bossGaitLoading[kind]=true;
 const entry=BOSS_GAITS[kind];
 for(const [direction,source] of Object.entries(entry.images)){
  const image=new Image();image.onload=()=>{
   bossGait[kind][direction]=cacheClassGait(image,entry.frames[direction],kind,direction,BOSS_GAIT_HEIGHTS[kind]*2);
   C.dataset['bossGait'+kind+direction]='ready';image.onload=null;image.onerror=null;image.src='';
  };
  image.onerror=()=>{C.dataset['bossGait'+kind+direction]='failed'};image.src=source;
 }
}
function drawBossGait(kind,x,y,width,height,anim,facing,hit,seed,actor){
 if(drawBossSkill(kind,x,y,width,height,anim,facing,hit,seed,actor))return true;
 if(!bossGait[kind]||(anim!=='walk'&&anim!=='idle'))return false;
 preloadBossGait(kind);
 const direction=actor?.walkDirection||(facing<0?'left':'right'),image=bossGait[kind][direction];if(!image)return false;
 const frame=anim==='idle'?image.gaitData.idleFrame:Math.floor((actor?.walkCycle||0)*8)%8,r=image.gaitData.frames[frame];if(!r)return false;
 const scale=height/119*BOSS_GAIT_HEIGHTS[kind]/image.gaitData.bodyHeight,ground=actor?.r!=null?actor.r*.7-12:8;
 ctx.save();ctx.translate(Math.round(x),Math.round(y+ground));ctx.imageSmoothingEnabled=false;
 if(hit>0)ctx.filter='brightness(1.6) saturate(.65)';
 ctx.drawImage(image,r.x,r.y,r.w,r.h,-r.anchorX*scale,-r.anchorY*scale,r.w*scale,r.h*scale);ctx.restore();return true;
}
