const fs=require('node:fs');
let source=fs.readFileSync('make-class-preview.cjs','utf8');
source=source.replaceAll('class-gait-frames-v2.json','boss-gait-frames-v2.json').replaceAll('class-gait-art.json','boss-gait-art.json').replaceAll('Wizard and Rogue movement review','Boss movement review')
 .replace('<option value="mage">Wizard / Mage</option><option value="rogue">Rogue</option>','<option value="warlord">Warlord</option><option value="pyro">Pyromancer</option><option value="necro">Necromancer</option>')
 .replace('art={mage:{},rogue:{}}','art={warlord:{},pyro:{},necro:{}}')
 .replace('cls,dir);image.onload','cls,dir,({warlord:92,pyro:84,necro:84}[cls])*2);image.onload')
 .replace('strides={mage:84,rogue:92},speeds={mage:225,rogue:280}','strides={warlord:80,pyro:64,necro:64},speeds={warlord:68,pyro:42,necro:42}')
 .replace('92*.88*.85/image.gaitData.bodyHeight','({warlord:92,pyro:84,necro:84}[cls])/image.gaitData.bodyHeight')
 .replaceAll('heroes-walk-review.html','boss-walk-review.html');
// Reuse the review controls and exact shared cache implementation.
require('node:vm').runInNewContext(source,{require,console});
