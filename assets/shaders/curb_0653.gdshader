shader_type spatial;
render_mode cull_disabled;
void fragment() {
    float stripe = step(0.5,fract(UV.y/2.6));
    vec3 paint = mix(vec3(0.58,0.035,0.022),vec3(0.82,0.82,0.76),stripe);
    float groove = 0.5+0.5*cos(UV.y*24.0);
    float aa = 1.0-smoothstep(0.04,0.4,length(fwidth(UV)));
    ALBEDO = paint*(0.88+0.12*groove*aa);
    float rim=smoothstep(0.0,0.13,UV.x)*(1.0-smoothstep(0.88,1.0,UV.x));
    ALBEDO *= 0.85+0.15*rim;
    NORMAL_MAP=normalize(vec3(0.0,sin(UV.y*24.0)*0.12*aa,1.0))*0.5+0.5;
    ROUGHNESS = 0.82;
}
