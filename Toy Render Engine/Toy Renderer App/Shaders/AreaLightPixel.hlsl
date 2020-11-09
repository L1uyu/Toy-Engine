#include "LTC.hlsli"

float4 main(VertexOut pin) : SV_TARGET
{
    float3 normal = normalize(pin.NormalW);
    float3 viewDir = normalize(gEyePosW - pin.PosW.xyz);
	
    float4 color = float4(0.0, 0.0, 0.0, gDiffuseAlbedo.a);
	
    
    AreaLight al;
    al.dir = float3(0.0, 0.0, 1.0);
    al.height = 8.0;
    al.width = 8.0;
    al.horizontal = float3(-1.0, 0.0, 0.0);
    al.position = float3(0.0, 5.0, -14.99);
    al.lumin = gAreaLight.lumin;
    al.color = float4(0.0f, 0.0f, 1.0f, 1.0f);
	
	
    float3 diff = LTC_Diffuse(normal, viewDir, pin.PosW.xyz, gRoughness, gAreaLight);
    float3 spec = LTC_GGX(normal, viewDir, pin.PosW.xyz, gFresnelR0, gRoughness, gAreaLight);
    diff = gDiffuseAlbedo.xyz * diff;
    float3 LTC = gAreaLight.lumin * gAreaLight.color.xyz * (spec + diff);
    LTC *= INV_PI;
    color += gEmission + float4(LTC, gDiffuseAlbedo.a);
	
	
    float3 diff2 = LTC_Diffuse(normal, viewDir, pin.PosW.xyz, gRoughness, al);
    float3 spec2 = LTC_GGX(normal, viewDir, pin.PosW.xyz, gFresnelR0, gRoughness, al);
    diff2 = gDiffuseAlbedo.xyz * diff2;
    float3 LTC2 = al.lumin * al.color.xyz * (spec2 + diff2);
    LTC2 *= INV_PI;
    color += float4(LTC2, gDiffuseAlbedo.a);
	
    return color;
}