// Simulation-owned motion clocks: rendering never advances animation or combat.
const KNIGHT_WALK_STRIDE=88; // World pixels per complete two-step cycle in the new art.
const HERO_WALK_STRIDES={knight:KNIGHT_WALK_STRIDE,mage:84,rogue:92};
const BOSS_WALK_STRIDES={warlord:80,pyro:64,necro:64};
const MOB_WALK_STRIDES={cultist:64,skeleton:60,acolyte:64,hound:76};
const KNIGHT_DIRECTIONS=['right','southeast','down','southwest','left','northwest','up','northeast'];
function knightMovementDirection(dx,dy,previous){
 const angle=Math.atan2(dy,dx),sector=Math.PI/4,old=KNIGHT_DIRECTIONS.indexOf(previous);
 // Five degrees of overlap around each 45-degree view prevent joystick chatter.
 if(old>=0){const delta=Math.atan2(Math.sin(angle-old*sector),Math.cos(angle-old*sector));if(Math.abs(delta)<=sector/2+Math.PI/36)return previous}
 return KNIGHT_DIRECTIONS[(Math.round(angle/sector)+8)%8];
}
function trackMotion(actor,old,dt){
 const wasMoving=actor.trackedMoving,distance=Math.hypot(actor.x-old.x,actor.y-old.y);actor.move=distance>.05;actor.trackedMoving=actor.move;
 const heroClass=actor===s.hero?selectedClass:actor.cls;
 const boss=actor.type==='boss'&&BOSS_WALK_STRIDES[actor.id],mob=actor.type!=='boss'&&MOB_WALK_STRIDES[actor.sprite],stride=boss||mob||HERO_WALK_STRIDES[heroClass]||104;
 const hero=actor===s.hero||actor.cls;
 actor.walkCycle=actor.move?(actor.walkCycle||0)+distance/stride:hero||boss||mob?(actor.walkCycle||0):0;
 actor.walkSettle=actor.move?0:wasMoving?.1:Math.max(0,(actor.walkSettle||0)-dt);
 if(actor.move&&(HERO_WALK_STRIDES[heroClass]||boss||mob)){
  actor.walkDirection=knightMovementDirection(actor.x-old.x,actor.y-old.y,actor.walkDirection);
 }
 actor.idleClock=(actor.idleClock||0)+dt;
}
function animationIndex(kind,anim,actor,seed=0){
 const sequence=spriteSequences[kind][anim]||spriteSequences[kind].idle;if(reduceMotion.matches&&anim==='idle')return sequence.start;
 let index;
 if(actor&&anim==='walk')index=Math.floor((actor.walkCycle||0)*sequence.count)%sequence.count;
 else if(actor&&(anim==='attack'||anim==='skill')){const duration=anim==='skill'?(actor.type==='boss'?.78:.66):((actor===s.hero||actor.drawingJumpPose)?.32:actor.type?.45:.3),remaining=anim==='skill'?actor.skillAnim:actor.attackAnim;
  index=Math.min(sequence.count-1,Math.floor(clamp(1-(remaining||0)/duration,0,1)*sequence.count));
 }else index=Math.floor((actor?.idleClock??s.elapsed)*3+(seed%7)*.7)%sequence.count;
 return sequence.start+index;
}
function impact(x,y,color){s.sparks.push({x,y,color,ttl:.16});if(s.sparks.length>36)s.sparks.shift()}
function updateImpacts(dt){for(const spark of s.sparks)spark.ttl-=dt;s.sparks=s.sparks.filter(spark=>spark.ttl>0)}
function drawImpacts(){if(reduceMotion.matches)return;ctx.save();ctx.lineWidth=2;for(const spark of s.sparks){ctx.globalAlpha=spark.ttl/.16;ctx.strokeStyle=spark.color;const length=4+(1-spark.ttl/.16)*9;
 for(let i=0;i<4;i++){const a=i*Math.PI/2+Math.PI/4;ctx.beginPath();ctx.moveTo(spark.x+Math.cos(a)*3,spark.y+Math.sin(a)*3);ctx.lineTo(spark.x+Math.cos(a)*length,spark.y+Math.sin(a)*length);ctx.stroke()}}
 ctx.restore();}
function advanceProjectile(p,dt){
 p.ttl-=dt;if(p.ttl<=0)return;
 const x=p.x,y=p.y,n=Math.max(1,Math.ceil(Math.hypot(p.vx,p.vy)*dt/4));
 for(let i=1;i<=n;i++){
  p.x=x+p.vx*dt*i/n;p.y=y+p.vy*dt*i/n;
  const cover=s.obstacles.find(o=>overlaps({x:p.x,y:p.y,r:p.r},o));
  if(cover){GameAudio.effect(coverHitSound(cover),p.x,p.y);if(cover.hp>0&&p.team==='hero')cover.hp=Math.max(0,cover.hp-p.damage);impact(p.x,p.y,'#c3b393');p.ttl=0;return}
  if(p.team==='hero'){const target=s.enemies.find(e=>!e.dead&&Math.hypot(e.x-p.x,e.y-p.y)<e.r+p.r);if(target){damage(target,p.damage,p.impactSound);p.ttl=0;return}}
  else if(Math.hypot(s.hero.x-p.x,s.hero.y-p.y)<s.hero.r+p.r){hurt(p.damage,p.bossHit,p.impactSound);p.ttl=0;return}
 }
}
