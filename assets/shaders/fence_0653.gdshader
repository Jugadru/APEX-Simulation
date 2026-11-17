shader_type spatial;
render_mode cull_disabled;
void fragment() {
    vec2 grid = abs(fract(vec2(UV.x+UV.y,UV.x-UV.y)*7.0)-0.5);
    float aa = max(length(fwidth(UV))*2.0,0.008);
    float wire = 1.0-smoothstep(0.025,0.025+aa,min(grid.x,grid.y));
    ALBEDO = vec3(0.28,0.32,0.34);
    METALLIC = 0.6;
    ROUGHNESS = 0.55;
    ALPHA = wire;
    ALPHA_SCISSOR_THRESHOLD = 0.5;
}
