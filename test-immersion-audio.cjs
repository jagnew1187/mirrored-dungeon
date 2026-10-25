const path=require('node:path'),assert=require('node:assert/strict');let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 let checks=0;
 for(const mobile of [false,true]){
  const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile}),errors=[];
  page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>{const raf=window.requestAnimationFrame.bind(window);window.requestAnimationFrame=fn=>fn.name==="frame"?0:raf(fn)});await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug?.audio);
  assert.equal(await page.evaluate(()=>MirroredDungeonDebug.audio.snapshot().state),'locked');checks++;
  await page.locator('#overlayButton').click();await page.waitForFunction(()=>MirroredDungeonDebug.audio.snapshot().state==='running');
  assert.equal(await page.evaluate(()=>MirroredDungeonDebug.audio.snapshot().scene),'camp');checks++;
  await page.waitForFunction(()=>MirroredDungeonDebug.audio.meter()>.00001);checks++;
  assert.ok(await page.evaluate(()=>{const d=MirroredDungeonDebug,s=d.state();s.enemies=[];s.campFriends=[];const before=d.audio.snapshot().footsteps;d.keys.add('d');for(let i=0;i<30;i++)d.step(.02);d.keys.clear();return d.audio.snapshot().footsteps>before}));checks++;
  for(const boss of ['warlord','necro','pyro']){
   await page.evaluate(boss=>{const d=MirroredDungeonDebug;d.reset();d.start();d.selectBoss(boss);d.renderAll()},boss);
   assert.equal(await page.evaluate(()=>MirroredDungeonDebug.audio.snapshot().scene),boss);checks++;
   const intro=await page.evaluate(()=>{const d=MirroredDungeonDebug,s=d.state();s.enemies=[];d.enterBoss();const start=s.elapsed,time=s.time,arrival=s.immersion.arrival.id;d.step(.1);d.renderAll();d.draw();return{arrival,scene:d.audio.snapshot().scene,elapsed:s.elapsed-start,ticking:s.time<time}});
   assert.equal(intro.arrival,boss);assert.equal(intro.scene,'boss-'+boss);assert.ok(intro.elapsed>.09&&intro.ticking);checks+=3;
   await page.locator('#game').screenshot({path:boss+'-'+(mobile?'mobile-':'')+'arrival-preview.png'});
  }
  await page.evaluate(()=>{const d=MirroredDungeonDebug;d.state().paused=true;d.renderAll()});await page.waitForFunction(()=>MirroredDungeonDebug.audio.snapshot().state==='suspended');checks++;
  await page.evaluate(()=>{const d=MirroredDungeonDebug;d.state().paused=false;d.renderAll()});await page.keyboard.press('a');await page.waitForFunction(()=>MirroredDungeonDebug.audio.snapshot().state==='running');checks++;
  await page.locator('.audio-settings summary').click();await page.locator('#audioMute').click();assert.equal(await page.locator('#audioMute').getAttribute('aria-pressed'),'true');checks++;
  await page.waitForFunction(()=>MirroredDungeonDebug.audio.meter()<.000001);checks++;
  await page.locator('#audioMaster').evaluate(el=>el.value='30');await page.locator('#audioMaster').dispatchEvent('input');assert.equal(await page.evaluate(()=>MirroredDungeonDebug.audio.snapshot().master),.3);checks++;
  await page.reload();await page.waitForFunction(()=>window.MirroredDungeonDebug?.audio);const saved=await page.evaluate(()=>MirroredDungeonDebug.audio.snapshot());assert.ok(saved.muted&&saved.master===.3&&!saved.unlocked);checks++;
  await page.locator('#overlayButton').click();await page.keyboard.press('m');assert.equal(await page.evaluate(()=>MirroredDungeonDebug.audio.snapshot().muted),false);checks++;
  await page.evaluate(()=>{const d=MirroredDungeonDebug;d.selectBoss('warlord');const s=d.state();s.enemies=[];d.step(.01);const o=s.obstacles.find(o=>o.hp>0);o.hp=0;d.step(.01)});
  assert.ok(await page.evaluate(()=>MirroredDungeonDebug.state().immersion.dust.length>0));checks++;
  assert.ok(await page.evaluate(()=>{const d=MirroredDungeonDebug,s=d.state(),before=JSON.stringify({obstacles:s.obstacles,hazards:s.hazards,elapsed:s.elapsed,dust:s.immersion.dust});d.draw();d.draw();return before===JSON.stringify({obstacles:s.obstacles,hazards:s.hazards,elapsed:s.elapsed,dust:s.immersion.dust})}));checks++;
  await page.emulateMedia({reducedMotion:'reduce'});await page.evaluate(()=>{const d=MirroredDungeonDebug,s=d.state();s.immersion.dust=[];const o=s.obstacles.find(o=>o.hp>0);o.hp=0;d.step(.01);d.draw()});assert.equal(await page.evaluate(()=>MirroredDungeonDebug.state().immersion.dust.length),0);checks++;
  // Crossfaded graphs retire after their scheduled fade; voices have a hard cap.
  await page.waitForFunction(()=>MirroredDungeonDebug.audio.snapshot().buses<=1,{},{timeout:5000});assert.ok(await page.evaluate(()=>MirroredDungeonDebug.audio.snapshot().voices<=48));checks++;
  assert.deepEqual(errors,[]);checks++;await page.close();
 }
 const unsupported=await browser.newPage();await unsupported.addInitScript(()=>{window.AudioContext=undefined;window.webkitAudioContext=undefined});await unsupported.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await unsupported.locator('#overlayButton').click();assert.ok(await unsupported.evaluate(()=>MirroredDungeonDebug.state().lobby&&!MirroredDungeonDebug.audio.snapshot().available));checks++;await unsupported.close();
 console.log(checks+' audio unlock/output, scenes, transitions, pause, preferences, mobile, particles and graceful fallback checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
