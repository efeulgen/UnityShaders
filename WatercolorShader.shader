Shader "FFF/WatercolorShader"
{
    Properties
    {
        _baseColor ("Base Color", Color) = (1, 1, 1, 1)
        _outlineWidth ("Outline Width", Range(1, 5)) = 1.5
        _outlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _noise ("Noise", 2D) = "white" {}
        _tiling ("Noise Uniform Tiling", Range(0.1, 10)) = 1
    }
    SubShader
    {
        Pass // watercolor pass
        {
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            float4 _baseColor;
            sampler2D _noise;
            float4 _noise_ST;
            float _tiling;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexWorld : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _noise);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 normalDir = normalize(i.worldNormal);
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.vertexWorld));

                // sampling 
                float4 noise = tex2D(_noise, i.uv * _tiling + float2(viewDir.x, viewDir.x) / 10); 

                // diffuse 
                float nDotL = max(0.0, dot(normalDir, _WorldSpaceLightPos0.xyz));
                float4 diffuseTerm;
                if (nDotL < 0.5 * noise.r)
                {
                    diffuseTerm = lerp(_baseColor, _baseColor / 1.2, noise);
                }
                else 
                {
                    float scalar = nDotL > 0.7 ? 2 : 1.75;
                    diffuseTerm = lerp(_baseColor * scalar, _baseColor * 1.2, noise);
                }
                
                
                return diffuseTerm;
            }
            ENDCG
        }
        Pass // outline pass
        {
            ZWrite Off
            ZTest LEqual
            Cull Front

            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _outlineColor;
            float _outlineWidth;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex * _outlineWidth);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return _outlineColor;
            }
            ENDCG
        }
    }
}