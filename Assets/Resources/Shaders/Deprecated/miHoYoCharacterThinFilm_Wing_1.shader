Shader "miHoYo/Character/ThinFilm_Wing" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_BloomFactor ("Bloom Factor", Float) = 1
		_MainTex ("Main Tex (RGB)", 2D) = "white" { }
		_FringeTex ("Fringe Tex (RGB)", 2D) = "white" { }
		_FringeBumpTex ("Frige Bump Tex", 2D) = "gray" { }
		_Opaqueness ("Opaqueness", Range(0, 1)) = 1
		_MinAlpha ("Min Alpha", Range(0, 1)) = 0
		[HideInInspector] _OpaquenessScalerWithoutHDR ("", Float) = 1
		_EmissionScaler ("Emission Scaler", Range(1, 20)) = 1
		[HideInInspector] _EmissionScalerScalerWithoutHDR ("", Float) = 1
		_FringeIntensity ("Fringe Intensity", Range(0, 10)) = 1
		_FringeBumpScaler ("Fringe Bump Scaler", Range(0, 10)) = 1
		_FringeRangeScaler ("Fringe Range Scaler", Range(0, 10)) = 1
		_FringeRangeOffset ("Fringe Range Offset", Range(0, 1)) = 0
		_FringeViewDistance ("Fringe View Distance", Float) = 5
		_FringeFresnel ("Fringe Fresnel", Vector) = (1,1,0,0)
		_FadeDistance ("Fade Start Distance", Range(0.1, 10)) = 0.5
		_FadeOffset ("Fade Start Offset", Range(0, 10)) = 1
		_DitherAlpha ("Dither Alpha Value", Range(0, 1)) = 1
		[Toggle(USINGDITHERALPAH)] _UsingDitherAlpha ("UsingDitherAlpha", Float) = 0
	}
	SubShader {
		Tags { "IGNOREPROJECTOR" = "true" "OutlineType" = "None" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
		Pass {
			Tags { "RenderPipeline" = "UniversalPipeline"  "LightMode" = "UniversalForward" "IGNOREPROJECTOR" = "true" "OutlineType" = "None" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
			Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "Lighting.cginc"

			struct a2v {
				float4 vertex : POSITION;
				fixed4 texcoord : TEXCOORD0;
				fixed3 normal : NORMAL;
				fixed4 color  : COLOR;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				fixed2 color1 : COLOR1;
				float4 uv0  : TEXCOORD0;
				float3 uv1  : TEXCOORD1;
				float3 uv2 : TEXCOORD2;
				float3 uv3 : TEXCOORD3;
				float3 uv4 : TEXCOORD4;
				half4 uv5 : TEXCOORD5;
			};

			fixed4 _Color;

			sampler2D _MainTex;			
			fixed4 _MainTex_ST;

			sampler2D _FringeTex;

			sampler2D _FringeBumpTex;
			fixed4 _FringeBumpTex_ST;

			fixed _OpaquenessScalerWithoutHDR;
			fixed _Opaqueness;

			fixed _FringeViewDistance;
			fixed _FringeBumpScaler;
			fixed _FringeRangeScaler;
			fixed _FringeRangeOffset;

			fixed _FringeIntensity;

			fixed _UsingDitherAlpha;
			fixed _DitherAlpha;

			fixed4 _FringeFresnel;

			fixed _EmissionScaler;
			fixed _EmissionScalerScalerWithoutHDR;

			fixed _MinAlpha;

			uniform fixed4x4 _DITHERMATRIX;

			v2f vert(a2v v)
			{
				v2f o;
				half3 adjCamPos_1;
				half3 d_2;
				half4 localOrig_3;
				half4 tmpvar_4;
				float3 tmpvar_5;
				half2 tmpvar_6;
				half4 tmpvar_7;
				tmpvar_6.x = 0.0;
				tmpvar_7 = half4(0.0, 0.0, 0.0, 0.0);
				tmpvar_4.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				tmpvar_4.zw = TRANSFORM_TEX(v.texcoord, _FringeBumpTex);
				tmpvar_6.y = (_Opaqueness * _OpaquenessScalerWithoutHDR);
				half4 tmpvar_8;
				tmpvar_8 = mul(unity_ObjectToWorld , half4(0.0, 0.0, 0.0, 1.0));
				localOrig_3 = (tmpvar_8 / tmpvar_8.w);
				float3 tmpvar_9;
				tmpvar_9 = normalize((_WorldSpaceCameraPos - localOrig_3.xyz));
				d_2 = tmpvar_9;
				float3 tmpvar_10;
				tmpvar_10 = (localOrig_3.xyz + (d_2 * _FringeViewDistance));
				adjCamPos_1 = tmpvar_10;
				float3 tmpvar_11;
				tmpvar_11 = normalize((adjCamPos_1 - mul(unity_ObjectToWorld , v.vertex).xyz));
				half4 tmpvar_12;
				half4 tmpvar_13;
				tmpvar_13.w = 1.0;
				tmpvar_13.xyz = v.vertex.xyz;
				tmpvar_12 = UnityObjectToClipPos(tmpvar_13);
				float3x3 tmpvar_14;
				tmpvar_14[0] = unity_WorldToObject[0].xyz;
				tmpvar_14[1] = unity_WorldToObject[1].xyz;
				tmpvar_14[2] = unity_WorldToObject[2].xyz;
				tmpvar_5 = -(normalize(mul(v.normal , tmpvar_14)));
				float3 tmpvar_15;
				tmpvar_15.z = 0.0;
				tmpvar_15.x = tmpvar_5.y;
				tmpvar_15.y = -(tmpvar_5.x);
				float3 tmpvar_16;
				tmpvar_16 = normalize(tmpvar_15);
				float3 tmpvar_17;
				tmpvar_17 = normalize(((tmpvar_5.yzx * tmpvar_16.zxy) - (tmpvar_5.zxy * tmpvar_16.yzx)));
				if (bool(_UsingDitherAlpha)) {
					half4 o_18;
					half4 tmpvar_19;
					tmpvar_19 = (tmpvar_12 * 0.5);
					float2 tmpvar_20;
					tmpvar_20.x = tmpvar_19.x;
					tmpvar_20.y = (tmpvar_19.y * _ProjectionParams.x);
					o_18.xy = (tmpvar_20 + tmpvar_19.w);
					o_18.zw = tmpvar_12.zw;
					tmpvar_7.xyw = o_18.xyw;
					tmpvar_7.z = _DitherAlpha;
				};
				o.pos = tmpvar_12;
				o.uv0 = tmpvar_4;
				o.uv1 = tmpvar_11;
				o.uv2 = tmpvar_16;
				o.uv3 = tmpvar_17;
				o.uv4 = tmpvar_5;
				o.color1 = tmpvar_6;
				o.uv5 = tmpvar_7;

				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				half3 fringeColor_1;
				half f_2;
				half2 uv_3;
				half cs_4;
				float3 bumpVector_5;
				half3 baseTexColor_6;
				half4 outColor_7;
				outColor_7.w = 0.0;
				fixed3 tmpvar_8;
				tmpvar_8 = tex2D (_MainTex, i.uv0.xy).xyz;
				baseTexColor_6 = tmpvar_8;
				outColor_7.xyz = (baseTexColor_6 * _Color.xyz);
				fixed3 tmpvar_9;
				tmpvar_9 = (tex2D (_FringeBumpTex, i.uv0.zw).xyz - fixed3(0.5, 0.5, 0.0));
				bumpVector_5 = tmpvar_9;
				bumpVector_5.xy = (bumpVector_5.xy * _FringeBumpScaler);
				float3 tmpvar_10;
				tmpvar_10 = normalize(bumpVector_5);
				bumpVector_5 = tmpvar_10;
				float tmpvar_11;
				tmpvar_11 = abs(dot ((
					((i.uv2 * tmpvar_10.x) + (i.uv3 * tmpvar_10.y))
					+ 
					(i.uv4 * tmpvar_10.z)
				), normalize(i.uv1)));
				cs_4 = tmpvar_11;
				half tmpvar_12;
				tmpvar_12 = (1.570796 - (sign(cs_4) * (1.570796 - 
					(sqrt((1.0 - abs(cs_4))) * (1.570796 + (abs(cs_4) * (-0.2146018 + 
						(abs(cs_4) * (0.08656672 + (abs(cs_4) * -0.03102955)))
					))))
				)));
				float tmpvar_13;
				tmpvar_13 = float(((tmpvar_12 * _FringeRangeScaler) + _FringeRangeOffset));
				uv_3 = float2(tmpvar_13, tmpvar_13);
				float tmpvar_14;
				float cs_15;
				cs_15 = cs_4;
				float power_16;
				power_16 = _FringeFresnel.x;
				float scale_17;
				scale_17 = _FringeFresnel.y;
				float bias_18;
				bias_18 = _FringeFresnel.z;
				tmpvar_14 = (bias_18 + (pow (
					clamp ((1.0 - cs_15), 0.0, 1.0)
				, power_16) * scale_17));
				f_2 = tmpvar_14;
				fixed4 tmpvar_19;
				tmpvar_19 = tex2D (_FringeTex, uv_3);
				float3 tmpvar_20;
				tmpvar_20 = (((tmpvar_19 * _FringeIntensity) * f_2) * (tmpvar_10.y + 0.5)).xyz;
				fringeColor_1 = tmpvar_20;
				outColor_7.xyz = ((outColor_7.xyz + fringeColor_1) - (outColor_7.xyz * fringeColor_1));
				outColor_7.xyz = (outColor_7.xyz * (_EmissionScaler * _EmissionScalerScalerWithoutHDR));
				float tmpvar_21;
				tmpvar_21 = max (min ((
					((i.color1.y * f_2) * (tmpvar_10.y + 0.5))
					* 3.0), 1.0), _MinAlpha);
				outColor_7.w = tmpvar_21;
				if (bool(_UsingDitherAlpha)) {
					half4 scrpos_22;
					scrpos_22 = i.uv5;
					half a_23;
					a_23 = i.uv5.z;
					if ((a_23 < 0.95)) {
						scrpos_22.xy = ((i.uv5.xy / i.uv5.w) * _ScreenParams.xy);
						a_23 = (a_23 * 17.0);
						float tmpvar_24;
						tmpvar_24 = (scrpos_22.y / 4.0);
						float tmpvar_25;
						tmpvar_25 = (frac(abs(tmpvar_24)) * 4.0);
						float tmpvar_26;
						if ((tmpvar_24 >= 0.0)) {
							tmpvar_26 = tmpvar_25;
						} else {
							tmpvar_26 = -(tmpvar_25);
						};
						float tmpvar_27;
						tmpvar_27 = (scrpos_22.x / 4.0);
						float tmpvar_28;
						tmpvar_28 = (frac(abs(tmpvar_27)) * 4.0);
						float tmpvar_29;
						if ((tmpvar_27 >= 0.0)) {
							tmpvar_29 = tmpvar_28;
						} else {
							tmpvar_29 = -(tmpvar_28);
						};
						float x_30;
						x_30 = ((a_23 - _DITHERMATRIX[
							int(tmpvar_26)
						][
							int(tmpvar_29)
						]) - 0.01);
						if ((x_30 < 0.0)) {
							discard;
						};
					};
				};
				return outColor_7;
			}			
			ENDCG					
		}
		Pass {
			Tags { "IGNOREPROJECTOR" = "true" "OutlineType" = "None" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
			ColorMask A 
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			struct a2v {
				float4 vertex : POSITION;
			};

			struct v2f {
				float4 pos : SV_POSITION;
			};

			fixed _BloomFactor;
			
			v2f vert(a2v v)
			{
				v2f o;
				half4 tmpvar_1;
				tmpvar_1.w = 1.0;
				tmpvar_1.xyz = v.vertex.xyz;
				o.pos = UnityObjectToClipPos(tmpvar_1);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				half4 color_1;
				color_1.xyz = half3(0.0, 0.0, 0.0);
				color_1.w = _BloomFactor;
				return color_1;
			}		
			ENDCG
		}
	}
}