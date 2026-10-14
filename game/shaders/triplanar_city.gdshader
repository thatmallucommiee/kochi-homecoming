shader_type spatial;
render_mode world_vertex_coords, diffuse_burley, specular_schlick_ggx;

uniform sampler2D surface_tex : source_color, repeat_enable;
uniform vec4 tint_color : source_color = vec4(1.0);
uniform float texture_scale = 0.2;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.9;

varying vec3 tri_world_pos;
varying vec3 tri_world_normal;

void vertex() {
    // world_vertex_coords makes this stable across differently sized MultiMesh instances.
    tri_world_pos = VERTEX * texture_scale;
    tri_world_normal = normalize(NORMAL);
}

void fragment() {
    vec3 normal = normalize(tri_world_normal);
    vec3 weights = pow(abs(normal), vec3(4.0));
    weights /= max(weights.x + weights.y + weights.z, 0.0001);

    // Triplanar projections avoid stretched textures on building sides and rooftops.
    vec3 from_x = texture(surface_tex, tri_world_pos.zy).rgb;
    vec3 from_y = texture(surface_tex, tri_world_pos.xz).rgb;
    vec3 from_z = texture(surface_tex, tri_world_pos.xy).rgb;
    vec3 sampled = from_x * weights.x + from_y * weights.y + from_z * weights.z;

    ALBEDO = sampled * tint_color.rgb;
    ROUGHNESS = surface_roughness;
    METALLIC = 0.0;
    SPECULAR = 0.22;
}
