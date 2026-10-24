// New hero art uses explicit 4x4 sheets, eight gait frames and eight action frames.
// The Knight has independently drawn left/right views; his equipment is never mirrored.
const heroArt={mage:{},knight:{},rogue:{}};
const HERO_WORLD_SCALE=.85;
const knightGait={};
if(typeof KNIGHT_GAIT_V2!=='undefined')for(const [direction,source] of Object.entries(KNIGHT_GAIT_V2.images)){
 const img=new Image();img.heroKey='knight-gait-'+direction;img.gaitDirection=direction;img.gaitData=KNIGHT_GAIT_V2.frames[direction];knightGait[direction]=img;
 img.onload=()=>{C.dataset['knightGait'+direction]='ready'};img.src=source;
}
function drawKnightGait(x,y,height,anim,facing,hit,actor){
 const direction=actor?.walkDirection||(facing<0?'left':'right'),directions=['right','left','down','up'];
 const diagonal=!directions.includes(direction),image=knightGait[anim==='idle'&&!diagonal?'idle':direction];if(!image?.naturalWidth)return false;
 const frame=anim==='idle'?(diagonal?image.gaitData.idleFrame:directions.indexOf(direction)):animationIndex('knight','walk',actor),r=image.gaitData.frames[frame];
 if(!r)return false;
 const scale=height*.88*HERO_WORLD_SCALE/image.gaitData.bodyHeight;
 ctx.save();ctx.translate(Math.round(x),Math.round(y));ctx.imageSmoothingEnabled=false;
 if(hit>0)ctx.filter='brightness(1.6) saturate(.65)';
 ctx.drawImage(image,r.x,r.y,r.w,r.h,-r.anchorX*scale,-r.anchorY*scale,r.w*scale,r.h*scale);ctx.restore();return true;
}
function loadHeroArt(cls,direction,source){
 if(!source)return;const img=new Image();img.heroKey=cls+'-'+direction;heroArt[cls][direction]=img;
 img.onload=()=>{if(direction==='right')spriteSequences[cls]={idle:{start:8,count:1},walk:{start:0,count:8},attack:{start:8,count:8},skill:{start:8,count:8}};
  C.dataset['hero'+cls[0].toUpperCase()+cls.slice(1)+(direction==='right'?'':direction[0].toUpperCase()+direction.slice(1))]='ready';refreshPortraits();};img.src=source;
}
loadHeroArt('mage','right',typeof HERO_MAGE!=='undefined'?HERO_MAGE:null);
loadHeroArt('knight','right',typeof HERO_KNIGHT!=='undefined'?HERO_KNIGHT:null);
loadHeroArt('rogue','right',typeof HERO_ROGUE!=='undefined'?HERO_ROGUE:null);
loadHeroArt('knight','left',typeof HERO_KNIGHT_LEFT!=='undefined'?HERO_KNIGHT_LEFT:null);
loadHeroArt('knight','strike',typeof HERO_KNIGHT_STRIKE!=='undefined'?HERO_KNIGHT_STRIKE:null);
function heroArtReady(cls){return !!heroArt[cls]?.right?.naturalWidth}
function heroFrameRect(img,frame){if(typeof HERO_FRAME_DATA!=='undefined'&&HERO_FRAME_DATA[img.heroKey])return HERO_FRAME_DATA[img.heroKey].frames[frame];const col=frame%4,row=Math.floor(frame/4),w=img.naturalWidth,h=img.naturalHeight;
 const x=Math.round(col*w/4),y=Math.round(row*h/4),ex=Math.round((col+1)*w/4),ey=Math.round((row+1)*h/4);
 return{x,y,w:ex-x,h:ey-y,anchorX:(ex-x)/2,anchorY:(ey-y)*.85};
}
function drawHeroSprite(kind,x,y,width,height,anim,facing,hit,seed,actor){
 if((kind==='mage'||kind==='rogue')&&(anim==='walk'||anim==='idle')&&drawClassGait(kind,x,y,height,anim,facing,hit,actor))return true;
 if(kind==='knight'&&(anim==='walk'||anim==='idle')&&drawKnightGait(x,y,height,anim,facing,hit,actor))return true;
 if(!heroArtReady(kind))return false;
 const explicitLeft=kind==='knight'&&facing<0;let img=explicitLeft?heroArt.knight.left:heroArt[kind].right;
 if(explicitLeft&&!img?.naturalWidth)img=heroArt.knight.right;
 if(!img?.naturalWidth)return false;
 // Use one coherent sheet per direction: independently generated halfway art
 // changes silhouette between steps. Knight frame 8 is his planted ready stance;
 // other classes use a grounded contact rather than their casting/attack pose.
 let frame=anim==='idle'?(kind==='knight'?8:actor?.walkSettle>0?animationIndex(kind,'walk',actor,seed):0):animationIndex(kind,anim,actor,seed);
 if(explicitLeft&&frame===12&&heroArt.knight.strike?.naturalWidth){img=heroArt.knight.strike;frame=0}
 const rect=heroFrameRect(img,frame);
 ctx.save();ctx.translate(Math.round(x),Math.round(y));if(facing<0&&kind!=='knight')ctx.scale(-1,1);ctx.imageSmoothingEnabled=false;
 if(hit>0)ctx.filter='brightness(1.6) saturate(.65)';
 const nominal=typeof HERO_FRAME_DATA!=='undefined'?HERO_FRAME_DATA[img.heroKey]?.bodyHeight:null,scale=height*.88*HERO_WORLD_SCALE/(nominal||rect.h*.8);
 const bob=anim==='walk'&&actor&&!reduceMotion.matches?-Math.round((1-Math.cos((actor.walkCycle||0)*Math.PI*4))*.65):0;
 ctx.drawImage(img,rect.x,rect.y,rect.w,rect.h,-rect.anchorX*scale,bob-rect.anchorY*scale,rect.w*scale,rect.h*scale);ctx.restore();return true;
}
function drawHeroPortrait(g,kind,width,height){
 if(!heroArtReady(kind))return false;const img=heroArt[kind].right,rect=heroFrameRect(img,8);g.clearRect(0,0,width,height);g.imageSmoothingEnabled=false;
 const nominal=typeof HERO_FRAME_DATA!=='undefined'?HERO_FRAME_DATA[img.heroKey]?.bodyHeight:null,scale=height*.85/(nominal||rect.h*.8);
 g.drawImage(img,rect.x,rect.y,rect.w,rect.h,width/2-rect.anchorX*scale,height-4-rect.anchorY*scale,rect.w*scale,rect.h*scale);return true;
}
