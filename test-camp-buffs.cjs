const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 let checks=0;
 for(const mobile of [false,true]){
  const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile}),errors=[];page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
  await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug&&document.getElementById('game').dataset.campMaterials==='ready'&&document.getElementById('game').dataset.buffArt==='ready');
  const result=await page.evaluate(()=>{const d=MirroredDungeonDebug;d.start();d.selectBoss('warlord');const s=d.state(),config=JSON.stringify(d.config),mask=JSON.stringify(s.obstacles),images=[];
   for(const id of ['edge','ward','crystal','surge']){s.gauntlet.options=[id];d.renderAll();const c=document.querySelector('canvas[data-reward-icon]');if(c.width!==80||c.height!==80)throw Error('high-density reward canvas missing');images.push(c.toDataURL())}
   s.gauntlet.options=['edge','ward','surge'];s.hero.x=s.gauntlet.room.rewardX;s.hero.y=s.gauntlet.room.rewardY;s.enemies=[];s.gauntlet.committed=true;s.gauntlet.commitTime=s.elapsed;d.chooseRewards();d.renderAll();d.draw();
   return{distinct:new Set(images).size,unchanged:mask===JSON.stringify(s.obstacles)&&config===JSON.stringify(d.config),text:document.getElementById('rewardPanel').textContent};
  });assert.equal(result.distinct,4);assert.ok(result.unchanged);assert.ok(result.text.includes('30%')&&result.text.includes('20%')&&result.text.includes('15s'));checks+=3;
  await page.screenshot({path:mobile?'mobile-buff-art-preview.png':'buff-art-preview.png',fullPage:false});
  if(mobile)await page.locator('[data-reward="edge"]').tap();else await page.locator('[data-reward="edge"]').click();assert.equal(await page.evaluate(()=>MirroredDungeonDebug.state().reward.status),'pending');checks++;
  await page.evaluate(()=>{MirroredDungeonDebug.draw()});assert.deepEqual(errors,[]);checks++;await page.close();
 }console.log(checks+' camp/buff art checks passed');
 }finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
