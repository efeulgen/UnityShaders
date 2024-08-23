Shader "FFF/ScribbleShader"
{
    Properties
    {
        _baseColor ("BaseColor", Color) = (1, 1, 1, 1)
        _linesColor ("Lines Color", Color) = (0.15, 0.15, 0.15, 1)
        _cutoff ("CutOff", Range(0, 1)) = 0.5
        _lineFrequency ("Line Frequency", Range(20, 100)) = 50
        _lineThickness ("Line Thickness", Range(0.1, 1)) = 0.4

        _PerliNoise ("Perlin Noise", 2D) = "white" {} 
        _DistortionAmount ("Distortion Amount", Range(0,5)) = 1
        _NoiseUniformTiling ("NoiseUniformTiling", Range(1, 20)) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            float4 _baseColor, _linesColor;
            float _cutoff, _lineFrequency, _lineThickness, _DistortionAmount, _NoiseUniformTiling;
            sampler2D _PerliNoise;
            float4 _PerliNoise_ST;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float4 worldVertex : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _PerliNoise);
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // sample texture 
                fixed4 noise = tex2D(_PerliNoise, i.uv * _NoiseUniformTiling);

                // diffuse term
                float3 normalDir = normalize(i.worldNormal);
                float3 ligthDir = normalize(UnityWorldSpaceLightDir(i.worldVertex));

                
                float nDotL = 1- max(0.0f, dot(normalDir, ligthDir));
                float4 diffuseTerm;
                if (nDotL > _cutoff)
                {
                    float4 pattern1 = frac(i.worldVertex.x * _lineFrequency) > _lineThickness * noise * _DistortionAmount ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern2 = frac(i.worldVertex.y * _lineFrequency) > _lineThickness * noise * _DistortionAmount ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern = saturate(pattern1 * pattern2);
                    diffuseTerm = (_baseColor / 4) * pattern;
                }
                else if (nDotL > _cutoff / 2)
                {
                    float4 pattern1 = frac(i.worldVertex.x * (_lineFrequency + 20)) > _lineThickness / 2 * noise * _DistortionAmount ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern2 = frac(i.worldVertex.y * (_lineFrequency + 20)) > _lineThickness / 2 * noise * _DistortionAmount ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern = saturate(pattern1 * pattern2);
                    diffuseTerm = (_baseColor / 2) * pattern;
                }
                else if (nDotL > _cutoff / 4)
                {
                    float4 pattern = frac(i.worldVertex.y * (_lineFrequency + 40)) > _lineThickness / 4 * noise * _DistortionAmount ? float4(1, 1, 1, 1) : float4(_linesColor);
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
        Pass
        {
            Tags { "LightMode"="ForwardAdd" }
            Blend One One
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            float4 _baseColor, _linesColor;
            float _cutoff, _lineFrequency, _lineThickness, _DistortionAmount, _NoiseUniformTiling;
            sampler2D _PerliNoise;
            float4 _PerliNoise_ST;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float4 worldVertex : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _PerliNoise);
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // sample texture 
                fixed4 noise = tex2D(_PerliNoise, i.uv * _NoiseUniformTiling);

                // diffuse term
                float3 normalDir = normalize(i.worldNormal);
                float3 ligthDir = normalize(UnityWorldSpaceLightDir(i.worldVertex));
                
                float nDotL = 1- max(0.0f, dot(normalDir, ligthDir));
                float4 diffuseTerm;
                if (nDotL > _cutoff)
                {
                    float4 pattern1 = frac(i.worldVertex.x * _lineFrequency) > _lineThickness * noise * _DistortionAmount ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern2 = frac(i.worldVertex.y * _lineFrequency) > _lineThickness * noise * _DistortionAmount ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern = saturate(pattern1 * pattern2);
                    diffuseTerm = (_baseColor / 4) * pattern;
                }
                else if (nDotL > _cutoff / 2)
                {
                    float4 pattern1 = frac(i.worldVertex.x * (_lineFrequency + 20)) > _lineThickness / 2 * noise * _DistortionAmount ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern2 = frac(i.worldVertex.y * (_lineFrequency + 20)) > _lineThickness / 2 * noise * _DistortionAmount ? float4(1, 1, 1, 1) : float4(_linesColor);
                    float4 pattern = saturate(pattern1 * pattern2);
                    diffuseTerm = (_baseColor / 2) * pattern;
                }
                else if (nDotL > _cutoff / 4)
                {
                    float4 pattern = frac(i.worldVertex.y * (_lineFrequency + 40)) > _lineThickness / 4 * noise * _DistortionAmount ? float4(1, 1, 1, 1) : float4(_linesColor);
                    diffuseTerm = (_baseColor / 1.2) * pattern;
                }
                else 
                {
                    diffuseTerm = _baseColor;
                }
                return diffuseTerm / 3;
            }
            ENDCG
        }
    }
}
