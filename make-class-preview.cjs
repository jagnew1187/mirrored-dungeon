const fs=require('node:fs');
const metadata=JSON.parse(fs.readFileSync('assets/class-gait-frames-v2.json','utf8'));
const manifest=JSON.parse(fs.readFileSync('assets/class-gait-art.json','utf8'));
const sources=Object.fromEntries(Object.entries(manifest).map(([cls,dirs])=>[cls,Object.fromEntries(Object.entries(dirs).map(([dir,spec])=>[dir,'data:image/png;base64,'+fs.readFileSync('assets/'+spec.file).toString('base64')]))]));
const renderer=fs.readFileSync('class-gait-renderer.js','utf8'),cache=renderer.slice(renderer.indexOf('function cacheClassGait'),renderer.indexOf("if(typeof HERO_CLASS_GAITS"));
const html=`<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Wizard and Rogue movement review</title>
<style>body{margin:20px auto;max-width:980px;padding:0 16px;background:#14212a;color:#f4e8cf;font:16px system-ui}button,input,select{margin:5px;padding:9px;accent-color:#e6bc72}canvas{width:100%;height:auto;image-rendering:pixelated;background:#1d2b34;border:1px solid #48616a;border-radius:10px}a{color:#a8dcec}</style>
<h1>Wizard and Rogue movement review</h1><p>Eight directions with walking and grounded standing poses. Top figures show game size; lower figures show 2× detail. The same compact sprite cache is used in the game.</p>
<label>Class <select id="character"><option value="mage">Wizard / Mage</option><option value="rogue">Rogue</option></select></label><label>Views <select id="views"><option value="cardinal">Front, back and sides</option><option value="diagonal">45° diagonals</option></select></label>
<button id="play">Pause</button><button id="stand">Stand</button><label>Speed <input id="speed" type="range" min="0.25" max="1.5" step="0.05" value="1"></label><label>Pose <input id="pose" type="range" min="0" max="7" value="0"></label><canvas width="960" height="540"></canvas><p><a href="index.html">Play the updated game</a></p>
<script>${cache}
const metadata=${JSON.stringify(metadata)},sources=${JSON.stringify(sources)},art={mage:{},rogue:{}};
for(const [cls,dirs] of Object.entries(sources))for(const [dir,src] of Object.entries(dirs)){const image=new Image();image.onload=()=>{art[cls][dir]=cacheClassGait(image,metadata[cls][dir],cls,dir);image.onload=null;image.src=''};image.src=src}
const canvas=document.querySelector('canvas'),g=canvas.getContext('2d'),character=document.getElementById('character'),views=document.getElementById('views'),play=document.getElementById('play'),stand=document.getElementById('stand'),speed=document.getElementById('speed'),pose=document.getElementById('pose');g.imageSmoothingEnabled=false;
let playing=true,standing=false,distance=0,last=0;const strides={mage:84,rogue:92},speeds={mage:225,rogue:280};
play.onclick=()=>{playing=!playing;play.textContent=playing?'Pause':'Play'};stand.onclick=()=>{standing=!standing;stand.textContent=standing?'Walk':'Stand'};character.onchange=()=>{distance=0};
pose.oninput=()=>{playing=false;standing=false;play.textContent='Play';stand.textContent='Stand';distance=(Number(pose.value)+.01)*strides[character.value]/8};
function paint(time){const dt=last?Math.min(.05,(time-last)/1000):0;last=time;const cls=character.value;if(playing&&!standing)distance+=speeds[cls]*dt*Number(speed.value);g.clearRect(0,0,960,540);
(views.value==='diagonal'?['southeast','southwest','northeast','northwest']:['right','left','down','up']).forEach((dir,column)=>{const cx=column*240+120,frame=standing?8:Math.floor(distance%strides[cls]/strides[cls]*8),image=art[cls][dir];
g.save();g.beginPath();g.rect(column*240,0,240,540);g.clip();g.fillStyle='#d6c49f';g.font='18px system-ui';g.textAlign='center';g.fillText(dir.toUpperCase(),cx,30);g.font='13px system-ui';g.fillText(standing?'Standing':'Pose '+(frame+1)+' / 8',cx,53);
const vectors={right:[1,0],left:[-1,0],down:[0,1],up:[0,-1],southeast:[Math.SQRT1_2,Math.SQRT1_2],southwest:[-Math.SQRT1_2,Math.SQRT1_2],northeast:[Math.SQRT1_2,-Math.SQRT1_2],northwest:[-Math.SQRT1_2,-Math.SQRT1_2]},amount=standing?0:distance,dx=(-vectors[dir][0]*amount)%32,dy=(-vectors[dir][1]*amount)%32;
g.strokeStyle='#30464d';for(const [top,bottom,multiplier] of [[70,235,1],[260,530,2]]){g.save();g.beginPath();g.rect(column*240,top,240,bottom-top);g.clip();for(let n=-2;n<20;n++){g.beginPath();g.moveTo(column*240+(n*32+dx)*multiplier,top);g.lineTo(column*240+(n*32+dx)*multiplier,bottom);g.stroke();g.beginPath();g.moveTo(column*240,top+(n*32+dy)*multiplier);g.lineTo(column*240+240,top+(n*32+dy)*multiplier);g.stroke()}g.restore()}
if(image){const r=image.gaitData.frames[frame];for(const [baseline,multiplier] of [[180,1],[430,2]]){const scale=92*.88*.85/image.gaitData.bodyHeight*multiplier;g.drawImage(image,r.x,r.y,r.w,r.h,cx-r.anchorX*scale,baseline-r.anchorY*scale,r.w*scale,r.h*scale)}}g.restore()});requestAnimationFrame(paint)}requestAnimationFrame(paint);
</script>`;
fs.writeFileSync('heroes-walk-review.html',html);console.log('Created heroes-walk-review.html');
