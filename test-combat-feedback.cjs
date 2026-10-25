const path=require('node:path'),assert=require('node:assert/strict');let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 const page=await browser.newPage();await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug);
 const checks=await page.evaluate(()=>{
  const d=MirroredDungeonDebug;let n=0;const check=(v,m)=>{if(!v)throw Error(m);n++},advance=t=>{while(t>1e-8){const dt=Math.min(.01,t);d.step(dt);t-=dt}};
  function fresh(cls='knight'){
   d.reset();d.chooseClass(cls);d.start();d.selectBoss('warlord');d.enterBoss();const s=d.state();s.enemies=[];s.obstacles=[];s.hazards=[];s.waveAt=9999;s.rival.remaining=9999;s.hero.x=420;s.hero.y=310;return s;
  }
  const mob=(x=460)=>({id:'timing',type:'shade',sprite:'cultist',x,y:310,r:11,hp:1000,max:1000,speed:0,dmg:7,attack:999,ability:999,slow:0,dead:false,hit:0,attackAnim:0,skillAnim:0});
  for(const cls of ['knight','mage','rogue']){
   let s=fresh(cls),e=mob();s.enemies=[e];d.setAttackInput(true,'test');d.setAttackInput(false,'test');d.step(.01);
   check(e.hp===1000&&s.shots.length===0&&!!s.hero.pendingBasic,cls+' starts anticipation without immediate damage');
   advance(d.playerActions.impactDelay[cls]-.02);check(e.hp===1000&&s.shots.length===0,cls+' no early impact');advance(.04);
   check(cls==='knight'?e.hp===966:s.shots.length===1,cls+' releases at authored frame');
   advance(.2);check(e.hp===1000-({knight:34,mage:23,rogue:19}[cls]),cls+' one attack deals damage exactly once');
   s=fresh(cls);e=mob(440);e.attack=0;s.enemies=[e];const hp=s.hero.hp;d.step(.01);
   check(s.hero.hp===hp&&e.contactStrike&&e.attackAnim>0,cls+' enemy windup visible before contact');advance(.15);check(s.hero.hp===hp,'no early enemy damage');s.hero.x=580;advance(.08);check(s.hero.hp===hp&&!e.contactStrike,'moving away evades committed contact');
   s=fresh(cls);e=mob(440);e.attack=0;s.enemies=[e];const full=s.hero.hp;advance(.23);check(s.hero.hp===full-7,'contact lands once after windup');
   s=fresh(cls);s.phase='gauntlet';s.elapsed=s.gauntlet.start+1.3;s.hazards=[{x:s.hero.x,y:s.hero.y,r:22,kind:'burn',offset:0}];const before=s.hero.hp;d.step(.01);
   check(s.hero.hp===before&&s.hero.burnUntil>s.elapsed,'burn starts without instant spike damage');s.hazards=[];advance(2.01);
   check(Math.abs(before-s.hero.hp-d.config.hazardDamage)<1e-6,'complete burn equals one spike');check(!s.hero.burnUntil,'burn expires');
   s=fresh(cls);s.phase='gauntlet';s.elapsed=s.gauntlet.start+1.3;s.hazards=[{x:s.hero.x,y:s.hero.y,r:22,kind:'fire',offset:0}];d.step(.01);const tick=s.hero.burnNextTick,amount=s.hero.burnTickDamage;advance(.3);
   check(s.hero.burnNextTick===tick&&s.hero.burnTickDamage===amount,'continued contact refreshes one burn without stacking or delaying ticks');
   s.paused=true;const until=s.hero.burnUntil;d.step(1);check(s.hero.burnUntil===until,'pause freezes burn');s.paused=false;
   s=fresh(cls);const x=s.hero.x;d.keys.add('d');d.step(.2);d.keys.clear();const normal=s.hero.x-x;s.hero.x=x;s.hero.slowUntil=s.elapsed+.8;d.keys.add('d');d.step(.2);d.keys.clear();check(Math.abs((s.hero.x-x)/normal-.75)<1e-8,'rune slow reduces travel by exactly 25 percent');
   d.reset();check(!d.state().hero.burnUntil&&!d.state().hero.pendingBasic,'restart clears burn and committed strikes');
   s=fresh(cls);s.phase='gauntlet';s.elapsed=s.gauntlet.start+1.3;s.hazards=[{x:s.hero.x,y:s.hero.y,r:22,kind:'burn',offset:0}];d.step(.01);s.hazards=[];s.hero.hp=1;const deathX=s.hero.x;d.keys.add('d');d.step(.6);d.keys.clear();check(s.mode==='lose'&&s.hero.x===deathX,'lethal burn ends simulation before movement or attacks');
  }
  return n;
 });assert.equal(checks,48);console.log(checks+' attack impact, dodgeable windup, burn total/refresh, slow and reset checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
