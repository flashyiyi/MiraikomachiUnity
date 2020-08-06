#ifndef URPToonLit_Unity_Include
#define URPToonLit_Unity_Include

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl" 
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" 

float SampleSceneLinearEyeDepth(float2 screenPos)
{
    return LinearEyeDepth(SampleSceneDepth(screenPos), _ZBufferParams);
}

float GetCameraAspect()
{
    float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
    return abs(nearUpperRight.y / nearUpperRight.x);
}

float4x4 GetCameraProjection()
{
    return unity_CameraProjection;
}

float GetReversedZ()
{
#if defined(UNITY_REVERSED_Z)
    return -1;
#else
    return 1;
#endif
}

float4 ClampNearClipZ(float4 positionCS)
{
#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif
    return positionCS;
}

sampler2D _MatCapMap;
half4 SampleMatCap(half2 normalVS)
{
    half4 matcap = tex2D(_MatCapMap, normalVS * 0.5 + 0.5);
    return matcap;
}

#endif