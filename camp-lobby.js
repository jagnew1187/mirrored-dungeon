// Practice uses the existing combat simulation, with no competitive countdown.
// Starting a match constructs fresh state so damage, cooldowns and kills cannot
// carry out of the sandbox or give either competitor a head start.
function enterCampLobby(){
 clearPlayerInput();s.mode='running';s.lobby=true;s.selectNeeded=false;s.practiceWaveAt=8;s.practiceWaves=0;
 hideOverlay();closeBossSheet();spawnCampPracticeMobs();
 log('Practice freely in camp. Choose a first boss to begin a fresh match.','good');renderAll();
}
const PRACTICE_ENEMY_CAP=12;
function spawnCampPracticeMobs(count=2){
 if(!s.lobby||s.mode!=='running'||s.paused)return 0;
 const positions=[['guard',65,190],['shade',W-65,150],['shade',65,H-110],['guard',W-65,H-140]];
 const slots=Math.max(0,PRACTICE_ENEMY_CAP-s.enemies.filter(e=>!e.dead).length),added=Math.min(count,slots);
 for(let i=0;i<added;i++)spawnMob(...positions[i%positions.length]);
 if(added)s.practiceWaves=(s.practiceWaves||0)+1;return added;
}
function updateCampLobby(){
 s.enemies=s.enemies.filter(e=>!e.dead);
 if(s.elapsed>=s.practiceWaveAt){
  if(s.enemies.length<5)spawnCampPracticeMobs();
  s.practiceWaveAt=s.elapsed+10;
 }
}
function beginCampMatch(){
 if(!s.lobby)return;
 clearPlayerInput();resetJoystick();s=makeState();s.mode='running';s.selectNeeded=true;lastBossHTML='';
 startRivalGauntlet(BOSSES[Math.floor(seeded(DEV.seed+11)()*BOSSES.length)].id);
 log('Match started. Both mirrors are racing.','hi');
}
function spawnPracticeWave(){
 if(!s.lobby||s.mode!=='running'||s.paused)return false;
 const added=spawnCampPracticeMobs(4);if(added){s.practiceWaveAt=s.elapsed+10;toast('Practice wave · '+added+' more enemies',1.7)}renderAll();return added>0;
}
const practiceStyle=document.createElement('style');practiceStyle.textContent='.practice-panel{position:absolute;top:8px;right:8px;width:min(310px,calc(100% - 110px));display:flex;align-items:center;justify-content:space-between;gap:10px;z-index:4;padding:5px 8px;background:#11232ceb;border:1px solid #857457;border-radius:9px;color:#ecd4a8;font:12px monospace;box-sizing:border-box}.practice-panel[hidden]{display:none}.practice-panel strong{font-size:17px;color:#ffe1a1}.practice-panel small{display:block;color:#b7c7bb;font-size:10px}.practice-panel button{min-height:44px;padding:6px 10px;background:#354535;border:1px solid #a99263;border-radius:7px;color:#ffdda0;font:700 12px monospace;touch-action:manipulation}.practice-panel button:disabled{opacity:.5}.practice-panel .wave-mobile{display:none}@media(max-width:560px){.practice-panel .practice-word,.practice-panel .practice-wave-number,.practice-panel .wave-desktop{display:none}.practice-panel .wave-mobile{display:inline}.practice-panel button{padding:6px 8px}.practice-panel{gap:6px}.practice-panel small{font-size:9px}} ';document.head.append(practiceStyle);
const practicePanel=document.createElement('section');practicePanel.className='practice-panel';practicePanel.hidden=true;practicePanel.setAttribute('aria-label','Untimed practice controls');practicePanel.innerHTML='<div title="Shared practice kills, including your companions"><span><span class="practice-word">Practice </span>kills: <strong id="practiceKills" aria-live="polite">0</strong></span><small><span id="practiceMobCount"></span><span class="practice-wave-number" id="practiceWaveCount"></span></small></div><button type="button" id="practiceWave" aria-label="Spawn another practice wave">+ <span class="wave-desktop">Spawn wave</span><span class="wave-mobile">Wave</span></button>';document.querySelector('.arena-wrap').append(practicePanel);
$('practiceWave').onclick=spawnPracticeWave;
$('practiceWave').addEventListener('keydown',ev=>{if(ev.key===' '||ev.key==='Enter')ev.stopPropagation()});
function renderPracticeCamp(){
 practicePanel.hidden=!(s.lobby&&s.mode==='running');if(practicePanel.hidden)return;
 const alive=s.enemies.filter(e=>!e.dead).length;$('practiceKills').textContent=s.mobSent;$('practiceMobCount').textContent=alive+' / '+PRACTICE_ENEMY_CAP+' mobs';$('practiceWaveCount').textContent=' · Wave '+s.practiceWaves;
 $('practiceWave').disabled=s.paused||alive>=PRACTICE_ENEMY_CAP;
}
