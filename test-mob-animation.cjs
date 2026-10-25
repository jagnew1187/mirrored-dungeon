const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{let total=0;
for(const mobile of [false,true]){
 const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
 const errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug);
 for(const kind of ['cultist','skeleton','acolyte','hound']){
  await page.evaluate(kind=>MirroredDungeonDebug.preloadMobArt(kind),kind);
  await page.waitForFunction(kind=>['right','southeast','down','southwest','left','northwest','up','northeast'].every(dir=>document.getElementById('game').dataset['mobArt'+kind+dir]==='ready'),kind);
  total+=await page.evaluate(kind=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d');let n=0;const check=(v,m)=>{if(!v)throw Error(kind+': '+m);n++};
   d.reset();d.chooseClass('knight');d.start();d.selectBoss('warlord');d.enterBoss();const s=d.state();s.obstacles=[];s.hazards=[];s.rings=[];s.shots=[];s.waveAt=9999;s.hero.attack=999;s.hero.hp=99999;
   const e={type:'shade',sprite:kind,id:'mob-test',x:420,y:310,r:11,hp:100,max:100,speed:84,dmg:5,attack:999,ability:999,slow:0,dead:false,hit:0,attackAnim:0,skillAnim:0};s.enemies=[e];
   const dirs=['right','southeast','down','southwest','left','northwest','up','northeast'],stride={cultist:64,skeleton:60,acolyte:64,hound:76}[kind],body=kind==='hound'?38:54;
   for(let i=0;i<8;i++){
    const dir=dirs[i],a=i*Math.PI/4;e.x=420;e.y=310;e.walkDirection=undefined;s.hero.x=420+Math.cos(a)*160;s.hero.y=310+Math.sin(a)*160;const old=e.walkCycle||0;d.step(.04);const distance=Math.hypot(e.x-420,e.y-310);
    check(e.walkDirection===dir,'AI selects '+dir);check(Math.abs(distance-84*.04)<1e-5,'original AI speed');check(Math.abs(e.walkCycle-old-distance/stride)<1e-5,'distance driven stride');
    s.hero.x=e.x;s.hero.y=e.y;const phase=e.walkCycle;d.step(.04);check(!e.move&&e.walkCycle===phase&&e.walkDirection===dir,'stop keeps phase and direction');
    let args,mirrored=false;const draw=g.drawImage,scale=g.scale;g.drawImage=function(...a){args=a;return draw.apply(this,a)};g.scale=function(x,y){if(x<0)mirrored=true;return scale.call(this,x,y)};
    try{for(const anim of ['walk','attack']){const poses=new Set(),count=anim==='walk'?8:7;
     for(let frame=0;frame<count;frame++){
      const actor={r:11,walkDirection:dir,attackDirection:dir,walkCycle:(frame+.01)/8,attackAnim:.45*(1-(frame+.01)/7)};
      d.showSprite(kind,420,310,62,76,anim,-1,0,0,actor);const image=args[0],r=image.gaitData.frames[anim==='walk'?frame:9+frame];
      check(image.gaitClass===kind&&image.gaitDirection===dir,'authored direction');check(args[1]===r.x&&args[2]===r.y,'ordered '+anim+' frame');check(r.x>=0&&r.y>=0&&r.x+r.w<=image.width&&r.y+r.h<=image.height,'atlas bounds');check(Math.abs(args[6]+r.anchorY*body/image.gaitData.bodyHeight)<1e-5,'grounded boots/paws');poses.add(args[1]+':'+args[2]);
     }check(poses.size===count,'distinct '+anim+' poses')
    }
    const image=args[0],idle=image.gaitData.frames[8];d.showSprite(kind,420,310,62,76,'idle',1,0,0,{r:11,walkDirection:dir});check(args[1]===idle.x&&args[2]===idle.y,'planted standing pose');check(!mirrored,'no mirrored equipment');check(image.width*image.height<image.sourcePixels,'compact cached atlas');check(Math.abs(image.gaitData.bodyHeight-body*2)<1,'2x body resolution');
    }finally{g.drawImage=draw;g.scale=scale}
   }
   e.x=420;e.y=310;s.hero.x=445;s.hero.y=310;e.attack=0;e.attackAnim=0;const hp=s.hero.hp;d.step(.02);check(e.attackAnim===.45&&e.attack===1.6,'original attack duration and cooldown');check(s.hero.hp===hp,'contact windup does not damage early');check(e.attackDirection==='right','attack aims at hero');
   const phase=e.walkCycle;s.paused=true;d.step(.1);check(e.attackAnim===.45&&e.walkCycle===phase,'pause freezes mob animation');s.paused=false;d.step(.21);check(s.hero.hp===hp-5,'contact damage follows windup');
   // Rendering prioritizes attacks even when a hurt enemy is pursuing a moving hero.
   e.move=true;e.walkDirection='left';e.attackDirection='right';e.attackAnim=.3;let used=false;const draw=g.drawImage;g.drawImage=function(...a){if(a[0].gaitClass===kind&&a[0].gaitDirection==='right'&&a[1]===a[0].gaitData.frames[11].x&&a[2]===a[0].gaitData.frames[11].y)used=true;return draw.apply(this,a)};try{d.draw();check(used,'attack remains visible during movement')}finally{g.drawImage=draw}
   d.reset();check(!d.state().enemies.some(e=>e.id==='mob-test'),'restart clears animated enemies');return n;
  },kind);
 }
 await page.emulateMedia({reducedMotion:'reduce'});total+=await page.evaluate(()=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d'),draw=g.drawImage;let args,first;g.drawImage=function(...a){args=a;return draw.apply(this,a)};try{d.showSprite('hound',420,310,62,76,'attack',1,0,0,{attackAnim:.45});first=args;d.showSprite('hound',420,310,62,76,'attack',1,0,0,{attackAnim:.01});if(first[1]===args[1]&&first[2]===args[2])throw Error('essential attacks frozen');return 1}finally{g.drawImage=draw}});assert.deepEqual(errors,[]);await page.close();
}
const page=await browser.newPage();await page.goto('file:///'+path.resolve('mob-animation-review.html').replaceAll('\\','/'));await page.waitForFunction(()=>['cultist','skeleton','acolyte','hound'].every(k=>Object.keys(art[k]).length===8));
for(const kind of ['cultist','skeleton','acolyte','hound'])for(const view of ['cardinal','diagonal'])for(const mode of ['walk','idle','attack']){
 await page.locator('#character').selectOption(kind);await page.locator('#views').selectOption(view);await page.locator('#mode').selectOption(mode);await page.locator('#pose').evaluate(e=>{e.value='3';e.dispatchEvent(new Event('input'))});assert.equal(await page.locator('#play').innerText(),'Play');total++;await page.locator('canvas').screenshot({path:kind+'-'+view+'-'+mode+'-mob-preview.png'});
}
console.log(total+' mob direction, walking, attack, damage, timing, cache, desktop/mobile and preview checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
