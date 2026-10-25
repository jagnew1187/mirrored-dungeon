const path=require('node:path'),assert=require('node:assert/strict');let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});let checks=0;try{
const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[];page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug?.requestJump);
async function setup(cls='mage'){await page.evaluate(cls=>{const d=MirroredDungeonDebug;d.reset();d.chooseClass(cls);d.start();d.selectBoss('warlord');d.enterBoss();const s=d.state();s.obstacles=[];s.hazards=[];s.enemies=[{id:'mouse-target',type:'shade',sprite:'cultist',x:480,y:310,r:11,hp:10000,max:10000,speed:0,dmg:0,attack:999,ability:999,slow:0,dead:false,hit:0,attackAnim:0,skillAnim:0}];s.waveAt=9999;s.rival.remaining=9999;s.hero.x=420;s.hero.y=310;s.hero.attack=0;s.hero.hp=9999;d.renderAll()},cls)}
async function point(x,y){return page.evaluate(({x,y})=>{const c=document.getElementById('game'),b=c.getBoundingClientRect(),scale=Math.min(b.width/c.width,b.height/c.height);return{x:b.left+(b.width-c.width*scale)/2+x*scale,y:b.top+(b.height-c.height*scale)/2+(y-MirroredDungeonDebug.cameraY())*scale}},{x,y})}

const step=seconds=>page.evaluate(seconds=>{for(let t=0;t<seconds;t+=.02)MirroredDungeonDebug.step(.02)},seconds);
for(const cls of ['mage','rogue','knight']){
 await setup(cls);await page.keyboard.down('Shift');await page.keyboard.down('d');await step(.2);
 assert(await page.evaluate(()=>{const h=MirroredDungeonDebug.state().hero;return h.x===420&&h.y===310&&!h.move}),'Shift pins keyboard movement');checks++;await page.keyboard.up('d');
 let p=await point(180,310);await page.mouse.move(p.x,p.y);await page.mouse.down();await step(.2);
 assert(await page.evaluate(cls=>{const s=MirroredDungeonDebug.state();return s.hero.x===420&&s.hero.y===310&&s.enemies[0].hp===10000&&s.hero.facing===-1&&(cls==='knight'?s.hero.swing>0:s.shots.some(p=>p.team==='hero'&&p.vx<0&&Math.abs(p.vy)<.01))},cls),'Shift click fires toward empty ground, ignoring the enemy behind');checks++;
 await step(.8);assert(await page.evaluate(()=>MirroredDungeonDebug.state().hero.x===420),'Hold repeats without moving');checks++;
 p=await point(420,110);await page.mouse.move(p.x,p.y);await page.evaluate(()=>{const h=MirroredDungeonDebug.state().hero;h.attack=0;h.pendingBasic=null});await step(.2);
 if(cls!=='knight'){assert(await page.evaluate(()=>MirroredDungeonDebug.state().shots.some(p=>p.team==='hero'&&p.vy<0&&Math.abs(p.vx)<.01)),'Held attacks follow updated cursor');checks++}
 await page.mouse.up();await step(.8);assert(await page.evaluate(()=>{const h=MirroredDungeonDebug.state().hero;return h.attackAnim===0&&!h.pendingBasic}),'Releasing mouse stops free fire');checks++;
 await page.keyboard.up('Shift');await page.keyboard.down('d');await step(.1);assert(await page.evaluate(()=>MirroredDungeonDebug.state().hero.x>420),'Releasing Shift restores movement');checks++;await page.keyboard.up('d');
 // A selected distant enemy cannot pull the hero while Shift is held.
 await setup(cls);await page.evaluate(()=>MirroredDungeonDebug.state().hero.x=120);p=await point(480,290);await page.mouse.click(p.x,p.y);await page.keyboard.down('Shift');await step(.2);assert(await page.evaluate(()=>MirroredDungeonDebug.state().hero.x===120),'Shift cancels approach movement');checks++;
 await page.evaluate(()=>window.dispatchEvent(new Event('blur')));await page.keyboard.up('Shift');await page.keyboard.down('d');await step(.1);assert(await page.evaluate(()=>MirroredDungeonDebug.state().hero.x>120),'Blur clears stand-still lock');checks++;await page.keyboard.up('d');
}
await setup('knight');await page.evaluate(()=>{const s=MirroredDungeonDebug.state();s.enemies=[];s.obstacles=[{x:455,y:300,w:20,h:20,kind:'wood',hp:100}]});
await page.keyboard.down('Shift');const away=await point(180,310);await page.mouse.move(away.x,away.y);await page.mouse.down();await step(.2);
assert.equal(await page.evaluate(()=>MirroredDungeonDebug.state().obstacles[0].hp),100,'A directed swing must not strike cover behind the hero');checks++;await page.mouse.up();await page.keyboard.up('Shift');
assert.deepEqual(errors,[]);checks++;console.log(checks+' Shift pinning, free aim, held attacks, mouse release, selected targets and blur checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
