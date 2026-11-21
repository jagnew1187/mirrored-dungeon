shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float edge = smoothstep(0.35, 1.3, length(centered));
	COLOR = vec4(0.015, 0.02, 0.035, edge * 0.25);
}
