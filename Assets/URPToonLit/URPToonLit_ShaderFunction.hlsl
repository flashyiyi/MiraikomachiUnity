#ifndef URPToonLit_ShaderFunction_Include
#define URPToonLit_ShaderFunction_Include

#include "URPToonLit_Shared.hlsl"

///////////////////////////////////////////////////////////////////////////////////////
// CBUFFER and Uniforms 
// (you should put all uniforms of all passes inside this single UnityPerMaterial CBUFFER! else SRP batching is not possible!)
///////////////////////////////////////////////////////////////////////////////////////

// all sampler2D don't need to put inside CBUFFER 
sampler2D _BaseMap;
sampler2D _DarkMap;
sampler2D _BumpMap;
sampler2D _OutlineMap;
sampler2D _RimMap;
sampler2D _PBRMap;
sampler2D _LightMap;
sampler2D _AOMap;
sampler2D _EmissionMap;

// put all your uniforms(usually things inside properties{} at the start of .shader file) inside this CBUFFER, in order to make SRP batcher compatible
CBUFFER_START(UnityPerMaterial)

// base color
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _DarkColor;
half _BumpScale;

// alpha
half _Cutoff;

//lighting    
half _CelShadeMidPoint;
half _CelShadeSoftness;

//Rim
half4 _RimColor;
half _DepthRimWidth;
half _DepthRimThreshold;

half4 _NormalRimColor;
half _NormalRimWidth;
half _NormalRimSharp;

//depth shadow
half _DepthShadowWidth;
half _DepthShadowThreshold;
half2 _DepthShadowOffest;

// shadow mapping
half _MainLightShadowThreshold;
half _CustomShadowBias;
half _SlopeShadowBias;
//int _SelfShadowIndex;

// ibm
half _Smoothness;
half _ToonDiffuseMuit;
half _DiffuseMuit;
half _HighLightMuit;
half _IBLMuit;
half4 _FixedHighLightColor;
half _FixedHighLightHideSpeed;
half _FixedHighLightBlur;
half4 _MatCapColor;
half4 _EmissionColor;

// outline
float _OutlineWidth;
half4 _OutlineColor;
float _OutlineZOffset;
float _VectorZOffest;
float _OutlineScaledMaxDistance;

//HSV
half3 _HSV_L1;
half3 _HSV_L2;
half3 _HSV_L3;

half _HSVAlpha;
CBUFFER_END

//GlobalParams
half4 _FrontLightColor = 1;
half4 _BackLightColor = 1;
half _AdditiveLightRimLightMuit = 1;
half _AdditiveLightDarkColor = 0.5;
half _AdditiveLightSoftBlend = 0.5;
half _SHLightSoftBlend = 0;
half _MaxLightDistanceAttenuation = 1;

half3 _LightDirection;


///////////////////////////////////////////////////////////////////////////////////////
// Vertex
///////////////////////////////////////////////////////////////////////////////////////

struct VertexShaderWorkSetting
{
    bool isOutline;
    bool applyShadowBiasFixToHClipPos;
};

VertexShaderWorkSetting GetDefaultVertexShaderWorkSetting()
{
    VertexShaderWorkSetting output;
    output.isOutline = false;
    output.applyShadowBiasFixToHClipPos = false;
    return output;
}

