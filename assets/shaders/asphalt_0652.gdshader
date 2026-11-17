shader_type spatial;
render_mode cull_disabled;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float grain(vec2 p) { vec3 q = fract(vec3(p.x,p.y,p.x)*0.1031); q += dot(q,q.yzx+33.33); return fract((q.x+q.y)*q.z); }
void fragment() {
    float detail = grain(floor(world_pos.xz * 32.0));
    float fade = 1.0 - smoothstep(0.025, 0.15, length(fwidth(world_pos.xz)));
    float patches = grain(floor(world_pos.xz * 0.18));
    ALBEDO = vec3(0.075,0.082,0.09) * (0.92 + patches * 0.12 + (detail-0.5)*0.07*fade);
    float rubber = exp(-pow((UV.x - 0.52 - 0.12*sin(UV.y*0.018))*5.0, 2.0));
    float streak = grain(vec2(floor(UV.x*150.0), floor(UV.y*0.025)));
    ALBEDO *= 1.0 - rubber*(0.19 + streak*0.13);
    ROUGHNESS = 0.91 - rubber*0.12;
}
