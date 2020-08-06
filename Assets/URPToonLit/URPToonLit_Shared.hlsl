#ifndef URPToonLit_Shared_Include
#define URPToonLit_Shared_Include

// Required by all Universal Render Pipeline shaders.
// It will include Unity built-in shader variables (except the lighting variables)
// (https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
// It will also include many utilitary functions. 

// Material shader variables are not defined in SRP or URP shader library.
// This means _BaseColor, _BaseMap, _BaseMap_ST, and all variables in the Properties section of a shader
// must be defined by the shader itself. If you define all those properties in CBUFFER named
// UnityPerMaterial, SRP can cache the material properties between frames and reduce significantly the cost
// of each drawcall.
// In this case, although URP's LitInput.hlsl contains the CBUFFER for the material
// properties defined above. As one can see this is not part of the ShaderLibrary, it specific to the
// URP Lit shader.
// So we are not going to use LitInput.hlsl, we will implement everything by ourself.
//#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

//note:
//subfix OS means object space (e.g. positionOS = position object space)
//subfix WS means world space (e.g. positionWS = position world space)#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


#include "URPToonLit_Unity.hlsl"

// all pass will share this Attributes struct
struct Attributes
{
    float3 positionOS   : POSITION;
    half3 normalOS     : NORMAL;
    half4 tangentOS    : TANGENT;
    float2 uv           : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

// all pass will share this Varyings struct
struct Varyings
{
    float4 uv                       : TEXCOORD0;
    float4 positionWSAndFogFactor   : TEXCOORD2; // xyz: positionWS, w: vertex fog factor

    half4 normalWS                  : TEXCOORD3;
    half4 tangentWS                 : TEXCOORD4;
    half4 bitangentWS               : TEXCOORD5;

#ifdef _MAIN_LIGHT_SHADOWS
    float4 shadowCoord              : TEXCOORD6; // compute shadow coord per-vertex for the main light
#endif
    float4 positionCS               : TEXCOORD7;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct SurfaceData
{
    half3 albedo;
    half3 dark;
    half  alpha;
    half3 normalTS;
    half4 emission;
    half smoothness;

    half celShadeMidPoint;
    half celShadeSoftness;
    half celOcclusion;

    half4 depthRimColor;
    half depthRimWidth;
    half depthRimThreshold;

    half4 normalRimColor;
    half normalRimWidth;
    half normalRimSharp;

    half depthShadowWidth;
    half depthShadowThreshold;
    half2 depthShadowOffest;

    half4 fixedHighLightColor;
    half fixedHighLight;
    half fixedHighLightHideSpeed;
    half fixedHighLightBlur;

    half toonMuit;
    half diffuseMuit;
    half highLightMuit;
    half IBLMuit;

    half3 matCapColor;
    half matCapMuit;

    half4 frontLightColor;
    half4 backLightColor;
    half additiveLightRimLightMuit;
    half additiveLightDarkColor;
    half additiveLightSoftBlend;
    half SHLightSoftBlend;
    half maxLightDistanceAttenuation;
};

struct LightingData
{
    half2 uv;
    half2 screenUv;
    half3 normalWS;
    float3 positionWS;
    float4 positionCS;