Varyings VertexShaderWork(Attributes input, VertexShaderWorkSetting setting, out float4 outpos : SV_POSITION)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    //Input
    half2 uv = TRANSFORM_TEX(input.uv, _BaseMap);
    half3 outlineParams = tex2Dlod(_OutlineMap, float4(uv, 0, 0)).rgb;
    half outlineWidth = _OutlineWidth * outlineParams.x;
    half outlineZOffset = _OutlineZOffset * outlineParams.y;
    half outlineScaledMaxDistance = _OutlineScaledMaxDistance;
    half vectorZOffest = _VectorZOffest * outlineParams.z;
    half3 lightDirection = _LightDirection;
    half3 shadowBias = _ShadowBias.xyz - float3(_CustomShadowBias, 0, _SlopeShadowBias);
    half3 mainLightShadowThreshold = _MainLightShadowThreshold;

    //Prepare data
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    half worldScale = length(vertexNormalInput.normalWS);
    half clipScale = vertexInput.positionCS.z / vertexInput.positionCS.w;
    half vectorScale = worldScale * clipScale;

    half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);


    //计算坐标
    float4 positionCS = vertexInput.positionCS;
    if (setting.isOutline)
    {
        positionCS = TransformPositionOSToOutlinePositionOS(positionCS, vertexNormalInput.normalWS, outlineWidth, outlineScaledMaxDistance, outlineZOffset, vectorScale);
    }

    // ShadowCaster
    if (setting.applyShadowBiasFixToHClipPos)
    {
        positionCS = TransformPositionWSToShadowPositionOS(vertexInput.positionWS, vertexNormalInput.normalWS, lightDirection, shadowBias);
    }
    else
    {
        //移动睫毛到头发上
        positionCS.z += vectorZOffest * vectorScale; 
    }   

    half4 screenPos = ComputeScreenPos(positionCS);

    //Output
    output.uv.xy = uv;
    output.uv.zw = screenPos.xy / screenPos.w;
    output.normalWS = half4(vertexNormalInput.normalWS, viewDirWS.x);
    output.tangentWS = half4(vertexNormalInput.tangentWS, viewDirWS.y);
    output.bitangentWS = half4(vertexNormalInput.bitangentWS, viewDirWS.z);
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, fogFactor);
    output.positionCS = positionCS;
    outpos = positionCS;

#ifdef _MAIN_LIGHT_SHADOWS
    output.shadowCoord = GetShadowCoord(vertexInput);
    output.shadowCoord.z += mainLightShadowThreshold;
#endif

    //OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    //OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    return output;
}


///////////////////////////////////////////////////////////////////////////////////////
// Clip
///////////////////////////////////////////////////////////////////////////////////////

SurfaceData InitializeSurfaceData(Varyings input)
{
    SurfaceData output;

    half2 uv = input.uv.xy;
    half4 baseColor = tex2D(_BaseMap, uv) * _BaseColor;
    half4 darkColor = tex2D(_DarkMap, uv) * _DarkColor;
    half4 bumpMap = tex2D(_BumpMap, uv);
    half4 emissionMap = tex2D(_EmissionMap, uv) * _EmissionColor;
    half3 rimMap = tex2D(_RimMap, uv).rgb;
    half4 pbrMap = tex2D(_PBRMap, uv);
    half3 aoMap = tex2D(_AOMap, uv).rgb;
    half3 lightMap = tex2D(_LightMap, uv).rgb;

    output.albedo = baseColor.rgb;
    output.alpha = baseColor.a;
    output.dark = darkColor.rgb;
    output.emission = emissionMap;
    output.normalTS = UnpackNormalScale(bumpMap, _BumpScale);
    output.smoothness = _Smoothness;

    output.celShadeMidPoint = _CelShadeMidPoint - aoMap.g;
    output.celShadeSoftness = _CelShadeSoftness;
    output.celOcclusion = 1 - aoMap.r;

    output.depthRimColor = half4(_RimColor.rgb * rimMap.r,_RimColor.a);
    output.depthRimWidth = _DepthRimWidth;
    output.depthRimThreshold = _DepthRimThreshold;
    output.normalRimColor = _NormalRimColor * rimMap.g;
    output.normalRimWidth = _NormalRimWidth;
    output.normalRimSharp = _NormalRimSharp;

    output.depthShadowWidth = _DepthShadowWidth * rimMap.b;
    output.depthShadowThreshold = _DepthShadowThreshold;
    output.depthShadowOffest = _DepthShadowOffest * rimMap.b;

    output.toonMuit = _ToonDiffuseMuit * pbrMap.r;
    output.diffuseMuit = _DiffuseMuit * pbrMap.g;
    output.highLightMuit = _HighLightMuit * pbrMap.b;
    output.IBLMuit = _IBLMuit * pbrMap.a;
    output.matCapColor = _MatCapColor.rgb * lightMap.g;

    output.fixedHighLight = lightMap.r;
    output.fixedHighLightColor = _FixedHighLightColor;
    output.fixedHighLightHideSpeed = _FixedHighLightHideSpeed;
    output.fixedHighLightBlur = _FixedHighLightBlur;

    output.frontLightColor = _FrontLightColor;
    output.backLightColor = _BackLightColor;
    output.additiveLightRimLightMuit = _AdditiveLightRimLightMuit;
    output.additiveLightDarkColor = _AdditiveLightDarkColor;
    output.additiveLightSoftBlend = _AdditiveLightSoftBlend;
    output.SHLightSoftBlend = _SHLightSoftBlend;
    output.maxLightDistanceAttenuation = _MaxLightDistanceAttenuation;

    return output;
}

