#include "StandardUtils.hlsli"

#define LUT_SIZE  64.0f
#define LUT_SCALE  (LUT_SIZE - 1.0f) / LUT_SIZE
#define LUT_BIAS  0.5f / LUT_SIZE

#define vec3 float3
#define vec2 float2
#define mat3 float3x3




float IntegrateEdgeNotUse(float3 L0, float3 L1)
{
    float c01 = dot(L0, L1);
	//float w01 = ( 1.5708 - 0.175 * c01 ) * rsqrt( c01 + 1 );	// 1 mad, 1 mul, 1 add, 1 rsqrt
	//float w01 = 1.5708 + (-0.879406 + 0.308609 * abs(c01) ) * abs(c01);

	//return acos( c01 ) * rsqrt( 1 - c01 * c01 );

#if 0
	// [ Hill et al. 2016, "Real-Time Area Lighting: a Journey from Research to Production" ]
	float w01 = ( 5.42031 + (3.12829 + 0.0902326 * abs(c01)) * abs(c01) ) /
				( 3.45068 + (4.18814 + abs(c01)) * abs(c01) );

	w01 = c01 > 0 ? w01 : PI * rsqrt( 1 - c01 * c01 ) - w01;
#else
    float w01 = (0.8543985 + (0.4965155 + 0.0145206 * abs(c01)) * abs(c01)) /
				(3.4175940 + (4.1616724 + abs(c01)) * abs(c01));
	
    w01 = c01 > 0 ? w01 : 0.5 * rsqrt(1 - c01 * c01) - w01;
#endif

    return w01;
}




void AreaLight_Corners(AreaLight light, out vec3 p0, out vec3 p1, out vec3 p2, out vec3 p3)
{
    float a = light.width * 0.5;
    float b = light.height * 0.5;
	vec3 verticle = cross(light.dir, light.horizontal);
	vec3 halfWidthVec = light.horizontal * a;
	vec3 halfHeightVec = verticle * b;

    p0 = light.position - halfHeightVec - halfWidthVec;
    p1 = light.position - halfHeightVec + halfWidthVec;
    p2 = light.position + halfHeightVec + halfWidthVec;
    p3 = light.position + halfHeightVec - halfWidthVec;
}


void _LTC_ClipQuadToHorizon(inout vec3 L[5], out int n)
{
    // detect clipping config
    int config = 0;
    if (L[0].z > 0.0)
        config += 1;
    if (L[1].z > 0.0)
        config += 2;
    if (L[2].z > 0.0)
        config += 4;
    if (L[3].z > 0.0)
        config += 8;

    // clip
    n = 0;

    if (config == 0)
    {
        // clip all
    }
    else if (config == 1) // V1 clip V2 V3 V4
    {
        n = 3;
        L[1] = -L[1].z * L[0] + L[0].z * L[1];
        L[2] = -L[3].z * L[0] + L[0].z * L[3];
    }
    else if (config == 2) // V2 clip V1 V3 V4
    {
        n = 3;
        L[0] = -L[0].z * L[1] + L[1].z * L[0];
        L[2] = -L[2].z * L[1] + L[1].z * L[2];
    }
    else if (config == 3) // V1 V2 clip V3 V4
    {
        n = 4;
        L[2] = -L[2].z * L[1] + L[1].z * L[2];
        L[3] = -L[3].z * L[0] + L[0].z * L[3];
    }
    else if (config == 4) // V3 clip V1 V2 V4
    {
        n = 3;
        L[0] = -L[3].z * L[2] + L[2].z * L[3];
        L[1] = -L[1].z * L[2] + L[2].z * L[1];
    }
    else if (config == 5) // V1 V3 clip V2 V4) impossible
    {
        n = 0;
    }
    else if (config == 6) // V2 V3 clip V1 V4
    {
        n = 4;
        L[0] = -L[0].z * L[1] + L[1].z * L[0];
        L[3] = -L[3].z * L[2] + L[2].z * L[3];
    }
    else if (config == 7) // V1 V2 V3 clip V4
    {
        n = 5;
        L[4] = -L[3].z * L[0] + L[0].z * L[3];
        L[3] = -L[3].z * L[2] + L[2].z * L[3];
    }
    else if (config == 8) // V4 clip V1 V2 V3
    {
        n = 3;
        L[0] = -L[0].z * L[3] + L[3].z * L[0];
        L[1] = -L[2].z * L[3] + L[3].z * L[2];
        L[2] = L[3];
    }
    else if (config == 9) // V1 V4 clip V2 V3
    {
        n = 4;
        L[1] = -L[1].z * L[0] + L[0].z * L[1];
        L[2] = -L[2].z * L[3] + L[3].z * L[2];
    }
    else if (config == 10) // V2 V4 clip V1 V3) impossible
    {
        n = 0;
    }
    else if (config == 11) // V1 V2 V4 clip V3
    {
        n = 5;
        L[4] = L[3];
        L[3] = -L[2].z * L[3] + L[3].z * L[2];
        L[2] = -L[2].z * L[1] + L[1].z * L[2];
    }
    else if (config == 12) // V3 V4 clip V1 V2
    {
        n = 4;
        L[1] = -L[1].z * L[2] + L[2].z * L[1];
        L[0] = -L[0].z * L[3] + L[3].z * L[0];
    }
    else if (config == 13) // V1 V3 V4 clip V2
    {
        n = 5;
        L[4] = L[3];
        L[3] = L[2];
        L[2] = -L[1].z * L[2] + L[2].z * L[1];
        L[1] = -L[1].z * L[0] + L[0].z * L[1];
    }
    else if (config == 14) // V2 V3 V4 clip V1
    {
        n = 5;
        L[4] = -L[0].z * L[3] + L[3].z * L[0];
        L[0] = -L[0].z * L[1] + L[1].z * L[0];
    }
    else if (config == 15) // V1 V2 V3 V4
    {
        n = 4;
    }

    if (n == 3)
        L[3] = L[0];
    if (n == 4)
        L[4] = L[0];
}

