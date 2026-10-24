const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
const page=await browser.newPage();await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));
await page.waitForFunction(()=>window.MirroredDungeonDebug&&['right','left','up','down','idle'].every(dir=>document.getElementById('game').dataset['knightGait'+dir]==='ready'));
const checks=await page.evaluate(()=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d');d.reset();d.chooseClass('knight');d.start();let n=0;const check=(value,message)=>{if(!value)throw Error(message);n++};
 for(const [dx,dy,direction] of [[88,0,'right'],[-88,0,'left'],[0,-88,'up'],[0,88,'down']]){
  const a={cls:'knight',x:dx,y:dy};d.trackMotion(a,{x:0,y:0},1);check(a.walkDirection===direction,'actual displacement selects '+direction);check(a.walkCycle===1,'88px complete gait cycle');
  a.x+=dx;a.y+=dy;d.trackMotion(a,{x:a.x-dx,y:a.y-dy},1);check(a.walkCycle===2,'continuous distance-driven gait');
  const phase=a.walkCycle;d.trackMotion(a,{x:a.x,y:a.y},.1);check(!a.move&&a.walkCycle===phase&&a.walkDirection===direction,'stop preserves phase and direction');
 }
 const a={cls:'knight',x:10,y:4.5,walkDirection:'right'};d.trackMotion(a,{x:0,y:0},.1);check(a.walkDirection==='right','diagonal hysteresis keeps horizontal');
 a.x+=10;a.y+=10;d.trackMotion(a,{x:a.x-10,y:a.y-10},.1);check(a.walkDirection==='southeast','strong diagonal input switches direction');
 a.x+=10;a.y+=6;d.trackMotion(a,{x:a.x-10,y:a.y-6},.1);check(a.walkDirection==='southeast','diagonal hysteresis keeps diagonal near sector boundary');
 d.selectBoss('warlord');const state=d.state();state.obstacles=[];state.hazards=[];state.enemies=[];state.waveAt=9999;state.hero.attack=999;
 for(const [key,direction] of [['d','right'],['a','left'],['w','up'],['s','down']]){
  state.hero.x=420;state.hero.y=1500;const old={x:state.hero.x,y:state.hero.y};d.keys.add(key);d.step(.04);d.keys.clear();
  check(state.hero.walkDirection===direction,'real input selects '+direction);
  check(Math.abs(Math.hypot(state.hero.x-old.x,state.hero.y-old.y)-204*.04)<1e-6,'Knight travel speed unchanged');
 }
 const stopped=state.hero.walkCycle;d.step(.04);check(!state.hero.move&&state.hero.walkCycle===stopped,'real stop freezes gait');check(state.hero.walkDirection==='down','real idle retains last direction');
 for(const [index,direction] of ['right','left','down','up'].entries()){
  const sources=new Set();let args,mirrored=false;const original=g.drawImage,originalScale=g.scale;
  g.drawImage=function(...a){args=a;return original.apply(this,a)};g.scale=function(x,y){if(x<0)mirrored=true;return originalScale.call(this,x,y)};
  try{for(let frame=0;frame<8;frame++){
   d.drawHeroSprite('knight',420,310,78,92,'walk',direction==='left'?-1:1,0,0,{walkDirection:direction,walkCycle:(frame+.01)/8});
   const image=args[0],r=image.gaitData.frames[frame],scale=92*.88*.85/image.gaitData.bodyHeight;
   check(image.gaitDirection===direction,'correct directional sheet');check(args[1]===r.x&&args[2]===r.y,'ordered gait pose');
   check(r.x>=0&&r.y>=0&&r.x+r.w<=image.naturalWidth&&r.y+r.h<=image.naturalHeight,'isolated source rectangle');
   check(Math.abs(args[6]+r.anchorY*scale)<1e-6,'support-foot ground anchor');sources.add(args[1]+':'+args[2]);
  }
  d.drawHeroSprite('knight',420,310,78,92,'idle',1,0,0,{walkDirection:direction,walkCycle:.4,walkSettle:.1});
  const r=args[0].gaitData.frames[index];check(args[0].gaitDirection==='idle'&&args[1]===r.x&&args[2]===r.y,'matching planted idle');
  }finally{g.drawImage=original;g.scale=originalScale}
  check(sources.size===8,'eight isolated poses');check(!mirrored,'no equipment mirroring');
 }
 return n;
});assert.equal(checks,169);
await page.evaluate(()=>{const d=MirroredDungeonDebug,c=document.getElementById('game');c.width=1000;c.height=620;const g=c.getContext('2d');g.fillStyle='#19242d';g.fillRect(0,0,c.width,c.height);
 ['right','left','down','up'].forEach((direction,row)=>{g.fillStyle='#f5dfad';g.font='16px monospace';g.fillText(direction.toUpperCase()+' — contact / down / passing / rise × 2',12,25+row*150);
  for(let frame=0;frame<8;frame++)d.drawHeroSprite('knight',65+frame*105,132+row*150,78,92,'walk',direction==='left'?-1:1,0,0,{walkDirection:direction,walkCycle:(frame+.01)/8});
  d.drawHeroSprite('knight',945,132+row*150,78,92,'idle',1,0,0,{walkDirection:direction});
 });});await page.locator('#game').screenshot({path:'knight-directional-gait-preview.png'});
const preview=await browser.newPage();const errors=[];preview.on('pageerror',e=>errors.push(e.message));await preview.goto('file:///'+path.resolve('knight-walk-review.html').replaceAll('\\','/'));
await preview.waitForFunction(()=>Object.values(art).length===9&&Object.values(art).every(i=>i.complete&&i.naturalWidth));assert.equal(errors.length,0);
await preview.locator('#stand').click();assert.equal(await preview.locator('#stand').innerText(),'Walk');
await preview.locator('#pose').evaluate(e=>{e.value='4';e.dispatchEvent(new Event('input'))});assert.equal(await preview.locator('#play').innerText(),'Play');
await preview.locator('canvas').screenshot({path:'knight-walk-review-preview.png'});
console.log((checks+3)+' Knight direction, gait, grounding, idle and preview checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
