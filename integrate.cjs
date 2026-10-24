const fs=require('node:fs');
let html=fs.readFileSync('index.html','utf8');
const start=html.indexOf('// Integrated inside'),end=html.indexOf('\n initSprites();reset();',start);
if(start<0||end<0)throw Error('Gauntlet integration markers missing');
const sources=['world.js','rewards.js','rival.js','telemetry.js','graphics.js'];
fs.writeFileSync('index.html',html.slice(0,start)+sources.map(file=>fs.readFileSync(file,'utf8')).join('\n')+html.slice(end));
