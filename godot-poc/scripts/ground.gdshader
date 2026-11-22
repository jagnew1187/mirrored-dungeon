shader_type canvas_item;
uniform sampler2D tile0 : repeat_enable, filter_nearest;
uniform sampler2D tile1 : repeat_enable, filter_nearest;
uniform sampler2D tile2 : repeat_enable, filter_nearest;
uniform sampler2D tile3 : repeat_enable, filter_nearest;
uniform vec2 map_size;
uniform bool camp=false;
// TC-02 surface-only comparison. 0 preserves the original sampling exactly.
uniform int floor_variant=0;
uniform bool comparison_interior=false;
uniform int count=0;
uniform vec4 segments[16];
float random(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
void fragment(){
 vec2 p=floor(UV*map_size/2.0)*2.0;
 float distance=10000.0;
 for(int i=0;i<16;i++){if(i>=count){break;}vec2 a=segments[i].xy;vec2 b=segments[i].zw;vec2 ab=b-a;float t=clamp(dot(p-a,ab)/dot(ab,ab),0.0,1.0);distance=min(distance,length(p-(a+t*ab)));}
 float rough=sin(p.x*.043)*3.0+sin(p.y*.037)*4.0+(random(floor(p/4.0))-.5)*12.0;
 float dirt=1.0-smoothstep(58.0,105.0,distance+rough);
 if(camp){float edge=length((p-vec2(575.0,385.0))/vec2(490.0,300.0));dirt=max(dirt,1.0-smoothstep(.80,1.03,edge+rough*.002));}
 vec4 grass=mix(texture(tile0,p/128.0),texture(tile3,p/128.0),.24+.15*sin(p.x*.012)*sin(p.y*.015));
 vec4 color=mix(grass,texture(tile1,p/128.0),dirt);
 float stone=(1.0-smoothstep(22.0,43.0,distance+rough))*.8;
 vec2 stone_p=p;
 float scale=floor_variant==1?1.25:1.5;
 if(floor_variant>0){stone_p=p/scale;}
 if(floor_variant==3){
  // Smooth domain warp varies existing irregular stone shapes without tile-edge jumps.
  stone_p+=vec2(sin(p.y*.019)+sin(p.x*.011+p.y*.009),sin(p.x*.017))*6.0;
 }
 vec3 masonry=texture(tile2,stone_p/128.0).rgb;
 if(floor_variant>=2){
  vec3 broad=(texture(tile2,(stone_p+vec2(2,0))/128.0).rgb+texture(tile2,(stone_p-vec2(2,0))/128.0).rgb+texture(tile2,(stone_p+vec2(0,2))/128.0).rgb+texture(tile2,(stone_p-vec2(0,2))/128.0).rgb)*.25;
  masonry=mix(masonry,broad,.38);
  masonry=mix(vec3(.40,.37,.30),masonry,.84);
 }
 if(comparison_interior){stone=1.0;}
 color=mix(color,vec4(masonry,1.0),stone);
 float vignette=camp?clamp(1.2-length((p-map_size*.5)/map_size),.62,1.0):.94;
 COLOR=vec4(color.rgb*vec3(.80,.86,.79)*vignette,1.0);
}
