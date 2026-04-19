// Pseudo3DShader.gdshader
// Apply to TileMapLayer or individual Sprite2D nodes.
// Simulates depth, ambient occlusion, edge highlights, and dynamic lighting
// entirely in 2D using pixel math.
//
// Usage in GDScript:
//   tilemap.material = ShaderMaterial.new()
//   tilemap.material.shader = load("res://scripts/shaders/Pseudo3DShader.gdshader")
//   tilemap.material.set_shader_parameter("light_dir", Vector2(0.6, -0.8))
//   tilemap.material.set_shader_parameter("light_color", Color(1.0, 0.92, 0.75))
//   tilemap.material.set_shader_parameter("ambient_color", Color(0.15, 0.12, 0.22))
//   tilemap.material.set_shader_parameter("depth_strength", 0.4)
//   tilemap.material.set_shader_parameter("edge_strength", 0.5)

shader_type canvas_item;

// ── Lighting parameters ───────────────────────────────────────
uniform vec2  light_dir = vec2(0.6, -0.8);       // normalized 2D light direction
uniform vec4  light_color : source_color = vec4(1.0, 0.92, 0.75, 1.0);
uniform vec4  ambient_color : source_color = vec4(0.15, 0.12, 0.22, 1.0);
uniform float light_intensity = 1.0;

// ── Pseudo-depth parameters ───────────────────────────────────
uniform float depth_strength = 0.40;   // how pronounced the 3D effect looks
uniform float edge_strength  = 0.50;   // edge highlight/shadow strength
uniform float edge_width     = 1.5;    // pixels for edge detection
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// ── Tint / style ──────────────────────────────────────────────
uniform float saturation_boost = 0.10;  // slight color richness
uniform float contrast_boost   = 0.05;

// ── Underground / depth tinting ───────────────────────────────
// Set these from World.gd based on player depth
uniform float underground_blend = 0.0;  // 0=surface, 1=deep underground
uniform vec4  underground_tint : source_color = vec4(0.05, 0.03, 0.12, 1.0);

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────
vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0*d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Generate a pseudo normal from local pixel neighborhood
// This simulates what a normal map would give, derived purely from the alpha/luminance
// of nearby pixels — creates the illusion of surface curvature at tile edges.
vec3 compute_pseudo_normal(sampler2D tex, vec2 uv, vec2 texel) {
	float e = edge_width;
	float l = texture(tex, uv + vec2(-e, 0.0) * texel).a;
	float r = texture(tex, uv + vec2( e, 0.0) * texel).a;
	float u = texture(tex, uv + vec2(0.0,  e) * texel).a;
	float d = texture(tex, uv + vec2(0.0, -e) * texel).a;
	// Construct surface normal from alpha gradient
	vec3 n = normalize(vec3((l - r) * depth_strength, (u - d) * depth_strength, 1.0));
	return n;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Fragment shader
// ─────────────────────────────────────────────────────────────────────────────
void fragment() {
	// Sample base color
	vec4 col = texture(TEXTURE, UV);
	if (col.a < 0.01) {
		COLOR = col;
		return;
	}

	// ── Pseudo surface normals ──────────────────────────────────────────────
	vec2 texel = 1.0 / vec2(textureSize(TEXTURE, 0));
	vec3 normal = compute_pseudo_normal(TEXTURE, UV, texel);

	// ── Diffuse lighting ────────────────────────────────────────────────────
	vec3 ld = normalize(vec3(light_dir, 0.8));   // z=0.8 gives soft directionality
	float ndl = max(dot(normal, ld), 0.0);

	vec3 diffuse  = light_color.rgb * ndl * light_intensity;
	vec3 ambient  = ambient_color.rgb;
	vec3 lighting = ambient + diffuse;

	// ── Edge highlight / shadow ─────────────────────────────────────────────
	// Bright highlight on lit edges, shadow on opposite edges
	float e_dist = edge_width * 2.0;
	vec4 n_alpha = texture(TEXTURE, UV + vec2(0.0, -e_dist) * texel);
	vec4 s_alpha = texture(TEXTURE, UV + vec2(0.0,  e_dist) * texel);
	vec4 w_alpha = texture(TEXTURE, UV + vec2(-e_dist, 0.0) * texel);
	vec4 e_alpha = texture(TEXTURE, UV + vec2( e_dist, 0.0) * texel);

	float edge_up    = clamp((col.a - n_alpha.a) * 3.0, 0.0, 1.0);  // top edge lit
	float edge_down  = clamp((col.a - s_alpha.a) * 3.0, 0.0, 1.0);  // bottom edge dark
	float edge_left  = clamp((col.a - w_alpha.a) * 2.0, 0.0, 1.0);
	float edge_right = clamp((col.a - e_alpha.a) * 2.0, 0.0, 1.0);

	float highlight = (edge_up + edge_left * 0.5)  * edge_strength;
	float shadow    = (edge_down + edge_right * 0.4) * edge_strength;

	// ── Apply lighting to color ─────────────────────────────────────────────
	vec3 lit_color = col.rgb * lighting;
	lit_color += highlight * light_color.rgb * 0.4;
	lit_color -= shadow * 0.25;

	// ── Saturation boost ────────────────────────────────────────────────────
	vec3 hsv = rgb_to_hsv(lit_color);
	hsv.y    = clamp(hsv.y * (1.0 + saturation_boost), 0.0, 1.0);
	hsv.z    = clamp(hsv.z * (1.0 + contrast_boost),   0.0, 1.0);
	lit_color = hsv_to_rgb(hsv);

	// ── Underground depth tint ──────────────────────────────────────────────
	lit_color = mix(lit_color, underground_tint.rgb * lit_color, underground_blend * 0.6);

	COLOR = vec4(clamp(lit_color, 0.0, 1.0), col.a);
}
