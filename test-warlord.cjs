const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
 await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug);
 await page.waitForFunction(()=>document.getElementById('game').dataset.warlordProps==='ready');
 await page.waitForFunction(()=>document.getElementById('game').dataset.warlordDecor==='ready');
 const count=await page.evaluate(()=>{
  const d=MirroredDungeonDebug;let checks=0;const check=(v,m)=>{if(!v)throw Error(m);checks++};
  for(const cls of ['mage','knight','rogue']){
   d.reset();d.chooseClass(cls);d.start();d.selectBoss('warlord');const s=d.state(),room=s.gauntlet.room;
   check(room.options.includes('edge'),'Edge always offered');check(d.rewardText('edge').includes('30%'),'exact Warlord benefit');check(d.rewardDrawbackText('edge').includes('20%'),'exact drawback');
   check(JSON.stringify(room)===JSON.stringify(d.room('warlord')),'equivalent deterministic room');
   s.enemies=[];s.hero.x=room.rewardX;s.hero.y=room.rewardY;s.gauntlet.committed=true;s.gauntlet.commitTime=s.elapsed;d.chooseRewards();const time=s.time;d.step(.1);check(s.time<time,'collection timer running');check(d.claimReward('edge'),'claim edge');check(d.rewardModifiers(s.reward).damage===1,'pending benefit inactive');d.enterBoss();
   check(s.obstacles.length===4,'throne cover installed');check(d.rewardModifiers(s.reward).damage===1.3&&d.rewardModifiers(s.reward).taken===1.2,'30/20 effects');
   const hp=s.boss.hp;d.damage(s.boss,10);check(Math.abs(s.boss.hp-(hp-13))<.001,'actual boss damage amplified');
   const cover=s.obstacles[0],e={x:cover.x+20,y:cover.y+20,r:29};d.resolveSolid(e);check(!s.obstacles.some(o=>e.x+e.r>o.x&&e.x-e.r<o.x+o.w&&e.y+e.r>o.y&&e.y-e.r<o.y+o.h),'large enemy depenetration');
   // Drive the real boss around a pillar toward the hero with combat disabled.
   const boss=s.boss;s.enemies=[boss];boss.x=165;boss.y=293;s.hero.x=300;s.hero.y=293;boss.attack=999;boss.ability=999;s.hero.attack=999;s.waveAt=999;s.hero.hp=9999;const before=Math.hypot(boss.x-s.hero.x,boss.y-s.hero.y);
   for(let i=0;i<180;i++)d.step(.04);check(Math.hypot(boss.x-s.hero.x,boss.y-s.hero.y)<before-30,'boss navigates around cover');
   s.elapsed=s.reward.until+.01;check(d.rewardModifiers(s.reward).damage===1&&d.rewardModifiers(s.reward).taken===1,'both expire at 15s');
   d.damage(boss,99999);check(s.bossStates.warlord.done&&s.phase==='vault'&&s.obstacles.length===0,'victory clears arena');d.reset();check(!d.state().reward&&d.state().obstacles.length===0,'restart clears state');
  }
  d.start();d.selectBoss('pyro');check(d.rewardText('edge').includes('25%'),'other dungeon reward unchanged');
  d.reset();d.start();d.selectBoss('warlord');const s=d.state();
  s.enemies=[];s.hero.y=500;s.hero.x=420;s.gauntlet.claimed=true;d.renderAll();
  s.obstacles=[{x:120,y:300,w:100,h:60,kind:'wood',hp:90},{x:260,y:300,w:100,h:60,kind:'wood',hp:25},{x:400,y:300,w:100,h:60,kind:'wood',hp:0},{x:120,y:400,w:64,h:64,kind:'crate',hp:65},{x:260,y:400,w:48,h:64,kind:'barrel',hp:65},{x:400,y:400,w:80,h:56,kind:'wall',hp:-1}];
  s.hazards=['recovery','warning','active'].map((state,i)=>({x:170+i*140,y:220,r:22,kind:'spike',state,offset:0}));
  const masks=JSON.stringify(s.obstacles),traps=JSON.stringify(s.hazards);d.draw();check(JSON.stringify(s.obstacles)===masks&&JSON.stringify(s.hazards)===traps,'new artwork leaves masks, health and trap states intact');
  const broken={x:450,y:330,r:16};d.resolveSolid(broken);check(broken.x===450&&broken.y===330,'destroyed barrier remains passable');
  check(document.getElementById('game').dataset.warlordProps==='ready','embedded alpha atlas loads');
  check(document.getElementById('game').dataset.warlordDecor==='ready','embedded decoration atlas loads');
  return checks;
 });assert.ok(count>40);await page.locator('#game').screenshot({path:'warlord-traps-barriers-preview.png'});console.log(count+' Warlord checks passed');
 }finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
