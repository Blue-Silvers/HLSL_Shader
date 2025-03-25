Shader "Custom/S_MultiLineShader" //change path for schear in material
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white"{}
        _Color("Color", Color) = (1,1,1,1)
        _Start("Start", float) = 0.4
        _Width("Width", float) = 0.6
        _Amount("Amount", int) = 1
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
            uniform half4 _Color;
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform float _Start;
            uniform float _Width;
            uniform int _Amount;

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

           VertexOutput vert (VertexInput v)
           {
               VertexOutput o;
               o.vertex = UnityObjectToClipPos(v.vertex);
               o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);               return o;
           }

           float drawLine(float2 uv)
           {
               float lineCycle = 1.0/_Amount;
               if(uv.x % lineCycle > _Start && uv.x % lineCycle < _Width)
              {
                  return 1;
              }
              return 0;
           }

           half4 frag (VertexOutput i) : COLOR
           {
               float4 color = tex2D(_MainTex, i.texcoord) * _Color;
               color.a = drawLine(i.texcoord);
               return color;
           }

           ENDCG
        }
    }
}
