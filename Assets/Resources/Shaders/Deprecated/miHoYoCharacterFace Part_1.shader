Shader "miHoYo/Character/Face Part" {
	Properties {
		_Color ("Main Color", Color) = (0.5,0.5,0.5,1)
		_BloomFactor ("Bloom Factor", Float) = 1
		_EmissionFactor ("Emission Factor", Range(0, 10)) = 1
		_MainTex ("Base (RGB)", 2D) = "white" { }
		_ColorToOffset ("Color To Tune", Color) = (0,0,0,0)
		_ColorTolerance ("Color Tolerance", Range(0.01, 1)) = 0
		_HueOffset ("Hue Offset", Range(0, 1)) = 0
		_SaturateOffset ("Satureate Offset", Range(-1, 1)) = 0
		_ValueOffset ("Value Offset", Range(-1, 1)) = 0
		[Toggle(USINGDITHERALPAH)] _UsingDitherAlpha ("UsingDitherAlpha", Float) = 0
		_DitherAlpha ("Dither Alpha Value", Range(0, 1)) = 1		
	}
	SubShader {
		Tags { "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
		Pass {
			Name "BASE"
			Tags { "IGNOREPROJECTOR" = "true" "RenderPipeline" = "UniversalPipeline"  "LightMode" = "UniversalForward" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
			Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Offset -2, -2

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
				fixed2 color0 : COLOR1;
				half2 uv0  : TEXCOORD0;
				float3 uv1  : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
			};

			fixed4 _Color;
			fixed4 _ColorToOffset;
			fixed _ColorTolerance;

			sampler2D _MainTex;			
			fixed4 _MainTex_ST;

			fixed _UsingDitherAlpha;
			fixed _DitherAlpha;

			fixed _HueOffset;
			fixed _SaturateOffset;
			fixed _ValueOffset;

			fixed _EmissionFactor;

			fixed _lightProbToggle;
			fixed4 _lightProbColor;

			uniform fixed4x4 _DITHERMATRIX;

			v2f vert(a2v v)
			{
				v2f o;

				half2 tmpvar_1;
				float4 tmpvar_2;
				tmpvar_2 = float4(0.0, 0.0, 0.0, 0.0);
				float4 tmpvar_3;
				float4 tmpvar_4;
				tmpvar_4.w = 1.0;
				tmpvar_4.xyz = v.vertex.xyz;
				tmpvar_3 = UnityObjectToClipPos(tmpvar_4);
				tmpvar_1 = TRANSFORM_TEX(v.texcoord, _MainTex);
				fixed maxChannel_5;
				fixed minChannel_6;
				half3 HSV_7;
				if ((_ColorToOffset.y < _ColorToOffset.x)) {
					maxChannel_5 = _ColorToOffset.x;
					minChannel_6 = _ColorToOffset.y;
				} else {
					maxChannel_5 = _ColorToOffset.y;
					minChannel_6 = _ColorToOffset.x;
				};
				if ((maxChannel_5 < _ColorToOffset.z)) {
					maxChannel_5 = _ColorToOffset.z;
				};
				if ((_ColorToOffset.z < minChannel_6)) {
					minChannel_6 = _ColorToOffset.z;
				};
				HSV_7.xy = half2(0.0, 0.0);
				HSV_7.z = maxChannel_5;
				fixed tmpvar_8;
				tmpvar_8 = (maxChannel_5 - minChannel_6);
				if ((tmpvar_8 != 0.0)) {
					half3 delRGB_9;
					HSV_7.y = (tmpvar_8 / HSV_7.z);
					delRGB_9 = (((HSV_7.zzz - _ColorToOffset) + (3.0 * tmpvar_8)) / (6.0 * tmpvar_8));
					if ((_ColorToOffset.x == HSV_7.z)) {
						HSV_7.x = (delRGB_9.z - delRGB_9.y);
					} else {
						if ((_ColorToOffset.y == HSV_7.z)) {
							HSV_7.x = ((0.3333333 + delRGB_9.x) - delRGB_9.z);
						} else {
							if ((_ColorToOffset.z == HSV_7.z)) {
								HSV_7.x = ((0.6666667 + delRGB_9.y) - delRGB_9.x);
							};
						};
					};
				};
				if (bool(_UsingDitherAlpha)) {
					float4 o_10;
					float4 tmpvar_11;
					tmpvar_11 = (tmpvar_3 * 0.5);
					float2 tmpvar_12;
					tmpvar_12.x = tmpvar_11.x;
					tmpvar_12.y = (tmpvar_11.y * _ProjectionParams.x);
					o_10.xy = (tmpvar_12 + tmpvar_11.w);
					o_10.zw = tmpvar_3.zw;
					tmpvar_2.xyw = o_10.xyw;
					tmpvar_2.z = _DitherAlpha;
				};
				o.pos = tmpvar_3;
				o.color0 = fixed4(0.0, 0.0, 0.0, 0.0);
				o.uv0 = tmpvar_1;
				o.uv1 = HSV_7;
				o.uv2 = tmpvar_2;

				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				float4 tmpvar_1;
				half4 outColor_2;
				fixed4 tmpvar_3;
				tmpvar_3 = tex2D (_MainTex, i.uv0);
				outColor_2 = tmpvar_3;
				half3 RGB_4;
				RGB_4 = outColor_2.xyz;
				fixed maxChannel_5;
				fixed minChannel_6;
				half3 HSV_7;
				if ((outColor_2.y < outColor_2.x)) {
					maxChannel_5 = RGB_4.x;
					minChannel_6 = RGB_4.y;
				} else {
					maxChannel_5 = RGB_4.y;
					minChannel_6 = RGB_4.x;
				};
				if ((maxChannel_5 < outColor_2.z)) {
					maxChannel_5 = RGB_4.z;
				};
				if ((outColor_2.z < minChannel_6)) {
					minChannel_6 = RGB_4.z;
				};
				HSV_7.xy = half2(0.0, 0.0);
				HSV_7.z = maxChannel_5;
				fixed tmpvar_8;
				tmpvar_8 = (maxChannel_5 - minChannel_6);
				if ((tmpvar_8 != 0.0)) {
					half3 delRGB_9;
					HSV_7.y = (tmpvar_8 / HSV_7.z);
					delRGB_9 = (((HSV_7.zzz - outColor_2.xyz) + (3.0 * tmpvar_8)) / (6.0 * tmpvar_8));
					if ((outColor_2.x == HSV_7.z)) {
						HSV_7.x = (delRGB_9.z - delRGB_9.y);
					} else {
						if ((outColor_2.y == HSV_7.z)) {
							HSV_7.x = ((0.3333333 + delRGB_9.x) - delRGB_9.z);
						} else {
							if ((outColor_2.z == HSV_7.z)) {
								HSV_7.x = ((0.6666667 + delRGB_9.y) - delRGB_9.x);
							};
						};
					};
				};
				half3 x_10;
				x_10 = (HSV_7 - i.uv1);
				half3 tmpvar_11;
				tmpvar_11.x = frac((HSV_7.x + _HueOffset));
				tmpvar_11.y = clamp ((HSV_7.y + _SaturateOffset), 0.0, 1.0);
				tmpvar_11.z = clamp ((HSV_7.z + _ValueOffset), 0.0, 1.0);
				half3 tmpvar_12;
				tmpvar_12 = lerp (tmpvar_11, HSV_7, float((
					sqrt(dot (x_10, x_10))
					>= _ColorTolerance)));
				fixed var_3_13;
				fixed var_2_14;
				fixed var_1_15;
				fixed var_h_16;
				half3 RGB_17;
				RGB_17 = tmpvar_12.zzz;
				half tmpvar_18;
				tmpvar_18 = (tmpvar_12.x * 6.0);
				var_h_16 = tmpvar_18;
				fixed tmpvar_19;
				tmpvar_19 = floor(var_h_16);
				half tmpvar_20;
				tmpvar_20 = (tmpvar_12.z * (1.0 - tmpvar_12.y));
				var_1_15 = tmpvar_20;
				half tmpvar_21;
				tmpvar_21 = (tmpvar_12.z * (1.0 - (tmpvar_12.y * 
					(var_h_16 - tmpvar_19)
				)));
				var_2_14 = tmpvar_21;
				half tmpvar_22;
				tmpvar_22 = (tmpvar_12.z * (1.0 - (tmpvar_12.y * 
					(1.0 - (var_h_16 - tmpvar_19))
				)));
				var_3_13 = tmpvar_22;
				if ((tmpvar_19 == 0.0)) {
					half3 tmpvar_23;
					tmpvar_23.x = tmpvar_12.z;
					tmpvar_23.y = var_3_13;
					tmpvar_23.z = var_1_15;
					RGB_17 = tmpvar_23;
				} else {
					if ((tmpvar_19 == 1.0)) {
						half3 tmpvar_24;
						tmpvar_24.x = var_2_14;
						tmpvar_24.y = tmpvar_12.z;
						tmpvar_24.z = var_1_15;
						RGB_17 = tmpvar_24;
					} else {
						if ((tmpvar_19 == 2.0)) {
							half3 tmpvar_25;
							tmpvar_25.x = var_1_15;
							tmpvar_25.y = tmpvar_12.z;
							tmpvar_25.z = var_3_13;
							RGB_17 = tmpvar_25;
						} else {
							if ((tmpvar_19 == 3.0)) {
								half3 tmpvar_26;
								tmpvar_26.x = var_1_15;
								tmpvar_26.y = var_2_14;
								tmpvar_26.z = tmpvar_12.z;
								RGB_17 = tmpvar_26;
							} else {
								if ((tmpvar_19 == 4.0)) {
									half3 tmpvar_27;
									tmpvar_27.x = var_3_13;
									tmpvar_27.y = var_1_15;
									tmpvar_27.z = tmpvar_12.z;
									RGB_17 = tmpvar_27;
								} else {
									half3 tmpvar_28;
									tmpvar_28.x = tmpvar_12.z;
									tmpvar_28.y = var_1_15;
									tmpvar_28.z = var_2_14;
									RGB_17 = tmpvar_28;
								};
							};
						};
					};
				};
				outColor_2.xyz = ((RGB_17 * _Color.xyz) * _EmissionFactor);
				half3 color_29;
				color_29 = outColor_2.xyz;
				half3 tmpvar_30;
				if ((_lightProbToggle > 0.5)) {
					tmpvar_30 = _lightProbColor.xyz;
				} else {
					tmpvar_30 = half3(1.0, 1.0, 1.0);
				};
				color_29 = (outColor_2.xyz * tmpvar_30);
				outColor_2.xyz = color_29;
				if (bool(_UsingDitherAlpha)) {
					float4 scrpos_31;
					scrpos_31 = i.uv2;
					half a_32;
					a_32 = i.uv2.z;
					if ((a_32 < 0.95)) {
						scrpos_31.xy = ((i.uv2.xy / i.uv2.w) * _ScreenParams.xy);
						a_32 = (a_32 * 17.0);
						float tmpvar_33;
						tmpvar_33 = (scrpos_31.y / 4.0);
						float tmpvar_34;
						tmpvar_34 = (frac(abs(tmpvar_33)) * 4.0);
						float tmpvar_35;
						if ((tmpvar_33 >= 0.0)) {
							tmpvar_35 = tmpvar_34;
						} else {
							tmpvar_35 = -(tmpvar_34);
						};
						float tmpvar_36;
						tmpvar_36 = (scrpos_31.x / 4.0);
						float tmpvar_37;
						tmpvar_37 = (frac(abs(tmpvar_36)) * 4.0);
						float tmpvar_38;
						if ((tmpvar_36 >= 0.0)) {
							tmpvar_38 = tmpvar_37;
						} else {
							tmpvar_38 = -(tmpvar_37);
						};
						float x_39;
						x_39 = ((a_32 - _DITHERMATRIX[
							int(tmpvar_35)
						][
							int(tmpvar_38)
						]) - 0.01);
						if ((x_39 < 0.0)) {
							discard;
						};
					};
				};
				tmpvar_1 = outColor_2;
				return tmpvar_1;
			}
			ENDCG
		}
		Pass {
			Name "CONSTANT_REPLACE"
			Tags { "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
			ColorMask A
			ZWrite Off
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			struct a2v {
				float4 vertex : POSITION;
				fixed4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv0  : TEXCOORD0;
				float2 uv2 : TEXCOORD2;
			};

			sampler2D _MainTex;			
			fixed4 _MainTex_ST;

			fixed _UsingBloomMask;

			sampler2D _BloomMask;
			fixed4 _BloomMask_ST;
			fixed _BloomFactor;

			v2f vert(a2v v)
			{
				v2f o;

				float2 tmpvar_1;
				half2 tmpvar_2;
				float4 tmpvar_3;
				float4 tmpvar_4;
				tmpvar_4.w = 1.0;
				tmpvar_4.xyz = v.vertex.xyz;
				tmpvar_3 = UnityObjectToClipPos(tmpvar_4);
				tmpvar_1 = TRANSFORM_TEX(v.texcoord, _MainTex);
				if (bool(_UsingBloomMask)) {
					tmpvar_2 = TRANSFORM_TEX(v.texcoord, _BloomMask);
				};
				o.pos = tmpvar_3;
				o.uv0 = tmpvar_1;
				o.uv2 = tmpvar_2;

				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				half4 color_1;
				color_1.xyz = half3(0.0, 0.0, 0.0);
				fixed x_2;
				x_2 = (tex2D (_MainTex, i.uv0).w - 0.01);
				if ((x_2 < 0.0)) {
					discard;
				};
				color_1.w = _BloomFactor;
				return color_1;
			}			
			ENDCG
		}
	}
	Fallback "Diffuse"
}