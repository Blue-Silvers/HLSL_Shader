Shader "Custom/S_NormalFoamAndGradientWaveShader" //change path for schear in material
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Gradient("Gradient Texture", 2D) = "white" {}
        _FirstColor("First Color", Color) = (1,1,1,1)
        _SecondColor("Second Color", Color) = (1,1,1,1)
        _NormalTex1("Normal Texture 1", 2D) = "bump" {}
        _NormalTex2("Normal Texture 2", 2D) = "bump" {}
        _HeightFactor("Height Factor", float) = 0.1
        _Speed("Speed", vector) = (1,2,3)
        _Frequency("Frequency", vector) = (1,2,3)
        _Amplitude("Amplitude", float) = 0.1
        _WaveDirection("Wave Direction", vector) = (1,1,1)
        _GradientSensivity("Gradient Sensitivity", Range(0, 1)) = 1
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777
        _FoamDistance("Foam Distance", float) = 1
        _LightDir("Fake Light Direction", vector) = (1, 1, 1)
        _NormalStrength("Normal Strength", Range(0, 2)) = 1
    }

    SubShader
    {
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
        }

        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex, _Gradient, _NormalTex1, _NormalTex2, _CameraDepthTexture;
            float4 _MainTex_ST, _Gradient_ST;
            float4 _FirstColor, _SecondColor, _FoamColor;
            float _HeightFactor, _Amplitude, _GradientSensivity;
            float4 _Speed, _Frequency, _WaveDirection;
            float _SurfaceNoiseCutoff, _FoamDistance;
            float4 _LightDir;
            float _NormalStrength;

            struct VertexInput {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 gradcoord : TEXCOORD2;
            };

            struct VertexOutput {
                float4 vertex : SV_POSITION;
                float4 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float displacement : DISPLACEMENT;
                float4 gradcoord : TEXCOORD2;
                float4 screenPosition : TEXCOORD4;
            };

            float4 vertexAnimWave(float4 pos, float2 uv)
            {
                pos.y += sin((uv.x - _Time.y * _Speed.y) * _Frequency.y) * (1 - uv.x) * _Amplitude;
                pos.x += _Speed.x != 0 ? sin((uv.y - _Time.y * _Speed.x) * _Frequency.x) * _Amplitude : 0;
                pos.z += _Speed.z != 0 ? sin((uv.x - _Time.y * _Speed.z) * _Frequency.z) * _Amplitude : 0;
                return pos;
            }

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.gradcoord.xy = v.gradcoord.xy * _Gradient_ST.xy + _Gradient_ST.zw;

                v.vertex = vertexAnimWave(v.vertex, v.texcoord.xy);
                v.texcoord.xy += _Time.x * _WaveDirection;

                o.texcoord.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                o.displacement = tex2Dlod(_MainTex, float4(v.texcoord.xy * _MainTex_ST.xy, 0, 0));
                o.vertex = UnityObjectToClipPos(v.vertex + v.normal * o.displacement * _HeightFactor);

                o.displacement += v.vertex.y;
                o.screenPosition = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag(VertexOutput i) : SV_Target
            {
                float4 color1 = i.displacement * _FirstColor;
                float4 color2 = (1 - i.displacement) * _SecondColor;
                float4 color = color1 + color2 + i.displacement;
                color.a = sqrt(1 - i.gradcoord.x * _GradientSensivity);

                // Normals
                float3 normal1 = UnpackNormal(tex2D(_NormalTex1, i.texcoord.xy));
                float3 normal2 = UnpackNormal(tex2D(_NormalTex2, i.texcoord.xy + float2(_Time.x * 0.05, _Time.x * 0.07)));
                float3 finalNormal = normalize(lerp(normal1, normal2, 0.5));
                float3 lightDir = normalize(_LightDir);
                float normalLight = saturate(dot(finalNormal, lightDir)) * _NormalStrength;
                color.rgb *= lerp(0.5, 1.0, normalLight);

                // Foam
                float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition)).r;
                float existingDepthLinear = LinearEyeDepth(existingDepth01);
                float depthDifference = existingDepthLinear - i.screenPosition.w;
                float4 surfaceNoiseSample = tex2D(_MainTex, i.texcoord.xy);
                float foamDepthDifference01 = saturate(depthDifference / _FoamDistance);
                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;
                float surfaceNoise = surfaceNoiseSample.r > surfaceNoiseCutoff ? 1 : 0;

                color.rgb += surfaceNoise * _FoamColor.rgb;
                color.a += surfaceNoise * _FoamColor.a;

                return color;
            }
            ENDCG
        }
    }
}