// A raised prism drawn over the existing footprint. Projection never changes collision.
const WALL_LOOK={
 warlord:{cap:'#b9b6a3',rim:'#777f7f',side:'#29323c',front:'#37414a',tint:'#b9b6a32b'},
 necro:{cap:'#a4bbb0',rim:'#6c8d80',side:'#162e2c',front:'#304c47',tint:'#9db9a538'},
 pyro:{cap:'#cda786',rim:'#987456',side:'#302323',front:'#503932',tint:'#c2956838'}
};
let warlordWallTexture=null;
function wallMaterial(id){
 if(id==='necro')return necroMaterial(1);if(id==='pyro')return pyroMaterial(1);
 if(id!=='warlord'||!warlordAtlas.naturalWidth)return null;
 if(!warlordWallTexture){warlordWallTexture=document.createElement('canvas');warlordWallTexture.width=warlordWallTexture.height=128;
  const g=warlordWallTexture.getContext('2d');g.imageSmoothingEnabled=false;const iw=warlordAtlas.naturalWidth,ih=warlordAtlas.naturalHeight;g.drawImage(warlordAtlas,iw/2,0,iw/2,ih/2,0,0,128,128);
 }return warlordWallTexture;
}
function wallPolygon(points,color){ctx.beginPath();points.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));ctx.closePath();ctx.fillStyle=color;ctx.fill()}
function drawRaisedWall(o,top,perimeter=false){
 if(!WALL_LOOK[s.active]||!['masonry','wall'].includes(o.kind)||o.hp===0)return false;
 const p=WALL_LOOK[s.active],rise=20,lean=7,x=Math.round(o.x),y=Math.round(o.y),w=o.w,h=o.h;
 const viewTop=Math.max(y-rise,top-30),viewBottom=Math.min(y+h+12,top+H+30);if(viewBottom<=viewTop)return true;
 ctx.save();ctx.imageSmoothingEnabled=false;ctx.beginPath();ctx.rect(x-lean-3,viewTop,w+lean+22,viewBottom-viewTop);ctx.clip();
 // Contact and cast shadows anchor the unchanged solid footprint to the floor.
 ctx.fillStyle='#040a0ed0';ctx.fillRect(x+w,y+5,6,h+6);ctx.fillStyle='#040a0e55';ctx.fillRect(x+w+6,y+9,10,h+6);
 const face=[[x-lean,y-rise],[x+w-lean,y-rise],[x+w-lean,y+h-rise],[x-lean,y+h-rise]];
 wallPolygon(face,p.rim);
 ctx.save();ctx.beginPath();face.forEach(([a,b],i)=>i?ctx.lineTo(a,b):ctx.moveTo(a,b));ctx.closePath();ctx.clip();
 const material=wallMaterial(s.active);
 if(material){ctx.fillStyle=ctx.createPattern(material,'repeat');ctx.fillRect(x-lean,viewTop,w,viewBottom-viewTop)}
 ctx.fillStyle=p.tint;ctx.fillRect(x-lean,viewTop,w,viewBottom-viewTop);
 // Large coping blocks read as architecture instead of another patterned floor strip.
 for(let row=Math.floor(viewTop/48)*48;row<viewBottom;row+=48){ctx.fillStyle='#080f16a0';ctx.fillRect(x-lean,row,w,3);ctx.fillStyle=p.cap;ctx.fillRect(x-lean+2,row+4,Math.max(2,w-4),2)}ctx.restore();
 wallPolygon([[x+w-lean,y-rise],[x+w,y],[x+w,y+h],[x+w-lean,y+h-rise]],p.side);
 ctx.fillStyle=p.rim;ctx.fillRect(x+w-lean,Math.max(y-rise,viewTop),2,Math.max(0,Math.min(y+h-rise,viewBottom)-Math.max(y-rise,viewTop)));
 wallPolygon([[x-lean,y+h-rise],[x+w-lean,y+h-rise],[x+w,y+h],[x,y+h]],p.front);
 // Visible front-face masonry courses reinforce height on low horizontal barriers.
 ctx.save();ctx.beginPath();ctx.moveTo(x-lean,y+h-rise);ctx.lineTo(x+w-lean,y+h-rise);ctx.lineTo(x+w,y+h);ctx.lineTo(x,y+h);ctx.closePath();ctx.clip();
 if(material){ctx.globalAlpha=.32;ctx.fillStyle=ctx.createPattern(material,'repeat');ctx.fillRect(x-lean,y+h-rise,w+lean,rise);ctx.globalAlpha=1}
 ctx.fillStyle='#070d1255';ctx.fillRect(x-lean,y+h-10,w+lean,2);for(let bx=x-lean+20;bx<x+w;bx+=24)ctx.fillRect(bx,y+h-rise,2,rise);ctx.restore();
 ctx.strokeStyle=p.cap;ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(x-lean,y+h-rise);ctx.lineTo(x+w-lean,y+h-rise);ctx.stroke();
 ctx.fillStyle=p.cap;ctx.fillRect(x-lean,Math.max(y-rise,viewTop),3,Math.max(0,Math.min(y+h-rise,viewBottom)-Math.max(y-rise,viewTop)));
 if(!perimeter){ctx.strokeStyle='#081118';ctx.lineWidth=2;ctx.strokeRect(x,y,w,h)}
 ctx.restore();return true;
}
function drawRaisedPerimeter(){
 if(!['gauntlet','boss'].includes(s.phase))return;const top=cameraY();
 // Outer trim is decorative; existing world bounds continue to define walkable limits.
 for(const x of [3,W-25])drawRaisedWall({x,y:top-64,w:22,h:H+128,kind:'masonry',hp:-1},top,true);
}
