Shader "FFF/ScreenSpaceCheckerBoardShader"
{
    Properties 
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _DivAmount ("Checker DivisionAmount", Range(2,500)) = 2
        _CutOff ("NdotL Cut Off", Range(0,1)) = 0.6

        _PerlinNoise ("PerlinNoise", 2D) = "white" {} 
        _LightNoiseScale ("Light Noise Uniform Scale", Range(1, 100)) = 1
        _CheckerNoiseScale ("Checker Noise Uniform Scale", Range(0, 2)) = 1
    }
    SubShader 
    {
        Tags { "RenderType"="Opaque" }
        Pass 
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _PerlinNoise;
            float4 _PerlinNoise_ST;
            float4 _BaseColor;
            float _DivAmount, _LightNoiseScale, _CheckerNoiseScale, _CutOff, _ShadowBright;

            struct appdata {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD2;
                float4 vertexWorld : TEXCOORD3;
                float4 screenSpaceCoords : TEXCOORD4;
                SHADOW_COORDS(1)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _PerlinNoise);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
                o.screenSpaceCoords = ComputeScreenPos(o.pos);
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
                float3 normalDir = normalize(i.worldNormal);
                float3 lightDir = UnityWorldSpaceLightDir(i.vertexWorld);
                float2 screenSpaceUVs = i.screenSpaceCoords.xy / i.screenSpaceCoords.w;

                // tex sampling
                float4 lightNoise = tex2D(_PerlinNoise, i.uv * _LightNoiseScale);
                float4 checkerNoise = tex2D(_PerlinNoise, i.uv * _CheckerNoiseScale);

                fixed4 finalColor;

                float nl = 1 - max(0, dot(normalDir, lightDir));
                if (nl > (_CutOff * lightNoise.x))
                {
                    finalColor = _BaseColor / 4 * ((floor(screenSpaceUVs.x * _DivAmount * checkerNoise.x) + floor(screenSpaceUVs.y * _DivAmount * checkerNoise.x)) % 2);
                }
                else if (nl > (_CutOff / 2 * lightNoise.x))
                {
                    finalColor = _BaseColor / 2  * ((floor(screenSpaceUVs.x * _DivAmount * checkerNoise.x) + floor(screenSpaceUVs.y * _DivAmount * checkerNoise.x)) % 2);
                }
                else 
                {
                    finalColor = _BaseColor * (1 - nl);
                }

                // shadow
                fixed shadow = SHADOW_ATTENUATION(i);
                return finalColor * shadow;
            }
            ENDCG
        }
        Pass 
        {
            Tags { "LightMode"="ShadowCaster" }
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }
}