half4 ShadeFinalColor(Varyings input, bool isOutline)
{
    //SurfaceData:
    SurfaceData surfaceData = InitializeSurfaceData(input);

    //LightingData:
    LightingData lightingData;
    lightingData.uv = input.uv.xy;
    lightingData.screenUv = input.uv.zw;
    lightingData.positionCS = input.positionCS;
    lightingData.normalWS = normalize(input.normalWS.xyz);
    lightingData.positionWS = input.positionWSAndFogFactor.xyz;
    //lightingData.viewDirectionWS = float3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
    lightingData.viewDirectionWS = SafeNormalize(GetCameraPositionWS() - lightingData.positionWS);

    lightingData.normalWS = TransformTangentToWorld(surfaceData.normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
    lightingData.normalVS = TransformWorldToViewDir(lightingData.normalWS);

#ifdef _MAIN_LIGHT_SHADOWS
    lightingData.shadowCoord = input.shadowCoord;
#endif

    half4 color = half4(ShadeAllLights(surfaceData, lightingData, input, isOutline), surfaceData.alpha);
    if (isOutline)
    {
        color *= _OutlineColor;
    }

    // fog
    half fogFactor = input.positionWSAndFogFactor.w;
    color.rgb = MixFog(color.rgb, fogFactor);

    half3x3 m = half3x3(_HSV_L1, _HSV_L2, _HSV_L3);
    m = lerp(half3x3(1, 0, 0, 0, 1, 0, 0, 0, 1), m, _HSVAlpha);
    color.rgb = mul(m, color.rgb);

    return color;
}

half4 BaseColorAlphaClipTest(Varyings input)
{
#ifdef _ALPHATEST_ON
    half alpha = tex2D(_BaseMap, input.uv.xy).a;
    clip(alpha - _Cutoff);
#endif
    return 0;
}

///////////////////////////////////////////////////////////////////////////////////////
// Shader Function
///////////////////////////////////////////////////////////////////////////////////////

Varyings BaseColorPassVertex(Attributes input, out float4 outpos : SV_POSITION)
{
    VertexShaderWorkSetting setting = GetDefaultVertexShaderWorkSetting();
    return VertexShaderWork(input, setting, outpos);
}

half4 BaseColorPassFragment(Varyings input) : SV_TARGET
{
    return ShadeFinalColor(input, false);
}

half4 BaseColorPassFragment_TransparentBlur(Varyings input) : SV_TARGET
{
    _RimColor = 0; //透明物体无法再使用深度边缘光
    half4 col = ShadeFinalColor(input, false);
    half3 grabCol = SampleSceneColor(input.uv.zw);
    return half4(lerp(grabCol,col.rgb,col.a),1);
}

Varyings OutlinePassVertex(Attributes input, out float4 outpos : SV_POSITION)
{
    VertexShaderWorkSetting setting = GetDefaultVertexShaderWorkSetting();
    setting.isOutline = true;
    return VertexShaderWork(input, setting, outpos);
}

half4 OutlinePassFragment(Varyings input) : SV_TARGET
{
    return ShadeFinalColor(input, true);
}

Varyings ShadowCasterPassVertex(Attributes input, out float4 outpos : SV_POSITION)
{
    VertexShaderWorkSetting setting = GetDefaultVertexShaderWorkSetting();
    setting.applyShadowBiasFixToHClipPos = true;
    return VertexShaderWork(input, setting, outpos);
}

half4 ShadowCasterPassFragment(Varyings input) : SV_TARGET
{
    BaseColorAlphaClipTest(input);
    return 0;
}

half4 ShadowCasterPassFragment_Transparent(Varyings input, float4 screenPos:VPOS) : SV_TARGET
{
    SurfaceData surfaceData = InitializeSurfaceData(input);
    transparencyClip(surfaceData.alpha, screenPos.xy);
    return 0;
}

Varyings DepthOnlyPassVertex(Attributes input, out float4 outpos : SV_POSITION)
{
    VertexShaderWorkSetting setting = GetDefaultVertexShaderWorkSetting();
    return VertexShaderWork(input, setting, outpos);
}

half4 DepthOnlyPassFragment(Varyings input) : SV_TARGET
{
    BaseColorAlphaClipTest(input);
    return 0;
}


#endif