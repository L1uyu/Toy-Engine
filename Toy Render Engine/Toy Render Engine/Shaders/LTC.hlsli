#include "StandardUtils.hlsli"

#define LUT_SIZE  64.0f
#define LUT_SCALE  (LUT_SIZE - 1.0f) / LUT_SIZE
#define LUT_BIAS  0.5f / LUT_SIZE

#define vec3 float3
#define vec2 float2
#define mat3 float3x3



vec2 LTC_Coords(float cosTheta, float roughness)
{
    float theta = acos(cosTheta);
    vec2 coords = vec2(roughness, theta / (0.5 * 3.14159));
 
    
    //进行缩放和偏移，以正确查找纹理
    coords = coords * (LUT_SIZE - 1.0) / LUT_SIZE + 0.5 / LUT_SIZE;
 
    return coords;
}


mat3 LTC_Matrix(sampler2D texLSDMat, vec2 coord)
{
    // 加载M逆矩阵
    float4 t = gLTCTex[0].Sample(gsamLinearWrap, coord);;
    mat3 Minv = mat3(
        1, 0, t.w,
        0, t.z, 0,
        t.y, 0, t.x
    );
 
    return Minv;
}

float IntegrateEdge_(vec3 v1, vec3 v2)
{
    float cosTheta = dot(v1, v2);
    cosTheta = clamp(cosTheta, -0.9999, 0.9999);
 
    float theta = acos(cosTheta);
    // 除以sin(theta)是因为v1，v2已经标准化
    float res = cross(v1, v2).z * theta / sin(theta);
 
    return res;
}

float IntegrateEdge(float3 L0, float3 L1)
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




