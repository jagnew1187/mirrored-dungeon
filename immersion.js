const BOSS_ARRIVAL_LINES={warlord:'You stand before the throne. Draw your steel.',necro:'Every footstep brings another soul to my halls.',pyro:'Come closer. Let the sanctuary burn.'};
function immersionState(){return s.immersion||(s.immersion={props:new Map(),dust:[],stepMark:Math.floor((s.hero.walkCycle||0)*2),jump:0,arrival:null})}
function noteBossArrival(id){
 const life=immersionState();life.arrival={id,start:s.elapsed};
 if(s.boss){s.boss.walkDirection='down';s.boss.facing=s.hero.x<s.boss.x?-1:1}
 GameAudio.sync();GameAudio.arrival(id);
}
function updateImmersion(dt){
 const life=immersionState(),h=s.hero,mark=Math.floor((h.walkCycle||0)*2);
 if(h.move&&!(h.jumpRemaining>0)&&mark!==life.stepMark)GameAudio.footstep();
 if(life.jump>0&&!(h.jumpRemaining>0))GameAudio.footstep(true);
 life.stepMark=mark;life.jump=h.jumpRemaining||0;
 const live=new Set(s.obstacles);
 for(const prop of s.obstacles){
  if(life.props.get(prop)>0&&prop.hp===0){
   GameAudio.effect(coverHitSound(prop)==='hit-wood'?'break-wood':'break-stone',prop.x+prop.w/2,prop.y+prop.h/2);
   if(!reduceMotion.matches)for(let i=0;i<6;i++)life.dust.push({x:prop.x+prop.w*(i+.5)/6,y:prop.y+prop.h*.65,vx:(i-2.5)*12,vy:-22-(i%3)*8,ttl:.55,color:s.active==='necro'?'#89998a':s.active==='pyro'?'#b69179':'#c7aa7e'});
  }
  life.props.set(prop,prop.hp);
 }
 for(const prop of life.props.keys())if(!live.has(prop))life.props.delete(prop);
 for(const puff of life.dust){puff.x+=puff.vx*dt;puff.y+=puff.vy*dt;puff.ttl-=dt}
 life.dust=life.dust.filter(p=>p.ttl>0).slice(-36);
 if(life.arrival&&(s.phase!=='boss'||life.arrival.id!==s.active||s.elapsed-life.arrival.start>2.6))life.arrival=null;
}
function drawEnvironmentalLife(){
 if(reduceMotion.matches)return;ctx.save();const top=cameraY(),time=s.elapsed;
 if(s.phase==='vault'){
  const fire=CAMP_LAYOUT.fire;
  for(let i=0;i<7;i++){const age=(time*.45+i*.37)%1;ctx.globalAlpha=(1-age)*.55;ctx.fillStyle=i%2?'#ffb965':'#e58046';ctx.fillRect(Math.round(fire.x+Math.sin(i*2.3+age*4)*19),Math.round(fire.y-10-age*66),2,3)}
 }else{
  const fire=s.active==='pyro',crypt=s.active==='necro';ctx.fillStyle=fire?'#f1a85e':crypt?'#95b6a3':'#c8b59b';
  for(let band=Math.floor((top-180)/240)*240;band<top+H+180;band+=240)for(let i=0;i<5;i++){
   const phase=(time*(fire?.12:.035)+i*.19+band*.001)%1,y=band+230-phase*200;
   const x=fire?(i%2?W-60:48)+Math.sin(i+phase*5)*16:50+((i*167+band*3)%Math.max(1,W-100)+W-100)%(W-100);
   ctx.globalAlpha=(1-phase)*(fire?.5:.17);ctx.fillRect(Math.round(x),Math.round(y),fire?2:1,fire?3:2);
  }
 }
 for(const puff of s.immersion?.dust||[]){ctx.globalAlpha=puff.ttl/.55;ctx.fillStyle=puff.color;ctx.fillRect(Math.round(puff.x),Math.round(puff.y),3,2)}ctx.restore();
}
function drawBossArrival(){
 const arrival=s.immersion?.arrival;if(!arrival||s.phase!=='boss')return;
 const age=s.elapsed-arrival.start,alpha=Math.min(1,age/.18,(2.6-age)/.5);if(alpha<=0)return;
 ctx.save();ctx.globalAlpha=alpha;const width=Math.min(W-68,590),left=(W-width)/2,y=cameraY()+64;
 ctx.fillStyle='#101c29e8';ctx.fillRect(left,y,width,53);ctx.fillStyle='#ad8553';ctx.fillRect(left,y,width,2);
 ctx.fillStyle='#f0cc92';ctx.textAlign='center';ctx.font='bold 13px Georgia';ctx.fillText(BOSSES.find(b=>b.id===arrival.id).name.toUpperCase(),W/2,y+18);
 ctx.fillStyle='#e7d8c1';ctx.font='13px Georgia';ctx.fillText(BOSS_ARRIVAL_LINES[arrival.id],W/2,y+38,width-20);ctx.restore();
}
