Shader "Unlit/CarToonShader"
{
	Properties
	{
		_BaseColor ("BaseColor", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		

		

		//Tone Based Shading
		[MaterialToggle] _Is_LightColor_1st_Shade ("Is_LightColor_1st_Shade", Float ) = 1
		_1st_ShadeColor ("1st_ShadeColor", Color) = (1,1,1,1)
		_1st_ShadeMap ("1st_ShadeMap", 2D) = "white" {}
        

		 [MaterialToggle] _Is_LightColor_2nd_Shade ("Is_LightColor_2nd_Shade", Float ) = 1
		_2nd_ShadeColor ("2nd_ShadeColor", Color) = (1,1,1,1)
		_2nd_ShadeMap ("2nd_ShadeMap", 2D) = "white" {}
       
	    _Set_ShadePosition ("Set_ShadePosition", 2D) = "white" {}
		_BaseColor_Step ("BaseColor_Step", Range(0, 1)) = 0.6
        _BaseShade_Feather ("Base/Shade_Feather", Range(0.0001, 1)) = 0.0001
		_ShadeColor_Step ("ShadeColor_Step", Range(0, 1)) = 0.4
        _1st2nd_Shades_Feather ("1st/2nd_Shades_Feather", Range(0.0001, 1)) = 0.0001

		//hair
		 _MatCap_Sampler ("MatCap_Sampler", 2D) = "black" {}
         _MatCapColor ("MatCapColor", Color) = (1,1,1,1)
		 _NormalMapForMatCap ("NormalMapForMatCap", 2D) = "bump" {}
		 _Tweak_MatCapUV ("Tweak_MatCapUV", Range(-0.5, 0.5)) = 0
         _Rotate_MatCapUV ("Rotate_MatCapUV", Range(-1, 1)) = 0
		 _Rotate_NormalMapForMatCapUV ("Rotate_NormalMapForMatCapUV", Range(-1, 1)) = 0

		//Rim
		[MaterialToggle] _Is_LightColor_RimLight ("Is_LightColor_RimLight", Float ) = 1
        _RimLightColor ("RimLightColor", Color) = (1,1,1,1)
        _RimLight_Power ("RimLight_Power", Range(0, 1)) = 0.1

		//Specular
		[MaterialToggle] _Is_LightColor_HighColor ("Is_LightColor_HighColor", Float ) = 1
		[MaterialToggle] _Is_SpecularToHighColor ("Is_SpecularToHighColor", Float ) = 0
		_HighColor ("HighColor", Color) = (0,0,0,1)
		_HighColor_Power ("HighColor_Power", Range(0, 1)) = 0
		_HighColor_Tex ("HighColor_Tex", 2D) = "white" {}

		//Outline
		//[KeywordEnum(NML,POS)] _OUTLINE("OUTLINE MODE", Float) = 0
		_Outline_Width ("Outline_Width", Float ) = 1
        _Farthest_Distance ("Farthest_Distance", Float ) = 10
        _Nearest_Distance ("Nearest_Distance", Float ) = 0.5
        _Outline_Sampler ("Outline_Sampler", 2D) = "white" {}
		//_OutlineTex ("OutlineTex", 2D) = "white" {}
        _Outline_Color ("Outline_Color", Color) = (0.5,0.5,0.5,1)
		_Offset_Z ("Offset_Camera_Z", Float) = 0
	}
	SubShader
	{
		
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Name "Outline"
			Cull Front 
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile _OUTLINE_NML _OUTLINE_POS
			
			#include "UnityCG.cginc"

			uniform float _Outline_Width;
            uniform float _Farthest_Distance;
            uniform float _Nearest_Distance;
			uniform sampler2D _Outline_Sampler; uniform float4 _Outline_Sampler_ST;
			//uniform sampler2D _OutlineTex; uniform float4 _OutlineTex_ST;
			uniform float4 _Outline_Color;
			uniform float _Offset_Z;

			struct VertexInput
			{
				float4 vertex : POSITION;
				float2 texcoord0 : TEXCOORD0;
			};

			struct VertexOutput
			{
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
			};

			VertexOutput vert (VertexInput v)
			{
				VertexOutput o = (VertexOutput)0;
				
				float2 Set_UV0 = v.texcoord0;
				float4 _Outline_Sampler_var = tex2Dlod(_Outline_Sampler,float4(TRANSFORM_TEX(Set_UV0, _Outline_Sampler),0.0,0));
				float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1));
				float3 length = smoothstep( _Farthest_Distance, _Nearest_Distance, distance(objPos.rgb,_WorldSpaceCameraPos))*_Outline_Sampler_var.rgb;
				float Set_Outline_Width = _Outline_Width*0.001*length.r*2;

				float3 viewDirection = _WorldSpaceCameraPos.xyz - o.pos.xyz;
                float4 viewDirectionVP = mul(UNITY_MATRIX_VP, float4(viewDirection.xyz, 1));
				
                o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + normalize(v.vertex)*Set_Outline_Width,1) );
				_Offset_Z = _Offset_Z * -0.01;
				o.pos.z = o.pos.z + _Offset_Z*viewDirectionVP.z;
				return o;
			}
			
			fixed4 frag (VertexOutput i) : SV_Target
			{
				fixed4 col = _Outline_Color;
				return col;
			}
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags {
                "LightMode"="ForwardBase"
            }
			CGPROGRAM

			#pragma vertex vert 			
			#pragma fragment frag 

			#include "UnityCG.cginc" 
			#include "AutoLight.cginc"
            #include "Lighting.cginc"

            uniform float4 _RimLightColor;
            uniform fixed _Is_LightColor_RimLight;
			uniform float _RimLight_Power;
			

			uniform fixed _Is_LightColor_HighColor;
			uniform fixed _Is_SpecularToHighColor;
			uniform float _HighColor_Power;
			uniform float4 _HighColor;
            uniform sampler2D _HighColor_Tex; uniform float4 _HighColor_Tex_ST;

			uniform float4 _BaseColor;
			uniform sampler2D _MainTex;uniform float4 _MainTex_ST;

			uniform sampler2D _1st_ShadeMap; uniform float4 _1st_ShadeMap_ST;
            uniform float4 _1st_ShadeColor;
			uniform fixed _Is_LightColor_1st_Shade;

			uniform sampler2D _2nd_ShadeMap; uniform float4 _2nd_ShadeMap_ST;
            uniform float4 _2nd_ShadeColor;
			uniform fixed _Is_LightColor_2nd_Shade;

			uniform sampler2D _Set_ShadePosition; uniform float4 _Set_ShadePosition_ST;

			uniform float _BaseColor_Step;
            uniform float _BaseShade_Feather;

			uniform float _ShadeColor_Step;
            uniform float _1st2nd_Shades_Feather;

			uniform sampler2D _MatCap_Sampler; uniform float4 _MatCap_Sampler_ST;
            uniform float4 _MatCapColor;
			uniform sampler2D _NormalMapForMatCap; uniform float4 _NormalMapForMatCap_ST;
            uniform float _Rotate_NormalMapForMatCapUV;
			uniform float _Tweak_MatCapUV;
            uniform float _Rotate_MatCapUV;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord0 : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
			};

			

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv0 = v.texcoord0;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float2 Set_UV0 = i.uv0;
				UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);
				float3 lightColor = _LightColor0.rgb;//*attenuation
				i.normalDir = normalize(i.normalDir);

		
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float3 halfDirection = normalize(viewDirection+lightDirection);

				float _Specular_var = 0.5*dot(halfDirection,i.normalDir)+0.5;
				float3 _SpecularColor =  pow(_Specular_var,_HighColor_Power);
				float3 _SpecularColor_1 = 1.0 - step(_Specular_var,(1.0 - _HighColor_Power));
				float3 _SpecularColor_2 = pow(_Specular_var,exp2(lerp(11,1,_HighColor_Power)));
				_SpecularColor = lerp(_SpecularColor_1,_SpecularColor_2,_Is_SpecularToHighColor);

				float4 _HighColor_Tex_var = tex2D(_HighColor_Tex,TRANSFORM_TEX(Set_UV0, _HighColor_Tex));
				float3 _HighColor_var = lerp( _HighColor_Tex_var.rgb*_HighColor.rgb, _HighColor_Tex_var.rgb*_HighColor.rgb*lightColor,_Is_LightColor_HighColor);


				float3 _Is_LightColor_RimLight_var = lerp( _RimLightColor.rgb, (_RimLightColor.rgb*lightColor), _Is_LightColor_RimLight );
				float _RimArea_var = (1.0 - dot(i.normalDir,viewDirection));
                float _RimLightPower_var = pow(_RimArea_var,exp2(lerp(3,0,_RimLight_Power)));

				float4 _BaseMap_var = tex2D(_MainTex,TRANSFORM_TEX(Set_UV0, _MainTex));
				float3 Set_BaseColor = _BaseColor.rgb*_BaseMap_var.rgb;

				float4 _1st_ShadeMap_var = tex2D(_1st_ShadeMap,TRANSFORM_TEX(Set_UV0, _1st_ShadeMap));
                float3 Set_1st_ShadeColor = lerp( (_1st_ShadeColor.rgb*_1st_ShadeMap_var.rgb), ((_1st_ShadeColor.rgb*_1st_ShadeMap_var.rgb)*lightColor), _Is_LightColor_1st_Shade );
                float4 _2nd_ShadeMap_var = tex2D(_2nd_ShadeMap,TRANSFORM_TEX(Set_UV0, _2nd_ShadeMap));
                float3 Set_2nd_ShadeColor = lerp( (_2nd_ShadeColor.rgb*_2nd_ShadeMap_var.rgb), ((_2nd_ShadeColor.rgb*_2nd_ShadeMap_var.rgb)*lightColor), _Is_LightColor_2nd_Shade );
			    float _HalfLambert_var = 0.5*dot(i.normalDir,lightDirection)+0.5;
				float4 _Set_ShadePosition_var = tex2D(_Set_ShadePosition,TRANSFORM_TEX(Set_UV0, _Set_ShadePosition));
				float offsetColor1 = (_BaseColor_Step-_BaseShade_Feather);
                float Set_FinalShadowSample = saturate((1.0 + ( (_HalfLambert_var - offsetColor1) * ((1.0 - _Set_ShadePosition_var.rgb).r - 1.0) ) / (_BaseColor_Step - offsetColor1)));
                float offsetColor2 = (_ShadeColor_Step-_1st2nd_Shades_Feather);
                float3 _FinalColor_var = lerp(Set_BaseColor,lerp(Set_1st_ShadeColor,Set_2nd_ShadeColor,
                saturate((1.0 + ( (_HalfLambert_var - offsetColor2) * ((1.0 - _Set_ShadePosition_var.rgb).r - 1.0) ) / (_ShadeColor_Step - offsetColor2)))),
                Set_FinalShadowSample); 

				float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float _Rot_MatCapUV_var_ang = (_Rotate_MatCapUV*3.141592654);
                float _Rot_MatCapUV_var_spd = 1.0;
                float _Rot_MatCapUV_var_cos = cos(_Rot_MatCapUV_var_spd*_Rot_MatCapUV_var_ang);
                float _Rot_MatCapUV_var_sin = sin(_Rot_MatCapUV_var_spd*_Rot_MatCapUV_var_ang);
                float2 _Rot_MatCapUV_var_piv = float2(0.5,0.5);
                float _Rot_MatCapNmUV_var_ang = (_Rotate_NormalMapForMatCapUV*3.141592654);
                float _Rot_MatCapNmUV_var_spd = 1.0;
                float _Rot_MatCapNmUV_var_cos = cos(_Rot_MatCapNmUV_var_spd*_Rot_MatCapNmUV_var_ang);
                float _Rot_MatCapNmUV_var_sin = sin(_Rot_MatCapNmUV_var_spd*_Rot_MatCapNmUV_var_ang);
                float2 _Rot_MatCapNmUV_var_piv = float2(0.5,0.5);
                float2 _Rot_MatCapNmUV_var = (mul(Set_UV0-_Rot_MatCapNmUV_var_piv,float2x2( _Rot_MatCapNmUV_var_cos, -_Rot_MatCapNmUV_var_sin, _Rot_MatCapNmUV_var_sin, _Rot_MatCapNmUV_var_cos))+_Rot_MatCapNmUV_var_piv);
                float3 _NormalMapForMatCap_var = UnpackNormal(tex2D(_NormalMapForMatCap,TRANSFORM_TEX(_Rot_MatCapNmUV_var, _NormalMapForMatCap)));
                float2 _ViewNormalAsMatCapUV = (mul(UNITY_MATRIX_V, float4(lerp( i.normalDir, mul( _NormalMapForMatCap_var.rgb, tangentTransform ).rgb, 1 ),0) ).rg*0.5+0.5);
                float2 _Rot_MatCapUV_var = (mul((0.0 + ((_ViewNormalAsMatCapUV - (0.0+_Tweak_MatCapUV)) * (1.0 - 0.0) ) / ((1.0-_Tweak_MatCapUV) - (0.0+_Tweak_MatCapUV)))-_Rot_MatCapUV_var_piv,float2x2( _Rot_MatCapUV_var_cos, -_Rot_MatCapUV_var_sin, _Rot_MatCapUV_var_sin, _Rot_MatCapUV_var_cos))+_Rot_MatCapUV_var_piv);
                float4 _MatCap_Sampler_var = tex2D(_MatCap_Sampler,TRANSFORM_TEX(_Rot_MatCapUV_var, _MatCap_Sampler));

				float3 finalColor =  _FinalColor_var + _MatCap_Sampler_var.rgb*_MatCapColor.rgb  +    _HighColor_var*_SpecularColor + _RimLightPower_var*_Is_LightColor_RimLight_var;

			
				fixed4 finalRGBA = fixed4(finalColor,1);

				return finalRGBA;
			}
			ENDCG
		}
	}
}
