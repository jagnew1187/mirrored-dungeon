module.exports=html=>{
 if(!html.includes("updatePlayerActions(dt);if(s.mode!=="))html=html.replace('updatePlayerActions(dt);',"updatePlayerActions(dt);if(s.mode!=='running')return;");
 html=html.replace('heroActionAnimation(h),h.facing,h.flash','heroActionAnimation(h),h.attackAnim>0&&!(h.skillAnim>0)?h.attackFacing??h.facing:h.facing,h.flash');
 html=html.replace('for(const e of s.enemies){if(e.dead)continue;const boss=', 'for(const e of [...s.enemies].sort((a,b)=>a.y-b.y)){if(e.dead)continue;const boss=');
 if(html.includes('// Combat impact timing hooks'))return html;
 const replace=(from,to)=>{if(!html.includes(from))throw Error('Missing combat feedback hook: '+from);html=html.replace(from,to)};
 replace("if(d>e.r+h.r+12){const f=", "if(d>e.r+h.r+12&&!e.contactStrike){const f=");
 replace("if(d<e.r+h.r+12 && e.attack<=0){e.attackAnim=.45;e.attackDirection=knightMovementDirection(h.x-e.x,h.y-e.y,e.walkDirection);hurt(e.dmg+(e.type==='boss'&&s.bossStates[e.id].empowered?5:0),e.type==='boss');e.attack=e.type==='boss'?(s.order.includes('warlord')?1.0:1.55):1.6}","updateEnemyContact(e,d,dt);");
 replace("let healthW=boss?82:34;", "drawEnemyWindup(e);let healthW=boss?82:34;");
 html=html.replaceAll('h.slowUntil>s.elapsed?.6:1','h.slowUntil>s.elapsed?1-DEV.traps.slowAmount:1');
 replace('function step(dt){', '// Combat impact timing hooks\n function step(dt){');
 return html;
};
