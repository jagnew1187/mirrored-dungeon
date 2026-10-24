const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
let total=0;
for(const mobile of [false,true]){
 const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
 const errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));
 await page.waitForFunction(()=>window.MirroredDungeonDebug&&['mage','rogue'].every(cls=>['right','southeast','down','southwest','left','northwest','up','northeast'].every(dir=>document.getElementById('game').dataset[cls+'Gait'+dir]==='ready')));
 total+=await page.evaluate(()=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d');let n=0;const check=(v,m)=>{if(!v)throw Error(m);n++};
  for(const cls of ['mage','rogue']){
   d.reset();d.chooseClass(cls);d.start();d.selectBoss('warlord');const s=d.state();s.enemies=[];s.obstacles=[];s.hazards=[];s.waveAt=9999;s.hero.attack=999;
   for(const [keys,dir] of [['d','right'],['sd','southeast'],['s','down'],['sa','southwest'],['a','left'],['wa','northwest'],['w','up'],['wd','northeast']]){
    s.hero.x=420;s.hero.y=1500;const old={x:s.hero.x,y:s.hero.y},phase=s.hero.walkCycle||0;
    for(const key of keys)d.keys.add(key);d.step(.04);d.keys.clear();const distance=Math.hypot(s.hero.x-old.x,s.hero.y-old.y);
    check(s.hero.walkDirection===dir,cls+' input selects '+dir);check(Math.abs(distance-(cls==='mage'?225:280)*.04)<1e-6,'travel speed remains unchanged, including diagonal normalization');
    check(Math.abs(s.hero.walkCycle-phase-distance/(cls==='mage'?84:92))<1e-6,'distance-based class stride');
    const stopped=s.hero.walkCycle;d.step(.04);check(!s.hero.move&&s.hero.walkCycle===stopped&&s.hero.walkDirection===dir,'stopping retains phase and facing');
    let args,mirrored=false;const draw=g.drawImage,scale=g.scale;g.drawImage=function(...a){args=a;return draw.apply(this,a)};g.scale=function(x,y){if(x<0)mirrored=true;return scale.call(this,x,y)};
    try{
     const poses=new Set();
     for(let frame=0;frame<8;frame++){
      d.drawHeroSprite(cls,420,310,78,92,'walk',-1,0,0,{walkDirection:dir,walkCycle:(frame+.01)/8});
      const image=args[0],r=image.gaitData.frames[frame],factor=92*.88*.85/image.gaitData.bodyHeight;
      check(image.gaitClass===cls&&image.gaitDirection===dir&&args[1]===r.x&&args[2]===r.y,'ordered authored class/direction frame');
      check(r.x>=0&&r.y>=0&&r.x+r.w<=image.width&&r.y+r.h<=image.height,'cached frame bounds');
      check(Math.abs(args[6]+r.anchorY*factor)<1e-6,'grounded boot baseline');poses.add(args[1]+':'+args[2]);
     }
     check(poses.size===8,'eight actual walking poses');
     const image=args[0];check(image.tagName==='CANVAS'&&image.width*image.height<image.sourcePixels,'compact atlas cache reduces decoded pixels');
     check(Math.abs(image.gaitData.bodyHeight-144)<1,'cache retains approximately 2x game body resolution');
     d.drawHeroSprite(cls,420,310,78,92,'idle',-1,0,0,s.hero);const idle=image.gaitData.frames[8];
     check(args[0]===image&&args[1]===idle.x&&args[2]===idle.y,'dedicated standing pose matches last direction');check(!mirrored,'authored views never mirror held equipment');
    }finally{g.drawImage=draw;g.scale=scale}
   }
   for(const [previous,angle,expected] of [['right',24,'right'],['right',31,'southeast'],['southeast',20,'southeast'],['southeast',15,'right']]){
    const angleRadians=angle*Math.PI/180,a={cls,x:10*Math.cos(angleRadians),y:10*Math.sin(angleRadians),walkDirection:previous};d.trackMotion(a,{x:0,y:0},.1);check(a.walkDirection===expected,'class angular hysteresis');
   }
  }return n;
 });assert.deepEqual(errors,[]);
 await page.emulateMedia({reducedMotion:'reduce'});
 total+=await page.evaluate(()=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d');let n=0;
  for(const cls of ['mage','rogue']){let first,last;const draw=g.drawImage;g.drawImage=function(...a){last=a;return draw.apply(this,a)};
   try{d.drawHeroSprite(cls,420,310,78,92,'walk',1,0,0,{walkDirection:'down',walkCycle:0});first=last.slice();d.drawHeroSprite(cls,420,310,78,92,'walk',1,0,0,{walkDirection:'down',walkCycle:.5});if(first[1]===last[1]&&first[2]===last[2])throw Error('reduced motion must retain essential walk poses');n++}finally{g.drawImage=draw}
  }return n;
 });await page.close();
}
const page=await browser.newPage();await page.goto('file:///'+path.resolve('heroes-walk-review.html').replaceAll('\\','/'));
await page.waitForFunction(()=>['mage','rogue'].every(cls=>Object.keys(art[cls]).length===8));
for(const cls of ['mage','rogue'])for(const view of ['cardinal','diagonal']){
 await page.locator('#character').selectOption(cls);await page.locator('#views').selectOption(view);await page.locator('#pose').evaluate(e=>{e.value='4';e.dispatchEvent(new Event('input'))});
 assert.equal(await page.locator('#play').innerText(),'Play');total++;
 await page.locator('canvas').screenshot({path:cls+'-'+view+'-gait-preview.png'});
 await page.locator('#stand').click();assert.equal(await page.locator('#stand').innerText(),'Walk');total++;
 await page.locator('canvas').screenshot({path:cls+'-'+view+'-standing-preview.png'});
}
console.log(total+' Wizard/Rogue movement, standing, cache, desktop/mobile and preview checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
