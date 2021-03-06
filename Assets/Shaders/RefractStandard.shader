﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/RefractStandard" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Transparency ("Transparency", Range(0,1)) = 1
		_Refraction ("Refraction", Range(0,1)) = 0.1
		_RefractionColor ("Refraction Color", Color) = (1,1,1,1)
		_EmissionColor ("Emission Color", Color) = (0,0,0,1)
		[Toggle(WAVE)] _Wave("Wave mesh", Float) = 0
		_WaveStrength("Waving Strength", Float) = 1.0
		_WaveSpeed("Waving Speed", Float) = 1.0
		_WaveScale("Waving Scale", Float) = 1.0
	}
	SubShader {
		Tags { "Queue"="Transparent" "RenderType"="Transparent" }

		LOD 200
		GrabPass { "_GrabTex" }

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		#include "Waving.cginc"
		#pragma shader_feature WAVE

		sampler2D _MainTex;

		struct Input {
			float4 screenPos; // for refraction
			float3 worldPos;
		};

		void vert (inout appdata_full v) {
			#ifdef WAVE
				if (ShouldWave(v.color.r))
				{
					float3 normal;
					v.vertex.xyz += mul(unity_WorldToObject, WaveVertex2D(mul(unity_ObjectToWorld, v.vertex), v.color.r, normal));
					v.normal = UnityWorldToObjectDir(normal);
				}
			#endif
      }

		half _Glossiness;
		half _Metallic;
		half _Transparency;
		half _Refraction;
		fixed4 _Color;
		fixed4 _EmissionColor;
		fixed4 _RefractionColor;
        sampler2D _GrabTex;
		float4 _GrabTex_TexelSize;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			//fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			float3 worldNormal = WorldNormalVector(IN, o.Normal);
			float3 viewNormal = normalize(mul((float3x3)UNITY_MATRIX_V, worldNormal));

			//float3 viewDir = normalize(mul((float3x3)UNITY_MATRIX_V, IN.worldPos));
			//float3 viewCross = cross(viewDir, viewNormal);
			//viewNormal = float3(-viewCross.y, viewCross.x, 0);
			
			half rimValue = 0;

			if (UNITY_MATRIX_P[3][3] > 0)
			{
				rimValue = viewNormal.z;
				IN.screenPos.xy -= viewNormal.xy * _Refraction * 0.05;
			}
			else
			{
				half3 viewDirection = normalize(_WorldSpaceCameraPos - IN.worldPos);
				rimValue = dot(viewDirection, worldNormal);
				IN.screenPos.xy -= viewNormal.xy * _Refraction;
			}

			half transparency = saturate(1 - _Transparency + 1 - rimValue);
			o.Albedo = _Color.rgb * transparency;
            o.Emission = tex2Dproj(  _GrabTex, UNITY_PROJ_COORD(IN.screenPos)).rgb * (1 - transparency) * _RefractionColor + _EmissionColor;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = 1;
		}
		ENDCG
	}
}
