//This shader will assume you already enabled DepthTexture in URP setting
//All important lines have comments, lines without comments are just regular shader code
Shader "JustOutputCameraDepthTexture"
{
	SubShader
	{
		Pass
		{			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "NiloCameraDepthTextureUtil.hlsl" // (3), include this for easy coding here

			struct VertexInput
			{
				float3 posOS : POSITION;
			};

			struct VertexOutput
			{
				float4 posCS : SV_POSITION;

				float4 screenPos : TEXCOORD0; // (1), add a float4 varying for screenPos
			};

			VertexOutput vert (VertexInput v)
			{
				VertexOutput o;

				o.posCS = TransformObjectToHClip(v.posOS);

				o.screenPos = ComputeScreenPos(o.posCS); // (2), calculate screenPos in vertex shader, pass screenPos to fragment shader using (1)

				return o;
			}

			half4 frag (VertexOutput IN) : SV_Target
			{
				float linear01Depth = SampleSceneLinear01Depth(IN.screenPos); // (4), use screenPos to SampleSceneLinear01Depth
				float linearEyeDepth = SampleSceneLinearEyeDepth(IN.screenPos);

				
				//(1)render linear01Depth
				//return linear01Depth;

				//(2)render linearEyeDepth
				//return linearEyeDepth;

				//(3)will render the same value as linear01Depth
				//because "linear01Depth * cameraFarPlane" equals linearEyeDepth
				float cameraFarPlane = _ProjectionParams.z;
				return linearEyeDepth / cameraFarPlane;
			}

			ENDHLSL
		}
	}
}