Shader "URPToon/Lit (With Outline)"
{
    Properties
    {
        [Header(Base Color)]
        [HDR][MainColor]_BaseColor("_BaseColor", Color) = (1,1,1,1)
        [MainTexture]_BaseMap("_BaseMap (albedo)", 2D) = "white" {}
        [HDR]_DarkColor("_DarkColor", Color) = (0.5,0.5,0.5,1)
        [NoScaleOffset]_DarkMap("_DarkMap", 2D) = "white" {}
        [NoScaleOffset]_BumpMap("_BumpMap",2D) = "bump"{}
        _BumpScale("_BumpScale", Range(0,5)) = 1

        [Header(Lighting)]
        [KeywordEnum(SMOOTH,SHARP,RAMP)]_LIGHT("Mode", Float) = 0
        _ToonDiffuseMuit("_ToonDiffuseMuit", Range(0,1)) = 1
        [HideIf(_ToonDiffuseMuit,0)]_CelShadeMidPoint("_CelShadeMidPoint", Range(-1,1)) = 0.0
        [HideIf(_ToonDiffuseMuit,0)]_CelShadeSoftness("_CelShadeSoftness", Range(0,1)) = 0.05
        _DiffuseMuit("_DiffuseMuit", Range(0,1)) = 0
        _HighLightMuit("_HighLightMuit", Range(0,1)) = 0
        [HideIf(_HighLightMuit,0)]_Smoothness("_Smoothness", Range(0,0.99)) = 0
        [HDR]_FixedHighLightColor("_FixedHighLightColor", Color) = (0,0,0,0)
        [HideIf(_FixedHighLightColor,0)]_FixedHighLightHideSpeed("_FixedHighLightHideSpeed", Range(-1,2)) = 0
        [HideIf(_FixedHighLightColor,0)]_FixedHighLightBlur("_FixedHighLightBlur", Range(0,1)) = 0.1
        [HDR]_MatCapColor("_MatCapColor", Color) = (0,0,0,0)
        [HideIf(_MatCapColor,0)][NoScaleOffset]_MatCapMap("_MatCapMap", 2D) = "black" {}
        [HDR]_EmissionColor("_EmissionColor", Color) = (0,0,0)
        [HideIf(_EmissionColor,0)]_EmissionMap("_EmissionMap", 2D) = "white" {}

        [Header(ILM Maps)]
        [NoScaleOffset]_PBRMap("_PBRMap(DiffuseMask,HighLightMask,Smoothness)", 2D) = "white" {}
        [NoScaleOffset]_LightMap("_LightMap(FixedHighLight,MATCAPMask,CubeMapMask)", 2D) = "black" {}
        [NoScaleOffset]_AOMap("_AOMap(AO,AOOffest,SDFInline)", 2D) = "black" {}

        [Header(Rim Lighting)]
        [HDR]_RimColor("_RimColor", Color) = (0,0,0,0)
        [HideIf(_RimColor,0)]_DepthRimWidth("_DepthRimWidth", Range(0,5)) = 0
        [HideIf(_RimColor,0,_DepthRimWidth,0)]_DepthRimThreshold("_DepthRimThreshold", Range(0,0.5)) = 0.1
        [Space]
        [HDR]_NormalRimColor("_NormalRimColor", Color) = (0,0,0,0)
        [HideIf(_NormalRimColor,0)]_NormalRimWidth("_NormalRimWidth", Range(0,1)) = 0
        [Space]
        _DepthShadowWidth("_DepthShadowWidth", Range(0,5)) = 0
        [HideIf(_DepthShadowWidth,0)]_DepthShadowThreshold("_DepthShadowThreshold", Range(0,0.5)) = 0.1
        [HideIf(_DepthShadowWidth,0)]_DepthShadowOffest("_DepthShadowOffest", Vector) = (0,0,0,0)
        [NoScaleOffset]_RimMap("_RimMap(DepthRimMask,NormalRimMask,DepthShadowMask)", 2D) = "white" {}

        [Header(Shadow mapping)]
        [KeywordEnum(OFF,ON,SHADOWS)]_SELF_LIGHT("_SELF_LIGHT_SHADOWS", Float) = 0
        _MainLightShadowThreshold("_MainLightShadowThreshold",Range(0,1)) = 0
        _CustomShadowBias("_CustomShadowBias", Range(0,2)) = 0
        _SlopeShadowBias("_SlopeShadowBias", Range(0,1)) = 0

        [Header(Outline)]
        _OutlineWidth("_OutlineWidth (Clip Space)", Range(0, 0.025)) = 0.005
        [HideIf(_OutlineWidth,0)]_OutlineColor("_OutlineColor", Color) = (0.3,0.3,0.3,1)
        [HideIf(_OutlineWidth,0)]_OutlineZOffset("Outline ZOffset", Range(0.0, 0.1)) = 0.0
        [HideIf(_OutlineWidth,0)]_OutlineScaledMaxDistance("Outline Scaled Max Distance", Range(1, 10)) = 1
        _VectorZOffest("Vector ZOffest", Range(0,1)) = 0
        [NoScaleOffset]_OutlineMap("_OutlineMap(Width,ZOffest,VectorZOffest)", 2D) = "white" {}

        [Header(ColorGrading)]
        [HSV(_HSV_P,_HSV_L1,_HSV_L2,_HSV_L3)]_HSV("_HSV", Vector) = (0,1,1,0)
        [Hide]_HSV_P("", Vector) = (0,0,0,0)
        [Hide]_HSV_L1("", Vector) = (1,0,0,0)
        [Hide]_HSV_L2("", Vector) = (0,1,0,0)
        [Hide]_HSV_L3("", Vector) = (0,0,1,0)
        _HSVAlpha("_HSVAlpha",Range(0,1)) = 1

        [Header(Alpha)]
        [Toggle(_ALPHATEST_ON)]_UseAlphaClipping("_UseAlphaClipping", Float) = 0
        [ShowIf(_UseAlphaClipping)]_Cutoff("_Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.5
    }
    SubShader 
    {       
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
        }
        
        // ------------------------------------------------------------------
        // Forward pass. Shades GI, emission, fog and all lights in a single pass.
        // Compared to Builtin pipeline forward renderer, URP forward renderer will
        // render a scene with multiple lights with less drawcalls and less overdraw.
        Pass
        {               
            Name "SurfaceColor"
            Tags{"LightMode" = "UniversalForward"}
            ZTest Equal //只有在Pre-Depth激活的情况下才能这样设置

            HLSLPROGRAM
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT 
            #pragma multi_compile_fog

            #pragma shader_feature _LIGHT_SMOOTH _LIGHT_SHARP _LIGHT_RAMP
            #pragma shader_feature _SELF_LIGHT_OFF _SELF_LIGHT_ON _SELF_LIGHT_SHADOWS
            #pragma shader_feature _ _ALPHATEST_ON

            #include "URPToonLit_ShaderFunction.hlsl" 

            #pragma vertex BaseColorPassVertex
            #pragma fragment BaseColorPassFragment

            ENDHLSL
        }
        
        // ------------------------------------------------------------------
        // Outline pass. Similar to "SurfaceColor" pass, but vertex position are pushed out a bit base on normal direction, also color is darker 
        Pass 
        {
            Name "Outline"
            Tags{"LightMode" = "Outline"}

            Cull Front

            HLSLPROGRAM

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #pragma shader_feature _LIGHT_SMOOTH _LIGHT_SHARP _LIGHT_RAMP
            #pragma shader_feature _SELF_LIGHT_OFF _SELF_LIGHT_ON _SELF_LIGHT_SHADOWS
            #pragma shader_feature _ _ALPHATEST_ON

            #include "URPToonLit_ShaderFunction.hlsl"

            #pragma vertex OutlinePassVertex
            #pragma fragment OutlinePassFragment

            ENDHLSL
        }
        

        // Used for rendering URP's shadowmaps
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ColorMask 0
            //Cull Off
            HLSLPROGRAM

            #pragma vertex ShadowCasterPassVertex
            #pragma fragment ShadowCasterPassFragment

            #include "URPToonLit_ShaderFunction.hlsl"

            ENDHLSL
        }

        // Used for rendering self shadowmaps
        Pass
        {
            Name "ShadowCasterSelf"
            Tags{"LightMode" = "ShadowCasterSelf"}

            ColorMask 0
            Cull Front
            HLSLPROGRAM

            #pragma vertex ShadowCasterPassVertex
            #pragma fragment ShadowCasterPassFragment

            #include "URPToonLit_ShaderFunction.hlsl"

            ENDHLSL
        }

        // Used for depth prepass
        // If depth texture is needed, we need to perform a depth prepass for this shader. 
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}
             
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex DepthOnlyPassVertex
            #pragma fragment DepthOnlyPassFragment

            #include "URPToonLit_ShaderFunction.hlsl"

            ENDHLSL
        }
    }
    CustomEditor "ExtendShaderGUI"
}
