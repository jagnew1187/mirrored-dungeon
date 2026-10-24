const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{let total=0;
for(const mobile of [false,true]){
 const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
 const errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));
 await page.waitForFunction(()=>window.MirroredDungeonDebug);
 for(const kind of ['warlord','pyro','necro']){
  await page.evaluate(kind=>{const d=MirroredDungeonDebug;d.reset();d.chooseClass('knight');d.start();d.selectBoss(kind)},kind);
  await page.waitForFunction(kind=>['left','right'].every(side=>document.getElementById('game').dataset['bossSkill'+kind+side]==='ready'),kind);
  total+=await page.evaluate(kind=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d');let n=0;const check=(v,m)=>{if(!v)throw Error(kind+': '+m);n++};
   d.enterBoss();const s=d.state(),boss=s.enemies.find(e=>e.type==='boss');s.enemies=[boss];s.obstacles=[];s.hazards=[];s.waveAt=9999;s.hero.attack=999;s.hero.hp=99999;boss.attack=999;boss.ability=0;boss.x=420;boss.y=210;s.hero.x=600;s.hero.y=450;s.order=[];
   d.step(.02);check(boss.skillAnim===.78,'existing skill duration');check(boss.skillFacing===1,'cast direction latched');
   if(kind==='warlord'){const ring=s.rings.find(r=>r.bomb);check(ring?.dmg===22&&ring.r===54&&Math.abs(ring.ttl-.98)<1e-6,'original slam telegraph and damage');check(boss.ability===5.5,'original slam cooldown')}
   if(kind==='pyro'){check(s.shots.length===3&&s.shots.every(p=>p.damage===11&&Math.abs(Math.hypot(p.vx,p.vy)-228)<1e-6),'original three-shot fire fan');check(boss.ability===4.4,'original fire cooldown')}
   if(kind==='necro'){check(s.enemies.length===2&&s.enemies.some(e=>e.type==='shade'),'original shade summon');check(boss.ability===7,'original summon cooldown')}
   const clock=s.time,remaining=boss.skillAnim;s.paused=true;d.step(.1);check(s.time===clock&&boss.skillAnim===remaining,'pause freezes simulation and animation');s.paused=false;
   s.hero.x=120;d.step(.02);check(boss.facing===-1&&boss.skillFacing===1,'turning during cast retains artwork orientation');
   let args,mirrored=false;const draw=g.drawImage,scale=g.scale;g.drawImage=function(...a){args=a;return draw.apply(this,a)};g.scale=function(x,y){if(x<0)mirrored=true;return scale.call(this,x,y)};
   try{for(const side of ['left','right']){const poses=new Set();for(let frame=0;frame<9;frame++){
    const actor={type:'boss',r:29,skillFacing:side==='left'?-1:1,skillAnim:.78*(1-(frame+.01)/9)};
    d.showSprite(kind,420,310,113,119,'skill',-actor.skillFacing,0,0,actor);
    const image=args[0],r=image.gaitData.frames[frame],body=kind==='warlord'?92:84;
    check(image.gaitAnimation==='skill'&&image.gaitClass===kind&&image.gaitDirection===side,'uses authored skill sheet and locked side');check(args[1]===r.x&&args[2]===r.y,'chronological pose');
    check(r.x>=0&&r.y>=0&&r.x+r.w<=image.width&&r.y+r.h<=image.height,'valid atlas bounds');check(Math.abs(args[6]+r.anchorY*body/image.gaitData.bodyHeight)<1e-6,'boot baseline stays grounded');poses.add(args[1]+':'+args[2]);
    check(Math.abs(image.gaitData.bodyHeight-body*2)<1,'2x body resolution');check(image.width*image.height<image.sourcePixels,'compact decoded atlas');
   }check(poses.size===9,'nine action poses per side')}check(!mirrored,'no weapon mirroring');
   }finally{g.drawImage=draw;g.scale=scale}
   return n;
  },kind);
 }
 await page.emulateMedia({reducedMotion:'reduce'});
 total+=await page.evaluate(()=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d'),draw=g.drawImage;let first,last;g.drawImage=function(...a){last=a;return draw.apply(this,a)};try{d.showSprite('necro',420,310,113,119,'skill',1,0,0,{skillAnim:.78});first=last;d.showSprite('necro',420,310,113,119,'skill',1,0,0,{skillAnim:.1});if(first[1]===last[1]&&first[2]===last[2])throw Error('essential skill poses frozen');return 1}finally{g.drawImage=draw}});
 assert.deepEqual(errors,[]);await page.close();
}
const page=await browser.newPage();await page.goto('file:///'+path.resolve('boss-skill-review.html').replaceAll('\\','/'));await page.waitForFunction(()=>['warlord','pyro','necro'].every(kind=>Object.keys(art[kind]).length===2));
for(const side of ['left','right'])for(const frame of [0,4,8]){await page.locator('#side').selectOption(side);await page.locator('#pose').evaluate((e,f)=>{e.value=String(f);e.dispatchEvent(new Event('input'))},frame);assert.equal(await page.locator('#play').innerText(),'Play');total++;await page.locator('canvas').screenshot({path:'boss-skill-'+side+'-'+frame+'-preview.png'})}
console.log(total+' boss skill pose, direction, timing, original ability, desktop/mobile and preview checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
