shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.24,0.32,0.20,1.0);
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
float hash(vec2 p) { vec3 q = fract(vec3(p.x,p.y,p.x)*0.1031); q += dot(q,q.yzx+33.33); return fract((q.x+q.y)*q.z); }
float noise(vec2 p) {
    vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
    float broad=noise(world_pos.xz*0.028);
    float dry=smoothstep(0.48,0.77,noise(world_pos.xz*0.017+vec2(51.0)));
    float fine=noise(world_pos.xz*3.0);
    float mowing = 0.96 + 0.04*sin(world_pos.x*0.52+world_pos.z*0.13);
    ALBEDO=mix(base_color.rgb,vec3(0.27,0.25,0.16),dry*0.65)*(0.80+broad*0.30+fine*0.06)*mowing;
    ROUGHNESS=1.0;
}
