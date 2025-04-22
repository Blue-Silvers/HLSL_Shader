Shader "Custom/S_Ghost"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white"{}
        _FirstColor("FirstColor", Color) = (1,1,1,1)
        _SecondColor("SecondColor", Color) = (1,1,1,1)
        _Speed("Speed", float) = 0.1
        _Frequency("Frequency", float) = 0.1
        _Amplitude("Amplitude", float) = 0.1
    }
    SubShader
    {
        Tags{
        "Queue" = "Transparent"
        "RenderType" = "Transparent"
        "IgnoreProjector" = "True"
        }

        LOD 100
        CULL Off
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
            uniform float _Speed;
            uniform float _Frequency;
            uniform float _Amplitude;
            #include "UnityCG.cginc"

            struct VertexInput //appdata
            {
                float4 vertex : POSITION;
                float4 texcoord: TEXCOORD0;

            };

           struct VertexOutput//v2f
           {
               float4 vertex : SV_POSITION;
               float4 texcoord: TEXCOORD0;
           };

           float4 vertexAnimFlag(float4 pos, float2 uv)
           {
                pos.z = pos.z + sin((uv.x - _Time.y * _Speed) * _Frequency)* uv.x * _Amplitude;

                return pos;
           }

           VertexOutput vert (VertexInput v)
           {
               VertexOutput o;
               v.vertex = vertexAnimFlag(v.vertex, v.texcoord.xy); 
               o.vertex = UnityObjectToClipPos(v.vertex);
               o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);

               return o;
           }

           half4 frag (VertexOutput i) : COLOR
           {
               float4 color1 = tex2D(_MainTex, i.texcoord) * _SecondColor;
                color1.a = i.texcoord.x;
                float4 color2 = tex2D(_MainTex, i.texcoord) * _FirstColor;
                color2.a = 1 - i.texcoord.x;
                float4 color = tex2D(_MainTex, i.texcoord) * half4((color1.x*color1.a + color2.x*color2.a), (color1.y*color1.a + color2.y*color2.a), (color1.z*color1.a + color2.z*color2.a), (color1.a + color2.a));
                
               return tex2D(_MainTex, i.texcoord) * color;
           }

           ENDCG
        }
    }
}
