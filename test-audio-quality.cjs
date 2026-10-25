const path=require('node:path'),fs=require('node:fs'),assert=require('node:assert/strict');let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{let checks=0;const metadata=require('./assets/audio/combat-v2.json'),wav=fs.readFileSync('assets/audio/combat-v2.wav');assert.equal(wav.toString('ascii',0,4),'RIFF');assert.equal(wav.readUInt32LE(24),44100);assert.equal(wav.readUInt16LE(34),16);checks+=3;
 for(const clips of Object.values(metadata.clips)){assert.equal(clips.length,2);checks++;for(const c of clips){assert.ok(c.offset>=0&&c.duration>0&&c.offset+c.duration<=metadata.seconds);checks++}}
 let peak=0;for(let i=44;i<wav.length;i+=2)peak=Math.max(peak,Math.abs(wav.readInt16LE(i)/32768));assert.ok(peak>.1&&peak<=.621);assert.ok(metadata.seconds<40&&wav.length<4*1048576);checks+=2;
 // Mage cues must stay short and smooth, without the old noisy glass transient.
 for(const key of ['arcane-cast','hit-arcane','fire-cast','hit-fire','frost-cast','hit-frost','heal'])for(const clip of metadata.clips[key]){
  const first=Math.round(clip.offset*44100),n=Math.round(clip.duration*44100);let energy=0,difference=0,previous=0,peak=0;
  for(let j=0;j<n;j++){const value=wav.readInt16LE(44+(first+j)*2)/32768;energy+=value*value;difference+=(value-previous)**2;previous=value;peak=Math.max(peak,Math.abs(value))}
  assert.ok(clip.duration<=.6&&peak<.5&&energy>0,key+' has a restrained, short envelope');
  assert.ok(difference/energy<.35,key+' avoids harsh high-frequency chatter');checks+=2;
 }
 const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
  for(const mobile of [false,true]){
   const page=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile}),errors=[];page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>{window.__sampleStarts=[];const start=AudioBufferSourceNode.prototype.start;AudioBufferSourceNode.prototype.start=function(...args){if(!this.loop)window.__sampleStarts.push({duration:this.buffer?.duration,rate:this.playbackRate.value,args});return start.apply(this,args)};AudioContext.prototype.createConvolver=function(){throw Error('Combat audio must remain dry')};const raf=window.requestAnimationFrame.bind(window);window.requestAnimationFrame=fn=>fn.name==='frame'?0:raf(fn)});await page.goto('file:///'+path.resolve('index.html').replaceAll('\\','/'));await page.locator('#overlayButton').click();await page.waitForFunction(()=>MirroredDungeonDebug.audio.snapshot().quality==='ready');checks++;
   await page.evaluate(()=>{const a=MirroredDungeonDebug.audio;a.set('music',0);a.set('ambience',0);a.set('effects',1);window.__sampleStarts=[]});
   for(const kind of Object.keys(metadata.clips).filter(k=>!k.startsWith('foot-'))){await page.waitForTimeout(80);assert.ok(await page.evaluate(kind=>{const d=MirroredDungeonDebug,a=d.audio,n=a.snapshot().sampledEvents;return a.effect(kind,d.state().hero.x,d.state().hero.y)&&a.snapshot().sampledEvents===n+1},kind),kind+' must use the PCM bank');checks++}
   assert.ok(await page.evaluate(()=>window.__sampleStarts.length>0&&window.__sampleStarts.every(c=>c.duration<=1.001&&c.rate===1&&c.args.length===0)),'Each cue uses an isolated buffer at its original pitch');checks++;
   assert.ok(await page.evaluate(()=>MirroredDungeonDebug.audio.snapshot().sampleVoices<=8),'Sample overlap is capped');checks++;
   await page.waitForTimeout(100);assert.ok(await page.evaluate(()=>{const a=MirroredDungeonDebug.audio;a.effect('hit-metal');return a.snapshot().voices<=48}));checks++;
   await page.evaluate(()=>MirroredDungeonDebug.audio.set('muted',true));await page.waitForFunction(()=>MirroredDungeonDebug.audio.meter()<.000001);checks++;
   assert.deepEqual(errors,[]);checks++;await page.close();
  }
 }finally{await browser.close()}console.log(checks+' PCM quality, isolated clips, fixed pitch, dry playback, overlap limits, headroom, sample playback, mobile, mute and resource checks passed');
})().catch(e=>{console.error(e);process.exitCode=1});
