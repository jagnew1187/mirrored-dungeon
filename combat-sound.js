function skillSound(cls,which){
 return {mage:{frost:'frost-cast',heal:'heal'},knight:{fire:'cleave',frost:'shield',heal:'guard'},rogue:{fire:'twin-daggers',frost:'shadow',heal:'smoke'}}[cls]?.[which]||null;
}
function physicalHitSound(enemy){return enemy.armored||enemy.sprite==='skeleton'||enemy.id==='warlord'?'hit-metal':'hit-flesh'}
function coverHitSound(cover){return ['wood','barricade','crate','barrel','coffin'].includes(cover.kind)?'hit-wood':'hit-stone'}
function soundProjectile(projectile,team,color){
 let launch='fire-cast',impact='hit-fire';
 if(team==='hero'){
  if(color==='#83d8eb'){launch='arcane-cast';impact='hit-arcane'}
  else if(color==='#ffa85f'){launch='fire-cast';impact='hit-fire'}
  else{launch=['#b1edca','#e6f9b7'].includes(color)?null:'dagger-throw';impact=null}
 }
 projectile.impactSound=impact;GameAudio.effect(launch,projectile.x,projectile.y);
}
