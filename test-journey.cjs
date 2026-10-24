const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 let checks=0;
 for(const mobile of [false,true]){
  const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile}),errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug&&document.getElementById('game').dataset.journeyAssets==='ready'&&document.getElementById('game').dataset.campMaterials==='ready'&&document.getElementById('game').dataset.buffArt==='ready');
  await page.evaluate(()=>{const d=MirroredDungeonDebug;d.start();d.draw()});if(mobile)await page.locator('#bossClose').tap();await page.locator('#game').screenshot({path:mobile?'mobile-camp-preview.png':'heroes-camp-preview.png'});
  assert.equal(await page.locator('#arenaTag').textContent(),'HEROES’ CAMP');checks++;
  for(const boss of ['warlord','necro','pyro']){
   const result=await page.evaluate(boss=>{const d=MirroredDungeonDebug;d.reset();d.start();d.selectBoss(boss);const s=d.state(),r=s.gauntlet.room,mask=JSON.stringify(s.obstacles);d.draw();const intact=mask===JSON.stringify(s.obstacles),posts=s.obstacles.filter(o=>o.kind==='gateway');
    s.enemies=[];s.hero.x=r.mainX;s.hero.y=235;d.renderAll();d.draw();return {intact,posts:posts.length,valid:d.validate(r.obstacles,r)};
   },boss);assert.ok(result.intact&&result.valid&&result.posts===2);checks++;
   await page.locator('#game').screenshot({path:`${boss}-${mobile?'mobile-':''}entrance-preview.png`});
   const phase=await page.evaluate(()=>{const d=MirroredDungeonDebug,s=d.state();s.hero.y=129;d.step(.01);return s.phase});assert.equal(phase,'boss');checks++;
  }
  assert.deepEqual(errors,[]);checks++;await page.close();
 }console.log(checks+' journey/camp checks passed');
 }finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
