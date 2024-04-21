Shader "FFF/Water"
{
    Properties
    {
        _noise ("Noise", 2D) = "white" {}
        _voronoi ("Voronoi", 2D) = "white" {}
        _color1 ("Color1", Color) = (1, 1, 1, 1)
        _color2 ("Color2", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        GrabPass 
        {
            "_BackgroundTexture"
        }
        Pass 
        {
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            #include "UnityCG.cginc"

            sampler2D _noise;
            sampler2D _BackgroundTexture;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                // float2 uv : TEXCOORD0;
                float4 grabPos : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _noise);
                o.grabPos = ComputeGrabScreenPos(o.pos);

                float4 noise = tex2Dlod(_noise, float4(v.uv.xy, 0, 0));
                o.grabPos.y += sin(_Time * 5 * noise) * 1 * 1;
                o.grabPos.x += cos(_Time * 5 * noise) * 1 * 1;

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return tex2Dproj(_BackgroundTexture, i.grabPos);
            }
            ENDCG
        }
        Pass 
        {
            Blend One One
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            sampler2D _voronoi;
            sampler2D _noise;
            float4 _voronoi_ST;
            float4 _color1;
            float4 _color2;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float4 worldVertex : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _voronoi);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex);

                float4 noise = tex2Dlod(_noise, float4(v.uv.xy, 0, 0));
                o.uv.y += sin(_Time * 5 * noise) * 1 * 1;
                o.uv.x += cos(_Time * 5 * noise) * 1 * 1;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 normalDir = normalize(i.worldNormal);
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldVertex));
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldVertex));

                // sampling 
                float4 voronoi = tex2D(_voronoi, i.uv / 10);
                float4 noise = tex2D(_noise, i.uv/ 10);

                // specular
                float3 reflectionVec = reflect(-lightDir, normalDir);
                float vDotR = max(0.0, dot(viewDir, reflectionVec));
                float3 spec = pow(vDotR, 48);
                float4 specularTerm = float4(spec, 1) * _LightColor0;
                specularTerm *= noise;

                return lerp(_color1, _color2, voronoi) + specularTerm;
            }
            ENDCG
        }
    }
}
