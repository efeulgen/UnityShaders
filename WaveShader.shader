Shader "FFF/WaveShader"
{
      Properties 
      {
            [Header(Main Texture)]
            _MainTex ("Main Texture", 2D) = "white" {}
            _MainTexUniTiling ("Main Texture Uniform Tiling", Range(0,50)) = 0

            [Header(Wave 1)]
            _Freq1 ("Wave 1 Frequency", Range(0, 10)) = 1
            _Amp1 ("Wave 1 Amplitude", Range(0, 10)) = 1
            _Speed1 ("Wave 1 Speed", Range(1, 30)) = 1
            _Freq1_Min ("Wave 1 Minor Frequency", Range(0, 10)) = 1
            _Amp1_Min ("Wave 1 Minor Amplitude", Range(0, 10)) = 1
            _Speed1_Min ("Wave 1 Minor Speed", Range(1, 30)) = 1
            _WaveRot1 ("Wave 1 Rotation (Rad)", Range(0, 6.283)) = 0

            [Header(Wave 2)]
            _Freq2 ("Wave 2 Frequency", Range(0, 10)) = 1
            _Amp2 ("Wave 2 Amplitude", Range(0, 10)) = 1
            _Speed2 ("Wave 2 Speed", Range(1, 30)) = 1
            _WaveRot2 ("Wave 2 Rotation (Rad)", Range(0, 6.283)) = 0

            //[Header(Foam)]
            //_FoamColor ("Foam Color", Color) = (1,1,1,1)

            [Header(Sunshine)]
            _SpecColor ("Specular Color", Color) = (1,1,1,1)
            _PerlinNoise ("Perlin Noise", 2D) = "white" {}
            _Shininess ("Shininess", Range(1, 60)) = 1
            _Speed ("Speed", Range(1,20)) = 10
            _Scalar1 ("Sunshine Motion Scalar 1", Range(0.1,10)) = 0.25
            _Scalar2 ("Sunshine Motion Scalar 2", Range(0.1,10)) = 0.25
            _Scalar3 ("Sunshine Motion Scalar 3", Range(0.1,10)) = 0.25
            _Scalar4 ("Sunshine Motion Scalar 4", Range(0.1,10)) = 0.25

            [Header(Depth)]
            _WaterDepthColor ("Water Depth Color", Color) = (1,1,1,1)
            _WaterDepth ("Water Depth", Range(0.01,1)) = 1
      }
      SubShader 
      {
            Tags { "Queue"="Transparent" }
            CGPROGRAM
            #pragma target 4.0
            #pragma surface surf Lambert vertex:vert alpha:fade

            float4 RotateAroundY(float4 vec, float radian)
            {
                  float s = sin(radian);
                  float c = cos(radian);
                  float4x4 rotMat = float4x4(c, 0, s, 0,
                                             0, 1, 0, 0,
                                            -s, 0, c, 0,
                                             0, 0, 0, 1);
                  return mul(rotMat, vec);
            } 

            sampler2D _MainTex, _PerlinNoise, _CameraDepthTexture;
            float _MainTexUniTiling;
            float _Freq1, _Freq1_Min, _Freq2, _Amp1, _Amp1_Min, _Amp2, _Speed1, _Speed1_Min, _Speed2, _WaveRot1, _WaveRot2;
            fixed4 _FoamColor, _WaterDepthColor;
            float _Shininess, _Scalar1, _Scalar2, _Scalar3, _Scalar4, _Speed, _WaterDepth;
            
            struct Input {
                  float2 uv_MainTex;
                  float3 viewDir;
                  float3 worldPos;
                  float3 vertColor;
                  float4 screenPos;
            };

            struct appdata {
                  float4 vertex : POSITION;
                  float3 normal : NORMAL;
                  float4 texcoord : TEXCOORD0;
                  float4 texcoord1 : TEXCOORD1;
                  float4 texcoord2 : TEXCOORD2;
            };

            void vert(inout appdata v, out Input o)
            {
                  UNITY_INITIALIZE_OUTPUT(Input, o);
                  float rotatedX = RotateAroundY(v.vertex, _WaveRot1).x;
                  float rotatedZ = RotateAroundY(v.vertex, _WaveRot2).z;
                  float wave1 = sin(rotatedX * _Freq1 + _Time * _Speed1) * _Amp1 + sin(rotatedX * _Freq1_Min + _Time * _Speed1_Min) * _Amp1_Min; 
                  float wave2 = sin(rotatedZ * _Freq2 + _Time * _Speed2) * _Amp2;
                  v.vertex.y += wave1;
                  v.vertex.y += wave2;

                  o.vertColor = max(0.75, wave1 + 0.5);
            }

            void surf(Input IN, inout SurfaceOutput o)
            {
                  float3 lightDir = normalize(UnityWorldSpaceLightDir(IN.worldPos));
                  float3 reflectDir = reflect(-lightDir, o.Normal);
                  float vr = max(0, dot(IN.viewDir, reflectDir));
                  float spec = pow(vr, _Shininess);

                  float4 tex = tex2D(_MainTex, IN.uv_MainTex * _MainTexUniTiling);
                  float4 pNoise = tex2D(_PerlinNoise, IN.uv_MainTex);

                  // sunshine motion 
                  float t = _Time * _Speed;
                  float c = sin(IN.worldPos.x * _Scalar1); 
                  c += sin(IN.worldPos.z * _Scalar2);
                  c += sin(_Scalar3 * (IN.worldPos.x * sin(t) + IN.worldPos.z * cos(t)));
                  float c1 = pow(IN.worldPos.x + sin(t), 2);
                  float c2 = pow(IN.worldPos.z + cos(t), 2);
                  c += sin(sqrt(_Scalar4 * (c1 + c2)));
                  
                  fixed3 finalCol = lerp(tex * IN.vertColor, _SpecColor, spec * saturate(c) * pNoise);

                  // depth 
                  float2 screenSpaceUVs = IN.screenPos.xy / IN.screenPos.w;
                  float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenSpaceUVs));
                  float surface = UNITY_Z_0_FAR_FROM_CLIPSPACE(IN.screenPos.z);
                  float depthDifference = (depth - surface);
                  float depthFallOff = pow(2, -depthDifference * _WaterDepth);
                  finalCol = lerp(finalCol, _WaterDepthColor, depthFallOff);

                  o.Albedo = finalCol;
                  o.Alpha = 1 - depthFallOff;
            }
            ENDCG
      }
}
