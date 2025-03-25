Shader "Custom/S_MonochromeShader" //change path for schear in material
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work

            #include "UnityCG.cginc"

            fixed4 _Color;

            struct VertexInput //appdata
            {
                float4 vertex : POSITION;
            };

           struct VertexOutput//v2f
           {
               float4 vertex : SV_POSITION;
           };

           VertexOutput vert (VertexInput v)
           {
               VertexOutput o;
               o.vertex = UnityObjectToClipPos(v.vertex);
               return o;
           }

           fixed4 frag (VertexOutput i) : SV_Target
           {
               return _Color;
           }
           ENDCG
        }
    }
}