    half3 viewDirectionWS;
    float4 shadowCoord;
    half3 normalVS;
};

///////////////////////////////////////////////////////////////////////////////////////
// Share
///////////////////////////////////////////////////////////////////////////////////////

half3 SoftBlend(half3 a, half3 b, half soft)
{
    //return lerp(a + b, SoftLight(a, b), soft);
    //    return 1 - (1 - a) * (1 - b); //ÂËÉ«
    //return b * a;
    return a + lerp(1, a, soft) * b;

}

float GetCameraFOV()
{
    float t = GetCameraProjection()._m11;
    float Rad2Deg = 180 / 3.1415926;
    float fov = atan(1.0 / t) * 2.0 * Rad2Deg;
    return fov;
}

void transparencyClip(float alpha, float2 screenPos)
{
    // Screen-door transparency: Discard pixel if below threshold.
    float4x4 thresholdMatrix =
    { 1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
        13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
        4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
        16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };
    float4x4 _RowAccess = { 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 };
    clip(alpha - thresholdMatrix[fmod(screenPos.x, 4)] * _RowAccess[fmod(screenPos.y, 4)]);
}

half stepAntiAliasing(half y, half x)
{
    half v = x - y;
    return saturate(v / fwidth(v));
}

///////////////////////////////////////////////////////////////////////////////////////
// Vertex
///////////////////////////////////////////////////////////////////////////////////////

float4 TransformPositionOSToOutlinePositionOS(float4 positionCS, float3 normalWS, float outlineWidth, float outlineMaxDistance, float outlineZOffset, float vectorScale)
{
    //float3 normal = lerp(vertexNormalInput.normalWS, vertexNormalInput.tangentWS, _OutlineNormalOffset);
    //fixed soft Outline Width
    //float lengthN = length(vertexNormalInput.normalWS);
    //float NoT = dot(normal, vertexNormalInput.normalWS);
    //_OutlineWidth *= lengthN / (NoT / lengthN);

    float3 normal = normalWS;

    //use clip space outline
    float3 clipNormal = TransformWorldToHClipDir(normal);
    float2 projectedNormal = normalize(clipNormal.xy);
    projectedNormal *= outlineWidth;

    //fixed screen aspect
    projectedNormal.x *= GetCameraAspect();

    //scaled - max distance
    projectedNormal *= min(positionCS.w, outlineMaxDistance * GetCameraProjection()._m00);

    //clip offestZ
    float offsetZ = outlineZOffset * GetReversedZ() * vectorScale;
    return positionCS + float4(projectedNormal, offsetZ, 0);
}

float3 ApplyCustomShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection, float3 shadowBias)
{
    float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
    float scale = invNdotL * shadowBias.y;
    float bias = shadowBias.x + length(cross(normalWS, lightDirection)) / length(lightDirection) * shadowBias.z;
    positionWS = lightDirection * bias + positionWS;
    positionWS = normalWS * scale + positionWS;
    return positionWS;
}

float4 TransformPositionWSToShadowPositionOS(float3 positionWS, float3 normalWS, half3 lightDirection, float3 shadowBias)
{
    //see GetShadowPositionHClip() in URP/Shaders/ShadowCasterPass.hlsl 
    positionWS = ApplyCustomShadowBias(positionWS, normalWS, lightDirection, shadowBias);
    return ClampNearClipZ(TransformWorldToHClip(positionWS));
}

///////////////////////////////////////////////////////////////////////////////////////
// frag
///////////////////////////////////////////////////////////////////////////////////////

half GetLightAttenuation(SurfaceData surfaceData, LightingData lightingData, Light light, half direction)
{
    half3 N = lightingData.normalWS;
    half3 L = light.direction;

    half NoL = dot(N, L);

    half minPoint = surfaceData.celShadeMidPoint;

#ifdef _LIGHT_RAMP
    half lightAttenuation = 1;
#else
    #ifdef _LIGHT_SHARP
        half lightAttenuation = stepAntiAliasing(minPoint, NoL);
    #else
        half lightAttenuation = smoothstep(minPoint - surfaceData.celShadeSoftness, minPoint + surfaceData.celShadeSoftness, NoL);
    #endif
#endif
    lightAttenuation = lerp(1, lightAttenuation * surfaceData.celOcclusion, direction);
    lightAttenuation *= light.shadowAttenuation;

    return lightAttenuation;
}

half3 ShadePBRLight(half3 baseColor, SurfaceData surfaceData, LightingData lightingData, Light light, bool mainLight)
{
    half3 N = lightingData.normalWS;
    half3 L = light.direction;
    half3 V = lightingData.viewDirectionWS;
    half3 H = normalize(L + V);

    half NoL = max(dot(N, L),0);
    half NoH = max(dot(N, H),0);

    float roughness = 1 - surfaceData.smoothness;
    float roughnessSqr = roughness * roughness;
    float temp = NoH * NoH * (roughnessSqr - 1) + 1;
    float dggx = roughnessSqr / (temp * temp);

    half3 diffuse = 0;
    half lightAttenuation = light.shadowAttenuation * surfaceData.celOcclusion;
    if (mainLight)
    {
        diffuse = lerp(surfaceData.dark * surfaceData.backLightColor.rgb, surfaceData.albedo * surfaceData.frontLightColor.rgb, NoL * lightAttenuation) * light.color.rgb;
    }
    else
    {
        diffuse = surfaceData.albedo * (NoL * lightAttenuation) * light.color;
    }
    half3 highLight = surfaceData.albedo * dggx * lightAttenuation * light.color;
    return baseColor * surfaceData.toonMuit + diffuse * surfaceData.diffuseMuit + highLight * surfaceData.highLightMuit;
}


half GetDepthDiff(Light light, LightingData lightingData, half2 baseOffest, half2 offest = 0)
{
    float3 clipNormal = TransformWorldToHClipDir(light.direction);
    float depth = SampleSceneLinearEyeDepth(lightingData.screenUv + (baseOffest * clipNormal.xy + offest) * 0.01 / lightingData.positionCS.w);
    float currentDepth = lightingData.positionCS.w;
    return depth - currentDepth;
}

half3 ShadeMatCap(half3 baseColor, SurfaceData surfaceData, LightingData lightingData)
{
    half4 matcap = SampleMatCap(lightingData.normalVS.xy);
    half3 color = baseColor * matcap.rgb * surfaceData.matCapColor.rgb;
    return baseColor + color;
}

half3 ShadeFixedHighLight(half3 baseColor, SurfaceData surfaceData, LightingData lightingData)
{
    float rim = max(0, dot(lightingData.viewDirectionWS, lightingData.normalWS));
    rim = saturate(lerp(-surfaceData.fixedHighLightHideSpeed,1, rim));
    float threshold = 1 - surfaceData.fixedHighLight;
    return baseColor + baseColor * surfaceData.fixedHighLightColor.rgb * smoothstep(threshold, threshold + surfaceData.fixedHighLightBlur, rim);
}

half3 ShadeDepthRimLight(SurfaceData surfaceData, LightingData lightingData, Light light)
{
    half3 baseColor = lerp(1, surfaceData.albedo, surfaceData.depthRimColor.a);
    half outLine = GetDepthDiff(light, lightingData, float2(1, -1) * surfaceData.depthRimWidth) > surfaceData.depthRimThreshold;
    half3 result = baseColor * surfaceData.depthRimColor.rgb * light.color * outLine;
    return result;
}

half3 ShadeNormalRimLight(half3 baseColor, SurfaceData surfaceData, LightingData lightingData, Light light)
{
    float rim = 1 - max(0, dot(lightingData.viewDirectionWS, lightingData.normalWS));
    rim = pow(abs(rim), 1 / (surfaceData.normalRimWidth + 0.01));
    half3 result = surfaceData.normalRimColor.rgb * light.color;
    return lerp(baseColor + result * rim,lerp(baseColor,result,rim), surfaceData.normalRimColor.a);
    //    surfaceData.albedo * _RimColor* (rim / (1 - _NormalRimWidth) > 1)
}

half ShadeDepthRimShadow(SurfaceData surfaceData, LightingData lightingData, Light light)
{
    if (surfaceData.depthShadowWidth == 0)
        return 1;
    return GetDepthDiff(light, lightingData, float2(1, -1) * surfaceData.depthShadowWidth, surfaceData.depthShadowOffest * surfaceData.depthShadowWidth) >= -surfaceData.depthShadowThreshold;
}

half3 ShadeSHLight(SurfaceData surfaceData)
{
    return surfaceData.albedo * min(1, SampleSH(0));
}

half3 ShadeMainLight(SurfaceData surfaceData, LightingData lightingData, Light light, Varyings input, bool isOutline)
{
    half lightAttenuation = GetLightAttenuation(surfaceData, lightingData, light, 1);
    lightAttenuation *= ShadeDepthRimShadow(surfaceData, lightingData, light);

    //Lighting
    half3 mainResult = lerp(surfaceData.dark * surfaceData.backLightColor.rgb, surfaceData.albedo * surfaceData.frontLightColor.rgb, lightAttenuation) * light.color;

    //PBRLighting
    mainResult = ShadePBRLight(mainResult,surfaceData, lightingData, light, true);

    if (!isOutline)
    {
        mainResult = ShadeMatCap(mainResult, surfaceData, lightingData);
        mainResult = ShadeNormalRimLight(mainResult, surfaceData, lightingData, light);
        mainResult = ShadeFixedHighLight(mainResult, surfaceData, lightingData);
        
        //RimLighting
        mainResult += ShadeDepthRimLight(surfaceData, lightingData, light);
    }

    return mainResult;
}

half3 ShadeAdditiveLight(SurfaceData surfaceData, LightingData lightingData, Light light, half direction, Varyings input, bool isOutline)
{
    half lightAttenuation = GetLightAttenuation(surfaceData, lightingData, light, direction);
    half3 mainResult = surfaceData.albedo * lightAttenuation * light.color;
    //PBRLighting
    mainResult = ShadePBRLight(mainResult, surfaceData, lightingData, light, false);

    //RimLighting
    if (!isOutline)
    {
        mainResult += ShadeDepthRimLight(surfaceData, lightingData, light) * surfaceData.additiveLightRimLightMuit;
    }
    return mainResult * min(surfaceData.maxLightDistanceAttenuation,light.distanceAttenuation);
}

// this function contains no lighting logic, it just pass lighting results data around
half3 ShadeAllLights(SurfaceData surfaceData, LightingData lightingData, Varyings input, bool isOutline)
{
    // Indirect lighting
    half3 SHLight = ShadeSHLight(surfaceData);
    
    Light mainLight;
#ifdef _MAIN_LIGHT_SHADOWS
    mainLight = GetMainLight(lightingData.shadowCoord);
#else
    mainLight = GetMainLight();
#endif

#if defined(_SELF_LIGHT_SHADOWS) || defined(_SELF_LIGHT_ON)
    Light selfLight = GetSelfLight(_SelfShadowIndex, lightingData.positionWS);
    mainLight.direction = selfLight.direction;
    #if defined(_SELF_LIGHT_SHADOWS)
        mainLight.shadowAttenuation *= selfLight.shadowAttenuation;
    #endif 
#endif 

    // Main light
    half3 mainLightResult = ShadeMainLight(surfaceData, lightingData, mainLight, input, isOutline);
    half3 additionalLightSumResult = 0;

#ifdef _ADDITIONAL_LIGHTS
    int additionalLightsCount = GetAdditionalLightsCount();
    for (int i = 0; i < additionalLightsCount; ++i)
    {
        Light light = GetAdditionalLight(i, lightingData.positionWS);
        additionalLightSumResult += ShadeAdditiveLight(surfaceData, lightingData, light, surfaceData.additiveLightDarkColor, input, isOutline);
    }
#endif

    half3 result = mainLightResult;
    result = SoftBlend(result, SHLight, surfaceData.SHLightSoftBlend);
    result = SoftBlend(result, additionalLightSumResult, surfaceData.additiveLightSoftBlend);
    result = SoftBlend(result, surfaceData.emission.rgb, surfaceData.emission.a);
    return result;
}

#endif
