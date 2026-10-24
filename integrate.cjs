const fs=require('node:fs');
let html=fs.readFileSync('index.html','utf8').replace(/<!-- Runtime asset bundles -->[\s\S]*?<!-- End runtime asset bundles -->\n?/g,'');
// Apply core renderer hooks only inside the complete atomic build.
if(!html.includes('if(drawBossGait(kind,'))html=html.replace('  if(drawHeroSprite(kind,','  if(drawBossGait(kind,x,y,width,height,anim,facing,hit,seed,actor))return;\n  if(drawHeroSprite(kind,');
html=html.replace('window.MirroredDungeonDebug={drawHeroSprite,','window.MirroredDungeonDebug={drawBossGait,preloadBossGait,showSprite,drawHeroSprite,');
html=html.replace('e.skillAnim=.78;if(e.id', 'e.skillAnim=.78;e.skillFacing=e.facing;if(e.id');
if(!html.includes('if(drawMobSprite(kind,'))html=html.replace('  if(drawBossGait(kind,','  if(drawMobSprite(kind,x,y,width,height,anim,facing,hit,seed,actor))return;\n  if(drawBossGait(kind,');
html=html.replace('window.MirroredDungeonDebug={drawBossGait,','window.MirroredDungeonDebug={drawMobSprite,preloadMobArt,drawBossGait,');
html=html.replace("62,76,e.move?'walk':e.attackAnim>0?'attack':'idle'","62,76,e.attackAnim>0?'attack':e.move?'walk':'idle'");
html=html.replace('e.attackAnim=.45;hurt(', 'e.attackAnim=.45;e.attackDirection=knightMovementDirection(h.x-e.x,h.y-e.y,e.walkDirection);hurt(');
const marker=html.includes('// Integrated assets and world modules')?'// Integrated assets and world modules':'// Integrated inside';
const start=html.indexOf(marker),end=html.indexOf('\n initSprites();reset();',start);
if(start<0||end<0)throw Error('Gauntlet integration markers missing');
const sources=['world.js','rewards.js','rival.js','telemetry.js','environments.js','warlord.js','warlord-props.js','warlord-decor.js','necro.js','pyro.js','journey.js','camp-rewards.js','camp-allies.js','walls.js','combat.js','class-gait-renderer.js','mob-animation.js','boss-gait-renderer.js','boss-skill-renderer.js','hero-animation.js','graphics.js'];
const embedded=(fs.existsSync('assets/hero-frames-v1.json')?'const HERO_FRAME_DATA='+fs.readFileSync('assets/hero-frames-v1.json','utf8').trim()+';\n':'')+[['WARLORD_ATLAS','assets/warlord-materials-v1.png'],['WARLORD_PROPS','assets/warlord-props-v1.png'],['WARLORD_DECOR','assets/warlord-decor-v1.png'],['NECRO_MATERIALS','assets/necro-materials-v1.png'],['NECRO_PROPS','assets/necro-props-v1.png'],['PYRO_MATERIALS','assets/pyro-materials-v1.png'],['PYRO_PROPS','assets/pyro-props-v1.png'],['JOURNEY_ATLAS','assets/journey-v1.png'],['CAMP_MATERIALS','assets/camp-materials-v1.png'],['BUFF_ART','assets/buff-art-v1.png'],['HERO_MAGE','assets/mage-animation-v1.png'],['HERO_KNIGHT','assets/knight-animation-v1.png'],['HERO_ROGUE','assets/rogue-animation-v1.png'],['HERO_KNIGHT_LEFT','assets/knight-left-animation-v1.png'],['HERO_KNIGHT_STRIKE','assets/knight-left-strike-v1.png']].map(([name,file])=>fs.existsSync(file)?'const '+name+'="data:image/png;base64,'+fs.readFileSync(file).toString('base64')+'";\n':'').join('');
const knightImages=Object.fromEntries(Object.entries(JSON.parse(fs.readFileSync('assets/knight-art.json','utf8'))).map(([direction,spec])=>[direction,'data:image/png;base64,'+fs.readFileSync('assets/'+spec.file).toString('base64')]));
const knightEmbedded='const KNIGHT_GAIT_V2='+JSON.stringify({images:knightImages,frames:JSON.parse(fs.readFileSync('assets/knight-gait-v2.json','utf8'))})+';\n';
const classFrames=JSON.parse(fs.readFileSync('assets/class-gait-frames-v2.json','utf8')),classAssets=JSON.parse(fs.readFileSync('assets/class-gait-art.json','utf8'));
const classArt=Object.fromEntries(Object.entries(classAssets).map(([cls,directions])=>[cls,{frames:classFrames[cls],images:Object.fromEntries(Object.entries(directions).map(([direction,spec])=>[direction,'data:image/png;base64,'+fs.readFileSync('assets/'+spec.file).toString('base64')]))}]));
const classEmbedded='const HERO_CLASS_GAITS='+JSON.stringify(classArt)+';\n';
const bossFrames=JSON.parse(fs.readFileSync('assets/boss-gait-frames-v2.json','utf8')),bossAssets=JSON.parse(fs.readFileSync('assets/boss-gait-art.json','utf8'));
const bossArt=Object.fromEntries(Object.entries(bossAssets).map(([kind,directions])=>[kind,{frames:bossFrames[kind],images:Object.fromEntries(Object.entries(directions).map(([direction,spec])=>[direction,'data:image/png;base64,'+fs.readFileSync('assets/'+spec.file).toString('base64')]))}]));
const bossEmbedded='const BOSS_GAITS='+JSON.stringify(bossArt)+';\n';
const skillFrames=JSON.parse(fs.readFileSync('assets/boss-skill-frames-v1.json','utf8'));
const skillArt=Object.fromEntries(Object.entries(skillFrames).map(([kind,frames])=>[kind,{frames,images:Object.fromEntries(['left','right'].map(side=>[side,'data:image/png;base64,'+fs.readFileSync('assets/'+kind+'-skill-'+side+'-v1.png').toString('base64')]))}]));
const skillEmbedded='const BOSS_SKILLS='+JSON.stringify(skillArt)+';\n';
const mobFrames=JSON.parse(fs.readFileSync('assets/mob-runtime-frames-v1.json','utf8'));
if(Object.keys(mobFrames).length!==4||Object.values(mobFrames).some(entry=>Object.keys(entry.frames).length!==8))throw Error('Mob motion requires all four designs and eight views');
const mobArt=Object.fromEntries(Object.entries(mobFrames).map(([kind,entry])=>[kind,{...entry,images:Object.fromEntries(Object.keys(entry.frames).map(direction=>[direction,'data:image/png;base64,'+fs.readFileSync('assets/mob-runtime/'+kind+'-'+direction+'-v1.png').toString('base64')]))}]));
const mobEmbedded='const MOB_MOTION='+JSON.stringify(mobArt)+';\n';
let output=html.slice(0,start)+'// Integrated assets and world modules\n'+embedded+knightEmbedded+classEmbedded+bossEmbedded+skillEmbedded+mobEmbedded+sources.map(file=>fs.readFileSync(file,'utf8')).join('\n')+html.slice(end);
// Keep each published file below GitHub's size limit while retaining file:// play.
fs.mkdirSync('runtime-assets',{recursive:true});const bundles=[];
output=output.replace(/^const ([A-Z][A-Z0-9_]+)=(.*);$/gm,(line,name,value)=>{
 if(line.length<200000)return line;
 JSON.parse(value); // Bundle values are data, never executable expressions.
 const file='runtime-assets/'+name.toLowerCase().replaceAll('_','-')+'.js';
 fs.writeFileSync(file,'globalThis.MirroredAssetData=globalThis.MirroredAssetData||{};\nglobalThis.MirroredAssetData.'+name+'='+value+';\n');bundles.push(file);
 return 'const '+name+'=globalThis.MirroredAssetData.'+name+';';
});
output=output.replace('<script>','<!-- Runtime asset bundles -->\n'+bundles.map(file=>'<script src="'+file+'"></script>').join('\n')+'\n<!-- End runtime asset bundles -->\n<script>');
output=output.replace('Offline single-file option','Offline local build');
// OneDrive/browser file handles can briefly lock the existing HTML on Windows.
// Publish a complete temporary build atomically, retaining the previous file on failure.
fs.writeFileSync('.index-build.tmp',output);
for(let attempt=0;;attempt++){
 try{fs.renameSync('.index-build.tmp','index.html');break}
 catch(error){if(attempt>=4)throw error;Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,100*(attempt+1))}
}
