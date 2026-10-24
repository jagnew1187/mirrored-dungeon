// Visual skill playback follows the existing simulation-owned 0.78 second clock.
const bossSkills={warlord:{},pyro:{},necro:{}},bossSkillsLoading={};
function preloadBossSkills(kind){
 if(typeof BOSS_SKILLS==='undefined'||!BOSS_SKILLS[kind]||bossSkillsLoading[kind])return;
 bossSkillsLoading[kind]=true;
 for(const [side,source] of Object.entries(BOSS_SKILLS[kind].images)){
  const image=new Image();image.onload=()=>{
   const cached=cacheClassGait(image,BOSS_SKILLS[kind].frames[side],kind,side,BOSS_GAIT_HEIGHTS[kind]*2);
   cached.gaitAnimation='skill';bossSkills[kind][side]=cached;C.dataset['bossSkill'+kind+side]='ready';image.onload=null;image.onerror=null;image.src='';
  };image.onerror=()=>{C.dataset['bossSkill'+kind+side]='failed'};image.src=source;
 }
}
function drawBossSkill(kind,x,y,width,height,anim,facing,hit,seed,actor){
 if(anim!=='skill'||!bossSkills[kind])return false;
 preloadBossSkills(kind);
 const side=(actor?.skillFacing??facing)<0?'left':'right',image=bossSkills[kind][side];if(!image)return false;
 const progress=Math.max(0,Math.min(1,1-(actor?.skillAnim??.78)/.78)),frame=Math.min(8,Math.floor(progress*9)),r=image.gaitData.frames[frame];
 const scale=height/119*BOSS_GAIT_HEIGHTS[kind]/image.gaitData.bodyHeight,ground=actor?.r!=null?actor.r*.7-12:8;
 ctx.save();ctx.translate(Math.round(x),Math.round(y+ground));ctx.imageSmoothingEnabled=false;if(hit>0)ctx.filter='brightness(1.6) saturate(.65)';
 ctx.drawImage(image,r.x,r.y,r.w,r.h,-r.anchorX*scale,-r.anchorY*scale,r.w*scale,r.h*scale);ctx.restore();return true;
}
