const path=require('node:path'),assert=require('node:assert/strict');let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{let checks=0;
 for(const viewport of [{width:1440,height:1000},{width:390,height:844},{width:320,height:568}]){const mobile=viewport.width<600;
  const page=await browser.newPage({viewport,isMobile:mobile,hasTouch:mobile});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug&&document.getElementById('game').dataset.campPavilion==='ready');
  await page.evaluate(()=>{MirroredDungeonDebug.start();MirroredDungeonDebug.draw()});assert.ok(await page.locator('.practice-panel').isVisible());checks++;
  assert.equal(await page.locator('#practiceKills').textContent(),'0');checks++;
  await page.evaluate(()=>{const d=MirroredDungeonDebug;d.damage(d.state().enemies[0],9999);d.renderAll()});assert.equal(await page.locator('#practiceKills').textContent(),'1');checks++;
  await page.locator('#practiceWave').click();assert.equal(await page.evaluate(()=>MirroredDungeonDebug.state().enemies.filter(e=>!e.dead).length),5);checks++;
  await page.locator('#practiceWave').click();await page.locator('#practiceWave').click();assert.ok(await page.locator('#practiceWave').isDisabled());checks++;
  assert.ok(await page.evaluate(()=>{const s=MirroredDungeonDebug.state();return s.enemies.filter(e=>!e.dead).length===12&&s.time===210&&!s.rival}));checks++;
  await page.evaluate(()=>{const d=MirroredDungeonDebug,s=d.state();s.paused=true;d.renderAll()});assert.ok(await page.locator('#practiceWave').isDisabled());checks++;
  await page.evaluate(()=>{const d=MirroredDungeonDebug,s=d.state();s.paused=false;d.damage(s.enemies.find(e=>!e.dead),9999);d.renderAll()});assert.equal(await page.locator('#practiceKills').textContent(),'2');checks++;
  const button=await page.locator('#practiceWave').boundingBox(),canvas=await page.locator('#game').boundingBox();assert.ok(button.height>=44&&button.x>=canvas.x&&button.x+button.width<=canvas.x+canvas.width);checks++;
  if(mobile){const jump=await page.locator('#jumpButton').boundingBox(),stick=await page.locator('#touchJoystick').boundingBox();assert.ok(button.y+button.height<jump.y&&button.y+button.height<stick.y);checks++}
  await page.evaluate(()=>MirroredDungeonDebug.draw());await page.locator('#game').screenshot({path:mobile?'mobile-practice-pavilion-preview.png':'practice-pavilion-preview.png'});
  await page.evaluate(()=>MirroredDungeonDebug.selectBoss('warlord'));assert.ok(await page.locator('.practice-panel').isHidden());checks++;
  assert.ok(await page.evaluate(()=>{const s=MirroredDungeonDebug.state();return s.mobSent===0&&s.elapsed===0&&!!s.rival}));checks++;
  await page.evaluate(()=>{MirroredDungeonDebug.reset();MirroredDungeonDebug.start()});assert.equal(await page.locator('#practiceKills').textContent(),'0');checks++;await page.close();
 }
 console.log(checks+' pavilion, practice kills, extra waves, cap, pause, fresh-match and mobile control checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
