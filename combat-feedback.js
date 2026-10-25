const ENEMY_CONTACT_WINDUP=.2;
function updateEnemyContact(e,d,dt){
 if(e.contactStrike){
  e.contactStrike.remaining-=dt;
  if(e.contactStrike.remaining<=.000001){
   e.contactStrike=null;
   GameAudio.effect(e.sprite==='hound'?'bite':'enemy-swing',e.x,e.y);
   if(Math.hypot(s.hero.x-e.x,s.hero.y-e.y)<e.r+s.hero.r+12&&visibleLine(e,s.hero))hurt(e.dmg+(e.type==='boss'&&s.bossStates[e.id].empowered?5:0),e.type==='boss');
  }
  return;
 }
 if(d<e.r+s.hero.r+12&&e.attack<=0&&visibleLine(e,s.hero)){
  e.attackAnim=.45;e.attackDirection=knightMovementDirection(s.hero.x-e.x,s.hero.y-e.y,e.walkDirection);
  e.contactStrike={remaining:ENEMY_CONTACT_WINDUP};
  e.attack=e.type==='boss'?(s.order.includes('warlord')?1:1.55):1.6;
 }
}
function applyTrapBurn(){
 const h=s.hero,config=DEV.traps;
 // Refresh the duration without adding a second burn or resetting its tick clock.
 if(!(h.burnUntil>s.elapsed)){h.burnNextTick=s.elapsed+config.burnDuration/config.burnTicks;h.burnTickDamage=DEV.hazardDamage*DEV.difficulty/config.burnTicks}
 h.burnUntil=s.elapsed+config.burnDuration;
}
function updateTrapBurn(){
 const h=s.hero;if(!h.burnUntil)return;
 const interval=DEV.traps.burnDuration/DEV.traps.burnTicks;
 while(h.burnNextTick<=s.elapsed+1e-8&&h.burnNextTick<=h.burnUntil+1e-8&&s.mode==='running'){
  h.trapImpact='burn';h.trapImpactUntil=s.elapsed+.32;hurt(h.burnTickDamage,false,'hit-fire');h.burnNextTick+=interval;
 }
 if(s.elapsed>=h.burnUntil)h.burnUntil=0;
}
function drawEnemyWindup(e){
 if(selectedMouseEnemy()===e){
  const y=Math.round(e.y-(e.type==='boss'?84:MOB_BODY_HEIGHTS[e.sprite]||54)-16),x=Math.round(e.x);
  ctx.save();ctx.fillStyle=inBasicAttackRange(e)?'#ffe0a3':'#9bd9ed';ctx.fillRect(x-5,y,10,2);ctx.fillRect(x-3,y+2,6,2);ctx.fillRect(x-1,y+4,2,2);ctx.restore();
 }
 if(!e.contactStrike)return;
 ctx.save();ctx.translate(Math.round(e.x),Math.round(e.y-(e.type==='boss'?80:MOB_BODY_HEIGHTS[e.sprite]||54)-10));
 ctx.fillStyle='#6b3434';ctx.fillRect(-8,0,16,4);ctx.fillStyle='#ffcc83';ctx.fillRect(-6,0,12,2);ctx.fillRect(-3,4,6,2);ctx.fillStyle='#fff0bf';ctx.fillRect(-1,6,2,2);ctx.restore();
}
