const PLAYER_ACTIONS={jumpDuration:.46,jumpCooldown:1.25,jumpHeight:28,attackBuffer:.16,impactDelay:{knight:.16,mage:.16,rogue:.12}};
const attackInputs=new Set();let queuedAttackUntil=-Infinity,mouseEnemyTarget=null,mouseAim=null;
function standStillHeld(){return keys.has('shift')}
function aimAtCursor(){if(!mouseAim)return null;return inputPoint(mouseAim)}
function clearPlayerInput(){attackInputs.clear();queuedAttackUntil=-Infinity;mouseEnemyTarget=null;lastEnemyPick=null;if(s?.hero)s.hero.pendingBasic=null;keys.delete('j');keys.delete('shift');mouseAim=null;attackPointer=null;canvasAttackPointer=null;pointer=false;pointerTarget=null;document.getElementById('attackButton')?.setAttribute('aria-pressed','false')}
function selectedMouseEnemy(){return mouseEnemyTarget&&!mouseEnemyTarget.dead&&mouseEnemyTarget.hp>0&&s.enemies.includes(mouseEnemyTarget)?mouseEnemyTarget:null}
function inBasicAttackRange(enemy){return enemy&&Math.hypot(enemy.x-s.hero.x,enemy.y-s.hero.y)<classData().range&&visibleLine(s.hero,enemy)}
let lastEnemyPick=null;
function mouseEnemyAt(point,cycle=false){
 const candidates=s.enemies.filter(e=>!e.dead&&e.hp>0).map(e=>{const height=e.type==='boss'?BOSS_GAIT_HEIGHTS[e.id]||84:MOB_BODY_HEIGHTS[e.sprite]||54,width=e.type==='boss'?42:e.sprite==='hound'?38:22;return{e,height,width}}).filter(({e,height,width})=>Math.abs(point.x-e.x)<=width&&point.y>=e.y-height+6&&point.y<=e.y+e.r).sort((a,b)=>b.e.y-a.e.y||Math.abs(point.x-a.e.x)-Math.abs(point.x-b.e.x)).map(a=>a.e);
 let target=candidates[0]||null;
 if(cycle&&lastEnemyPick&&s.elapsed-lastEnemyPick.time<.65&&Math.hypot(point.x-lastEnemyPick.x,point.y-lastEnemyPick.y)<10&&candidates.includes(mouseEnemyTarget))target=candidates[(candidates.indexOf(mouseEnemyTarget)+1)%candidates.length];
 if(cycle)lastEnemyPick={...point,time:s.elapsed};return target;
}
function drawMouseSelection(){const enemy=selectedMouseEnemy();if(!enemy)return;ctx.save();ctx.strokeStyle=inBasicAttackRange(enemy)?'#ffe0a3':'#9bd9ed';ctx.lineWidth=2;ctx.beginPath();ctx.ellipse(enemy.x,enemy.y+enemy.r*.7,enemy.r+8,8,0,0,Math.PI*2);ctx.stroke();ctx.restore()}
function setAttackInput(pressed,source='button'){
 if(!pressed){attackInputs.delete(source);return}
 if(s.mode!=='running'||s.paused)return;
 attackInputs.add(source);queuedAttackUntil=s.elapsed+PLAYER_ACTIONS.attackBuffer;
}
function manualAttackWanted(){return attackInputs.size>0||s.elapsed<=queuedAttackUntil||!!selectedMouseEnemy()}
function requestJump(){
 if(s.mode!=='running'||s.paused||(s.hero.jumpCooldown||0)>0)return false;
 s.hero.jumpRemaining=PLAYER_ACTIONS.jumpDuration;s.hero.jumpCooldown=PLAYER_ACTIONS.jumpCooldown;return true;
}
function heroJumpHeight(){const remaining=s?.hero?.jumpRemaining||0;return remaining>0?Math.sin(Math.PI*(1-remaining/PLAYER_ACTIONS.jumpDuration))*PLAYER_ACTIONS.jumpHeight:0}
function jumpsOverHazard(hazard){return ['spike','burn','rune'].includes(hazard.kind)&&heroJumpHeight()>=10}
function updatePlayerActions(dt){const h=s.hero,wasAirborne=(h.jumpRemaining||0)>0;h.jumpRemaining=Math.max(0,(h.jumpRemaining||0)-dt);h.jumpCooldown=Math.max(0,(h.jumpCooldown||0)-dt);
 updateTrapBurn();
 h.jumpLanding=Math.max(0,(h.jumpLanding||0)-dt);
 if(wasAirborne&&!h.jumpRemaining){h.jumpLanding=.12;impact(h.x-9,h.y+8,'#c5b18a');impact(h.x+9,h.y+8,'#c5b18a')}
 if(mouseEnemyTarget){const target=selectedMouseEnemy();if(!target){mouseEnemyTarget=null;h.pendingBasic=null;pointer=false;pointerTarget=null}else pointerTarget=standStillHeld()||inBasicAttackRange(target)?null:{x:target.x,y:target.y}}
}
function heroActionAnimation(h){return h.skillAnim>0?'skill':h.attackAnim>0||h.swing>0?'attack':h.jumpRemaining>0?'idle':h.move?'walk':'idle'}
function performManualAttack(dt){
 const h=s.hero;h.attack-=dt;
 if(h.pendingBasic){h.pendingBasic.remaining-=dt;if(h.pendingBasic.remaining<=.000001){const strike=h.pendingBasic;h.pendingBasic=null;resolveBasicImpact(strike)}}
 if(!manualAttackWanted()||h.attack>0||h.pendingBasic)return false;
 const stationary=standStillHeld(),cursor=stationary?aimAtCursor():null,chosen=stationary?null:selectedMouseEnemy(),explicit=attackInputs.size>0||s.elapsed<=queuedAttackUntil;
 if(chosen&&!inBasicAttackRange(chosen)&&!explicit)return false;
 queuedAttackUntil=-Infinity;const def=classData();
 let target=inBasicAttackRange(chosen)?chosen:bestTarget(def.range);
 if(cursor){
  target=mouseEnemyAt(cursor);
  if(selectedClass==='knight'){
   const dx=cursor.x-h.x,dy=cursor.y-h.y,length=Math.hypot(dx,dy)||1;
   target=s.enemies.filter(e=>!e.dead&&e.hp>0&&inBasicAttackRange(e)&&((e.x-h.x)*dx+(e.y-h.y)*dy)/(Math.hypot(e.x-h.x,e.y-h.y)*length||1)>.65).sort((a,b)=>Math.hypot(a.x-h.x,a.y-h.y)-Math.hypot(b.x-h.x,b.y-h.y))[0]||null;
  }
  const aim=target||cursor;if(Math.hypot(aim.x-h.x,aim.y-h.y)>2)h.walkDirection=knightMovementDirection(aim.x-h.x,aim.y-h.y);
  if(Math.abs(aim.x-h.x)>2)h.facing=aim.x<h.x?-1:1;
 }
 if(target&&Math.abs(target.x-h.x)>2)h.facing=target.x<h.x?-1:1;
 h.attackFacing=h.facing;h.attackAnim=.32;h.attack=def.attackRate*rewardModifiers(s.reward).attackInterval;
 h.pendingBasic={remaining:PLAYER_ACTIONS.impactDelay[selectedClass],cls:selectedClass,target,damage:def.attackDamage,aim:cursor?{...(target||cursor)}:target?{x:target.x,y:target.y}:null,lockAim:!!cursor};
 return true;
}
function resolveBasicImpact(strike){
 const h=s.hero,def=CLASSES[strike.cls],target=strike.target&&!strike.target.dead&&s.enemies.includes(strike.target)?strike.target:null;
 if(strike.cls==='knight'){
  GameAudio.effect('sword-swing',h.x,h.y);
  h.swing=.18;
  if(target&&Math.hypot(target.x-h.x,target.y-h.y)<def.range&&visibleLine(h,target)){damage(target,strike.damage);s.rings.push({x:target.x,y:target.y,r:5,max:22,ttl:.16,color:'#f1d0a1'})}
  else if(!strike.target){const cover=s.obstacles.filter(o=>o.hp>0&&(!strike.lockAim||!strike.aim||((o.x+o.w/2-h.x)*(strike.aim.x-h.x)+(o.y+o.h/2-h.y)*(strike.aim.y-h.y))/(Math.hypot(o.x+o.w/2-h.x,o.y+o.h/2-h.y)*Math.hypot(strike.aim.x-h.x,strike.aim.y-h.y)||1)>.65)&&Math.hypot(h.x-o.x-o.w/2,h.y-o.y-o.h/2)<85).sort((a,b)=>Math.hypot(h.x-a.x-a.w/2,h.y-a.y-a.h/2)-Math.hypot(h.x-b.x-b.w/2,h.y-b.y-b.h/2)).find(o=>visibleLine(h,{x:o.x+o.w/2,y:o.y+o.h/2},s.obstacles.filter(other=>other!==o)));if(cover){GameAudio.effect(coverHitSound(cover),h.x,h.y);cover.hp=Math.max(0,cover.hp-strike.damage)}}
 }else{
  const index=KNIGHT_DIRECTIONS.indexOf(h.walkDirection),angle=index>=0?index*Math.PI/4:h.facing<0?Math.PI:0;
  const aim=(strike.lockAim?strike.aim:target||strike.aim)||{x:h.x+Math.cos(angle)*300,y:h.y+Math.sin(angle)*300};
  shot(h.x,h.y,aim.x,aim.y,strike.cls==='rogue'?545:445,strike.damage,'hero',def.auto,strike.cls==='rogue'?4:5);
 }
 return true;
}
const actionStyle=document.createElement('style');actionStyle.textContent=`
.combat-actions{pointer-events:none;position:absolute;right:12px;bottom:12px;display:flex;align-items:end;gap:8px;z-index:4}.combat-actions[hidden]{display:none}.combat-actions button{pointer-events:auto;min-width:66px;min-height:58px;border:1px solid #d7b16e;border-radius:16px;background:#193347ed;color:#ffe7bc;box-shadow:0 3px 12px #0009;touch-action:none;user-select:none;-webkit-user-select:none;display:flex;flex-direction:column;align-items:center;justify-content:center;font-weight:800}.combat-actions button small{font-size:10px;font-weight:500}.combat-actions #attackButton{min-width:84px;background:#713d32ed;border-color:#e9b56f}.combat-actions #attackButton[aria-pressed=true]{background:#b16d42}.combat-actions button:disabled{opacity:.82;background:#142b3be8;border-color:#638995;color:#d9e9ed}.combat-actions button:focus-visible{outline:3px solid #fff;outline-offset:2px}
@media(pointer:coarse){.combat-actions{right:10px;bottom:40px;gap:6px}.combat-actions button{pointer-events:auto;min-width:50px;min-height:52px;font-size:12px}.combat-actions #attackButton{min-width:66px;min-height:62px}.combat-actions button small{font-size:9px}}
`;document.head.append(actionStyle);
const combatActions=document.createElement('div');combatActions.className='combat-actions';combatActions.hidden=true;combatActions.setAttribute('aria-label','Basic combat controls');
combatActions.innerHTML='<button type="button" id="jumpButton" title="Space: 0.46-second hop, 1.25-second cooldown. Jump spikes, burning tiles and runes. Flame jets, enemies and boss attacks still hit.">Jump<small id="jumpStatus">READY</small></button><button type="button" id="attackButton" aria-pressed="false" title="J: tap to attack once; hold to repeat. Aims at a nearby visible enemy.">Attack<small id="attackStatus">HOLD</small></button>';
document.querySelector('.arena-wrap').append(combatActions);
const attackButton=$('attackButton');let attackPointer=null,canvasAttackPointer=null;
attackButton.addEventListener('pointerdown',ev=>{if(s.mode!=='running'||s.paused||attackPointer!==null||ev.pointerType==='mouse'&&ev.button!==0)return;ev.preventDefault();attackPointer=ev.pointerId;attackButton.setPointerCapture(ev.pointerId);setAttackInput(true,'pointer');renderPlayerActions()});
for(const name of ['pointerup','pointercancel','lostpointercapture'])attackButton.addEventListener(name,ev=>{if(ev.pointerId!==attackPointer)return;setAttackInput(false,'pointer');attackPointer=null;if(name!=='pointerup'){queuedAttackUntil=-Infinity;s.hero.pendingBasic=null}renderPlayerActions()});
// detail===0 preserves keyboard and assistive-technology button activation without double attacks after touch.
attackButton.addEventListener('click',ev=>{if(ev.detail===0&&s.mode==='running'&&!s.paused)queuedAttackUntil=s.elapsed+PLAYER_ACTIONS.attackBuffer});
// Capture Shift-click before the normal click-to-move handler.
C.addEventListener('pointerdown',ev=>{
 if(ev.pointerType!=='mouse')return;
 mouseAim={clientX:ev.clientX,clientY:ev.clientY};
 if(ev.button!==0||!standStillHeld()||s.mode!=='running'||s.paused)return;
 ev.preventDefault();ev.stopImmediatePropagation();C.setPointerCapture(ev.pointerId);
 canvasAttackPointer=ev.pointerId;mouseEnemyTarget=null;pointer=false;pointerTarget=null;
 setAttackInput(true,'stand-still-mouse');renderPlayerActions();
},true);
C.addEventListener('pointermove',ev=>{if(ev.pointerType==='mouse'){mouseAim={clientX:ev.clientX,clientY:ev.clientY};if(standStillHeld()){pointer=false;pointerTarget=null}}},true);
C.addEventListener('pointerdown',ev=>{
 if(ev.pointerType!=='mouse'||ev.button!==0||s.mode!=='running'||s.paused)return;
 const previousTarget=mouseEnemyTarget;mouseEnemyTarget=mouseEnemyAt(inputPoint(ev),true);canvasAttackPointer=ev.pointerId;
 if(previousTarget!==mouseEnemyTarget)s.hero.pendingBasic=null;
 if(!mouseEnemyTarget)s.hero.pendingBasic=null;
 if(mouseEnemyTarget){pointer=false;pointerTarget=inBasicAttackRange(mouseEnemyTarget)?null:{x:mouseEnemyTarget.x,y:mouseEnemyTarget.y}}
 renderPlayerActions();
});
C.addEventListener('pointermove',ev=>{if(ev.pointerType==='mouse')C.style.cursor=s.mode==='running'&&mouseEnemyAt(inputPoint(ev))?'pointer':'crosshair'});
for(const name of ['pointerup','pointercancel','lostpointercapture'])C.addEventListener(name,ev=>{
 if(ev.pointerId!==canvasAttackPointer)return;
 setAttackInput(false,'stand-still-mouse');canvasAttackPointer=null;
 if(name!=='pointerup'){mouseEnemyTarget=null;s.hero.pendingBasic=null;pointer=false;pointerTarget=null}
 renderPlayerActions();
});
$('jumpButton').addEventListener('pointerdown',ev=>{ev.preventDefault();requestJump();renderPlayerActions()});
$('jumpButton').addEventListener('click',ev=>{if(ev.detail===0){requestJump();renderPlayerActions()}});
window.addEventListener('keydown',ev=>{if(ev.target?.matches('input,select,textarea')||ev.ctrlKey||ev.metaKey||ev.altKey)return;const key=ev.key.toLowerCase();if(key==='shift'){pointer=false;pointerTarget=null}if(key==='j'&&!ev.repeat)setAttackInput(true,'keyboard');if(key===' '){ev.preventDefault();if(!ev.repeat)requestJump()}});
window.addEventListener('keyup',ev=>{if(ev.key.toLowerCase()==='j')setAttackInput(false,'keyboard');if(ev.key==='Shift'){setAttackInput(false,'stand-still-mouse');pointer=false;pointerTarget=null}});
window.addEventListener('blur',()=>{clearPlayerInput();attackPointer=null});document.addEventListener('visibilitychange',()=>{if(document.hidden){clearPlayerInput();resetJoystick();keys.clear();attackPointer=null}});
$('pause').addEventListener('click',()=>{clearPlayerInput();attackPointer=null});
function renderPlayerActions(){
 combatActions.hidden=s.mode!=='running'||s.paused;const disabled=s.mode!=='running'||s.paused;
 attackButton.disabled=disabled;attackButton.setAttribute('aria-pressed',String(!disabled&&manualAttackWanted()));
 $('jumpButton').disabled=disabled||(s.hero.jumpCooldown||0)>0;
 const touch=matchMedia('(pointer:coarse)').matches;
 $('jumpStatus').textContent=s.hero.jumpCooldown>0?(Math.ceil(s.hero.jumpCooldown*10)/10).toFixed(1)+'s':touch?'READY':'SPACE';
 $('attackStatus').textContent=s.hero.attack>0?'RECOVERING':touch?'HOLD':'J · HOLD';
}
C.setAttribute('aria-label','Top-down battlefield. Left click an enemy to approach and attack automatically in range. Click the ground to cancel the target and move only. Hold Shift to stand still; Shift + left click attacks toward the cursor, including empty ground. Touch drag or joystick moves only. J or Attack also attacks; Space or Jump hops over ground traps.');
const controlsHint=document.querySelector('.hint');if(controlsHint)controlsHint.textContent='Click enemy: approach + attack · Click again: cycle overlapping enemies · Click ground: move / cancel target · Move: WASD / arrows, touch drag or joystick · Attack: J / Attack · Jump: Space · Skills: 1 / 2 / 3.';