void ClipQuadToHorizon(inout vec3 L[5], out int n)
{
    // 由Z分量分别确定四个点的可见性
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

vec2 _LTC_CorrectUV(vec2 uv)
{
    uv =  uv * LUT_SCALE + LUT_BIAS;
    return float2(uv.x, 1 - uv.y);
}

// _LTC_GetInvM_GGX, _LTC_GetNF_GGX
vec2 _LTC_GetUV(float roughness, float NoV)
{
	vec2 uv = vec2(roughness, sqrt(1.0 - NoV));
    return _LTC_CorrectUV(uv);
}


mat3 _LTC_GetInvM_GGX(vec2 uv)
{
 //   float4 t1 = gLTCTex[0].Sample(gsamLinearWrap, uv);
 //   return mat3(
	//	t1.x, 0.0, t1.y, // col0
	//	0.0,   t1.z,   0.0, // col1
	//	t1.w, 0, 1.0 // col2
	//);
    float4 t = gLTCTex[0].Sample(gsamLinearWrap, uv);
    mat3 Minv = mat3(
        1, 0, t.w,
        0, t.z, 0,
        t.y, 0, t.x
    );
    return Minv;
}

vec2 _LTC_GetNF_GGX(vec2 uv)
{
    float4 t2 = gLTCTex[1].Sample(gsamLinearWrap, uv);
    return vec2(t2.x, t2.y);
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

vec3 LTC_Evaluate(vec3 N, vec3 V, vec3 P, mat3 Minv, float3 points[4], bool twoSided)
{
    // 围绕法线N构造标准正交基
    vec3 T1, T2;
    T1 = normalize(V - N * dot(V, N));
    T2 = cross(N, T1);
 
    // 构建世界坐标系转变成法线N正交基构成的坐标系的转换矩阵
    Minv = Minv * mat3(T1, T2, N);
 
    // 面积光的多边形（分配5个顶点用于剪切）P表示片段的世界坐标，points表示面积光（矩形）的顶点
    vec3 L[5];
    L[0] = mul(Minv, points[0] - P);
    L[1] = mul(Minv, points[1] - P);
    L[2] = mul(Minv, points[2] - P);
    L[3] = mul(Minv, points[3] - P);
    //L[4] = L[3]; // avoid warning
 
    

 
    int n;
    // 对平面进行裁剪，例如四边形经过裁剪可能变成三角形或者五边形
    ClipQuadToHorizon(L, n);
    
    if (n == 0)
        return vec3(0, 0, 0);
 
    // project onto sphere
    L[0] = normalize(L[0]);
    L[1] = normalize(L[1]);
    L[2] = normalize(L[2]);
    L[3] = normalize(L[3]);
    L[4] = normalize(L[4]);
 
    // 根据积分公式对每条边进行积分（其结果等于多边形的面积积分）
    float sum = 0.0;
 
    sum += IntegrateEdge(L[0], L[1]);
    sum += IntegrateEdge(L[1], L[2]);
    sum += IntegrateEdge(L[2], L[3]);
    if (n >= 4)
        sum += IntegrateEdge(L[3], L[4]);
    if (n == 5)
        sum += IntegrateEdge(L[4], L[0]);
 
    sum = twoSided ? abs(sum) : max(0.0, -sum);
 
    vec3 Lo_i = vec3(sum, sum, sum);
 
    // 叠加纹理颜色
    
 
    return Lo_i;
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
    
    //sum += _LTC_IntegrateEdge(L[0], L[1]);
    //sum += _LTC_IntegrateEdge(L[1], L[2]);
    //sum += _LTC_IntegrateEdge(L[2], L[3]);
    //if (n >= 4)
    //    sum += _LTC_IntegrateEdge(L[3], L[4]);
    //if (n == 5)
    //    sum += _LTC_IntegrateEdge(L[4], L[0]);

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

vec3 LTC_Spec(vec3 N, vec3 V, vec3 P, vec3 F0, float roughness, AreaLight light)
{
    
    float NoV = saturate(dot(N, V) + 1e-7);
	//vec2 uv = _LTC_GetUV(roughness, NoV);
	vec2 uv = _LTC_GetUV(NoV, roughness);
	mat3 invM = _LTC_GetInvM_GGX(uv);
	vec2 nf = _LTC_GetNF_GGX(uv);
	
	vec3 Fr = F0 * nf.x + (1 - F0) * nf.y;
	vec3 L = light.lightColor * Fr ;
   
    float3 cor[4];
    AreaLight_Corners(light, cor[0], cor[1], cor[2], cor[3]);
    float3 spec = LTC_Evaluate(N, V, P, invM, cor, true);
    return  spec * L;
}


float3 PolygonIrradiance(float3 Poly[4])
{
    float3 L0 = normalize(Poly[0]); //  2 mad, 4 mul, 1 rsqrt
    float3 L1 = normalize(Poly[1]); //  2 mad, 4 mul, 1 rsqrt
    float3 L2 = normalize(Poly[2]); //  2 mad, 4 mul, 1 rsqrt
    float3 L3 = normalize(Poly[3]); //  2 mad, 4 mul, 1 rsqrt
	// 24 alu, 4 rsqrt

#if 0
	float3 L;
	L  = acos( dot( L0, L1 ) ) * normalize( cross( L0, L1 ) );
	L += acos( dot( L1, L2 ) ) * normalize( cross( L1, L2 ) );
	L += acos( dot( L2, L3 ) ) * normalize( cross( L2, L3 ) );
	L += acos( dot( L3, L0 ) ) * normalize( cross( L3, L0 ) );
#else
    float w01 = IntegrateEdge(L0, L1);
    float w12 = IntegrateEdge(L1, L2);
    float w23 = IntegrateEdge(L2, L3);
    float w30 = IntegrateEdge(L3, L0);

#if 0
	float3 L;
	L  = w01 * cross( L0, L1 );	// 6 mul, 3 mad
	L += w12 * cross( L1, L2 );	// 3 mul, 6 mad
	L += w23 * cross( L2, L3 );	// 3 mul, 6 mad
	L += w30 * cross( L3, L0 );	// 3 mul, 6 mad
#else
    float3 L;
    L = cross(L1, -w01 * L0 + w12 * L2); // 6 mul, 6 mad
    L += cross(L3, w30 * L0 + -w23 * L2); // 3 mul, 9 mad
#endif
#endif

	// Vector irradiance
    return L;
}

//float SphereHorizonCosWrap(float NoL, float SinAlphaSqr)
//{
//#if 1
//    float SinAlpha = sqrt(SinAlphaSqr);

//    if (NoL < SinAlpha)
//    {
//        NoL = max(NoL, -SinAlpha);
//#if 1
//		// Accurate sphere irradiance
//		float CosBeta = NoL;
//		float SinBeta = sqrt( 1 - CosBeta * CosBeta );
//		float TanBeta = SinBeta / CosBeta;

//		float x = sqrt( 1 / SinAlphaSqr - 1 );
//		float y = -x / TanBeta;
//		float z = SinBeta * sqrt(1 - y*y);

//		NoL = NoL * acos(y) - x * z + atan( z / x ) / SinAlphaSqr;
//		NoL /= PI;
//#else
//		// Hermite spline approximation
//		// Fairly accurate with SinAlpha < 0.8
//		// y=0 and dy/dx=0 at -SinAlpha
//		// y=SinAlpha and dy/dx=1 at SinAlpha
//        NoL = pow(2, SinAlpha + NoL) / (4 * SinAlpha + 1e-7);
//#endif
//    }
//#else
//	NoL = saturate( ( NoL + SinAlphaSqr ) / ( 1 + SinAlphaSqr ) );
//#endif

//    return NoL;
//}

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
    //Poly[0] = mul(LTC, Poly[0]);
    //Poly[1] = mul(LTC, Poly[1]);
    //Poly[2] = mul(LTC, Poly[2]);
    //Poly[3] = mul(LTC, Poly[3]);
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

    //sum += _LTC_IntegrateEdge(L[0], L[1]);
    //sum += _LTC_IntegrateEdge(L[1], L[2]);
    //sum += _LTC_IntegrateEdge(L[2], L[3]);
    //if (n >= 4)
    //    sum += _LTC_IntegrateEdge(L[3], L[4]);
    //if (n == 5)
    //    sum += _LTC_IntegrateEdge(L[4], L[0]);
    
    //sum = max(0.0, sum);
    sum = abs(sum);
   
 //   float3 L = PolygonIrradiance(Poly);
    
 //   float LengthSqr = dot(L, L);
 //   float InvLength = rsqrt(LengthSqr);
 //   float Length = LengthSqr * InvLength;
    
 //   // Mean light direction
 //   L *= InvLength;
    

	//// Solid angle of sphere		= 2*PI * ( 1 - sqrt(1 - r^2 / d^2 ) )
	//// Cosine weighted integration	= PI * r^2 / d^2
	//// SinAlphaSqr = r^2 / d^2;
 //   float SinAlphaSqr = Length;
 //   float NoL = SphereHorizonCosWrap(L.z, SinAlphaSqr);
 //   float Irradiance = SinAlphaSqr * NoL;

	//// Kill negative and NaN
 //   Irradiance = -min(-Irradiance, 0.0);
    
    float3 SpecularColor = LTCAmp.y + (LTCAmp.x - LTCAmp.y) * float3(1, 1, 1);
	vec3 Fr = F0 * LTCAmp.x + (1 - F0) * LTCAmp.y;

    return sum * Fr ;
}