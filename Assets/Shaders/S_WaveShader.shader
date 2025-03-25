Shader "Custom/S_WaveShader" //change path for schear in material
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white"{}
        _FirstColor("FirstColor", Color) = (1,1,1,1)
        _SecondColor("SecondColor", Color) = (1,1,1,1)
        _HeightFactor("HeightFactor", float) = 0.1
        _Speed("Speed", float) = 1
        _Frequency("Frequency", float) = 5
        _Amplitude("Amplitude", float) = 0.1
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
            uniform half4 _FirstColor;
            uniform half4 _SecondColor;
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform float _HeightFactor;
            uniform float _Speed;
            uniform float _Frequency;
            uniform float _Amplitude;
            uniform vector _WaveDirection;

            #include "UnityCG.cginc"

            struct VertexInput //appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

           struct VertexOutput//v2f
           {
               float4 vertex : SV_POSITION;
               float4 normal : NORMAL;
               float4 texcoord : TEXCOORD0;
               float displacement : DISPLACEMENT;
           };

           float4 vertexAnimFlag(float4 pos, float2 uv)
           {
                pos.y = pos.y + sin((uv.x - _Time.y * _Speed) * _Frequency) * _Amplitude;
                return pos;
           }

           VertexOutput vert (VertexInput v)
           {
               VertexOutput o;

               v.vertex = vertexAnimFlag(v.vertex, v.texcoord.xy); 
               v.texcoord.xy +=_Time.x * _WaveDirection;

               o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);


               o.displacement = tex2Dlod(_MainTex, v.texcoord* _MainTex_ST);
               o.vertex = UnityObjectToClipPos(v.vertex + (v.normal * o.displacement * _HeightFactor));

               o.displacement += v.vertex.y;
               return o;
           }

           half4 frag (VertexOutput i) : COLOR
           {
                float4 color1 = i.displacement * _FirstColor;
                float4 color2 = (1-i.displacement) * _SecondColor;

                float4 color = color1 + color2 + i.displacement;
                return color;
           }

           ENDCG
        }
    }
}