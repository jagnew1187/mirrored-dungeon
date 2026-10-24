const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
let checks=0;
for(const mobile of [false,true]){
 const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile});
 await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));
 await page.waitForFunction(()=>window.MirroredDungeonDebug&&['southeast','southwest','northeast','northwest'].every(dir=>document.getElementById('game').dataset['knightGait'+dir]==='ready'));
 checks+=await page.evaluate(()=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d');let n=0;const check=(value,message)=>{if(!value)throw Error(message);n++};
 d.reset();d.chooseClass('knight');d.start();d.selectBoss('warlord');const s=d.state();s.enemies=[];s.obstacles=[];s.hazards=[];s.waveAt=9999;s.hero.attack=999;
 for(const [keys,direction] of [['sd','southeast'],['sa','southwest'],['wd','northeast'],['wa','northwest']]){
  s.hero.x=420;s.hero.y=1500;const old={x:s.hero.x,y:s.hero.y},phase=s.hero.walkCycle||0;
  for(const key of keys)d.keys.add(key);d.step(.04);d.keys.clear();const distance=Math.hypot(s.hero.x-old.x,s.hero.y-old.y);
  check(s.hero.walkDirection===direction,'diagonal input selects '+direction);check(Math.abs(distance-204*.04)<1e-6,'diagonal travel is normalized');
  check(Math.abs(s.hero.walkCycle-phase-distance/88)<1e-6,'turning preserves stride phase');
  const frozen=s.hero.walkCycle;d.step(.04);check(!s.hero.move&&s.hero.walkCycle===frozen&&s.hero.walkDirection===direction,'diagonal standing retains direction');
  const draw=g.drawImage,scale=g.scale;let args,mirrored=false;g.drawImage=function(...a){args=a;return draw.apply(this,a)};g.scale=function(x,y){if(x<0)mirrored=true;return scale.call(this,x,y)};
  try{
   const poses=new Set();
   for(let frame=0;frame<8;frame++){
    d.drawHeroSprite('knight',420,310,78,92,'walk',1,0,0,{walkDirection:direction,walkCycle:(frame+.01)/8});
    const img=args[0],r=img.gaitData.frames[frame],factor=92*.88*.85/img.gaitData.bodyHeight;
    check(img.gaitDirection===direction&&args[1]===r.x&&args[2]===r.y,'correct diagonal walk source');
    check(r.x>=0&&r.y>=0&&r.x+r.w<=img.naturalWidth&&r.y+r.h<=img.naturalHeight,'diagonal sampling bounds');
    check(Math.abs(args[6]+r.anchorY*factor)<1e-6,'diagonal boots at ground baseline');poses.add(args[1]+':'+args[2]);
   }
   check(poses.size===8,'eight distinct diagonal source cells');
   d.drawHeroSprite('knight',420,310,78,92,'idle',1,0,0,s.hero);const img=args[0],r=img.gaitData.frames[8];
   check(img.gaitDirection===direction&&args[1]===r.x&&args[2]===r.y,'dedicated planted diagonal idle');check(!mirrored,'diagonal equipment is never mirrored');
  }finally{g.drawImage=draw;g.scale=scale}
 }
 // Angles near a sector edge retain the previous view until leaving the overlap.
 for(const [previous,angle,expected] of [['right',24,'right'],['right',31,'southeast'],['southeast',20,'southeast'],['southeast',15,'right'],['up',-66,'up'],['up',-59,'northeast']]){
  const r=angle*Math.PI/180,a={cls:'knight',x:Math.cos(r)*10,y:Math.sin(r)*10,walkDirection:previous};d.trackMotion(a,{x:0,y:0},.1);check(a.walkDirection===expected,'eight-sector hysteresis');
 }
 return n;
 });await page.close();
}
assert.equal(checks,260);console.log(checks+' diagonal Knight keyboard, mobile-layout, frame, standing and angle checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
