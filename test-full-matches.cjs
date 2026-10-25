const path=require('node:path'),fs=require('node:fs'),assert=require('node:assert/strict');let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 const page=await browser.newPage();await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug);
 const results=await page.evaluate(()=>{
  const d=MirroredDungeonDebug,results=[];
  for(const cls of ['mage','knight','rogue']){
   d.reset();d.chooseClass(cls);d.start();let s=d.state();d.selectBoss('warlord');s=d.state();d.setAttackInput(true,'full-match');let frames=0;
   while(s.mode==='running'&&frames++<6000){
    const h=s.hero;d.keys.clear();
    if(s.phase==='vault'){
     const next=['warlord','pyro','necro'].find(id=>!s.bossStates[id].done);if(next)d.selectBoss(next);
    }
    let goal=null;
    if(s.phase==='gauntlet'){
     goal={x:s.gauntlet.room.mainX,y:100};
     if(s.hazards.some(t=>Math.hypot(t.x-h.x,t.y-h.y)<65&&t.state!=='recovery'))d.requestJump();
    }else if(s.boss&&!s.boss.dead){
     const boss=s.boss,dx=h.x-boss.x,dy=h.y-boss.y,distance=Math.hypot(dx,dy)||1,radius=cls==='knight'?70:210;
     goal={x:Math.max(45,Math.min(795,boss.x+dx/distance*radius)),y:Math.max(90,Math.min(575,boss.y+dy/distance*radius))};
     const bomb=s.rings.find(r=>r.bomb&&r.ttl>0&&Math.hypot(h.x-r.x,h.y-r.y)<r.r+35);
     if(bomb)goal={x:Math.max(45,Math.min(795,h.x+(h.x<420?100:-100))),y:Math.max(90,Math.min(575,h.y+70))};
    }
    if(goal){const next=d.enemyWaypoint(h,goal),dx=next.x-h.x,dy=next.y-h.y;if(Math.abs(dx)>5)d.keys.add(dx>0?'d':'a');if(Math.abs(dy)>5)d.keys.add(dy>0?'s':'w')}
    const nearest=Math.min(Infinity,...s.enemies.filter(e=>!e.dead).map(e=>Math.hypot(e.x-h.x,e.y-h.y)));
    if(nearest<(cls==='knight'?105:350))d.cast('fire');
    if(nearest<145)d.cast('frost');if(h.hp<h.max*.68)d.cast('heal');
    d.step(.04);
   }
   d.keys.clear();d.clearPlayerInput();results.push({class:cls,outcome:s.mode,bosses:s.order,seconds:+s.elapsed.toFixed(2),hp:+s.hero.hp.toFixed(2),rivalBosses:s.botKills,gauntlets:s.stats.gauntlets.length,encounters:s.stats.encounters.map(e=>({boss:e.boss,outcome:e.outcome,seconds:+e.time.toFixed(2)}))});
  }return results;
 });fs.writeFileSync('test-full-matches-results.json',JSON.stringify(results,null,2)+'\n');console.log(JSON.stringify(results));assert.ok(results.every(r=>r.outcome==='win'&&r.bosses.length===3),'all classes clear all three real encounters with the rival and unmodified health/damage');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
