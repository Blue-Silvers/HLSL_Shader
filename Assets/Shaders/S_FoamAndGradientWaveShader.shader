Shader "Custom/S_FoamAndGradientWaveShader" //change path for schear in material
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white"{}
        _Gradient("Gradient Texture", 2D) = "white"{}
        _FirstColor("FirstColor", Color) = (1,1,1,1)
        _SecondColor("SecondColor", Color) = (1,1,1,1)
        _HeightFactor("HeightFactor", float) = 0.1
        _Speed("Speed", vector) = (1,2,3)
        _Frequency("Frequency", vector) = (1,2,3)
        _Amplitude("Amplitude", float) = 0.1
        _WaveDirection("WaveDirection", vector) = (1,1,1)
        _GradientSensivity("GradientSensivity", Range(0, 1)) = 1

        // _ShallowColor("Depth Color Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        // _DeepColor("Depth Color Deep", Color) = (0.086, 0.407, 1, 0.749)
        // _DepthMaxDistance("Depth Maximum Distance", Float) = 1

        _FoamColor("FoamColor", Color) = (1,1,1,1)
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777
        _FoamDistance("FoamDistance", float) = 1
    }
    SubShader
    {
        Tags{
        "Queue" = "Transparent"
        "RenderType" = "Transparent"
        "IgnoreProjector" = "True"
        }

        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            uniform half4 _FirstColor;
            uniform half4 _SecondColor;
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform float _HeightFactor;
            uniform vector _Speed;
            uniform vector _Frequency;
            uniform float _Amplitude;
            uniform vector _WaveDirection;
            float _GradientSensivity;
            uniform sampler2D _Gradient;
            uniform float4 _Gradient_ST;

            // float4 _ShallowColor;
            // float4 _DeepColor;
            // float _DepthMaxDistance;
            uniform half4 _FoamColor;
            sampler2D _CameraDepthTexture;
            float _SurfaceNoiseCutoff;
            float _FoamDistance;

            #include "UnityCG.cginc"

            struct VertexInput //appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 gradcoord : TEXCOORD2;
            };

           struct VertexOutput//v2f
           {
               float4 vertex : SV_POSITION;
               float4 normal : NORMAL;
               float4 texcoord : TEXCOORD0;
               float displacement : DISPLACEMENT;
               float4 gradcoord : TEXCOORD2;
               float4 screenPosition : TEXCOORD4;
           };

           float4 vertexAnimWave(float4 pos, float2 uv)
           {
                //Wave
                pos.y = pos.y + sin((uv.x - _Time.y * _Speed.y) * _Frequency.y) * (1-uv.x) * _Amplitude; 
                //Advence Wave
                pos.x = _Speed.x != 0 ? pos.x + sin((uv.y - _Time.y * _Speed.x) * _Frequency.x) * _Amplitude : pos.x;
                pos.z = _Speed.z != 0 ? pos.z + sin((uv.x - _Time.y * _Speed.z) * _Frequency.z) * _Amplitude : pos.z;
                return pos;
           }

           VertexOutput vert (VertexInput v)
           {
               VertexOutput o;

               o.gradcoord.xy = (v.gradcoord.xy * _Gradient_ST.xy + _Gradient_ST.zw);

               v.vertex = vertexAnimWave(v.vertex, v.texcoord.xy); 
               v.texcoord.xy +=_Time.x * _WaveDirection;

               o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);

               o.displacement = tex2Dlod(_MainTex, v.texcoord* _MainTex_ST);
               o.vertex = UnityObjectToClipPos(v.vertex + (v.normal * o.displacement * _HeightFactor));

               o.displacement += v.vertex.y;

               o.screenPosition = ComputeScreenPos(o.vertex);

               return o;
           }

           half4 frag (VertexOutput i) : COLOR
           {
                float4 color1 = i.displacement * _FirstColor;
                float4 color2 = (1-i.displacement) * _SecondColor;

                float4 color = color1 + color2 + i.displacement;
                color.a = sqrt(1 - i.gradcoord.x * _GradientSensivity);

                //foam
                float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition)).r;
                float existingDepthLinear = LinearEyeDepth(existingDepth01);

                float depthDifference = existingDepthLinear - i.screenPosition.w;

                float4 surfaceNoiseSample = tex2D(_MainTex, i.texcoord);
                float foamDepthDifference01 = saturate(depthDifference / _FoamDistance);
                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;
                float surfaceNoise = surfaceNoiseSample > surfaceNoiseCutoff ? 1 : 0;
                //fix foam color
                color.x = color.x + surfaceNoise >= 1 ? _FoamColor.x : color.x + surfaceNoise;
                color.y = color.y + surfaceNoise >= 1 ? _FoamColor.y : color.y + surfaceNoise;
                color.z = color.z + surfaceNoise >= 1 ? _FoamColor.z : color.z + surfaceNoise;
                color.w = color.w + surfaceNoise >= 1 ? _FoamColor.w : color.w + surfaceNoise;

                //frag
                return color;
           }

           ENDCG
        }
    }
}