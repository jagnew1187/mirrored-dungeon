// Integrated inside the original game's closure. Shared seeded room model for both mirrors.
const DEV = {
 warlord:{edge:{damage:.30,duration:15,drawback:{stat:"taken",amount:.20,duration:15}}},
 seed:42017, difficulty:1, enemies:3, obstacleDensity:18, hazardFrequency:1,
 worldHeight:3400, detourDepth:650, rewardGuards:2, guardHealth:82,
 significantHit:9, hazardDamage:7, hazardInterval:.8,
 rewards:{edge:{damage:.25,duration:15,drawback:{stat:'taken',amount:.20,duration:15}},ward:{reduction:.70,drawback:{stat:'move',amount:.12,duration:10}},crystal:{healing:.30,drawback:null},surge:{cooldown:.25,duration:15,drawback:{stat:'attack',amount:.15,duration:15}}},
 rival:{attackUptime:.66,dodgeChance:.62}, telemetrySamples:8
};
function seeded(seed){return()=>{seed|=0;seed=seed+0x6D2B79F5|0;let t=Math.imul(seed^seed>>>15,1|seed);t^=t+Math.imul(t^t>>>7,61|t);return((t^t>>>14)>>>0)/4294967296}}
function roomRandom(id,seed=DEV.seed){return seeded((seed|0)+BOSSES.findIndex(b=>b.id===id)*7919)}
function roomGeometry(){const height=Math.max(H+1000,DEV.worldHeight);return {height,mainX:Math.round(W*.46),wallX:Math.round(W*.65),rewardX:Math.round(W*.85),junctionY:height-520,rewardY:height-520-DEV.detourDepth,startY:height-100,exitY:100}}
function worldBottom(){return s?.phase==='gauntlet'?s.gauntlet.room.height:H}
function cameraY(){return s?.phase==='gauntlet'?clamp(s.hero.y-H*.67,0,worldBottom()-H):0}
function overlaps(a,o){return o.hp!==0&&a.x+a.r>o.x&&a.x-a.r<o.x+o.w&&a.y+a.r>o.y&&a.y-a.r<o.y+o.h}
function clearAt(x,y,r,obstacles=s.obstacles,bottom=worldBottom()){return x>=30+r/4&&x<=W-30-r/4&&y>=75&&y<=bottom-30&&!obstacles.some(o=>overlaps({x,y,r},o))}
function visibleLine(a,b,obstacles=s.obstacles,r=2){const length=Math.hypot(b.x-a.x,b.y-a.y),steps=Math.max(1,Math.ceil(length/14));for(let i=1;i<=steps;i++)if(obstacles.some(o=>overlaps({x:a.x+(b.x-a.x)*i/steps,y:a.y+(b.y-a.y)*i/steps,r},o)))return false;return true}
function validateLayout(obstacles,room=roomGeometry()){
 const size=24,start=[Math.round(room.mainX/size),Math.round(room.startY/size)],queue=[start],seen=new Set([start.join(',')]);let exit=false,reward=false;
 for(let i=0;i<queue.length;i++){const [cx,cy]=queue[i],x=cx*size,y=cy*size;if(Math.hypot(x-room.mainX,y-room.exitY)<48)exit=true;if(Math.hypot(x-room.rewardX,y-room.rewardY)<48)reward=true;if(exit&&reward)return true;for(const [dx,dy]of [[1,0],[-1,0],[0,1],[0,-1]]){const nx=cx+dx,ny=cy+dy,key=nx+','+ny;if(!seen.has(key)&&clearAt(nx*size,ny*size,20,obstacles,room.height)){seen.add(key);queue.push([nx,ny])}}}return false;
}
function makeRoom(id,seed=DEV.seed){
 const rng=roomRandom(id,seed),room={...roomGeometry(),id,seed,obstacles:[],hazards:[],guards:[],enemies:[],options:rewardOptions(id,seed),inherited:false};
 room.obstacles.push({x:room.wallX,y:65,w:28,h:room.junctionY-25,kind:'masonry',hp:-1});
 for(let i=0;i<DEV.obstacleDensity;i++){const o={x:Math.round((48+rng()*(W-130))/4)*4,y:Math.round((180+rng()*(room.height-470))/4)*4,w:i%4===1?64:32,h:i%4===0?46:28,kind:['pillar','wall','rubble','wood'][i%4],hp:i%4===3?65:-1};
 // Reserve both walking spines and the junction: random decoration cannot seal a route.
 if(o.x<room.mainX+64&&o.x+o.w>room.mainX-64||o.x<room.rewardX+55&&o.x+o.w>room.rewardX-55||Math.abs(o.y-room.junctionY)<170||room.obstacles.some(other=>overlaps({x:o.x+o.w/2,y:o.y+o.h/2,r:Math.max(o.w,o.h)/2+6},other)))continue;room.obstacles.push(o);
 }
 for(let i=0;i<10;i++){const optional=i>=7;room.hazards.push({x:optional?room.rewardX+(rng()-.5)*48:room.mainX+(i%3===0?0:(i%2?66:-66)),y:optional?room.rewardY+130+(i-7)*140:300+i*(room.junctionY-680)/7,r:22,kind:id==='pyro'?(i%2?'burn':'fire'):id==='necro'?'rune':'spike',offset:rng()*4.8,optional});}
 for(let i=0;i<DEV.enemies;i++)room.enemies.push({type:i===0?'guard':'shade',x:room.mainX+(i%2?65:-65),y:room.junctionY-300-i*630});
 for(let i=0;i<DEV.rewardGuards;i++)room.guards.push({type:'guard',x:room.rewardX+(i%2?32:-32),y:room.rewardY+70+i*100,summoner:id==='necro'&&i===0});
 room.obstacles.push({x:room.mainX-106,y:72,w:32,h:80,kind:'gateway',hp:-1},{x:room.mainX+74,y:72,w:32,h:80,kind:'gateway',hp:-1});
 if(id==='warlord')warlordArmory(room);if(id==='necro')necroHall(room);if(id==='pyro')pyroHall(room);
 if(!validateLayout(room.obstacles,room))throw Error('Unreachable gauntlet layout');return room;
}
function makeLayout(id){return makeRoom(id).obstacles}
function selectBoss(id){
 if(s.mode!=='running'||s.paused||s.active||!s.bossStates[id]||s.bossStates[id].done)return;
 closeBossSheet();closeRewards();resetJoystick();expireReward();s.reward=null;s.active=id;s.phase='gauntlet';s.selectNeeded=false;s.boss=null;s.enemies=[];s.shots=[];s.rings=[];pointerTarget=null;
 const room=makeRoom(id);s.gauntlet={id,room,start:s.elapsed,claimed:false,offered:false,completed:false,committed:false,commitTime:null,options:[...room.options],route:'direct',startDamage:s.stats.damageReceived};
 s.obstacles=room.obstacles;s.hazards=room.hazards;s.hero.x=room.mainX;s.hero.y=room.startY;s.hero.slowUntil=0;
 for(const e of room.enemies)spawnThemed(e.type,e.x,e.y);
 for(const e of room.guards){const mob=spawnThemed(e.type,e.x,e.y,true);mob.summoner=e.summoner;}
 s.stats.exposures.push({boss:id,options:[...room.options],class:selectedClass});
 if(s.bossStates[id].empowered)inheritGauntlet();toast('A wounded scout calls to you from beside the path.',4);log('Follow the path to the inner chamber, or seek the guarded supplies in the eastern wing.');renderAll();
}
function spawnThemed(type,x,y,rewardGuard=false){spawnMob(type,x,y);const e=s.enemies.at(-1);e.sprite=s.active==='necro'?'skeleton':s.active==='pyro'?'hound':'cultist';e.rewardGuard=rewardGuard;e.armored=s.active==='warlord'&&type==='guard';e.ability=2.5;e.hp=e.max=Math.round((rewardGuard?DEV.guardHealth:type==='guard'?65:36)*DEV.difficulty);e.dmg*=DEV.difficulty;e.charger=s.active==='warlord';e.home={x,y};resolveSolid(e);return e}
function applyRoomInheritance(room){if(room.inherited)return false;room.inherited=true;if(room.id==='pyro')room.hazards.push({x:room.mainX+65,y:Math.min(room.junctionY-200,1200),r:22,kind:'fire',offset:0,createdAt:s.elapsed});else room.enemies.push({type:'guard',x:room.mainX-65,y:Math.min(room.junctionY-200,1200)});return true}
function inheritGauntlet(){const g=s.gauntlet;if(!g||!applyRoomInheritance(g.room))return;if(g.id!=='pyro'){const e=g.room.enemies.at(-1);spawnThemed(e.type,e.x,e.y)}g.inherited=true;toast('Mirror inheritance: '+(g.id==='pyro'?'extra warned flame vent':g.id==='necro'?'undead reinforcement':'armored reinforcement'),4);log('The rival changed this gauntlet. All routes remain open.','hi')}
function beginEncounter(){if(s.phase!=='gauntlet'||s.mode!=='running')return;const g=s.gauntlet;g.completed=true;s.stats.gauntlets.push({boss:g.id,class:selectedClass,seed:g.room.seed,tuning:tuningSnapshot(),time:s.elapsed-g.start,route:g.route,reward:s.reward?.id||null,collectionTime:g.commitTime===null?0:(g.collectedAt||s.elapsed)-g.commitTime,detourTime:g.commitTime===null?0:(g.detourCompletedAt||s.elapsed)-g.commitTime,damage:s.stats.damageReceived-g.startDamage,empowered:s.bossStates[g.id].empowered});closeRewards();s.phase='boss';s.obstacles=[];s.hazards=[];s.hero.slowUntil=0;enterBoss(g.id);if(g.id==='warlord'){s.obstacles=warlordArenaMask();for(const e of s.enemies)resolveSolid(e);resolveSolid(s.hero)}if(g.id==='necro'){s.obstacles=necroArenaMask();for(const e of s.enemies)resolveSolid(e);resolveSolid(s.hero)}if(g.id==='pyro'){s.obstacles=pyroArenaMask();for(const e of s.enemies)resolveSolid(e);resolveSolid(s.hero)}s.encounter={boss:g.id,start:s.elapsed,startDamage:s.stats.damageReceived};activateReward(s.reward);toast('Gauntlet complete · '+BOSSES.find(b=>b.id===g.id).name,3)}
function resolveSolid(entity,old){if(clearAt(entity.x,entity.y,entity.r))return;if(old){const tx=entity.x;entity.x=old.x;if(clearAt(entity.x,entity.y,entity.r))return;entity.x=tx;entity.y=old.y;if(clearAt(entity.x,entity.y,entity.r))return;entity.x=old.x;return}for(let radius=8;radius<240;radius+=8)for(let a=0;a<8;a++){const x=entity.x+Math.cos(a*Math.PI/4)*radius,y=entity.y+Math.sin(a*Math.PI/4)*radius;if(clearAt(x,y,entity.r)){entity.x=x;entity.y=y;return}}}
function projectileCover(p,dt){for(const o of s.obstacles){if(o.hp===0)continue;const steps=Math.max(1,Math.ceil(Math.hypot(p.vx,p.vy)*dt/8));for(let i=0;i<=steps;i++)if(overlaps({x:p.x-p.vx*dt*i/steps,y:p.y-p.vy*dt*i/steps,r:p.r},o)){if(o.hp>0&&p.team==='hero')o.hp=Math.max(0,o.hp-p.damage);p.ttl=0;return true}}return false}
function hazardState(h){const cycle=5/Math.max(.05,DEV.hazardFrequency),origin=h.createdAt??s.gauntlet?.start??0,age=(s.elapsed-origin+h.offset)%cycle;return age<cycle*.25?'warning':age<cycle*.46?'active':'recovery'}
function updateEnvironment(){
 if(s.reward?.status==='active'&&s.elapsed>=s.reward.until&&s.elapsed>=s.reward.drawbackUntil)s.reward.status='expired';if(s.phase!=='gauntlet')return;const g=s.gauntlet,room=g.room;
 if(s.bossStates[g.id].empowered)inheritGauntlet();
 if(!g.committed&&(s.hero.x>room.wallX+45||s.hero.x>room.mainX+70&&s.hero.y>room.junctionY+50)){g.committed=true;g.commitTime=s.elapsed;g.route='reward';log('Reward detour entered: defeat its guards, then return to the main passage.');}
 if(g.committed&&g.collectedAt&&!g.detourCompletedAt&&Math.abs(s.hero.x-room.mainX)<45&&s.hero.y>room.junctionY+50)g.detourCompletedAt=s.elapsed;for(const h of s.hazards){h.state=hazardState(h);if(h.state==='active'&&Math.hypot(s.hero.x-h.x,s.hero.y-h.y)<h.r+s.hero.r){if(h.kind==='rune')s.hero.slowUntil=s.elapsed+.75;else if((h.nextHit||0)<=s.elapsed){hurt(DEV.hazardDamage*DEV.difficulty);h.nextHit=s.elapsed+DEV.hazardInterval}}}
 if(s.mode!=='running')return;
 if(g.committed&&!g.claimed&&!s.enemies.some(e=>e.rewardGuard&&!e.dead)&&Math.hypot(s.hero.x-room.rewardX,s.hero.y-room.rewardY)<60)chooseRewards();
 if(s.hero.y<130&&Math.abs(s.hero.x-room.mainX)<65)beginEncounter();
}
function enemyWaypoint(e,hero){
 const room=s.gauntlet?.room,goal=s.phase==='gauntlet'&&e.home&&(e.rewardGuard&&(!s.gauntlet.committed||hero.x<room.wallX+30)||Math.hypot(e.x-hero.x,e.y-hero.y)>650)?e.home:hero;
 if(visibleLine(e,goal,s.obstacles,e.r+2))return goal;
 if(e.pathUntil>s.elapsed&&e.path?.length){while(e.path.length>1&&Math.hypot(e.x-e.path[0].x,e.y-e.path[0].y)<14)e.path.shift();return e.path[0]}
 const grid=24,sx=Math.round(e.x/grid),sy=Math.round(e.y/grid),tx=Math.round(goal.x/grid),ty=Math.round(goal.y/grid),queue=[[sx,sy]],parents=new Map([[sx+','+sy,null]]);let found=null;
 for(let i=0;i<queue.length&&i<5500;i++){const [x,y]=queue[i];if(Math.abs(x-tx)+Math.abs(y-ty)<=1){found=[x,y];break}for(const [dx,dy]of [[0,-1],[1,0],[0,1],[-1,0]]){const nx=x+dx,ny=y+dy,key=nx+','+ny;if(!parents.has(key)&&clearAt(nx*grid,ny*grid,e.r+2)){parents.set(key,[x,y]);queue.push([nx,ny])}}}
 e.path=[];while(found){e.path.unshift({x:found[0]*grid,y:found[1]*grid});found=parents.get(found.join(','))}if(e.path.length>1)e.path.shift();e.pathUntil=s.elapsed+.7;return e.path[0]||e;
}
function routePoints(room,route){const start={x:room.mainX,y:room.startY},exit={x:room.mainX,y:room.exitY};if(route==='direct')return[start,exit];const mouth={x:room.rewardX,y:room.junctionY+110},fork={x:room.mainX,y:mouth.y},reward={x:room.rewardX,y:room.rewardY};return[start,fork,mouth,reward,mouth,fork,exit]}
function routeDistance(room,route){const p=routePoints(room,route);return p.slice(1).reduce((total,v,i)=>total+Math.hypot(v.x-p[i].x,v.y-p[i].y),0)}
