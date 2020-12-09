#include "StandardUtils.hlsli"

VertexOut main(VertexIn vin)
{
	VertexOut vout;
	
	vout.PosW = mul(gWorld, float4(vin.PosL, 1.0f));

	vout.NormalW = mul((float3x3)gWorld, vin.NormalL);

	vout.PosH = mul(gViewProj, vout.PosW);

	return vout;
}