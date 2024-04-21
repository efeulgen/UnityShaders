Shader "FFF/StylizedSpecularShader"
{
    Properties
    {
        _baseColor ("Base Color", Color) = (1, 1, 1, 1)
        _reflectionColor ("Reflection Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" }
        Pass 
        {
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            float4 _baseColor;
            float4 _reflectionColor;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertexClip : SV_POSITION;
                float4 vertexWorld : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertexClip = UnityObjectToClipPos(v.vertex);
                o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 normalDir = normalize(i.worldNormal);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.vertexWorld));
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.vertexWorld));

                // diffuse term 
                float nDotL = max(0.0, dot(normalDir, lightDir));
                float4 diffuseTerm =  nDotL < 0.5 ? float4(_reflectionColor / 5) * _LightColor0 : _baseColor * _LightColor0;

                // specular term
                float3 reflectionVec = reflect(-lightDir, normalDir);
                float vDotR = max(0.0, dot(viewDir, reflectionVec));
                float4 specularTerm = vDotR > 0.7 ? float4(_reflectionColor) : float4(0, 0, 0, 1);

                // rim term
                float vDotN = 1 - max(0, dot(viewDir, normalDir));
                float4 rimTerm = vDotN > 0.85 ? float4(_reflectionColor / 2) : float4(0, 0, 0, 1);

                return diffuseTerm + specularTerm + rimTerm;
            }

            ENDCG
        }
    }
}