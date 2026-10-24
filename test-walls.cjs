const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 let checks=0;
 for(const mobile of [false,true]){
  const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile}),errors=[];page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
  await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug&&document.getElementById('game').dataset.pyroAssets==='ready'&&document.getElementById('game').dataset.necroAssets==='ready'&&document.getElementById('game').dataset.warlordTiles==='ready');
  for(const boss of ['warlord','necro','pyro']){
   const result=await page.evaluate(boss=>{const d=MirroredDungeonDebug;d.reset();d.start();d.selectBoss(boss);const s=d.state();s.enemies=[];s.hero.y=1750;s.gauntlet.claimed=true;d.renderAll();const before=JSON.stringify(s.obstacles);d.draw();
    const wall=s.obstacles.find(o=>o.kind==='masonry'),e={x:wall.x+wall.w/2,y:1700,r:16};d.resolveSolid(e,{x:wall.x-32,y:1700});
    const pixels=()=>Array.from(document.getElementById('game').getContext('2d').getImageData(wall.x-4,Math.round(1600-d.cameraY()),22,20).data).join(',');const first=pixels();s.hero.y+=29;d.draw();const stable=first===pixels();
    return{same:before===JSON.stringify(s.obstacles),solid:e.x===wall.x-32,valid:d.validate(s.obstacles,s.gauntlet.room),stable};
   },boss);assert.ok(result.same&&result.valid,'projection preserves navigable masks');assert.ok(result.solid,'wall footprint still blocks movement');assert.ok(result.stable,'wall pixels stay fixed in world coordinates while scrolling');checks+=3;
   await page.locator('#game').screenshot({path:`${boss}-${mobile?'mobile-':''}raised-walls-preview.png`});
  }assert.deepEqual(errors,[]);checks++;await page.close();
 }console.log(checks+' wall rendering checks passed');
 }finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
