module.exports=html=>{
 const mouseStart="C.addEventListener('pointerdown',ev=>{if(s.mode!=='running'||s.paused)return;";
 html=html.replace(mouseStart,"C.addEventListener('pointerdown',ev=>{if(ev.pointerType==='mouse'&&ev.button!==0)return;if(s.mode!=='running'||s.paused)return;");
 html=html.replace('drawEnvironment();drawEntities();ctx.restore()', 'drawEnvironment();drawMouseSelection();drawEntities();ctx.restore()');
 // Gate all voluntary movement while Shift is held, including joystick and click paths.
 if(!html.includes('if(!standStillHeld()){\n  let dx=0,dy=0;')){
  html=html.replace('  let dx=0,dy=0;', '  if(!standStillHeld()){\n  let dx=0,dy=0;');
  html=html.replace('  h.x=clamp(h.x,30,W-30);h.y=clamp(h.y,75,worldBottom()-30);','  }\n  h.x=clamp(h.x,30,W-30);h.y=clamp(h.y,75,worldBottom()-30);');
 }
 if(html.includes('// Manual combat controls v1'))return html;
 const replace=(from,to)=>{if(!html.includes(from))throw Error('Manual controls integration anchor missing: '+from.slice(0,80));html=html.replace(from,to)};
 replace("function step(dt){if(s.mode!=='running'||s.paused)return;s.time-=dt;s.elapsed+=dt;","// Manual combat controls v1\n function step(dt){if(s.mode!=='running'||s.paused)return;s.time-=dt;s.elapsed+=dt;updatePlayerActions(dt);");
 const start=html.indexOf("resolveSolid(h,oldHero);trackMotion(h,oldHero,dt);if(selectedClass==='knight'"),end=html.indexOf('  for(const e of s.enemies)',start);
 if(start<0||end<0)throw Error('Automatic attack block missing');
 html=html.slice(0,start)+'resolveSolid(h,oldHero);trackMotion(h,oldHero,dt);performManualAttack(dt);\n'+html.slice(end);
 replace("function showSprite(kind,x,y,width,height,anim='idle',facing=1,hit=0,seed=0,actor=null){","function showSprite(kind,x,y,width,height,anim='idle',facing=1,hit=0,seed=0,actor=null){\n  if(actor&&actor===s?.hero)y-=heroJumpHeight();");
 replace("h.skillAnim>0?'skill':h.move?'walk':h.attackAnim>0||h.swing>0?'attack':'idle'","heroActionAnimation(h)");
 replace('function renderAll(){if(!s)return;renderRewardStatus();','function renderAll(){if(!s)return;renderRewardStatus();renderPlayerActions();');
 replace("function reset(){if(s?.mode==='running')","function reset(){clearPlayerInput();if(s?.mode==='running')");
 replace("function finish(win,reason){if(s.mode!=='running')return;","function finish(win,reason){if(s.mode!=='running')return;clearPlayerInput();");
 replace("function start(){s.mode='running';","function start(){clearPlayerInput();s.mode='running';");
 replace('r:16,attack:0,cd:', 'r:16,attack:0,jumpRemaining:0,jumpCooldown:0,cd:');
 replace('window.MirroredDungeonDebug={drawMobSprite,','window.MirroredDungeonDebug={requestJump,setAttackInput,clearPlayerInput,heroJumpHeight,jumpsOverHazard,playerActions:PLAYER_ACTIONS,drawMobSprite,');
 return html;
};
