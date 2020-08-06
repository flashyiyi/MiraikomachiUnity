Shader "miHoYo/Character/Avatar" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		[HideInInspector] _Scale ("Scale Compared to Maya", Float) = 0.01
		_BloomFactor ("Bloom Factor", Float) = 1
		_MainTex ("Main Tex (RGB)", 2D) = "white" { }		
		[NoScaleOffset]_LightMapTex ("Light Map Tex (RGB)", 2D) = "gray" { }
		_LightSpecColor ("Light Specular Color", Color) = (1,1,1,1)
		[HideInInspector] _LightArea ("Light Area Threshold", Range(0, 1)) = 0.51
		[HideInInspector] _SecondShadow ("Second Shadow Threshold", Range(0, 1)) = 0.51
		_FirstShadowMultColor ("First Shadow Multiply Color", Color) = (0.9,0.7,0.75,1)
		_SecondShadowMultColor ("Second Shadow Multiply Color", Color) = (0.75,0.6,0.65,1)
		_Shininess ("Specular Shininess", Range(0.1, 100)) = 10
		_SpecMulti ("Specular Multiply Factor", Range(0, 1)) = 0.1
		_OutlineWidth ("Outline Width", Range(0, 100)) = 0.2
		_OutlineColor ("Outline Color", Color) = (0,0,0,1)
		[NoScaleOffset]_OutlineColorTex ("Outline Color Tex", 2D) = "white" {}
		[Toggle(RIM_GLOW)] _RimGlow ("Rim Glow", Float) = 0
		_RGColor ("Rim Glow Color", Color) = (1,1,1,1)
		_RGShininess ("Rim Glow Shininess", Float) = 1
		_RGScale ("Rim Glow Scale", Float) = 1
		_RGBias ("Rim Glow Bias", Float) = 0
		_RGRatio ("Rim Glow Ratio", Range(0, 1)) = 0.5
	}
	SubShader {
		LOD 200
		Tags { "Distortion" = "None" "IGNOREPROJECTOR" = "true" "OutlineType" = "Complex" "QUEUE" = "Geometry" "Reflected" = "Reflected" "RenderType" = "Opaque" }
		Pass {
			Name "COMPLEX"
			LOD 200
			Tags { "Distortion" = "None" "IGNOREPROJECTOR" = "true" "RenderPipeline" = "UniversalPipeline"  "LightMode" = "UniversalForward" "OutlineType" = "Complex" "QUEUE" = "Geometry" "Reflected" = "Reflected" "RenderType" = "Opaque" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile __ RIM_GLOW

			#include "Lighting.cginc"

			struct a2v {
				float4 vertex : POSITION;
				fixed4 texcoord : TEXCOORD0;
				fixed3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;

				half diff : COLOR0;

				float3 worldNormal  : NORMAL0;
				float3 worldPos : NORMAL1;

				float2 uv  : TEXCOORD0;								
			};

			fixed4 _Color;

			sampler2D _MainTex;
			fixed4 _MainTex_ST;

			sampler2D _LightMapTex;

			fixed _LightArea;
			fixed _SecondShadow;
			
			fixed4 _FirstShadowMultColor;
			fixed4 _SecondShadowMultColor;

			fixed _Shininess;
			fixed4 _LightSpecColor;
			fixed _SpecMulti;

			fixed _BloomFactor;

		#ifdef RIM_GLOW
			uniform half4 _RGColor;
			uniform float _RGShininess;
			uniform float _RGScale;
			uniform float _RGBias;
			uniform float _RGRatio;
		#endif

			v2f vert(a2v v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				float4 worldPos;
				worldPos = mul(unity_ObjectToWorld , v.vertex);
				
				float3 worldNormal = normalize(mul(v.normal , (float3x3)unity_WorldToObject));

				half3 worldLight = _WorldSpaceLightPos0.xyz;

				o.worldPos = worldPos.xyz / worldPos.w;

				o.worldNormal = worldNormal;
				
				o.diff = ((dot (worldNormal, worldLight) * 0.4975) + 0.5);

				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				half4 color;
				half3 texBaseColor = tex2D (_MainTex, i.uv).xyz;
				half3 texLightColor = tex2D (_LightMapTex, i.uv).xyz;
				
				half threshold;
				
				half3 diffColor;

				half shadowCoeff = (texLightColor.y);

				if ((shadowCoeff < 0.09)) {
					threshold = ((i.diff + shadowCoeff) * 0.5);
					if ((threshold < _SecondShadow)) {
						diffColor = (texBaseColor * _SecondShadowMultColor);
					} else {
						diffColor = (texBaseColor * _FirstShadowMultColor);
					};
				} else {
					half shadowCoeff2;

					if ((shadowCoeff >= 0.5)) {
						shadowCoeff2 = ((shadowCoeff * 1.2) - 0.1);
					} else {
						shadowCoeff2 = ((shadowCoeff * 1.25) - 0.125);
					};
					threshold = ((i.diff + shadowCoeff2) * 0.5);
					if ((threshold < _LightArea)) {
						diffColor = (texBaseColor * _FirstShadowMultColor);
					} else {
						diffColor = texBaseColor;
					};
				};

				half3 V = normalize((_WorldSpaceCameraPos - i.worldPos));
				half3 H = normalize((_WorldSpaceLightPos0.xyz + V));				
				half3 N = normalize(i.worldNormal);

				half3 specColor;
				half spec = pow (max (dot (N, H), 0.0), _Shininess);
				if ((spec >= (1.0 - texLightColor.z))) {
					specColor = ((_LightSpecColor * _SpecMulti) * texLightColor.x);
				} else {
					specColor = half3(0.0, 0.0, 0.0);
				};

				color.xyz = (diffColor + specColor) * _Color.xyz;
				color.w = _BloomFactor;
				
			#ifdef RIM_GLOW
				half viewIntensity = pow(clamp((1.0 - dot(V, N)), 0.0, 1.0), _RGShininess);
				float rimIntensity = _RGBias + viewIntensity * _RGScale;
				half3 rimColor = (rimIntensity * _RGColor).xyz;
				float rimIntensityN = clamp(rimIntensity, 0.0, 1.0);

				color.xyz = lerp(color.xyz, rimColor, rimIntensityN * _RGRatio);
			#endif

				return color;
			}
			ENDCG	
		}

		Pass {
			Name "COMPLEX"
			LOD 200
			Tags { "Distortion" = "None" "IGNOREPROJECTOR" = "true" "LIGHTMODE" = "Outline" "OutlineType" = "Complex" "QUEUE" = "Geometry" "Reflected" = "Reflected" "RenderType" = "Opaque" }
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "Lighting.cginc"

			struct a2v {
				float4 vertex : POSITION;
				fixed4 normal : NORMAL;
				fixed2 texcoord : TEXCOORD1;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				fixed2 uv : TEXCOORD;
			};

			sampler2D _OutlineColorTex;
			uniform float4 _OutlineColorTex_ST;
			fixed _Scale;
			fixed _OutlineWidth;
			fixed4 _OutlineColor;


			v2f vert(a2v v)
			{
				v2f o;
				half3 N;
				half S;
				float3 viewPos = UnityObjectToViewPos(v.vertex);
				half4 color;

				S = (-(viewPos.z) / unity_CameraProjection[1].y);
				S = pow ((S / _Scale), 0.5);

				N.xy = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));//UnityObjectToViewPos(v.normal).xy;
				N.z = 0.01;
				N = normalize(N);
				
				half viewPosOffset;
				viewPosOffset = ((_OutlineWidth * _Scale) * (S));

				viewPos.xy = (viewPos.xy + (N.xy * viewPosOffset));

				o.pos = mul(UNITY_MATRIX_P ,float4(viewPos, 1.0));
				o.uv = TRANSFORM_TEX(v.texcoord, _OutlineColorTex);

				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				return tex2D(_OutlineColorTex,i.uv) * _OutlineColor;		
			}	
			ENDCG		
		}		
	}
	Fallback "Diffuse"
}