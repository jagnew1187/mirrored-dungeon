const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 const page=await browser.newPage();await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug&&['Mage','Knight','Rogue'].every(c=>document.getElementById('game').dataset['hero'+c]==='ready'));
 const count=await page.evaluate(()=>{
  const d=MirroredDungeonDebug;let n=0;const check=(v,m)=>{if(!v)throw Error(m);n++};
  for(const cls of ['mage','knight','rogue']){
   d.reset();d.chooseClass(cls);d.start();d.selectBoss('warlord');const s=d.state(),h=s.hero;s.enemies=[];s.hazards=[];s.waveAt=9999;h.x=386;h.y=1600;h.attack=999;
   d.keys.add('w');d.step(.04);d.keys.clear();check(h.move&&h.walkCycle>0,'actual travel advances walk');
   const phase=h.walkCycle;d.draw();d.draw();check(h.walkCycle===phase,'rendering cannot advance gait');
   const walker={cls,x:88,y:0};d.trackMotion(walker,{x:0,y:0},1);check(Math.abs(walker.walkCycle-({knight:1,mage:88/84,rogue:88/92}[cls]))<1e-9,'distance-based stride matches each class animation');
   const stoppedPhase=walker.walkCycle;d.trackMotion(walker,{x:88,y:0},.04);check(walker.walkCycle===stoppedPhase&&walker.walkSettle===.1,'stop preserves gait and starts short settle');
   d.trackMotion(walker,{x:88,y:0},.11);check(walker.walkSettle===0&&walker.walkCycle===stoppedPhase,'settle expires without advancing feet');
   walker.x=176;d.trackMotion(walker,{x:88,y:0},1);check(Math.abs(walker.walkCycle-stoppedPhase*2)<1e-9&&walker.walkSettle===0,'restart resumes gait without resetting');
   const actor={x:104,y:0};d.trackMotion(actor,{x:0,y:0},1);check(actor.walkCycle===1,'one gait cycle per stride');
   const a={x:52,y:0};d.trackMotion(a,{x:0,y:0},.5);a.x=104;d.trackMotion(a,{x:52,y:0},.5);check(a.walkCycle===actor.walkCycle,'gait independent of timestep');
   s.obstacles=[{x:400,y:1500,w:32,h:200,hp:-1,kind:'wall'}];h.x=384;h.y=1600;d.keys.add('d');d.step(.04);d.keys.clear();check(!h.move&&h.walkCycle===phase,'blocked input freezes the existing gait phase');
   h.attackAnim=.32;const first=d.animationIndex(cls,'attack',h);h.attackAnim=.01;const last=d.animationIndex(cls,'attack',h);check(first===8&&last===15,'one-shot attack plays from first to final frame');
   h.skillAnim=.66;check(d.animationIndex(cls,'skill',h)===8,'skill starts at first frame');
   const e={id:'test',type:'shade',sprite:'cultist',x:200,y:200,r:11,hp:100,max:100,dead:false};s.enemies=[e];s.obstacles=[];
   const bullet={x:100,y:200,vx:2000,vy:0,r:4,damage:10,team:'hero',ttl:3};d.advanceProjectile(bullet,.1);check(e.hp===90&&bullet.ttl===0,'fast projectile hits crossed target');
   e.hp=100;s.obstacles=[{x:150,y:180,w:20,h:40,hp:-1}];const blocked={...bullet,x:100,ttl:3};d.advanceProjectile(blocked,.1);check(e.hp===100&&blocked.ttl===0,'cover before enemy blocks shot');
   s.obstacles=[{x:250,y:180,w:20,h:40,hp:-1}];const near={...bullet,x:100,ttl:3};d.advanceProjectile(near,.1);check(e.hp===90,'enemy before wall receives hit');
   check(s.sparks.length>0,'actual hit emits feedback');d.reset();check(d.state().sparks.length===0,'reset clears feedback');
  }return n;
 });assert.equal(count,48);console.log(count+' combat/animation checks passed');
 }finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
