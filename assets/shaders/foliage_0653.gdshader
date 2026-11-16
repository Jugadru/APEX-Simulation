shader_type spatial;
uniform vec4 tint : source_color = vec4(0.21,0.29,0.15,1.0);
varying vec3 local_pos;
void vertex() {
    float irregular = sin(VERTEX.x*6.0+VERTEX.z*2.0)*cos(VERTEX.y*7.0+VERTEX.z*5.0);
    VERTEX += NORMAL*irregular*0.14;
    local_pos = VERTEX;
}
void fragment() {
    float leaves = sin(local_pos.x*31.0)*sin(local_pos.y*27.0)*cos(local_pos.z*25.0);
    float fade = 1.0-smoothstep(0.015,0.12,length(fwidth(local_pos)));
    ALBEDO = tint.rgb*(0.9+leaves*0.15*fade);
    ROUGHNESS = 0.95;
}
