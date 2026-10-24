const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));
 await page.waitForFunction(()=>['mage','rogue'].every(cls=>['right','left','down','up','southeast','southwest','northeast','northwest'].every(dir=>document.getElementById('game').dataset[cls+'Gait'+dir]==='ready')));
 await page.waitForFunction(()=>['right','left','up','down','idle'].every(dir=>document.getElementById('game').dataset['knightGait'+dir]==='ready'));
 await page.waitForFunction(()=>window.MirroredDungeonDebug&&['Mage','Knight','KnightLeft','KnightStrike','Rogue'].every(c=>document.getElementById('game').dataset['hero'+c]==='ready'));
 const n=await page.evaluate(()=>{const d=MirroredDungeonDebug;let n=0;const check=(v,m)=>{if(!v)throw Error(m);n++};
  for(const cls of ['mage','knight','rogue']){
   d.reset();d.chooseClass(cls);d.start();const s=d.state(),walk=new Set(),attack=new Set();
   for(let i=0;i<8;i++){s.hero.walkCycle=(i+.01)/8;walk.add(d.animationIndex(cls,'walk',s.hero));s.hero.attackAnim=.32*(1-(i+.01)/8);attack.add(d.animationIndex(cls,'attack',s.hero))}
   check(walk.size===8&&Math.min(...walk)===0&&Math.max(...walk)===7,'eight actual gait frames');check(attack.size===8&&Math.min(...attack)===8&&Math.max(...attack)===15,'eight timed attack frames');
   const image=d.heroArt[cls].right;for(let frame=0;frame<16;frame++){const r=d.heroFrameRect(image,frame);check(r.x>=0&&r.y>=0&&r.x+r.w<=image.naturalWidth&&r.y+r.h<=image.naturalHeight&&r.anchorX>0&&r.anchorY>0&&r.anchorY<=r.h,'isolated valid frame and foot anchor')}
  }
  check(d.heroArt.knight.left.src!==d.heroArt.knight.right.src,'Knight left is a distinct authored sheet');
  const context=document.getElementById('game').getContext('2d'),original=context.scale;let mirrored=false;context.scale=function(x,y){if(x<0)mirrored=true;return original.call(this,x,y)};
  try{d.drawHeroSprite('knight',420,310,78,92,'walk',-1,0,0,{walkCycle:.5})}finally{context.scale=original}
  check(!mirrored,'Knight drawing never mirrors equipment');return n;
 });assert.equal(n,56);
 for(const action of ['walk','attack']){
  await page.evaluate(action=>{const d=MirroredDungeonDebug,c=document.getElementById('game');c.width=action==='walk'?1680:840;const g=c.getContext('2d');g.fillStyle='#17242d';g.fillRect(0,0,c.width,c.height);
   [['mage',1],['knight',1],['knight',-1],['rogue',1]].forEach(([cls,facing],row)=>{g.fillStyle='#eed8ad';g.font='bold 14px monospace';g.fillText(cls.toUpperCase()+(facing<0?' LEFT':' RIGHT')+' · '+action,16,28+row*150);
    const count=action==='walk'?16:8;for(let i=0;i<count;i++){const actor={walkCycle:(i+.01)/count,attackAnim:.3*(1-(i+.01)/8)};d.drawHeroSprite(cls,65+i*101,135+row*150,70,84,action,facing,0,0,actor);}
   });
  },action);await page.locator('#game').screenshot({path:`hero-${action}-frames-preview.png`});
 }
 let gaitChecks=0;
 for(const reducedMotion of ['reduce','no-preference']){
  await page.emulateMedia({reducedMotion});
  gaitChecks+=await page.evaluate(()=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d');let count=0;
   const check=(v,m)=>{if(!v)throw Error(m);count++};
   for(const cls of ['mage','knight','rogue']){
    const frames=[];let draw;
    for(const phase of [0,.25]){g.clearRect(0,0,840,620);const original=g.drawImage;g.drawImage=function(...args){draw=args;return original.apply(this,args)};
     try{d.drawHeroSprite(cls,420,310,78,92,'walk',1,0,0,{walkCycle:phase})}finally{g.drawImage=original}
     frames.push(g.getImageData(360,200,120,120).data.slice());
    }
    check(frames[0].some((v,i)=>v!==frames[1][i]),cls+' walk visibly advances with current motion preference');
    const rect=draw[0].gaitData.frames[2],scale=92*.88*.85/draw[0].gaitData.bodyHeight;
    check(Math.abs(draw[8]-rect.h*scale)<.001,cls+' world art is 15 percent smaller');
    check(Math.abs(draw[6]+rect.anchorY*scale)<=1.01,cls+' boots stay at ground anchor');
   }return count;
  });
 }
 assert.equal(gaitChecks,18);
 const betweenChecks=await page.evaluate(()=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d');let n=0;
  for(const [cls,facing,key] of [['mage',1,'between'],['rogue',1,'between'],['knight',1,'between'],['knight',-1,'leftbetween']]){
   const poses=new Set();let args;const original=g.drawImage;g.drawImage=function(...a){args=a;return original.apply(this,a)};
   try{for(let i=0;i<16;i++){d.drawHeroSprite(cls,420,310,78,92,'walk',facing,0,0,{walkCycle:(i+.01)/16});poses.add(args[0].heroKey+':'+args[1]+':'+args[2]);if(args[0].gaitDirection!==(facing<0?'left':'right'))throw Error('walk must use coherent directional sheet')}}finally{g.drawImage=original}
   if(poses.size!==8)throw Error('eight consistent source poses required');n++;
  }return n;
 });assert.equal(betweenChecks,4);
 const idleChecks=await page.evaluate(()=>{const d=MirroredDungeonDebug,g=document.getElementById('game').getContext('2d');let n=0;
  for(const facing of [-1,1]){let args;const original=g.drawImage;g.drawImage=function(...a){args=a;return original.apply(this,a)};
   try{for(const walkSettle of [0,.1]){d.drawHeroSprite('knight',420,310,78,92,'idle',facing,0,0,{walkCycle:.4,walkSettle});const img=args[0],r=img.gaitData.frames[facing<0?1:0];if(img.gaitDirection!=='idle'||args[1]!==r.x||args[2]!==r.y)throw Error('Knight must stand with both feet planted immediately after stopping');n++}}
   finally{g.drawImage=original}
  }return n;
 });assert.equal(idleChecks,4);
 console.log((n+gaitChecks+betweenChecks+idleChecks)+' hero sprite checks passed');
 }finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
