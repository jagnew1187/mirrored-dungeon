const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
 await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug&&document.getElementById('game').dataset.necroAssets==='ready');
 const count=await page.evaluate(()=>{
  const d=MirroredDungeonDebug;let checks=0;const check=(v,m)=>{if(!v)throw Error(m);checks++};
  for(const cls of ['mage','knight','rogue']){
   d.reset();d.chooseClass(cls);d.start();d.selectBoss('necro');const s=d.state(),room=s.gauntlet.room;
   check(JSON.stringify(room)===JSON.stringify(d.room('necro')),'same seeded geometry and rewards');check(d.validate(room.obstacles,room),'both objectives reachable');check(room.obstacles.some(o=>o.kind==='coffin')&&room.obstacles.some(o=>o.kind==='tomb'),'functional burial props');
   const before=JSON.stringify(s.obstacles);d.draw();check(JSON.stringify(s.obstacles)===before,'rendering never mutates masks');
   s.enemies=[];s.hero.x=room.rewardX;s.hero.y=room.rewardY;s.gauntlet.committed=true;s.gauntlet.commitTime=s.elapsed;s.gauntlet.options=['edge'];d.chooseRewards();const time=s.time;d.step(.1);check(s.time<time,'claim does not pause timer');check(d.claimReward('edge'),'one reward claim');check(!d.claimReward('edge'),'no duplicate claim');check(d.rewardModifiers(s.reward).damage===1,'pending inactive');d.enterBoss();
   check(s.obstacles.length===4&&s.enemies.every(e=>!s.obstacles.some(o=>e.x+e.r>o.x&&e.x-e.r<o.x+o.w&&e.y+e.r>o.y&&e.y-e.r<o.y+o.h)),'arena and enemies spawn clear');
   check(d.rewardModifiers(s.reward).damage===1.25&&d.rewardModifiers(s.reward).taken===1.2,'existing Necro reward tuning preserved');const hp=s.boss.hp;d.damage(s.boss,10);check(Math.abs(s.boss.hp-(hp-12.5))<.001,'real boss damage');
   const o=s.obstacles[0],shot={x:o.x+20,y:o.y+20,r:5,vx:100,vy:0,damage:50,team:'hero',ttl:1};check(d.projectileCover(shot,.04)&&shot.ttl===0,'crypt cover blocks shots');
   const boss=s.boss;s.enemies=[boss];boss.x=165;boss.y=293;s.hero.x=300;s.hero.y=293;boss.attack=999;boss.ability=999;s.hero.attack=999;s.hero.hp=9999;s.waveAt=999;
   for(let i=0;i<240;i++)d.step(.04);check(Math.hypot(boss.x-s.hero.x,boss.y-s.hero.y)<100,'boss navigates around crypt pillar');
   d.damage(boss,99999);check(s.bossStates.necro.done&&s.phase==='vault'&&s.obstacles.length===0,'boss victory and arena cleanup');d.reset();check(!d.state().reward&&d.state().obstacles.length===0,'restart cleanup');
  }
  d.start();d.selectBoss('necro');const s=d.state();s.enemies=[];s.hazards=[{x:s.hero.x,y:s.hero.y,r:22,kind:'rune',offset:0}];s.elapsed=s.gauntlet.start+1.4;const hp=s.hero.hp;d.step(.01);check(s.hero.slowUntil>s.elapsed&&s.hero.hp===hp,'active rune slows without direct damage');s.hero.slowUntil=0;s.elapsed=s.gauntlet.start+3;d.step(.01);check(s.hero.slowUntil===0,'recovery rune harmless');
  const coffin=s.obstacles.find(o=>o.kind==='coffin');coffin.hp=0;const e={x:coffin.x+coffin.w/2,y:coffin.y+coffin.h/2,r:12};d.resolveSolid(e);check(e.x===coffin.x+coffin.w/2&&e.y===coffin.y+coffin.h/2,'broken coffin passable');
  s.hero.x=420;s.hero.y=600;s.gauntlet.claimed=true;d.renderAll();s.hazards=['recovery','warning','active'].map((state,i)=>({x:320+i*90,y:470,r:22,kind:'rune',offset:0,state}));d.draw();return checks;
 });assert.ok(count>=48);await page.locator('#game').screenshot({path:'necro-details-preview.png'});console.log(count+' Necromancer checks passed');
 }finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