vec3 _LTC_IntegrateEdgeVec(vec3 v1, vec3 v2)
{
    float x = dot(v1, v2);
    float y = abs(x);
	
    float a = 0.8543985 + (0.4965155 + 0.0145206 * y) * y;
    float b = 3.4175940 + (4.1616724 + y) * y;
    float v = a / b;
	
    float theta_sintheta = (x > 0.0) ? v : 0.5 * rsqrt(max(1.0 - x * x, 1e-7)) - v;
	
    return cross(v1, v2) * theta_sintheta;
}

float _LTC_IntegrateEdge(vec3 v1, vec3 v2)
{
    return _LTC_IntegrateEdgeVec(v1, v2).z;
}



float _LTC_Evaluate(vec3 N, vec3 V, vec3 P, mat3 invM, AreaLight light)
{
	vec3 p0, p1, p2, p3;
    AreaLight_Corners(light, p0, p1, p2, p3);
	
	// construct orthonormal basis around N
	vec3 T1, T2;
    T1 = normalize(V - N * dot(V, N));
    T2 = cross(N, T1);

	// rotate area light in (T1, T2, N) basis
    invM = invM * mat3(T1, T2, N);

	// polygon
	vec3 L[5];
    L[0] = mul(invM, (p0 - P));
    L[1] = mul(invM, (p1 - P));
    L[2] = mul(invM, (p2 - P));
    L[3] = mul(invM, (p3 - P));
    L[4] = L[3];

	// integrate
    float sum = 0.0;
    
    int n;
    _LTC_ClipQuadToHorizon(L, n);

    if (n == 0)
        return 0;
	// project onto sphere
    L[0] = normalize(L[0]);
    L[1] = normalize(L[1]);
    L[2] = normalize(L[2]);
    L[3] = normalize(L[3]);
    L[4] = normalize(L[4]);

    //integrate
    sum += _LTC_IntegrateEdge(L[1], L[0]);
    sum += _LTC_IntegrateEdge(L[2], L[1]);
    sum += _LTC_IntegrateEdge(L[3], L[2]);
    if (n >= 4)
        sum += _LTC_IntegrateEdge(L[4], L[3]);
    if (n == 5)
        sum += _LTC_IntegrateEdge(L[0], L[4]);
    
    

    //sum = max(0.0, sum);
    sum = abs(sum);
    
    return sum;
}

vec3 LTC_Diffuse(vec3 N, vec3 V, vec3 P, float roughness, AreaLight light)
{
	mat3 invM = mat3(1,1,1,1,1,1,1,1,1);
	
    float diffuse = _LTC_Evaluate(N, V, P, invM, light);
    return float3(1.0, 1.0, 1.0) * diffuse;
}



float3 LTC_GGX(float3 N, float3 V, float3 P, float3 F0, float roughness, AreaLight light)
{
    float NoV = saturate(abs(dot(N, V)) + 1e-5);
    
    float2 UV = float2(roughness, sqrt(1 - NoV));
    UV = UV * (63.0 / 64.0) + (0.5 / 64.0);
    
    float4 LTCMat = gLTCTex[0].Sample(gsamLinearWrap, UV);
    float4 LTCAmp = gLTCTex[1].Sample(gsamLinearWrap, UV);

    float3x3 LTC =
    {
        float3(LTCMat.x, 0, LTCMat.z),
		float3(0, 1, 0),
		float3(LTCMat.y, 0, LTCMat.w)
    };
    
    
    // Rotate to tangent space
    float3 T1 = normalize(V - N * dot(N, V));
    float3 T2 = cross(N, T1);
    float3x3 TangentBasis = float3x3(T1, T2, N);

    LTC = mul(LTC, TangentBasis);
    

    float3 Poly[4];
    AreaLight_Corners(light, Poly[0], Poly[1], Poly[2], Poly[3]);
    float3 L[5];
 
    L[0] = mul(LTC, Poly[0] - P);
    L[1] = mul(LTC, Poly[1] - P);
    L[2] = mul(LTC, Poly[2] - P);
    L[3] = mul(LTC, Poly[3] - P);
    L[4] = L[3];
    
    float sum = 0.0;
    int n;
    _LTC_ClipQuadToHorizon(L, n);

    if (n == 0)
        return float3(0, 0, 0);
	// project onto sphere
    L[0] = normalize(L[0]);
    L[1] = normalize(L[1]);
    L[2] = normalize(L[2]);
    L[3] = normalize(L[3]);
    L[4] = normalize(L[4]);
    
 
    sum += _LTC_IntegrateEdge(L[1], L[0]);
    sum += _LTC_IntegrateEdge(L[2], L[1]);
    sum += _LTC_IntegrateEdge(L[3], L[2]);
    if (n >= 4)
        sum += _LTC_IntegrateEdge(L[4], L[3]);
    if (n == 5)
        sum += _LTC_IntegrateEdge(L[0], L[4]);

    
    //sum = max(0.0, sum);
    sum = abs(sum);
   
 
    
	vec3 Fr = F0 * LTCAmp.x + (1 - F0) * LTCAmp.y;

    return sum * Fr ;
}