const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 let checks=0;
 for(const mobile of [false,true]){
  const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile}),errors=[];
  page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
  await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug);
  await page.locator('#overlayButton').click();
  checks+=await page.evaluate(()=>{
   const d=MirroredDungeonDebug;let n=0;const check=(ok,msg)=>{if(!ok)throw Error(msg);n++};
   for(const cls of ['mage','knight','rogue']){
    d.reset();d.chooseClass(cls);d.start();let s=d.state();
    check(s.lobby&&s.phase==='vault'&&!s.rival,'practice starts with no rival');
    check(s.enemies.length===2,'immediate practice targets');
    d.setAttackInput(true,'lobby-test');
    for(let i=0;i<2400;i++)d.step(.1);
    check(s.mode==='running'&&s.time===210&&!s.rival&&s.botKills===0,'practice cannot spend match time or advance rival');
    check(s.enemies.length>0&&s.enemies.length<=6,'practice mobs replenish with a bounded count');
    s.hero.hp=1;s.enemies=[{...s.enemies[0],x:s.hero.x,y:s.hero.y,hp:9999,max:9999,dmg:9999,attack:0}];d.setAttackInput(false,'lobby-test');d.step(.01);d.step(.22);
    check(s.mode==='running'&&s.hero.hp===s.hero.max,'falling in camp recovers without losing');
    s.hero.cd.fire=99;s.hero.jumpCooldown=1;s.mobSent=99;s.pending=7;s.hero.hp=2;
    d.selectBoss('warlord');s=d.state();
    check(!s.lobby&&s.rival&&s.phase==='gauntlet'&&s.elapsed===0&&s.time===210,'first boss starts both competitors at zero');
    check(s.hero.hp===s.hero.max&&s.hero.cd.fire===0&&s.hero.jumpCooldown===0&&s.mobSent===0&&s.pending===0,'practice state cannot carry into match');
    const remaining=s.rival.remaining;d.step(.1);
    check(s.time<210&&s.elapsed>.09&&s.rival.remaining<remaining,'match clock and rival advance together');
    s.paused=true;const time=s.time;d.step(1);check(s.time===time,'pause remains functional');s.paused=false;
    s.phase='vault';s.active=null;s.enemies=[];d.step(.1);check(s.time<time,'returning to camp during match remains timed');
   }
   d.reset();d.start();d.renderAll();d.draw();check(document.getElementById('clock').textContent==='LOBBY','lobby clock is clear');
   check(!document.body.classList.contains('boss-sheet-open'),'practice begins unobstructed on mobile');return n;
  });
  await page.locator('#game').screenshot({path:mobile?'mobile-lobby-preview.png':'camp-lobby-preview.png'});
  if(mobile){await page.locator('#bossToggle').tap();assert.ok(await page.locator('body').evaluate(el=>el.classList.contains('boss-sheet-open')));checks++}
  await page.locator('[data-boss="warlord"]').click();
  assert.ok(await page.evaluate(()=>{const s=MirroredDungeonDebug.state();return !s.lobby&&s.phase==='gauntlet'&&!!s.rival&&s.time===210}));checks++;
  assert.deepEqual(errors,[]);checks++;await page.close();
 }
 console.log(checks+' practice lobby and fresh match checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
