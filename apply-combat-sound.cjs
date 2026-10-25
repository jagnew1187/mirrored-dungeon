module.exports=html=>{
 html=html.replace("h.trapImpactUntil>s.elapsed&&['fire','burn'].includes(h.trapImpact)?'hit-fire':",'');
 if(html.includes('// Combat sound hooks'))return html;
 const replace=(from,to)=>{if(!html.includes(from))throw Error('Missing combat sound hook: '+from);html=html.replace(from,to)};
 replace('function shot(x,y,tx,ty,speed,damage,team,color,r=5){','// Combat sound hooks\n function shot(x,y,tx,ty,speed,damage,team,color,r=5){');
 replace(',r,ttl:3})}',',r,ttl:3});soundProjectile(s.shots.at(-1),team,color)}');
 replace('function damage(e,n){','function damage(e,n,soundKind=null){');
 replace("e.hit=.13;impact(e.x,e.y-10,'#ffe0a3');","e.hit=.13;if(n>0)GameAudio.effect(soundKind||physicalHitSound(e),e.x,e.y);impact(e.x,e.y-10,'#ffe0a3');");
 replace('function hurt(n,bossHit=false){','function hurt(n,bossHit=false,soundKind=null){');
 replace("h.flash=.32;impact(h.x,h.y-10,'#ff8389');","h.flash=.32;if(n>0)GameAudio.effect(soundKind||(h.guard>0?'hit-metal':'hurt'),h.x,h.y);impact(h.x,h.y-10,'#ff8389');");
 replace('h.skillAnim=.66;renderAll()','h.skillAnim=.66;GameAudio.effect(skillSound(selectedClass,which),h.x,h.y);renderAll()');
 replace('damage(e,24);e.slow=',"damage(e,24,'hit-frost');e.slow=");
 replace('damage(foe,46);foe.slow=',"damage(foe,46,'hit-arcane');foe.slow=");
 replace("if(e.id==='necro'){spawnMob", "if(e.id==='necro'){GameAudio.effect('necro-cast',e.x,e.y);spawnMob");
 replace('r.detonated=true;if(Math.hypot',"r.detonated=true;GameAudio.effect('boss-slam',r.x,r.y);if(Math.hypot");
 return html;
};
