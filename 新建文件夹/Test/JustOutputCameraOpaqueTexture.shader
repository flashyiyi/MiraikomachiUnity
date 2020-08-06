Shader "JustOutputCameraOpaqueTexture"
{
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent" //if you want to sample camera opaque texture, must write this line, because camera opaque texture is not yet ready until rendering enters transparent queue
		}
		Pass
		{
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "NiloCameraOpaqueTextureUtil.hlsl" // (3), include this for easy coding here

			struct VertexInput
			{
				float3 vertex : POSITION;
			};

			struct VertexOutput
			{
				float4 posCS : SV_POSITION;

				float4 screenPos : TEXCOORD3; // (1), add a float4 varying for screenPos
			};			

			VertexOutput vert (VertexInput v)
			{
				VertexOutput o;
				o.posCS = TransformObjectToHClip(v.vertex);
	
				o.screenPos = ComputeScreenPos(o.posCS); // (2), calculate screenPos in vertex shader, pass screenPos to fragment shader using (1)

				return o;
			}

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				float2 uvOffset = frac(sin(IN.screenPos * 2345) * 4567) * 0.03;//optional: some simple random noise only for this demo shader

				return float4(SampleSceneOpaqueColor(IN.screenPos,uvOffset),1);	 //(4) sample camera opaque texture	
			}

			ENDHLSL
		}
	}
}
