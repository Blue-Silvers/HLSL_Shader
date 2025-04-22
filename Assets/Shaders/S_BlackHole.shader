Shader "Custom/S_GalaxyShader"
{
    Properties
    {
        _SpiralTex("SpiralTexture", 2D) = "white" {}
        _StarTex("StarBackground", 2D) = "white" {}
        _CoreColor("CoreColor", Color) = (1, 0.95, 0.9, 1)
        _ArmTint("ArmTint", Color) = (0.6, 0.7, 1, 1)
        _RotationSpeed("RotationSpeed", float) = 0.1
        _Zoom("Zoom", float) = 1.5
        _CoreSize("CoreSize", float) = 0.2
        _ArmSharpness("ArmSharpness", float) = 4
        _GlowFalloff("Glow", float) = 3
        _BlackHoleRadius("BlackHoleRadius", float) = 0.05
        _BlackHoleWarp("BlackHoleStrength", float) = 0.2
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

        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _SpiralTex;
            sampler2D _StarTex;

            float4 _CoreColor;
            float4 _ArmTint;
            float _RotationSpeed;
            float _Zoom;
            float _CoreSize;
            float _ArmSharpness;
            float _GlowFalloff;
            float _BlackHoleRadius;
            float _BlackHoleWarp;

            #include "UnityCG.cginc"

            struct VertexInput //appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VertexOutput //v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 centeredUV : TEXCOORD1;
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.centeredUV = v.uv * 2 - 1;
                return o;
            }

            float2 RotateUV(float2 uv, float angle)
            {
                float s = sin(angle);
                float c = cos(angle);
                return float2(
                    uv.x * c - uv.y * s,
                    uv.x * s + uv.y * c
                );
            }

            fixed4 frag(VertexOutput i) : SV_Target
            {
                float2 centeredUV = i.centeredUV * _Zoom;
                float dist = length(centeredUV);

                float blackHoleEffect = smoothstep(_BlackHoleRadius * 1.5, _BlackHoleRadius, dist);
                centeredUV += normalize(centeredUV) * _BlackHoleWarp * blackHoleEffect;

                dist = length(centeredUV);
                float2 rotated = normalize(centeredUV) * dist;

                float angle = atan2(rotated.y, rotated.x);
                angle -= _Time.y * _RotationSpeed;

                // Spiral arms
                float2 spiralUV = float2(cos(angle), sin(angle)) * dist * 0.5 + 0.5;
                float arm = tex2D(_SpiralTex, spiralUV).r;

                // Star background
                float stars = tex2D(_StarTex, i.uv + float2(sin(_Time.y), cos(_Time.y)) * 0.01).r;

                float core = exp(-pow(dist / _CoreSize, _GlowFalloff));
                float armIntensity = pow(arm, _ArmSharpness);

                float3 color = _CoreColor.rgb * core + _ArmTint.rgb * armIntensity;

                float blackHoleMask = 1.0 - smoothstep(0.0, _BlackHoleRadius, dist);
                color *= blackHoleMask;
                color += stars;

                float alpha = saturate(core + armIntensity + stars * 0.5) * blackHoleMask;

                return float4(color, alpha);

            }
            ENDCG
        }
    }
}