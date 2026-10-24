const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug);
 const checks=await page.evaluate(()=>{
  const d=MirroredDungeonDebug;let checks=0;const check=(v,m)=>{if(!v)throw Error(m);checks++};
  for(const cls of ['mage','knight','rogue']){
   d.reset();d.chooseClass(cls);d.start();const s=d.state();s.waveAt=9999;s.rival.remaining=9999;s.hero.x=770;s.hero.y=570;s.hero.hp=9999;s.hero.attack=999;d.step(.01);
   check(s.campFriends.length===2&&s.campFriends.every(a=>a.cls!==cls),'other two classes assist');
   for(const ally of s.campFriends){
    for(const a of s.campFriends)a.attackCd=999;ally.attackCd=0;
    const mob={id:'camp'+checks,type:'shade',sprite:'cultist',x:ally.x+45,y:ally.y,r:11,hp:40,max:40,speed:0,dmg:0,attack:999,ability:999,slow:0,dead:false,hit:0,move:false,facing:1,attackAnim:0,skillAnim:0};s.enemies=[mob];s.shots=[];const sent=s.mobSent;
    let frames=0;while(!mob.dead&&frames++<350)d.step(.04);check(mob.dead,'companion '+ally.cls+' kills a real mob without player attacks');check(s.mobSent===sent+1,'normal kill bookkeeping exactly once');
   }
   const before=s.elapsed;s.paused=true;d.step(1);check(s.elapsed===before,'pause stops companion combat');s.paused=false;
   d.selectBoss('warlord');d.step(.01);check(!s.campFriends&&!s.shots.some(p=>p.campAlly),'companions and their shots stay out of dungeons');
   d.reset();check(!d.state().campFriends,'restart clears companions');
  }return checks;
 });assert.equal(checks,24);console.log(checks+' camp companion checks passed');
 }finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
