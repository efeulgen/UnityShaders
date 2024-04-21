Shader "FFF/ScribbleShader"
{
    Properties
    {
        _baseColor ("BaseColor", Color) = (1, 1, 1, 1)
        _linesColor ("Lines Color", Color) = (0.15, 0.15, 0.15, 1)
        _cutoff ("CutOff", Range(0, 1)) = 0.5
        _lineFrequency ("Line Frequency", Range(20, 100)) = 50
        _lineThickness ("Line Thickness", Range(0.1, 1)) = 0.4
    }
    SubShader
    {
        Tags { "RenderType" = "ForwardBase" }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            float4 _baseColor;
            float4 _linesColor;
            float _cutoff;
            float _lineFrequency;
            float _lineThickness;

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
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float nDotL = 1 - dot(normalize(i.worldNormal), _WorldSpaceLightPos0.xyz);

                float4 diffuseTerm;
                if (nDotL > _cutoff)
                {
                    float4 pattern1 = frac(i.worldVertex.x * _lineFrequency) > _lineThickness ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern2 = frac(i.worldVertex.y * _lineFrequency) > _lineThickness ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern = pattern1 * pattern2;
                    diffuseTerm = (_baseColor / 4) * pattern;
                }
                else if (nDotL > _cutoff / 2)
                {
                    float4 pattern1 = frac(i.worldVertex.x * (_lineFrequency + 20)) > _lineThickness / 2 ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern2 = frac(i.worldVertex.y * (_lineFrequency + 20)) > _lineThickness / 2 ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern = pattern1 * pattern2;
                    diffuseTerm = (_baseColor / 2) * pattern;
                }
                else if (nDotL > _cutoff / 4)
                {
                    float4 pattern = frac(i.worldVertex.y * (_lineFrequency + 40)) > _lineThickness / 4 ? float4(1, 1, 1, 1) : float4(_linesColor);
                    diffuseTerm = (_baseColor / 1.2) * pattern;
                }
                else 
                {
                    diffuseTerm = _baseColor;
                }
                return diffuseTerm;
            }
            ENDCG
        }
    }
}
