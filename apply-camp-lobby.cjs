module.exports=function(html){
 html=html.replace("if((s.selectNeeded||s.lobby)&&s.mode==='running'&&!s.active)","if(s.selectNeeded&&s.mode==='running'&&!s.active)");
 html=html.replace('function renderAll(){if(!s)return;GameAudio.sync();renderRewardStatus();','function renderAll(){if(!s)return;GameAudio.sync();renderPracticeCamp();renderRewardStatus();');
 html=html.replace('function renderAll(){if(!s)return;renderRewardStatus();','function renderAll(){if(!s)return;renderPracticeCamp();renderRewardStatus();');
 html=html.replace('if(s.mobSent%3===0)log(', 'if(!s.lobby&&s.mobSent%3===0)log(');
 if(html.includes('// Camp sandbox lobby hooks'))return html;
 const replacements=[
  [/function start\(\)\{[^\n]+\}/,"// Camp sandbox lobby hooks\n function start(){enterCampLobby()}"],
  ["s.time-=dt;s.elapsed+=dt;updatePlayerActions(dt);","if(!s.lobby)s.time-=dt;s.elapsed+=dt;updatePlayerActions(dt);"],
  ["  updateRival(dt);","  if(s.lobby){updateCampLobby();return}\n  updateRival(dt);"],
  ["if(h.hp<=0)finish(false,'Your hero fell in battle.')","if(h.hp<=0){if(s.lobby){h.hp=h.max;h.x=W/2;h.y=H-115;clearPlayerInput();toast('Practice recovery — back on your feet.',2)}else finish(false,'Your hero fell in battle.')}"],
  ["$('clock').textContent=formatTime(s.time)","$('clock').textContent=s.lobby?'LOBBY':formatTime(s.time)"],
  ["$('waveClock').textContent=s.mode==='idle'?'—':","$('waveClock').textContent=s.lobby?'Practice':s.mode==='idle'?'—':"],
  ["if(s.mode==='running'&&timeToWave<=8)","if(s.mode==='running'&&!s.lobby&&timeToWave<=8)"],
  ["$('rivalChip').textContent=s.mode==='idle'?","$('rivalChip').textContent=s.lobby?'Waiting for match':s.mode==='idle'?"],
  ["s.mode==='running'&&!s.active?'⚔ Choose'","s.lobby?'⚔ Start match':s.mode==='running'&&!s.active?'⚔ Choose'"],
  ["ctx.fillText('Choose your next expedition',W/2,260)","ctx.fillText(s.lobby?'Practice camp · choose a boss to start a match':'Choose your next expedition',W/2,260)"],
  ["'Start the match',start","'Enter practice camp',start"],
  ["recordMatch('abandoned','Restarted')","!s.lobby&&recordMatch('abandoned','Restarted')"],
  ["s.mode==='running'?'Choose a gauntlet.","s.lobby?'Practice is untimed. Choosing your first boss starts a fresh match.':s.mode==='running'?'Choose a gauntlet."]
 ];
 for(const [from,to]of replacements){if(typeof from==='string'&&!html.includes(from))throw Error('Missing lobby hook: '+from);html=html.replace(from,to)}
 return html;
};
