Shader "FFF/ScribbleShader02"
{
    Properties
    {
        _baseColor ("Base Color", Color) = (1, 1, 1, 1)
        _ambient ("First Pass Ambient Term", Range(0.5, 1)) = 0.8
        _lineFrequency("Line Frequency", Range(100, 200)) = 100
    }
    SubShader 
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        Pass // diffuse pass
        {
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            fixed4 _baseColor;
            float _ambient;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                float nDotL = max(_ambient, dot(normalize(i.worldNormal), _WorldSpaceLightPos0.xyz));
                return nDotL * _baseColor;
            }

            ENDCG
        }
        Pass // scribbles pass
        {
            Blend DstColor Zero

            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            float _lineFrequency;
            fixed4 _baseColor;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float4 worldVertex : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                float nDotL = dot(normalize(i.worldNormal), _WorldSpaceLightPos0.xyz);
                fixed4 diffuseTerm;
                if (nDotL < 0.52 && nDotL >= 0.5)
                {
                    diffuseTerm = fixed4((_baseColor / 4).rgb, 1);
                }
                else if (nDotL < 0.5)
                {
                    fixed4 pattern1 = frac(i.worldVertex.x * _lineFrequency) > 0.4 ? fixed4(1, 1, 1, 1) : fixed4((_baseColor / 2).rgb, 1);
                    fixed4 pattern2 = frac(i.worldVertex.y * _lineFrequency) > 0.4 ? fixed4(1, 1, 1, 1) : fixed4((_baseColor / 2).rgb, 1);
                    diffuseTerm = pattern1 * pattern2;
                }
                else 
                {
                    diffuseTerm = fixed4(1, 1, 1, 1);
                }
                return diffuseTerm;
            }

            ENDCG
        }
    }
}
