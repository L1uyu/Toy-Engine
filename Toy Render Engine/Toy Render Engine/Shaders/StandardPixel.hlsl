#include "StandardUtils.hlsli"

float4 main(VertexOut pin) : SV_TARGET
{
	float3 normal = normalize(pin.NormalW);
	float3 viewDir = normalize(gEyePosW - pin.PosW.xyz);
	
	float4 ambient = gAmbientLight * gDiffuseAlbedo;
	
	
	float4 color = float4(0.0, 0.0, 0.0, gDiffuseAlbedo.a);
	
	for (int i = 0; i < 3; i++)
	{
		float3 lightDir = -gLights[i].Direction;
		float3 halfDir = normalize(viewDir + lightDir);
		float NdotL = saturate(dot(normal, lightDir));
		float NdotV = saturate(dot(normal, viewDir));
		float HdotL = saturate(dot(halfDir, lightDir));
		float NdotH = saturate(dot(normal, halfDir));
		float3 lightStrength = gLights[i].Strength * NdotL;
		float roughness = gRoughness;
		
		float3 diffuse = DisneyDiffuse(gDiffuseAlbedo.rgb, roughness, NdotL, NdotV, HdotL);
		float3 spec = Fresnel(gFresnelR0, HdotL) *
			GGX(roughness, NdotH) *
			GGXVisibility(roughness, NdotL, NdotV);
		color.xyz += PI * (diffuse + spec) * lightStrength;
	}

	color +=  gEmission;
	
	return color;
}