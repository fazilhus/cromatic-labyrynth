/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

shader_type spatial;

// Uniforms.
uniform vec3 Albedo: source_color = vec3(1, 1, 1);
uniform float Roughness : hint_range(0.0, 1.0) = 1.0;
uniform float Metallicness : hint_range(0.0, 1.0) = 0.0;

uniform float grades[4];
uniform sampler2D palette : source_color;

// Methods.
void fragment()
{
	ALBEDO = Albedo;
	ROUGHNESS = Roughness;
	METALLIC = Metallicness;
}

float DistributionGGX(float cos_theta_m, float alpha)
{
	float alpha2 = alpha * alpha;
	float d = 1.0 + (alpha2 - 1.0) * cos_theta_m * cos_theta_m;
	return alpha2 / (PI * d * d);
}

float GeometryGGX(float NdotL, float NdotV, float alpha)
{
	return 0.5 / mix(2.0 * NdotL * NdotV, NdotL + NdotV, alpha);
}

vec3 SchlickBaseReflectivity(float metallic, float specular, vec3 albedo)
{
	float dielectric = 0.04 * specular * specular;
	return mix(vec3(dielectric), albedo, vec3(metallic));
}
	
float SchlickFresnel(float u)
{
	float m = 1.0 - u;
	float m2 = m * m;
	return m2 * m2 * m;
}

vec2 index_to_uv(int num)
{
	switch (num) {
		case 0:
			return vec2(0.);
		case 1:
			return vec2(0., 1. / 5.);
		case 2:
			return vec2(0., 2. / 5.);
		case 3:
			return vec2(0., 3. / 5.);
		case 4:
			return vec2(0., 4. / 5.);
	}
}

void light()
{
	// Calculate some vectors.
	vec3 half = normalize(VIEW + LIGHT);
	
	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	float NdotV = max(dot(NORMAL, VIEW), 0.0);
	float NdotH = max(dot(NORMAL, half), 0.0);
	float LdotH = max(dot(LIGHT, half), 0.0);
	
	// Diffuse light (Lambert).
	float light_strength = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	vec3 light_color;
	if (light_strength > grades[0]) {
		light_color = texture(palette, index_to_uv(1)).rgb;
	} else if (light_strength > grades[1]) {
		light_color = texture(palette, index_to_uv(2)).rgb;
	} else if (light_strength > grades[2]) {
		light_color = texture(palette, index_to_uv(3)).rgb;
	} else {
		light_color = texture(palette, index_to_uv(4)).rgb;
	}
	DIFFUSE_LIGHT = light_color * light_strength;
	
	//Specular light (Schlick-GGX).
	float ggxAlpha = ROUGHNESS * ROUGHNESS;
	float D = DistributionGGX(NdotH, ggxAlpha);
	float G = GeometryGGX(NdotL, NdotV, ggxAlpha);
	
	vec3 f0 = SchlickBaseReflectivity(METALLIC, SPECULAR_AMOUNT, texture(palette, index_to_uv(0)).rgb);
	float LdotH5 = SchlickFresnel(LdotH);
	float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
	vec3 F = f0 + (f90 - f0) * LdotH5;
	
	vec3 specularBRDF = max(NdotL * D * G * F, 0.0);
	SPECULAR_LIGHT += specularBRDF * texture(palette, index_to_uv(0)).rgb * ATTENUATION;
}
