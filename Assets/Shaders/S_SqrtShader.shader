Shader "Custom/S_SqrtShader" //change path for schear in material
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white"{}
        _SecondaryTex("Main Texture", 2D) = "white"{}
        _FirstColor("FirstColor", Color) = (1,1,1,1)
        _SecondColor("SecondColor", Color) = (1,1,1,1)
        _GradientSensivity("GradientSensivity", Range(0,100)) = 1
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
            uniform sampler2D _SecondaryTex;
            uniform float4 _SecondaryTex_ST;

            uniform float _GradientSensivity;

            #include "UnityCG.cginc"

            struct VertexInput //appdata
            {
                float4 vertex : POSITION;
                float4 texcoord: TEXCOORD0;
                float4 texcoord2: TEXCOORD1;
            };

           struct VertexOutput//v2f
           {
               float4 vertex : SV_POSITION;
               float4 texcoord: TEXCOORD0;
               float4 texcoord2: TEXCOORD1;
           };

           VertexOutput vert (VertexInput v)
           {
               VertexOutput o;
               o.vertex = UnityObjectToClipPos(v.vertex);
               o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);
               o.texcoord2.xy = (v.texcoord2.xy * _SecondaryTex_ST.xy + _SecondaryTex_ST.zw);
               return o;
           }

           half4 frag (VertexOutput i) : COLOR
           {
                float4 color1 = tex2D(_MainTex, i.texcoord) * _FirstColor;
                color1.a = 1 -  sqrt(i.texcoord.x*_GradientSensivity);
                float4 color2 = tex2D(_SecondaryTex, i.texcoord) * _SecondColor;
                color2.a = sqrt(i.texcoord.x*_GradientSensivity);
                float4 color = float4((color1.x*color1.a + color2.x*color2.a), (color1.y*color1.a + color2.y*color2.a), (color1.z*color1.a + color2.z*color2.a), (color1.a + color2.a));
                return color;
           }

           ENDCG
        }
    }
}
