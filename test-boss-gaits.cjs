const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{let total=0;
for(const mobile of [false,true]){
 const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
 const errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));
 await page.waitForFunction(()=>window.MirroredDungeonDebug);
 assert.equal(await page.evaluate(()=>Object.keys(document.getElementById('game').dataset).some(k=>k.startsWith('bossGait'))),false);total++;
 for(const kind of ['warlord','pyro','necro']){
  await page.evaluate(kind=>{const d=MirroredDungeonDebug;d.reset();d.chooseClass('knight');d.start();d.selectBoss(kind)},kind);
  await page.waitForFunction(kind=>['right','southeast','down','southwest','left','northwest','up','northeast'].every(dir=>document.getElementById('game').dataset['bossGait'+kind+dir]==='ready'),kind);
  await page.waitForFunction(kind=>['left','right'].every(side=>document.getElementById('game').dataset['bossSkill'+kind+side]==='ready'),kind);
  total+=await page.evaluate(kind=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d');let n=0;const check=(v,m)=>{if(!v)throw Error(kind+': '+m);n++};
   d.enterBoss();const s=d.state(),boss=s.enemies.find(e=>e.type==='boss');check(boss?.id===kind,'encounter still creates correct boss');s.enemies=[boss];s.obstacles=[];s.hazards=[];s.waveAt=9999;s.hero.attack=999;s.hero.hp=99999;boss.attack=999;boss.ability=999;
   const dirs=['right','southeast','down','southwest','left','northwest','up','northeast'],stride=kind==='warlord'?80:64,bodyHeight=kind==='warlord'?92:84;
   for(let i=0;i<8;i++){
    const dir=dirs[i],a=i*Math.PI/4;boss.x=420;boss.y=310;s.hero.x=420+Math.cos(a)*200;s.hero.y=310+Math.sin(a)*200;boss.walkDirection=undefined;const phase=boss.walkCycle||0;
    d.step(.04);const distance=Math.hypot(boss.x-420,boss.y-310);check(boss.walkDirection===dir,'AI movement chooses '+dir);check(Math.abs(distance-boss.speed*.04)<1e-5,'original movement speed');check(Math.abs(boss.walkCycle-phase-distance/stride)<1e-5,'distance driven gait');
    s.hero.x=boss.x;s.hero.y=boss.y;const stopped=boss.walkCycle;d.step(.04);check(!boss.move&&boss.walkCycle===stopped,'stationary phase retained');
    let args,mirrored=false;const draw=g.drawImage,scale=g.scale;g.drawImage=function(...a){args=a;return draw.apply(this,a)};g.scale=function(x,y){if(x<0)mirrored=true;return scale.call(this,x,y)};
    try{const poses=new Set();for(let frame=0;frame<8;frame++){
     d.showSprite(kind,420,310,113,119,'walk',-1,0,0,{type:'boss',r:29,walkDirection:dir,walkCycle:(frame+.01)/8});
     const image=args[0],r=image.gaitData?.frames[frame];check(image.gaitClass===kind&&image.gaitDirection===dir,'renderer uses authored boss direction');check(args[1]===r.x&&args[2]===r.y,'correct pose');
     check(r.x>=0&&r.y>=0&&r.x+r.w<=image.width&&r.y+r.h<=image.height,'atlas bounds');check(Math.abs(args[6]+r.anchorY*bodyHeight/image.gaitData.bodyHeight)<1e-5,'grounded boots');poses.add(args[1]+':'+args[2]);
    }
    const image=args[0],idle=image.gaitData.frames[8];check(poses.size===8,'eight walk poses');check(image.width*image.height<image.sourcePixels,'compact cached texture');check(Math.abs(image.gaitData.bodyHeight-bodyHeight*2)<1,'2x body resolution');
    d.showSprite(kind,420,310,113,119,'idle',-1,0,0,{r:29,walkDirection:dir});check(args[1]===idle.x&&args[2]===idle.y,'dedicated matching standing pose');check(!mirrored,'equipment never mirrored');
    for(const [anim,start] of [['attack',kind==='warlord'?5:6]]){
     d.showSprite(kind,420,310,113,119,anim,1,0,0,{type:'boss',attackAnim:.45,skillAnim:.78});check(!args[0].gaitData,'legacy action artwork retained');check(args[1]===start*228+2,'legacy action frame timing retained');
    }
    }finally{g.drawImage=draw;g.scale=scale}
   }
   d.reset();check(d.state().enemies.every(e=>e.type!=='boss'),'restart clears encounter');return n;
  },kind);
 }
 assert.deepEqual(errors,[]);await page.close();
}
const page=await browser.newPage();await page.goto('file:///'+path.resolve('boss-walk-review.html').replaceAll('\\','/'));await page.waitForFunction(()=>['warlord','pyro','necro'].every(kind=>Object.keys(art[kind]).length===8));
for(const kind of ['warlord','pyro','necro'])for(const view of ['cardinal','diagonal']){
 await page.locator('#character').selectOption(kind);await page.locator('#views').selectOption(view);await page.locator('#pose').evaluate(e=>{e.value='4';e.dispatchEvent(new Event('input'))});await page.locator('canvas').screenshot({path:kind+'-'+view+'-gait-preview.png'});
 await page.locator('#stand').click();assert.equal(await page.locator('#stand').innerText(),'Walk');total++;await page.locator('canvas').screenshot({path:kind+'-'+view+'-standing-preview.png'});
}
console.log(total+' boss gait, AI movement, action compatibility, desktop/mobile and preview checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
