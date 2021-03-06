﻿Shader "Custom/Auto3WayPlusTop" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_TopTex ("Top (RGB)", 2D) = "white" {}
		
		_StartValue("Start normal value (0 - bottom, 1 - top)", Range(-1,1)) = 0
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _TopTex;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		half _StartValue;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandard o) {

			float3 worldNormal = WorldNormalVector(IN, o.Normal);
			// Albedo comes from a texture tinted by color
			// use absolute value of normal as texture weights
            half3 blend = abs(worldNormal);
            // make sure the weights sum up to 1 (divide by sum of x+y+z)
            blend /= dot(blend,1.0);
            // read the three texture projections, for x,y,z axes
            fixed4 cx = tex2D(_MainTex, IN.worldPos.yz * 0.2);
            fixed4 cy = tex2D(_MainTex, IN.worldPos.xz * 0.2);
            fixed4 cz = tex2D(_MainTex, IN.worldPos.xy * 0.2);

			
			half mask = smoothstep(_StartValue, 1, worldNormal.y);

			blend *= (1 - mask);

            // blend the textures based on weights
            fixed4 c = cx * blend.x + cy * blend.y + cz * blend.z + mask * tex2D(_TopTex, IN.worldPos.xz * 0.2);
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = 1;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
