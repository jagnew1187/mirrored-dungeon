// Deterministic strategy/combat simulation: same class, seed, room and reward pool.
// No score-gap scaling, free rewards, or fixed boss-clear countdowns.
const CLASS_SKILLS={mage:{fire:78,frost:24,fireCd:5,frostCd:13,heal:65,healCd:22},knight:{fire:63,frost:42,fireCd:5,frostCd:12,heal:42,healCd:24},rogue:{fire:94,frost:46,fireCd:5,frostCd:12,heal:23,healCd:21}};
function rivalDps(cls){const c=CLASSES[cls],skills=CLASS_SKILLS[cls];return (c.attackDamage/c.attackRate+skills.fire/skills.fireCd+skills.frost/skills.frostCd)*DEV.rival.attackUptime}
function rivalDecision(room,rival){const rng=seeded(room.seed+room.id.length*941+1337),missing=1-rival.hp/rival.max;const scores=room.options.map(id=>({id,score:id==='crystal'?missing*DEV.rewards.crystal.healing*10:id==='ward'?DEV.rewards.ward.reduction*(rival.empowered[room.id]?1.6:1)-(DEV.rewards.ward.drawback?.amount||0):id==='surge'?DEV.rewards.surge.cooldown*(rival.class==='mage'?4:3)-(DEV.rewards.surge.drawback?.amount||0)*(rival.class==='rogue'?2:1):rewardConfig("edge",room.id).damage*3-(DEV.rewards.edge.drawback?.amount||0)*missing*2})).sort((a,b)=>b.score-a.score);const urgent=missing>.35&&room.options.includes('crystal'),consider=rival.empowered[room.id]||rng()<.40;return {route:urgent||consider?'reward':'direct',reward:urgent?'crystal':scores[0].id,reason:urgent?'recover health':rival.empowered[room.id]?'prepare for empowered boss':consider?'invest in power':'prioritize speed'}}
function startRivalGauntlet(id){
 const old=s.rival,c=CLASSES[selectedClass];const r=old||{class:selectedClass,hp:c.hp,max:c.hp,empowered:{},runs:[],rng:seeded(DEV.seed+56563),deaths:0};s.rival=r;
 r.room=makeRoom(id);r.reward=null;r.phase='gauntlet';r.id=id;r.start=s.elapsed;r.phaseStart=s.elapsed;r.decision=rivalDecision(r.room,r);r.options=[...r.room.options];r.damageStart=r.damageReceived||0;
 if(r.empowered[id])applyRoomInheritance(r.room);
 const base=r.room.enemies.reduce((hp,e)=>hp+(e.type==='guard'?65:36)*DEV.difficulty,0),extra=Math.min(7,s.botTrash||0)*49;s.botTrash=0;
 const optional=r.decision.route==='reward'?r.room.guards.length*DEV.guardHealth*DEV.difficulty:0;
 r.guardCombat=optional/rivalDps(r.class);r.duration=routeDistance(r.room,r.decision.route)/c.speed+(base+extra)/rivalDps(r.class)*.35+r.guardCombat;
 const points=routePoints(r.room,'reward');r.collectAt=s.elapsed+points.slice(1,4).reduce((total,p,i)=>total+Math.hypot(p.x-points[i].x,p.y-points[i].y),0)/c.speed+r.guardCombat+(base+extra)/rivalDps(r.class)*.175;
 r.remaining=r.duration;s.botTarget=id;s.botTimer=r.remaining;
 log('Rival: '+BOSSES.find(b=>b.id===id).name+' · '+r.decision.route+' route ('+r.decision.reason+').','hi');
}
function collectRivalReward(){const r=s.rival;if(r.decision.route!=='reward'||r.reward)return;const id=r.decision.reward;r.reward={id,values:structuredClone(rewardConfig(id,r.id)),status:id==='crystal'?'consumed':'pending',collectedAt:s.elapsed};if(id==='crystal')r.hp=Math.min(r.max,r.hp+r.max*DEV.rewards.crystal.healing);log('Rival claimed '+rewardData(id).name+' after its guarded detour.','hi')}
function beginRivalBoss(){const r=s.rival,def=BOSSES.find(b=>b.id===r.id);r.phase='boss';r.phaseStart=s.elapsed;r.bossMax=Math.round(def.base*(1+s.botKills*.15)*(r.empowered[r.id]?1.3:1));r.bossHp=r.bossMax;r.attackCd=0;r.fireCd=0;r.frostCd=0;r.healCd=0;r.hitCd=1.55;r.addHitCd=2.4;r.abilityCd=r.id==='pyro'?4.4:r.id==='warlord'?5.5:7;r.guardUntil=0;r.veilUntil=0;
 collectRivalReward();startReward(r.reward);
 r.runs.push({boss:r.id,seed:r.room.seed,route:r.decision.route,options:[...r.options],reward:r.reward?.id||null,gauntletTime:s.elapsed-r.start,collectionTime:r.decision.route==='reward'?r.guardCombat+2*(DEV.detourDepth+110)/CLASSES[r.class].speed:0,empowered:!!r.empowered[r.id]});
 log('Rival entered '+def.name+(r.reward?' with '+rewardData(r.reward.id).name:' without a reward')+'.','hi');
}
function rivalHurt(amount,bossHit=false){const r=s.rival;amount*=rewardModifiers(r.reward).taken;if(bossHit&&amount>=DEV.significantHit&&r.reward?.id==='ward'&&r.reward.status==='active'){amount*=1-DEV.rewards.ward.reduction;r.reward.status='consumed'}if(r.guardUntil>s.elapsed)amount*=.52;if(r.veilUntil>s.elapsed)amount*=.38;r.damageReceived=(r.damageReceived||0)+Math.min(r.hp,amount);r.hp=Math.max(0,r.hp-amount);if(r.hp<=0){r.deaths++;finish(true,'The rival fell while pursuing its route.')}}
function updateRival(dt){
 const r=s.rival;if(!r||s.mode!=='running')return;
 if(r.phase==='gauntlet'){
  r.remaining-=dt;s.botTimer=Math.max(0,r.remaining);
  if(r.decision.route==='reward'&&s.elapsed>=r.collectAt)collectRivalReward();
  // Combat attrition derives from the chosen route's combat time, not race position.
  const combatFraction=(r.decision.route==='reward'?r.guardCombat:0)/Math.max(.1,r.duration);
  rivalHurt(dt*combatFraction*7*(1-DEV.rival.dodgeChance)*DEV.difficulty);
  if(r.remaining<=0&&s.mode==='running')beginRivalBoss();return;
 }
 if(r.reward?.status==='active'&&s.elapsed>=r.reward.until&&s.elapsed>=r.reward.drawbackUntil)r.reward.status='expired';
 const skills=CLASS_SKILLS[r.class],c=CLASSES[r.class],modifiers=rewardModifiers(r.reward),edge=modifiers.damage,cooldown=modifiers.cooldown,dodgeChance=DEV.rival.dodgeChance*modifiers.move;
 for(const k of ['attackCd','fireCd','frostCd','healCd','hitCd','abilityCd','addHitCd'])r[k]-=dt;
 if(r.attackCd<=0){r.bossHp-=c.attackDamage*edge;r.attackCd=c.attackRate*modifiers.attackInterval/DEV.rival.attackUptime}
 if(r.fireCd<=0){r.bossHp-=skills.fire*edge;r.fireCd=skills.fireCd*cooldown/DEV.rival.attackUptime}
 if(r.frostCd<=0){r.bossHp-=skills.frost*edge;r.frostCd=skills.frostCd*cooldown/DEV.rival.attackUptime}
 if(r.hp<r.max-skills.heal&&r.healCd<=0){r.hp=Math.min(r.max,r.hp+skills.heal);r.healCd=skills.healCd*cooldown;if(r.class==='knight')r.guardUntil=s.elapsed+5;if(r.class==='rogue')r.veilUntil=s.elapsed+3.8;}
 if(r.bossHp<=0){r.runs.at(-1).bossTime=s.elapsed-r.phaseStart;r.runs.at(-1).damage=(r.damageReceived||0)-r.damageStart;if(r.reward&&['active','consumed'].includes(r.reward.status)&&r.reward.started!==undefined)r.reward.status='expired';r.runs.at(-1).rewardStatus=r.reward?.status||null;botBeatBoss();return}
 if(r.hitCd<=0){if(r.rng()>dodgeChance)rivalHurt((r.id==='warlord'?16:10)+(r.empowered[r.id]?5:0),true);r.hitCd=s.bossStates.warlord.rivalDone?1:1.55;}
 if(s.mode!=='running')return;
 if(r.abilityCd<=0){if(r.rng()>dodgeChance)rivalHurt(r.id==='warlord'?22:r.id==='pyro'?11:5,r.id!=='necro');if(s.bossStates.pyro.rivalDone&&r.rng()>dodgeChance)rivalHurt(9,true);r.abilityCd=r.id==='pyro'?4.4:r.id==='warlord'?5.5:7;}
 if(s.mode!=='running')return;if(s.bossStates.necro.rivalDone&&r.addHitCd<=0){if(r.rng()>dodgeChance)rivalHurt(5,false);r.addHitCd=2.4;}
 s.botTimer=Math.max(0,r.bossHp/rivalDps(r.class));
}
function empowerRival(id){const r=s.rival;if(!r)return;r.empowered[id]=true;if(r.id!==id)return;if(r.phase==='boss'){const increase=Math.round(r.bossMax*.3);r.bossMax+=increase;r.bossHp+=increase;log('Your victory empowered the rival’s mirrored boss.','good')}else if(applyRoomInheritance(r.room)){const extra=id==='pyro'?0:65*DEV.difficulty/rivalDps(r.class);r.remaining+=extra;r.duration+=extra;log('Your victory altered the rival’s '+id+' gauntlet.','good')}}
function rivalProgress(){const r=s.rival;if(!r)return 'Waiting to begin';const name=BOSSES.find(b=>b.id===r.id)?.name;return r.phase==='gauntlet'?`${name} · ${r.decision.route} route · ${Math.round((1-r.remaining/r.duration)*100)}%`:`${name} · boss ${Math.max(0,Math.ceil(r.bossHp/r.bossMax*100))}%${r.reward?.status==='active'?' · '+rewardData(r.reward.id).name:''}`}
