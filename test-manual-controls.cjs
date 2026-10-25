const path=require('node:path'),assert=require('node:assert/strict');let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{let total=0;
for(const mobile of [false,true]){const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile}),errors=[];page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.waitForFunction(()=>window.MirroredDungeonDebug?.requestJump);
 total+=await page.evaluate(()=>{const d=MirroredDungeonDebug;let n=0;const check=(v,m)=>{if(!v)throw Error(m);n++};
 const advance=t=>{for(let elapsed=0;elapsed<t;elapsed+=.02)d.step(Math.min(.02,t-elapsed))};
 function fresh(cls){d.reset();d.chooseClass(cls);d.start();d.selectBoss('warlord');d.enterBoss();const s=d.state();s.obstacles=[];s.hazards=[];s.shots=[];s.rings=[];s.enemies=[];s.waveAt=9999;s.rival.remaining=9999;s.hero.x=420;s.hero.y=310;s.hero.attack=0;s.hero.hp=9999;return s}
 for(const cls of ['mage','knight','rogue']){
  let s=fresh(cls),h=s.hero;const e={id:'manual',type:'shade',sprite:'cultist',x:465,y:310,r:11,hp:10000,max:10000,speed:0,dmg:0,attack:999,ability:999,slow:0,dead:false,hit:0,move:false,attackAnim:0,skillAnim:0};s.enemies=[e];
  advance(1.3);check(e.hp===10000&&s.shots.length===0&&h.attackAnim===0,cls+' never attacks without input');
  d.setAttackInput(true,'test');d.setAttackInput(false,'test');advance(.25);const damage={mage:23,knight:34,rogue:19}[cls];check(e.hp===10000-damage,cls+' tap performs exactly one attack');advance(1);check(e.hp===10000-damage,cls+' release does not keep firing');
  h.attack=0;d.setAttackInput(true,'test');advance(1.55);d.clearPlayerInput();check(e.hp<=10000-3*damage,cls+' hold repeats at normal cadence');const hp=e.hp;advance(.8);check(e.hp===hp,cls+' clear stops held attack');
  h.attack=.09;d.setAttackInput(true,'test');d.setAttackInput(false,'test');advance(.4);check(e.hp===hp-damage,cls+' short input buffer survives cooldown');
  d.clearPlayerInput();s.enemies=[];s.shots=[];h.attack=0;d.setAttackInput(true,'test');d.step(.02);d.clearPlayerInput();check(h.attackAnim>0,cls+' can intentionally attack empty space');
  const time=s.time;check(d.requestJump(),cls+' jump starts');d.step(.1);check(d.heroJumpHeight()>10&&s.time<time,cls+' airborne hop and running timer');check(!d.requestJump(),cls+' cooldown blocks jump spam');
  const remaining=h.jumpRemaining,cd=h.jumpCooldown;s.paused=true;d.step(.2);check(h.jumpRemaining===remaining&&h.jumpCooldown===cd,cls+' pause freezes jump');s.paused=false;advance(.4);check(h.jumpRemaining===0&&d.heroJumpHeight()===0,cls+' lands');advance(1);check(d.requestJump(),cls+' cooldown recovers');
  h.jumpRemaining=0;h.jumpCooldown=0;s.obstacles=[{x:450,y:280,w:35,h:80,hp:-1,kind:'wall'}];h.x=430;h.y=310;d.requestJump();d.keys.add('d');d.step(.1);d.keys.clear();check(h.x<=434,cls+' jump respects wall collision');
  for(const kind of ['spike','burn','rune','fire']){
   s=fresh(cls);h=s.hero;s.phase='gauntlet';s.elapsed=s.gauntlet.start+1.3;s.hazards=[{x:h.x,y:h.y,r:22,kind,offset:0}];d.requestJump();const hp=h.hp;d.step(.1);
   check(kind==='fire'?h.burnUntil>s.elapsed&&h.hp===hp:h.hp===hp,cls+' correct jumping hazard damage: '+kind);if(kind==='rune')check(!(h.slowUntil>s.elapsed),cls+' jump avoids curse slow');
   advance(.37);check(kind==='rune'?h.slowUntil>s.elapsed:['fire','burn'].includes(kind)?h.burnUntil>s.elapsed:h.hp<hp,cls+' landing restores hazard interaction: '+kind);
  }
  s=fresh(cls);h=s.hero;d.requestJump();d.step(.1);const airborneHp=h.hp;d.hurt(11,true);check(h.hp===airborneHp-11,cls+' boss attacks hit airborne hero');const bullet={x:h.x-10,y:h.y,vx:500,vy:0,r:4,damage:7,team:'enemy',ttl:2};d.advanceProjectile(bullet,.02);check(h.hp===airborneHp-18,cls+' projectiles hit airborne hero');
  d.reset();check(d.state().hero.jumpRemaining===0&&d.state().hero.jumpCooldown===0,cls+' restart clears jump state');
 }
 let s=fresh('knight');s.obstacles=[{x:450,y:290,w:20,h:40,hp:100,kind:'barricade'}];advance(.8);check(s.obstacles[0].hp===100,'Knight never auto-breaks barricades');s.hero.attack=0;d.setAttackInput(true,'test');d.step(.02);advance(.18);d.clearPlayerInput();check(s.obstacles[0].hp===66,'manual Knight attack breaks cover');d.recordMatch('loss','Control-mode telemetry test');const tuning=JSON.parse(d.history().at(-1).tuning);check(tuning.controls.mode==='manual-v1','manual mode separates balance history');check(tuning.controls.jump.jumpCooldown===1.25,'jump tuning recorded with results');return n;
 });
 // Real keyboard and button input, rather than only debug calls.
 await page.evaluate(()=>{const d=MirroredDungeonDebug;d.reset();d.chooseClass('mage');d.start();d.selectBoss('pyro');const s=d.state();s.enemies=[];s.hazards=[];s.obstacles=[];s.waveAt=9999;s.hero.attack=0;d.renderAll()});
 await page.keyboard.down('j');await page.evaluate(()=>MirroredDungeonDebug.step(.02));await page.keyboard.up('j');assert(await page.evaluate(()=>MirroredDungeonDebug.state().hero.attackAnim>0));total++;
 await page.keyboard.press('Space');assert(await page.evaluate(()=>MirroredDungeonDebug.state().hero.jumpRemaining>0));total++;
 await page.evaluate(()=>{const d=MirroredDungeonDebug;d.clearPlayerInput();d.state().hero.jumpRemaining=0;d.state().hero.jumpCooldown=0;d.state().hero.attack=0;d.renderAll()});
 const b=await page.locator('#attackButton').boundingBox();await page.mouse.move(b.x+b.width/2,b.y+b.height/2);await page.mouse.down();await page.evaluate(()=>MirroredDungeonDebug.step(.02));assert(await page.evaluate(()=>MirroredDungeonDebug.state().hero.attackAnim>0));total++;await page.mouse.up();
 await page.evaluate(()=>window.dispatchEvent(new Event('blur')));await page.evaluate(()=>{const d=MirroredDungeonDebug;d.state().hero.attack=0;d.state().shots=[];d.step(.3)});assert.equal(await page.evaluate(()=>MirroredDungeonDebug.state().shots.length),0);total++;
 await page.waitForFunction(()=>document.getElementById('game').dataset.pyroAssets==='ready'&&MirroredDungeonDebug.heroArtReady('mage'));await page.evaluate(()=>MirroredDungeonDebug.draw());await page.screenshot({path:mobile?'manual-mobile-preview.png':'manual-desktop-preview.png',fullPage:!mobile});assert.deepEqual(errors,[]);await page.close();
}
for(const viewport of [{width:320,height:568},{width:390,height:844},{width:844,height:390}]){
 const page=await browser.newPage({viewport,isMobile:true,hasTouch:true});await page.addInitScript(()=>window.requestAnimationFrame=()=>0);await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.evaluate(()=>{const d=MirroredDungeonDebug;d.start();d.selectBoss('pyro');const s=d.state();s.enemies=[];s.hazards=[];s.obstacles=[];s.waveAt=9999;d.renderAll()});
 const a=await page.locator('#attackButton').boundingBox(),j=await page.locator('#jumpButton').boundingBox(),skills=await page.locator('.skills').boundingBox();for(const b of [a,j]){assert(b.width>=44&&b.height>=44);assert(b.x>=0&&b.x+b.width<=viewport.width&&b.y>=0&&b.y+b.height<=viewport.height);assert(b.y+b.height<=skills.y||b.y>=skills.y+skills.height);total+=3}
 if(viewport.height>viewport.width){const stick=await page.locator('#touchJoystick').boundingBox();assert(stick.x+stick.width<=j.x);total++;
  const cdp=await page.context().newCDPSession(page),point=(b,id)=>({x:b.x+b.width/2,y:b.y+b.height/2,id});const move=point(stick,1);move.x+=30;
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[move,point(a,2),point(j,3)]});const before=await page.evaluate(()=>MirroredDungeonDebug.state().hero.x);await page.evaluate(()=>MirroredDungeonDebug.step(.1));assert(await page.evaluate(()=>{const h=MirroredDungeonDebug.state().hero;return h.attackAnim>0&&h.jumpRemaining>0}));assert(await page.evaluate(()=>MirroredDungeonDebug.state().hero.x)>before);total+=2;
  await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});await page.evaluate(()=>{const d=MirroredDungeonDebug;d.state().hero.attack=0;d.state().shots=[];d.step(.2)});assert.equal(await page.evaluate(()=>MirroredDungeonDebug.state().shots.length),0);total++;
 }
 await page.waitForFunction(()=>document.getElementById('game').dataset.pyroAssets==='ready'&&MirroredDungeonDebug.heroArtReady('mage'));await page.evaluate(()=>MirroredDungeonDebug.draw());await page.screenshot({path:'manual-'+viewport.width+'-controls-preview.png'});await page.close();
}
console.log(total+' manual attack, jump, hazard, collision, keyboard, multitouch and mobile-layout checks passed');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
