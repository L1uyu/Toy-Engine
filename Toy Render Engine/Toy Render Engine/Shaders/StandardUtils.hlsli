
#define MaxLights 16
#define PI  3.14159265f
#define INV_PI  0.31830988f
#define EPSILON 1e-7f //用于浮点数运算误差

struct VertexIn
{
    float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
};

struct VertexOut
{
    float4 PosH		: SV_POSITION;
    float4 PosW		: POSITION;
    float3 NormalW	: NORMAL;
};

struct Light
{
    float3 Strength;
    float FalloffStart; // point/spot light only
    float3 Direction;   // directional/spot light only
    float FalloffEnd;   // point/spot light only
    float3 Position;    // point light only
    float SpotPower;    // spot light only
};

struct AreaLight
{
    float3 position;
    float width;
    float3 dir;
    float height;
    float3 horizontal;
    float lumin;
    float4 color;
};


struct Material
{
    float4 DiffuseAlbedo;
    float3 FresnelR0;
    float Shininess;
    float4 Emission;
};

Texture2D gLTCTex[2] : register(t0);

SamplerState gsamPointWrap : register(s0);
SamplerState gsamPointClamp : register(s1);
SamplerState gsamLinearWrap : register(s2);
SamplerState gsamLinearClamp : register(s3);
SamplerState gsamAnisotropicWrap : register(s4);
SamplerState gsamAnisotropicClamp : register(s5);

cbuffer cbPerObject : register(b0)
{
	float4x4 gWorld;
};

cbuffer cbMaterial : register(b1)
{
    float4 gDiffuseAlbedo;
    float3 gFresnelR0;
    float  gRoughness;
    float4 gEmission;
    float4x4 gMatTransform;
};

cbuffer cbPass : register(b2)
{
    float4x4 gView;
    float4x4 gInvView;
    float4x4 gProj;
    float4x4 gInvProj;
    float4x4 gViewProj;
    float4x4 gInvViewProj;
    float3 gEyePosW;
    float cbPerObjectPad1;
    float2 gRenderTargetSize;
    float2 gInvRenderTargetSize;
    float gNearZ;
    float gFarZ;
    float gTotalTime;
    float gDeltaTime;
    float4 gAmbientLight;

    AreaLight gAreaLight;
    Light gLights[15];
 
}



float CalcAttenuation(float d, float falloffStart, float falloffEnd)
{
    // Linear falloff.
    return saturate((falloffEnd - d) / (falloffEnd - falloffStart));
}

float3 Fresnel(float3 R0, float LdotH)
{
	float f0 = pow(1.0 - LdotH, 5);
	return R0 + (1.0 - R0) * f0;
}

float GGX(float roughness, float NdotH)
{
	float alpha2 = roughness * roughness * roughness * roughness;
	float d = (NdotH * alpha2 - NdotH) * NdotH + 1; // 2 mad
	return alpha2 / (PI * d * d + EPSILON);
}

float GGXVisibility(float roughness,float NdotL, float NdotV)
{
	float alpha = roughness * roughness;
	float f0 = NdotL * (NdotV * (1.0 - alpha) + alpha);
	float f1 = NdotV * (NdotL * (1.0 - alpha) + alpha);
    return 0.5 / (f0 + f1 + EPSILON);
}

float3 DisneyDiffuse(float3 diffuseAlbedo,  float roughness, float NdotL, float NdotV, float HdotL)
{
	float F90 = 0.5 + 2 * roughness * HdotL * HdotL;
	float lightScatter = (1 + (F90 - 1) * pow(1 - NdotL, 5));
	float viewScatter = (1 + (F90 - 1) * pow(1 - NdotV, 5));
	return (diffuseAlbedo * INV_PI * lightScatter * viewScatter);
}

