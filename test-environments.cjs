const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
 await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug);
 await page.waitForFunction(()=>document.getElementById('game').dataset.warlordDecor==='ready');
 const images=[];
 for(const boss of ['warlord','pyro','necro'])for(const arena of [false,true]){
  const result=await page.evaluate(({boss,arena})=>{const d=MirroredDungeonDebug;d.reset();d.start();d.selectBoss(boss);const s=d.state(),mask=JSON.stringify(s.obstacles);d.draw();const unchanged=JSON.stringify(s.obstacles)===mask;
   if(arena)d.enterBoss();d.draw();const canvas=document.getElementById('game');return{unchanged,phase:s.phase,spawn:s.obstacles.every(o=>!(s.hero.x+s.hero.r>o.x&&s.hero.x-s.hero.r<o.x+o.w&&s.hero.y+s.hero.r>o.y&&s.hero.y-s.hero.r<o.y+o.h)),image:canvas.toDataURL()};},{boss,arena});
  assert.ok(result.unchanged,'rendering cannot mutate collision mask');assert.ok(result.spawn,'entrance is clear');assert.equal(result.phase,arena?'boss':'gauntlet');images.push(result.image);
  await page.locator('#game').screenshot({path:`${boss}-${arena?'arena':'gauntlet'}-preview.png`});
 }
 assert.equal(new Set(images).size,6,'all six environments visually distinct');console.log('19 environment checks passed; six scene previews captured.');
 }finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
