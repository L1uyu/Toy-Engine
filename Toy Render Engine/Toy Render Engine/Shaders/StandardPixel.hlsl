 //#include "StandardUtils.hlsli"
#include "LTC.hlsli"

float4 main(VertexOut pin) : SV_TARGET
{
	float3 normal = normalize(pin.NormalW);
	float3 viewDir = normalize(gEyePosW - pin.PosW.xyz);
	
	//float4 ambient = gAmbientLight * gDiffuseAlbedo;
	
	
	float4 color = float4(0.0, 0.0, 0.0, gDiffuseAlbedo.a);
	
	for (int i = 3; i < 3; i++)
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
    AreaLight al;
    al.dir = float3(0.0, 0.0, 1.0);
    al.height = 8.0;
    al.width = 8.0;
    al.horizontal = float3(-1.0, 0.0, 0.0);
    al.position = float3(0.0, 5.0, -14.99);
    al.lightColor = gAreaLight.lightColor;
	
	
    float3 diff = LTC_Diffuse(normal, viewDir, pin.PosW.xyz, gRoughness, gAreaLight);
    float3 spec = LTC_GGX(normal, viewDir, pin.PosW.xyz, gFresnelR0, gRoughness, gAreaLight);
    //float3 fr = Fr(normal, viewDir, gFresnelR0, gRoughness);
    diff = gDiffuseAlbedo.xyz * diff;
    //diff /=   2 * PI;
    float3 LTC = gAreaLight.lightColor * (spec + diff);
    LTC /= PI;
    color += gEmission + float4(LTC, gDiffuseAlbedo.a);
	
	
    float3 diff2 = LTC_Diffuse(normal, viewDir, pin.PosW.xyz, gRoughness, al);
    float3 spec2 = LTC_GGX(normal, viewDir, pin.PosW.xyz, gFresnelR0, gRoughness, al);
    //float3 fr = Fr(normal, viewDir, gFresnelR0, gRoughness);
    diff2 = gDiffuseAlbedo.xyz * diff2;
    //diff /=   2 * PI;
    float3 LTC2 = al.lightColor * (spec2 + diff2);
    LTC2 /= PI;
    color += gEmission + float4(LTC2, gDiffuseAlbedo.a);
	
	return color;
}