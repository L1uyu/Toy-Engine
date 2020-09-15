//***************************************************************************************
// color.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Transforms and colors geometry.
//***************************************************************************************

cbuffer cbPerObject : register(b0)
{
	float4x4 gWorldViewProj; 
	float4 gTime;
};

struct VertexIn
{
	float3 PosL  : POSITION;
    float4 Color : COLOR;
	float3 Tan : TANGENT;
};

struct VertexOut
{
	float4 PosH  : SV_POSITION;
    float4 Color : COLOR;
};

VertexOut VS(VertexIn vin)
{

	//vin.PosL.xy += 0.5f * sin(vin.PosL.x) * sin(3.0f * gTime.y);
	//vin.PosL.z *= 0.6f + 0.4f * sin(2.0f * gTime.y);

	VertexOut vout;
	// Transform to homogeneous clip space.
	//vout.PosH = mul(float4(vin.PosL, 1.0f), gWorldViewProj);
	vout.PosH = mul(gWorldViewProj, float4(vin.PosL, 1.0f));
	
	// Just pass vertex color into the pixel shader.
    vout.Color = vin.Color;
    
    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
	return pin.Color;
	//return float4(0, 0, 0, 1);
}


