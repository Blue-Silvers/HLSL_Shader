Shader "Custom/S_ToonWaterShader" //change path for schear in material
{
    Properties
    {
        _NoiseTex("Main Texture", 2D) = "white"{}
        _ShallowColor("Depth Color Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DeepColor("Depth Color Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1

        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777
        _FoamDistance("FoamDistance", float) = 1

        _WaveDirection("WaveDirection", vector) = (1,1,1)

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
            uniform sampler2D _NoiseTex;
            uniform float4 _NoiseTex_ST;
            float4 _ShallowColor;
            float4 _DeepColor;
            float _DepthMaxDistance;
            sampler2D _CameraDepthTexture;
            float _SurfaceNoiseCutoff;
            float _FoamDistance;
            uniform vector _WaveDirection;

            #include "UnityCG.cginc"

            struct VertexInput //appdata
            {
                float4 vertex : POSITION;
                float4 uv: TEXCOORD0;

            };

           struct VertexOutput//v2f
           {
               float4 vertex : SV_POSITION;
               float2 noiseUV: TEXCOORD0;
               float4 screenPosition : TEXCOORD2;
           };

           VertexOutput vert (VertexInput v)
           {
               VertexOutput o;

               v.uv.xy +=_Time.x * _WaveDirection;

               o.vertex = UnityObjectToClipPos(v.vertex);
               o.screenPosition = ComputeScreenPos(o.vertex);
               o.noiseUV = TRANSFORM_TEX(v.uv, _NoiseTex);
               return o;
           }

           fixed4 frag (VertexOutput i) : SV_Target
           {
               float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition)).r;
               float existingDepthLinear = LinearEyeDepth(existingDepth01);

               float depthDifference = existingDepthLinear - i.screenPosition.w;

               float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
               float4 waterColor = lerp(_ShallowColor, _DeepColor, waterDepthDifference01);

               float4 surfaceNoiseSample = tex2D(_NoiseTex, i.noiseUV);
               float foamDepthDifference01 = saturate(depthDifference / _FoamDistance);
               float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;
               float surfaceNoise = surfaceNoiseSample > surfaceNoiseCutoff ? 1 : 0;

               return waterColor + surfaceNoise;
           }

           ENDCG
        }
    }
}
