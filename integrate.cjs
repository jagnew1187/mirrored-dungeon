const fs=require('node:fs');
let html=fs.readFileSync('index.html','utf8');
const marker=html.includes('// Integrated assets and world modules')?'// Integrated assets and world modules':'// Integrated inside';
const start=html.indexOf(marker),end=html.indexOf('\n initSprites();reset();',start);
if(start<0||end<0)throw Error('Gauntlet integration markers missing');
const sources=['world.js','rewards.js','rival.js','telemetry.js','environments.js','warlord.js','warlord-props.js','warlord-decor.js','necro.js','pyro.js','journey.js','camp-rewards.js','camp-allies.js','walls.js','graphics.js'];
const embedded=[['WARLORD_ATLAS','assets/warlord-materials-v1.png'],['WARLORD_PROPS','assets/warlord-props-v1.png'],['WARLORD_DECOR','assets/warlord-decor-v1.png'],['NECRO_MATERIALS','assets/necro-materials-v1.png'],['NECRO_PROPS','assets/necro-props-v1.png'],['PYRO_MATERIALS','assets/pyro-materials-v1.png'],['PYRO_PROPS','assets/pyro-props-v1.png'],['JOURNEY_ATLAS','assets/journey-v1.png'],['CAMP_MATERIALS','assets/camp-materials-v1.png'],['BUFF_ART','assets/buff-art-v1.png']].map(([name,file])=>fs.existsSync(file)?'const '+name+'="data:image/png;base64,'+fs.readFileSync(file).toString('base64')+'";\n':'').join('');
fs.writeFileSync('index.html',html.slice(0,start)+'// Integrated assets and world modules\n'+embedded+sources.map(file=>fs.readFileSync(file,'utf8')).join('\n')+html.slice(end));
