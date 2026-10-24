// Camp companions help with ordinary waves only; they never enter dungeon combat.
function campCompanions(){
 if(!s.campFriends)s.campFriends=['mage','knight','rogue'].filter(cls=>cls!==selectedClass).map((cls,i)=>({cls,x:W/2+(i?105:-105),y:H/2+65,home:{x:W/2+(i?105:-105),y:H/2+65},r:15,attackCd:0,attackAnim:0,move:false,facing:i?-1:1}));
 return s.campFriends;
}
function updateCampCompanions(dt){
 if(s.phase!=='vault'){s.campFriends=null;return}
 for(const ally of campCompanions()){
  const stats=CLASSES[ally.cls];ally.attackCd=Math.max(0,ally.attackCd-dt);ally.attackAnim=Math.max(0,ally.attackAnim-dt);ally.move=false;
  let target=null,nearest=Infinity;
  for(const enemy of s.enemies){if(enemy.dead||enemy.type==='boss'||Math.hypot(enemy.x-ally.home.x,enemy.y-ally.home.y)>340)continue;
   const distance=Math.hypot(enemy.x-ally.x,enemy.y-ally.y);if(distance<nearest){nearest=distance;target=enemy}
  }
  const goal=target||ally.home,range=target?stats.range*.85:8,dx=goal.x-ally.x,dy=goal.y-ally.y,distance=Math.hypot(dx,dy);
  if(distance>range){const travel=Math.min(145*dt,distance-range);ally.x=clamp(ally.x+dx/distance*travel,45,W-45);ally.y=clamp(ally.y+dy/distance*travel,90,H-45);ally.move=true}
  if(Math.abs(dx)>1)ally.facing=dx<0?-1:1;
  if(target&&Math.hypot(target.x-ally.x,target.y-ally.y)<=stats.range&&ally.attackCd<=0){
   ally.attackAnim=.3;ally.attackCd=stats.attackRate*1.15;
   if(ally.cls==='knight'){damage(target,stats.attackDamage*.75);s.rings.push({x:target.x,y:target.y,r:4,max:24,ttl:.18,color:'#e6c88b'})}
   else{shot(ally.x,ally.y,target.x,target.y,ally.cls==='rogue'?545:445,stats.attackDamage*.75,'hero',stats.auto,4);s.shots.at(-1).campAlly=ally.cls}
  }
 }
}
function drawCampCompanions(){
 for(const ally of campCompanions()){
  ctx.save();ctx.strokeStyle='#a9d5b66b';ctx.lineWidth=2;ctx.beginPath();ctx.ellipse(ally.x,ally.y+7,18,7,0,0,Math.PI*2);ctx.stroke();ctx.restore();
  showSprite(ally.cls,ally.x,ally.y+12,66,80,ally.attackAnim>0?'attack':ally.move?'walk':'idle',ally.facing,0,ally.cls.length);
 }
}
