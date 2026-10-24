const fs=require('node:fs');
const data=JSON.parse(fs.readFileSync('assets/knight-gait-v2.json','utf8'));
const images=Object.fromEntries(Object.entries(JSON.parse(fs.readFileSync('assets/knight-art.json','utf8'))).map(([direction,spec])=>[direction,'data:image/png;base64,'+fs.readFileSync('assets/'+spec.file).toString('base64')]));
const html=`<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Knight walking review</title>
<style>body{margin:24px auto;max-width:980px;padding:0 16px;background:#14212a;color:#f4e8cf;font:16px system-ui}button,input{margin:6px;padding:10px;accent-color:#e6bc72}canvas{width:100%;height:auto;image-rendering:pixelated;background:#1d2b34;border:1px solid #48616a;border-radius:10px}a{color:#a8dcec}</style>
<h1>Knight walking review</h1><p>Eight directions, eight walking poses and planted standing poses. Ground movement and gait share the same distance clock. Top figures show game size; lower figures show 2× detail.</p>
<label>Views <select id="views"><option value="diagonal">45° diagonals</option><option value="cardinal">Front, back and sides</option></select></label>
<button id="play">Pause</button><button id="stand">Stand</button><label>Preview speed <input id="speed" type="range" min="0.25" max="1.5" step="0.05" value="1"></label><label>Step through poses <input id="pose" type="range" min="0" max="7" value="0"></label>
<canvas width="960" height="540"></canvas><p><a href="index.html">Play the updated game</a></p><script>
const metadata=${JSON.stringify(data)},sources=${JSON.stringify(images)},art={};let playing=true,standing=false,distance=0,last=0;
for(const [key,src] of Object.entries(sources)){art[key]=new Image();art[key].src=src}
const canvas=document.querySelector('canvas'),g=canvas.getContext('2d');g.imageSmoothingEnabled=false;
const play=document.getElementById('play'),stand=document.getElementById('stand'),speed=document.getElementById('speed'),pose=document.getElementById('pose'),views=document.getElementById('views');
play.onclick=()=>{playing=!playing;play.textContent=playing?'Pause':'Play'};stand.onclick=()=>{standing=!standing;stand.textContent=standing?'Walk':'Stand'};
pose.oninput=()=>{playing=false;standing=false;play.textContent='Play';stand.textContent='Stand';distance=(Number(pose.value)+.01)*88/8};
function paint(time){const dt=last?Math.min(.05,(time-last)/1000):0;last=time;if(playing&&!standing)distance+=204*dt*Number(speed.value);g.clearRect(0,0,960,540);
(views.value==='diagonal'?['southeast','southwest','northeast','northwest']:['right','left','down','up']).forEach((direction,column)=>{const diagonal=views.value==='diagonal',cx=column*240+120,phase=distance%88/88,frame=standing?(diagonal?metadata[direction].idleFrame:column):Math.floor(phase*8),key=standing&&!diagonal?'idle':direction,img=art[key],r=metadata[key].frames[frame];
g.save();g.beginPath();g.rect(column*240,0,240,540);g.clip();g.fillStyle='#d6c49f';g.font='18px system-ui';g.textAlign='center';g.fillText(direction.toUpperCase(),cx,30);g.font='13px system-ui';g.fillText(standing?'Standing':'Pose '+(frame+1)+' / 8',cx,53);
const vectors={right:[1,0],left:[-1,0],down:[0,1],up:[0,-1],southeast:[Math.SQRT1_2,Math.SQRT1_2],southwest:[-Math.SQRT1_2,Math.SQRT1_2],northeast:[Math.SQRT1_2,-Math.SQRT1_2],northwest:[-Math.SQRT1_2,-Math.SQRT1_2]},amount=standing?0:distance,dx=(-vectors[direction][0]*amount)%32,dy=(-vectors[direction][1]*amount)%32;
g.strokeStyle='#30464d';for(const [top,bottom,multiplier] of [[70,235,1],[260,530,2]]){g.save();g.beginPath();g.rect(column*240,top,240,bottom-top);g.clip();for(let n=-2;n<20;n++){g.beginPath();g.moveTo(column*240+(n*32+dx)*multiplier,top);g.lineTo(column*240+(n*32+dx)*multiplier,bottom);g.stroke();g.beginPath();g.moveTo(column*240,top+(n*32+dy)*multiplier);g.lineTo(column*240+240,top+(n*32+dy)*multiplier);g.stroke()}g.restore()}
if(img.complete&&img.naturalWidth)for(const [baseline,multiplier] of [[180,1],[430,2]]){const scale=92*.88*.85/metadata[key].bodyHeight*multiplier;g.drawImage(img,r.x,r.y,r.w,r.h,cx-r.anchorX*scale,baseline-r.anchorY*scale,r.w*scale,r.h*scale)}
g.restore()});requestAnimationFrame(paint)}requestAnimationFrame(paint);
</script>`;
fs.writeFileSync('knight-walk-review.html',html);console.log('Created knight-walk-review.html');
