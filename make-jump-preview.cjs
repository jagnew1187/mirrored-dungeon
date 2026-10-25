const path=require('node:path'),assert=require('node:assert/strict');
let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 const page=await browser.newPage({viewport:{width:1200,height:800}});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);
 await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));
 await page.waitForFunction(()=>['mage','rogue'].every(c=>document.getElementById('game').dataset[c+'Gaitright']==='ready')&&document.getElementById('game').dataset.knightGaitidle==='ready');
 const checks=await page.evaluate(()=>{
  const d=MirroredDungeonDebug,c=document.getElementById('game'),out=document.createElement('canvas');out.width=980;out.height=510;out.id='jumpReview';const g=out.getContext('2d');g.imageSmoothingEnabled=false;g.fillStyle='#17242d';g.fillRect(0,0,out.width,out.height);let checks=0;
  const labels=['Ready','Takeoff','Rising','Falling','Landing','Fire damage','Slowed'];
  for(const [row,cls]of ['knight','mage','rogue'].entries()){
   d.reset();d.chooseClass(cls);d.start();const s=d.state(),h=s.hero;s.enemies=[];s.campFriends=[];h.x=420;h.y=310;h.walkDirection='right';
   const poses=[];
   for(let col=0;col<labels.length;col++){
    h.jumpRemaining=col>0&&col<4?.46*(1-[0,.08,.32,.7][col]):0;h.jumpLanding=col===4?.1:0;h.flash=col===5?.26:0;h.burnUntil=col===5?s.elapsed+2:0;h.trapImpact='burn';h.trapImpactUntil=s.elapsed+1;h.slowUntil=col===6?s.elapsed+.8:0;
    d.draw();const pixels=c.getContext('2d').getImageData(360,210,120,130).data;poses.push(Array.from(pixels));
    g.fillStyle='#eddaa8';g.font='12px monospace';g.fillText(cls+' · '+labels[col],col*140+5,row*170+18);g.drawImage(c,360,210,120,130,col*140+10,row*170+30,120,130);
   }
   for(let i=1;i<poses.length;i++){if(!poses[i].some((p,j)=>p!==poses[0][j]))throw Error(cls+' visual phase missing: '+labels[i]);checks++}
  }
  document.body.replaceChildren(out);return checks;
 });assert.equal(checks,18);await page.locator('#jumpReview').screenshot({path:'hero-jump-status-preview.png'});console.log(checks+' jump/status visual checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
