// Local sampled combat audio with procedural ambience and score.
const AUDIO_SCENES={
 camp:{root:50,bpm:44,notes:[0,7,12,4,7,16,12,7],air:650,rumble:90,beat:false},
 warlord:{root:38,bpm:48,notes:[0,null,7,null,3,null,10,null],air:420,rumble:100,beat:false},
 necro:{root:33,bpm:40,notes:[12,null,19,null,15,null,10,null],air:1100,rumble:65,beat:false},
 pyro:{root:36,bpm:52,notes:[0,null,7,12,null,3,null,7],air:800,rumble:55,beat:false},
 'boss-warlord':{root:38,bpm:84,notes:[0,0,7,3,0,10,7,3],air:400,rumble:95,beat:true},
 'boss-necro':{root:33,bpm:68,notes:[12,7,15,10,12,19,15,7],air:950,rumble:65,beat:true},
 'boss-pyro':{root:36,bpm:108,notes:[0,7,12,15,12,7,10,7],air:750,rumble:55,beat:true}
};
const GameAudio=(()=>{
 const key='mirrored-audio-v1',defaults={master:.45,ambience:.55,music:.5,effects:.7,muted:false};let settings={...defaults};
 try{const saved=JSON.parse(localStorage.getItem(key)||'null');if(saved)for(const name of ['master','ambience','music','effects'])if(Number.isFinite(saved[name]))settings[name]=clamp(saved[name],0,1);if(typeof saved?.muted==='boolean')settings.muted=saved.muted}catch{}
 let ac=null,master=null,fx=null,compressor=null,analyser=null,current=null,timer=null,noise=null,available=true,lastFoot=-1,steps=0;
 const effectTimes=new Map(),effectCounts={};let lastEffect=null,effectWindow=0,effectBurst=0;
 let bankBuffer=null,bankState='locked',sampledEvents=0;
 const sampleClips=new Map(),sampleVoices=new Map();
 const buses=new Set(),voices=new Set();
 function save(){try{localStorage.setItem(key,JSON.stringify(settings))}catch{}}
 function level(g,value,time=.08){g.gain.setTargetAtTime(value,ac.currentTime,time)}
 function tone(bus,midi,at,duration,volume=.06,type='triangle',cutoff=1400){
  if(!bus||voices.size>=48)return;
  const osc=ac.createOscillator(),gain=ac.createGain(),filter=ac.createBiquadFilter();osc.type=type;osc.frequency.value=440*2**((midi-69)/12);filter.type='lowpass';filter.frequency.value=cutoff;
  gain.gain.setValueAtTime(0,at);gain.gain.linearRampToValueAtTime(volume,at+.025);gain.gain.exponentialRampToValueAtTime(.0001,at+duration);
  osc.connect(filter);filter.connect(gain);gain.connect(bus);voices.add(osc);osc.onended=()=>{voices.delete(osc);osc.disconnect();filter.disconnect();gain.disconnect()};osc.start(at);osc.stop(at+duration+.02);
 }
 function noiseHit(bus,at,duration,volume,frequency,type='bandpass'){
  if(!bus||voices.size>=48)return;
  const src=ac.createBufferSource(),filter=ac.createBiquadFilter(),gain=ac.createGain();src.buffer=noise;filter.type=type;filter.frequency.value=frequency;filter.Q.value=.6;
  gain.gain.setValueAtTime(.0001,at);gain.gain.linearRampToValueAtTime(volume,at+.008);gain.gain.exponentialRampToValueAtTime(.0001,at+duration);
  src.connect(filter);filter.connect(gain);gain.connect(bus);voices.add(src);src.onended=()=>{voices.delete(src);src.disconnect();filter.disconnect();gain.disconnect()};src.start(at,(steps*.173)%1);src.stop(at+duration+.02);
 }
 function drone(bus,midi,volume){const osc=ac.createOscillator(),gain=ac.createGain();osc.type='sine';osc.frequency.value=440*2**((midi-69)/12);gain.gain.value=volume;osc.connect(gain);gain.connect(bus.ambient);osc.start();bus.sources.push(osc);bus.nodes.push(osc,gain)}
 function drum(bus,at){
  if(voices.size>=48)return;const osc=ac.createOscillator(),gain=ac.createGain();osc.frequency.setValueAtTime(125,at);osc.frequency.exponentialRampToValueAtTime(48,at+.18);gain.gain.setValueAtTime(.0001,at);gain.gain.linearRampToValueAtTime(.14,at+.006);gain.gain.exponentialRampToValueAtTime(.0001,at+.24);osc.connect(gain);gain.connect(bus);voices.add(osc);osc.onended=()=>{voices.delete(osc);osc.disconnect();gain.disconnect()};osc.start(at);osc.stop(at+.26);
 }
 function makeBus(id){
  const profile=AUDIO_SCENES[id],bus={id,profile,sources:[],nodes:[],next:ac.currentTime+.06,step:0,dead:false};
  bus.gain=ac.createGain();bus.gain.gain.value=0;bus.gain.connect(master);bus.ambient=ac.createGain();bus.music=ac.createGain();bus.ambient.gain.value=settings.ambience;bus.music.gain.value=settings.music;bus.ambient.connect(bus.gain);bus.music.connect(bus.gain);bus.nodes.push(bus.gain,bus.ambient,bus.music);
  for(const [frequency,volume]of [[profile.air,.055],[profile.rumble,.075]]){
   const src=ac.createBufferSource(),filter=ac.createBiquadFilter(),gain=ac.createGain();src.buffer=noise;src.loop=true;filter.type='lowpass';filter.frequency.value=frequency;gain.gain.value=volume;
   src.connect(filter);filter.connect(gain);gain.connect(bus.ambient);src.start();bus.sources.push(src);bus.nodes.push(src,filter,gain);
  }
  drone(bus,profile.root,.025);drone(bus,profile.root+7,.012);
  level(bus.gain,1,.45);buses.add(bus);return bus;
 }
 function retire(bus){
  if(!bus||bus.dead)return;bus.dead=true;level(bus.gain,0,.35);
  for(const source of bus.sources)source.stop(ac.currentTime+1.8);
  // Free retired graphs even when gameplay changes rooms repeatedly.
  const cleanup=()=>{for(const node of bus.nodes)try{node.disconnect()}catch{}buses.delete(bus)};
  if(bus.sources.length)bus.sources[0].onended=cleanup;else cleanup();
 }
 function wanted(){return s?.phase==='boss'?'boss-'+s.active:s?.phase==='gauntlet'?s.active:'camp'}
 function mix(){
  if(!ac)return;level(master,settings.muted?0:settings.master);level(fx,settings.effects);
  if(current){const arrival=s?.immersion?.arrival,duck=arrival&&s.elapsed-arrival.start<1.3?.35:1;level(current.ambient,settings.ambience*duck);level(current.music,settings.music)}
 }
 function schedule(){
  if(!ac||ac.state!=='running'||!current||current.dead||settings.muted||s?.paused||s?.mode!=='running'||document.hidden)return;
  const b=current,p=b.profile;if(b.next<ac.currentTime-.5)b.next=ac.currentTime+.04;
  while(b.next<ac.currentTime+.2){
   const i=b.step++,at=b.next,note=p.notes[i%p.notes.length],beat=60/p.bpm;
   if(settings.music>0&&note!==null){tone(b.music,p.root+note+12,at,p.beat?.7:2.4,p.beat?.075:.035,p.beat&&b.id==='boss-warlord'?'triangle':'sine');
    if(p.beat&&i%4===0){const chord=Math.floor(i/8)%4,bass=p.root+[0,-4,3,-2][chord];tone(b.music,bass,at,beat*2,.09,'triangle',500);if(i%8===0)for(const interval of [0,chord===0?3:4,7])tone(b.music,bass+interval+12,at,beat*7.5,.022,'triangle',650)}
   }
   if(p.beat&&settings.music>0){if(i%2===0)drum(b.music,at);else noiseHit(b.music,at,.1,.035,1200);if(b.id==='boss-pyro')noiseHit(b.music,at+beat/2,.055,.025,3500)}
   if(settings.ambience>0){if(b.id.includes('pyro')||b.id==='camp')noiseHit(b.ambient,at+.08,.065,.045,2100);if(b.id==='necro'&&i%4===0)tone(b.ambient,81,at+.13,1.1,.018,'sine');if(b.id==='warlord'&&i%6===0)tone(b.ambient,74,at+.17,.5,.012,'sine')}
   b.next+=beat;
  }
 }
 function sync(){
  if(!ac)return;
  const shouldRun=s?.mode==='running'&&!s.paused&&!document.hidden;
  if(!shouldRun){if(ac.state==='running')ac.suspend().catch(()=>{});return}
  if(ac.state==='suspended')ac.resume().catch(()=>{});
  const id=wanted();if(current?.id!==id){retire(current);current=makeBus(id)}mix();schedule();
 }
 async function unlock(){
  if(!available)return;
  try{
   if(!ac){const Audio=window.AudioContext||window.webkitAudioContext;if(!Audio){available=false;updateAudioControls();return}ac=new Audio({latencyHint:'interactive'});master=ac.createGain();master.gain.value=settings.muted?0:settings.master;fx=ac.createGain();fx.gain.value=settings.effects;fx.connect(master);compressor=ac.createDynamicsCompressor();compressor.threshold.value=-18;compressor.ratio.value=4;master.connect(compressor);compressor.connect(ac.destination);analyser=ac.createAnalyser();analyser.fftSize=1024;compressor.connect(analyser);
    noise=ac.createBuffer(1,ac.sampleRate*3,ac.sampleRate);const data=noise.getChannelData(0);let seed=7331;for(let i=0;i<data.length;i++){seed=(seed*1664525+1013904223)>>>0;data[i]=seed/2147483648-1}
    if(typeof SOUND_BANK_V2!=='undefined'){
     bankState='loading';const bytes=Uint8Array.from(atob(SOUND_BANK_V2.data),c=>c.charCodeAt(0));
     ac.decodeAudioData(bytes.buffer).then(buffer=>{bankBuffer=buffer;
      // Isolate every clip before playback: pitch changes must never read adjacent cues.
      for(const [kind,clips]of Object.entries(SOUND_BANK_V2.clips))sampleClips.set(kind,clips.map(clip=>{const first=Math.round(clip.offset*buffer.sampleRate),length=Math.round(clip.duration*buffer.sampleRate),out=ac.createBuffer(1,length,buffer.sampleRate);out.copyToChannel(buffer.getChannelData(0).subarray(first,first+length),0);return out}));
      bankState='ready';C.dataset.audioSamples='ready'}).catch(()=>{bankState='fallback';C.dataset.audioSamples='fallback'});
    }else bankState='fallback';
    timer=setInterval(schedule,100);ac.onstatechange=()=>{if(ac.state!=='closed')sync()};
   }
   await ac.resume();sync();
  }catch{$('audioState').textContent='Tap or press a key to enable sound.'}
 }
 function footstep(landing=false){
  if(!ac||ac.state!=='running'||!current||settings.muted||settings.effects===0||s?.paused||document.hidden||ac.currentTime-lastFoot<.12)return;
  lastFoot=ac.currentTime;steps++;const camp=current.id==='camp',crypt=current.id.includes('necro'),fire=current.id.includes('pyro'),at=ac.currentTime;
  const carpet=s.active==='warlord'&&Math.abs(s.hero.x-(s.phase==='boss'?W/2:s.gauntlet?.room.mainX??W/2))<62;
  if(playSample(carpet?'foot-carpet':camp?'foot-grass':fire?'foot-lava':'foot-stone',s.hero.x,s.hero.y,landing?.35:.22,steps)){
   if(selectedClass==='knight')playSample('foot-metal',s.hero.x,s.hero.y,.085,steps);return;
  }
  noiseHit(fx,at,landing?.16:.085,landing?.17:.095,camp?650:fire?1200:1800);
  if(!camp){tone(fx,crypt?48:55,at,.12,.028,'sine');if(crypt)tone(fx,48,at+.09,.18,.012,'sine')}
  if(selectedClass==='knight')noiseHit(fx,at+.025,.055,.025,3200);
 }
 function playSample(kind,x,y,volume,variation){
  const clips=typeof SOUND_BANK_V2!=='undefined'&&SOUND_BANK_V2.clips[kind];if(!bankBuffer||!clips||voices.size>=48)return false;
  const buffers=sampleClips.get(kind);if(!buffers)return false;
  // Keep busy fights intelligible. Fade the oldest cue instead of stacking long tails.
  if(sampleVoices.size>=8){
   if(kind.startsWith('foot-'))return true;
   const [old,oldGain]=sampleVoices.entries().next().value;
   oldGain.gain.cancelScheduledValues(ac.currentTime);oldGain.gain.setTargetAtTime(0,ac.currentTime,.005);old.stop(ac.currentTime+.025);sampleVoices.delete(old);
  }
  const source=ac.createBufferSource(),gain=ac.createGain(),pan=ac.createStereoPanner?.();source.buffer=buffers[variation%buffers.length];source.playbackRate.value=1;gain.gain.value=volume;source.connect(gain);
  const output=pan||gain;if(pan){pan.pan.value=clamp(((x??s.hero.x)-s.hero.x)/(W*.6),-.4,.4);gain.connect(pan)}output.connect(fx);
  voices.add(source);sampleVoices.set(source,gain);sampledEvents++;source.onended=()=>{voices.delete(source);sampleVoices.delete(source);source.disconnect();gain.disconnect();pan?.disconnect()};
  source.start();return true;
 }
 function sweep(from,to,at,duration,volume,type='sine'){
  if(voices.size>=48)return;const osc=ac.createOscillator(),gain=ac.createGain();osc.type=type;osc.frequency.setValueAtTime(from,at);osc.frequency.exponentialRampToValueAtTime(to,at+duration);gain.gain.setValueAtTime(.0001,at);gain.gain.linearRampToValueAtTime(volume,at+.006);gain.gain.exponentialRampToValueAtTime(.0001,at+duration);osc.connect(gain);gain.connect(fx);voices.add(osc);osc.onended=()=>{voices.delete(osc);osc.disconnect();gain.disconnect()};osc.start(at);osc.stop(at+duration+.02);
 }
 function effect(kind,x=s?.hero?.x,y=s?.hero?.y){
  if(!kind||!ac||ac.state!=='running'||settings.muted||!settings.master||!settings.effects||s?.mode!=='running'||s.paused||document.hidden||voices.size>=46)return false;
  if(Number.isFinite(y)&&(y<cameraY()-90||y>cameraY()+H+90))return false;
  const at=ac.currentTime;if(at-(effectTimes.get(kind)??-1)<.055)return false;
  if(at-effectWindow>.25){effectWindow=at;effectBurst=0}if(effectBurst>=8)return false;
  effectTimes.set(kind,at);effectBurst++;effectCounts[kind]=(effectCounts[kind]||0)+1;lastEffect=kind;
  const distance=Math.hypot((x??s.hero.x)-s.hero.x,(y??s.hero.y)-s.hero.y),v=Math.max(.25,1-distance/900);
  if(playSample(kind,x,y,v*(kind==='boss-slam'?.65:.5),effectCounts[kind]))return true;
  const hiss=(duration,volume,freq,type='bandpass',offset=0)=>noiseHit(fx,at+offset,duration,volume*v,freq,type);
  const note=(midi,duration,volume,type='sine',offset=0)=>tone(fx,midi,at+offset,duration,volume*v,type,2300);
  const bend=(from,to,duration,volume,type='sine')=>sweep(from,to,at,duration,volume*v,type);
  switch(kind){
   case 'sword-swing':hiss(.12,.16,1600);bend(720,180,.1,.035,'triangle');break;
   case 'dagger-throw':hiss(.075,.12,2600,'highpass');bend(950,370,.09,.035);break;
   case 'twin-daggers':hiss(.08,.13,2600,'highpass');hiss(.08,.11,3000,'highpass',.06);break;
   case 'arcane-cast':bend(260,780,.16,.11);note(84,.2,.035,'sine',.03);break;
   case 'fire-cast':hiss(.24,.21,1500,'lowpass');bend(140,380,.18,.06,'triangle');break;
   case 'frost-cast':hiss(.28,.1,4200);note(90,.4,.05);note(97,.35,.025,'sine',.06);break;
   case 'cleave':hiss(.2,.24,1000);bend(700,140,.15,.07,'triangle');break;
   case 'shield':hiss(.08,.17,2200);note(57,.25,.09,'triangle');note(76,.2,.035);break;
   case 'heal':[72,76,79].forEach((n,i)=>note(n,.48,.07,'sine',i*.055));break;
   case 'guard':[48,55,60].forEach((n,i)=>note(n,.42,.065,'triangle',i*.04));break;
   case 'shadow':hiss(.24,.16,850);bend(600,120,.22,.065);break;
   case 'smoke':hiss(.32,.19,950,'lowpass');break;
   case 'necro-cast':[45,52,57].forEach(n=>note(n,.6,.045));hiss(.25,.075,850);break;
   case 'boss-slam':hiss(.3,.25,650,'lowpass');bend(130,35,.3,.15);break;
   case 'enemy-swing':hiss(.1,.1,1200);break;
   case 'bite':hiss(.075,.14,700,'lowpass');bend(130,70,.07,.04);break;
   case 'hit-metal':hiss(.05,.14,2800,'highpass');note(81,.22,.07,'triangle');note(87.5,.14,.025);break;
   case 'hit-flesh':hiss(.07,.19,1100,'lowpass');bend(100,45,.085,.065);break;
   case 'hit-arcane':hiss(.1,.12,2400);note(90,.18,.06);break;
   case 'hit-fire':hiss(.18,.19,1800,'lowpass');break;
   case 'hit-frost':hiss(.12,.13,3600,'highpass');note(96,.23,.045);break;
   case 'hit-stone':hiss(.09,.19,1400);note(52,.1,.045,'triangle');break;
   case 'hit-wood':hiss(.12,.2,1300,'lowpass');note(45,.1,.05,'triangle');break;
   case 'break-wood':hiss(.32,.25,1600);hiss(.19,.18,850,'bandpass',.075);break;
   case 'break-stone':hiss(.34,.23,850);bend(100,45,.2,.06);break;
   default:hiss(.085,.19,950,'lowpass');bend(160,65,.1,.065);break;
  }return true;
 }
 function arrival(id){if(!ac||!current||settings.muted||!settings.music)return;sync();const root=AUDIO_SCENES['boss-'+id].root;[0,7,12].forEach((n,i)=>tone(current.music,root+n,ac.currentTime+i*.09,1.5,.055,'triangle',950))}
 function set(name,value){if(name==='muted')settings.muted=!!value;else if(['master','ambience','music','effects'].includes(name))settings[name]=clamp(Number(value)||0,0,1);save();mix();updateAudioControls()}
 function snapshot(){return{...settings,available,unlocked:!!ac,state:ac?.state||'locked',scene:current?.id||null,voices:voices.size,buses:buses.size,footsteps:steps,lastEffect,effectCounts:{...effectCounts},quality:bankState,sampledEvents,sampleVoices:sampleVoices.size}}
 function meter(){if(!analyser||ac.state!=='running')return 0;const samples=new Float32Array(analyser.fftSize);analyser.getFloatTimeDomainData(samples);return Math.sqrt(samples.reduce((sum,v)=>sum+v*v,0)/samples.length)}
 function suspend(){if(ac?.state==='running')ac.suspend().catch(()=>{})}
 return{sync,unlock,footstep,arrival,effect,set,snapshot,meter,suspend};
})();
const audioStyle=document.createElement('style');audioStyle.textContent='.audio-settings{margin:8px 0;padding:8px 10px;border:1px solid #405467;border-radius:9px;background:#112130;color:#e8d5ac;font:12px monospace}.audio-settings summary{cursor:pointer;min-height:44px;display:flex;align-items:center}.audio-settings .audio-options{display:grid;grid-template-columns:1fr;gap:5px;max-width:380px}.audio-settings label{display:flex;align-items:center;gap:8px;min-height:44px}.audio-settings input{flex:1;min-width:80px;min-height:44px;accent-color:#d9b77c}.audio-settings button{min-height:44px;background:#23394a;color:#f1dba9;border:1px solid #7b7965;border-radius:7px}.audio-settings p{margin:5px 0;font:11px/1.4 monospace}';document.head.append(audioStyle);
const audioPanel=document.createElement('details');audioPanel.className='audio-settings';audioPanel.innerHTML='<summary>Sound · music & effects</summary><div class="audio-options"><button type="button" id="audioMute" aria-pressed="false">Mute sound</button><label>Volume <input id="audioMaster" aria-label="Overall audio volume" type="range" min="0" max="100"></label><label>Ambience <input id="audioAmbience" aria-label="Ambient sound volume" type="range" min="0" max="100"></label><label>Music <input id="audioMusic" aria-label="Music volume" type="range" min="0" max="100"></label><label>Effects <input id="audioEffects" aria-label="Combat and footstep sound volume" type="range" min="0" max="100"></label><p id="audioState">Sound starts after a tap or keypress. M: mute.</p></div>';
document.querySelector('.hint').after(audioPanel);
function updateAudioControls(){const a=GameAudio.snapshot();$('audioMute').textContent=a.muted?'Unmute sound':'Mute sound';$('audioMute').setAttribute('aria-pressed',String(a.muted));for(const name of ['master','ambience','music','effects'])$('audio'+name[0].toUpperCase()+name.slice(1)).value=Math.round(a[name]*100);if(!a.available)$('audioState').textContent='Audio is unavailable in this browser.'}
$('audioMute').onclick=()=>{GameAudio.unlock();GameAudio.set('muted',!GameAudio.snapshot().muted)};
for(const name of ['master','ambience','music','effects'])$('audio'+name[0].toUpperCase()+name.slice(1)).oninput=ev=>GameAudio.set(name,Number(ev.target.value)/100);
document.addEventListener('pointerdown',ev=>{if(ev.isTrusted)GameAudio.unlock()},{capture:true});
window.addEventListener('keydown',ev=>{if(!ev.isTrusted)return;GameAudio.unlock();if(ev.key.toLowerCase()==='m'&&!ev.repeat&&!ev.ctrlKey&&!ev.metaKey&&!ev.altKey&&!ev.target?.matches('input,textarea,select')){ev.preventDefault();GameAudio.set('muted',!GameAudio.snapshot().muted)}});
document.addEventListener('visibilitychange',()=>GameAudio.sync());window.addEventListener('pagehide',()=>GameAudio.suspend());updateAudioControls();
