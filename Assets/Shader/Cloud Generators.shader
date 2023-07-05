Shader "Cloud"
{
    Properties
    {
        _Rotate_Projection("Rotate Projection", Vector) = (1, 0, 0, 0)
        _Noise_Scale("Noise Scale", Float) = 10
        _Noise_Speed("Noise Speed", Float) = 0.1
        _Noise_Height("Noise Height", Float) = 100
        _Noise_Remap("Noise Remap", Vector) = (0, 1, -1, 1)
        _Color_Peak("Color Peak", Color) = (1, 1, 1, 0)
        _Color_Valley("Color Valley", Color) = (0, 0, 0, 0)
        _Noise_Edge_1("Noise Edge 1", Float) = 0
        _Noise_Edge_2("Noise Edge 2", Float) = 0
        _Noise_Power("Noise Power", Float) = 2
        _Base_Scale("Base Scale", Float) = 1
        _Base_Speed("Base Speed", Float) = 1
        _Base_Strength("Base Strength", Float) = 1
        _Curvature_Radius("Curvature Radius", Float) = 0
        _Fade_Depth("Fade Depth", Float) = 100
        _Fresnel_Power("Fresnel Power", Float) = 0
        _Fresnel_Opacity("Fresnel Opacity", Float) = 0
        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Unlit"
            "Queue"="Transparent"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalUnlitSubTarget"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                // LightMode: <None>
            }
        
        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma shader_feature _ _SAMPLE_GI
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_UNLIT
        #define _FOG_FRAGMENT 1
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float4 ScreenPosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float3 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_497a2e0f842a4fbabb751afd99768403_Out_0 = _Color_Valley;
            float4 _Property_3b96c1b5e4b14013a0f04d97358b6c46_Out_0 = _Color_Peak;
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float4 _Lerp_ee4bf3f820d6483888ea36c55648a92e_Out_3;
            Unity_Lerp_float4(_Property_497a2e0f842a4fbabb751afd99768403_Out_0, _Property_3b96c1b5e4b14013a0f04d97358b6c46_Out_0, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxxx), _Lerp_ee4bf3f820d6483888ea36c55648a92e_Out_3);
            float _Property_43a927776d66480484cc4703cff32226_Out_0 = _Fresnel_Power;
            float _FresnelEffect_b33ef2f2ee8e4c928aa84d3e20ab1c4f_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_43a927776d66480484cc4703cff32226_Out_0, _FresnelEffect_b33ef2f2ee8e4c928aa84d3e20ab1c4f_Out_3);
            float _Multiply_ab18c233aa39410c93b22a5ca8f118ba_Out_2;
            Unity_Multiply_float_float(_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2, _FresnelEffect_b33ef2f2ee8e4c928aa84d3e20ab1c4f_Out_3, _Multiply_ab18c233aa39410c93b22a5ca8f118ba_Out_2);
            float _Property_c7fdd5c658144a9292b683dbc2e6e16a_Out_0 = _Fresnel_Opacity;
            float _Multiply_f898bd126c3848b0bea239c1c826ac5e_Out_2;
            Unity_Multiply_float_float(_Multiply_ab18c233aa39410c93b22a5ca8f118ba_Out_2, _Property_c7fdd5c658144a9292b683dbc2e6e16a_Out_0, _Multiply_f898bd126c3848b0bea239c1c826ac5e_Out_2);
            float4 _Add_6267cda7a3ed42608458dcf70ab091de_Out_2;
            Unity_Add_float4(_Lerp_ee4bf3f820d6483888ea36c55648a92e_Out_3, (_Multiply_f898bd126c3848b0bea239c1c826ac5e_Out_2.xxxx), _Add_6267cda7a3ed42608458dcf70ab091de_Out_2);
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.BaseColor = (_Add_6267cda7a3ed42608458dcf70ab091de_Out_2.xyz);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull Back
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Unlit"
            "Queue"="Transparent"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalUnlitSubTarget"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                // LightMode: <None>
            }
        
        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma shader_feature _ _SAMPLE_GI
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_UNLIT
        #define _FOG_FRAGMENT 1
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float4 ScreenPosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float3 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_497a2e0f842a4fbabb751afd99768403_Out_0 = _Color_Valley;
            float4 _Property_3b96c1b5e4b14013a0f04d97358b6c46_Out_0 = _Color_Peak;
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float4 _Lerp_ee4bf3f820d6483888ea36c55648a92e_Out_3;
            Unity_Lerp_float4(_Property_497a2e0f842a4fbabb751afd99768403_Out_0, _Property_3b96c1b5e4b14013a0f04d97358b6c46_Out_0, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxxx), _Lerp_ee4bf3f820d6483888ea36c55648a92e_Out_3);
            float _Property_43a927776d66480484cc4703cff32226_Out_0 = _Fresnel_Power;
            float _FresnelEffect_b33ef2f2ee8e4c928aa84d3e20ab1c4f_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_43a927776d66480484cc4703cff32226_Out_0, _FresnelEffect_b33ef2f2ee8e4c928aa84d3e20ab1c4f_Out_3);
            float _Multiply_ab18c233aa39410c93b22a5ca8f118ba_Out_2;
            Unity_Multiply_float_float(_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2, _FresnelEffect_b33ef2f2ee8e4c928aa84d3e20ab1c4f_Out_3, _Multiply_ab18c233aa39410c93b22a5ca8f118ba_Out_2);
            float _Property_c7fdd5c658144a9292b683dbc2e6e16a_Out_0 = _Fresnel_Opacity;
            float _Multiply_f898bd126c3848b0bea239c1c826ac5e_Out_2;
            Unity_Multiply_float_float(_Multiply_ab18c233aa39410c93b22a5ca8f118ba_Out_2, _Property_c7fdd5c658144a9292b683dbc2e6e16a_Out_0, _Multiply_f898bd126c3848b0bea239c1c826ac5e_Out_2);
            float4 _Add_6267cda7a3ed42608458dcf70ab091de_Out_2;
            Unity_Add_float4(_Lerp_ee4bf3f820d6483888ea36c55648a92e_Out_3, (_Multiply_f898bd126c3848b0bea239c1c826ac5e_Out_2.xxxx), _Add_6267cda7a3ed42608458dcf70ab091de_Out_2);
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.BaseColor = (_Add_6267cda7a3ed42608458dcf70ab091de_Out_2.xyz);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull Back
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define REQUIRE_DEPTH_TEXTURE
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 WorldSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Rotate_Projection;
        float _Noise_Scale;
        float _Noise_Speed;
        float _Noise_Height;
        float4 _Noise_Remap;
        float4 _Color_Peak;
        float4 _Color_Valley;
        float _Noise_Edge_1;
        float _Noise_Edge_2;
        float _Noise_Power;
        float _Base_Scale;
        float _Base_Speed;
        float _Base_Strength;
        float _Curvature_Radius;
        float _Fade_Depth;
        float _Fresnel_Power;
        float _Fresnel_Opacity;
        CBUFFER_END
        
        // Object and Global properties
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);
        
            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
        
            Axis = normalize(Axis);
        
            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };
        
            Out = mul(rot_mat,  In);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        
        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }
        
        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        {
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }
        
        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            if (unity_OrthoParams.w == 1.0)
            {
                Out = LinearEyeDepth(ComputeWorldSpacePosition(UV.xy, SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), UNITY_MATRIX_I_VP), UNITY_MATRIX_V);
            }
            else
            {
                Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
            }
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_44e941c717d9497a92aff187715f9f6f_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_44e941c717d9497a92aff187715f9f6f_Out_2);
            float _Property_61dd966c51894f509a6f801d5456cc11_Out_0 = _Curvature_Radius;
            float _Divide_24278b7067fa4e67be9b7ea976556870_Out_2;
            Unity_Divide_float(_Distance_44e941c717d9497a92aff187715f9f6f_Out_2, _Property_61dd966c51894f509a6f801d5456cc11_Out_0, _Divide_24278b7067fa4e67be9b7ea976556870_Out_2);
            float _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2;
            Unity_Power_float(_Divide_24278b7067fa4e67be9b7ea976556870_Out_2, 3, _Power_63aa42d7c61e4eea82aa47487f419a98_Out_2);
            float3 _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2;
            Unity_Multiply_float3_float3(IN.WorldSpaceNormal, (_Power_63aa42d7c61e4eea82aa47487f419a98_Out_2.xxx), _Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2);
            float _Property_7c68397542c2438284eef5839ca7d620_Out_0 = _Noise_Edge_1;
            float _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0 = _Noise_Edge_2;
            float4 _Property_d45e548fb08c483881cf5056de408359_Out_0 = _Rotate_Projection;
            float _Split_9f7344a2e3b8409097e889c21f853bfc_R_1 = _Property_d45e548fb08c483881cf5056de408359_Out_0[0];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_G_2 = _Property_d45e548fb08c483881cf5056de408359_Out_0[1];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_B_3 = _Property_d45e548fb08c483881cf5056de408359_Out_0[2];
            float _Split_9f7344a2e3b8409097e889c21f853bfc_A_4 = _Property_d45e548fb08c483881cf5056de408359_Out_0[3];
            float3 _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_d45e548fb08c483881cf5056de408359_Out_0.xyz), _Split_9f7344a2e3b8409097e889c21f853bfc_A_4, _RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3);
            float _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0 = _Noise_Speed;
            float _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_f5108c94a24e4734aebd7b3097e2839b_Out_0, _Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2);
            float2 _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_04364c5fc10f499e9ddad4bbd1d7bb52_Out_2.xx), _TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3);
            float _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0 = _Noise_Scale;
            float _GradientNoise_dabf95d198524157b07434e53395de90_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_9a562f3c8b0e46a1a77e07e03a16dd35_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_dabf95d198524157b07434e53395de90_Out_2);
            float2 _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3);
            float _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_cc0e738123e342cc9c55d4624463bc46_Out_3, _Property_f8e3c2d0789b4e16b1246a4bb56ab11d_Out_0, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2);
            float _Add_b57854a7437e4a5088ec40517fd83e14_Out_2;
            Unity_Add_float(_GradientNoise_dabf95d198524157b07434e53395de90_Out_2, _GradientNoise_40c510b3db9c4aa2ba3e0e9e993b9533_Out_2, _Add_b57854a7437e4a5088ec40517fd83e14_Out_2);
            float _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2;
            Unity_Divide_float(_Add_b57854a7437e4a5088ec40517fd83e14_Out_2, 2, _Divide_b9b67fc6e333417db6f1b563d938f365_Out_2);
            float _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1;
            Unity_Saturate_float(_Divide_b9b67fc6e333417db6f1b563d938f365_Out_2, _Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1);
            float _Property_5578324b37214f9fb35783ee79be16e4_Out_0 = _Noise_Power;
            float _Power_5d4ba10668fa4290931074cee99fb34a_Out_2;
            Unity_Power_float(_Saturate_7549f394e4d7413d9c58d95dc4534cd5_Out_1, _Property_5578324b37214f9fb35783ee79be16e4_Out_0, _Power_5d4ba10668fa4290931074cee99fb34a_Out_2);
            float4 _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0 = _Noise_Remap;
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[0];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[1];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[2];
            float _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4 = _Property_03773c40e5ac44ac8749edca8adb1bcb_Out_0[3];
            float4 _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4;
            float3 _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5;
            float2 _Combine_faf6947901204239b2cf0d0a512a197e_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_R_1, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_G_2, 0, 0, _Combine_faf6947901204239b2cf0d0a512a197e_RGBA_4, _Combine_faf6947901204239b2cf0d0a512a197e_RGB_5, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6);
            float4 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4;
            float3 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5;
            float2 _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6;
            Unity_Combine_float(_Split_a2ec6bfc51474f329fd3b4c8234b1fe8_B_3, _Split_a2ec6bfc51474f329fd3b4c8234b1fe8_A_4, 0, 0, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGBA_4, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RGB_5, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6);
            float _Remap_6fc97aa788934561b62210d65d82e721_Out_3;
            Unity_Remap_float(_Power_5d4ba10668fa4290931074cee99fb34a_Out_2, _Combine_faf6947901204239b2cf0d0a512a197e_RG_6, _Combine_d1ecac6e7ccd487db4e40fdb30099523_RG_6, _Remap_6fc97aa788934561b62210d65d82e721_Out_3);
            float _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1;
            Unity_Absolute_float(_Remap_6fc97aa788934561b62210d65d82e721_Out_3, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1);
            float _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3;
            Unity_Smoothstep_float(_Property_7c68397542c2438284eef5839ca7d620_Out_0, _Property_368b7df5fb7949ca91c602e9ed8de0ef_Out_0, _Absolute_4c00b003f0f34642b94be6fff0eb5e9a_Out_1, _Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3);
            float _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0 = _Base_Speed;
            float _Multiply_96899bc40bfa45999d00bad995155875_Out_2;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Property_24f8b05feaec4e12bcc00920b0f0d933_Out_0, _Multiply_96899bc40bfa45999d00bad995155875_Out_2);
            float2 _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_eba7dd884f044321b4f95b9520db4f6b_Out_3.xy), float2 (1, 1), (_Multiply_96899bc40bfa45999d00bad995155875_Out_2.xx), _TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3);
            float _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0 = _Base_Scale;
            float _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_54d36e760f2946bf9f34ffd80d3dde65_Out_3, _Property_7821e71ea3ec400fb3ce990f04be3df7_Out_0, _GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2);
            float _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0 = _Base_Strength;
            float _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2;
            Unity_Multiply_float_float(_GradientNoise_8fcebe8513544f1a94a8bab7bd8043d9_Out_2, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2);
            float _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2;
            Unity_Add_float(_Smoothstep_8ce457dac5b046c4830a8f2dc828ee4c_Out_3, _Multiply_b712c4bff2204e4da3d1565fac9be6a9_Out_2, _Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2);
            float _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2;
            Unity_Add_float(1, _Property_dbe4873fc6b142c88747647f36d25c5e_Out_0, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2);
            float _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2;
            Unity_Divide_float(_Add_2c0093a926ec4d3a9b2b76d605e57cbb_Out_2, _Add_8b43a65f1bd1436da5e412ca20fe18fe_Out_2, _Divide_10de1329e38141089b97b4c7450c8fe7_Out_2);
            float3 _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2;
            Unity_Multiply_float3_float3(IN.ObjectSpaceNormal, (_Divide_10de1329e38141089b97b4c7450c8fe7_Out_2.xxx), _Multiply_9835ff602f9c432b8d396954fde504fe_Out_2);
            float _Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0 = _Noise_Height;
            float3 _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2;
            Unity_Multiply_float3_float3(_Multiply_9835ff602f9c432b8d396954fde504fe_Out_2, (_Property_472f5cf68c6843d086d0cad76c8e7a98_Out_0.xxx), _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2);
            float3 _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_7d339192e289470cb4db0cb5fde5ace5_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2);
            float3 _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            Unity_Add_float3(_Multiply_73c5879a17864ec6b9c98b09f6918f66_Out_2, _Add_fe8e5a3a397b4f489c686b17f7edf700_Out_2, _Add_927240ba02b847749df49b1e5063bac0_Out_2);
            description.Position = _Add_927240ba02b847749df49b1e5063bac0_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1);
            float _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2;
            Unity_Subtract_float(_SceneDepth_541506ad80d24148a83b265f5dd04744_Out_1, 1, _Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2);
            float _Property_afbf72b3463441f9bd921c060dd8416d_Out_0 = _Fade_Depth;
            float _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2;
            Unity_Divide_float(_Subtract_a7f012d6e4b543e2ad93a57ab9d7b18d_Out_2, _Property_afbf72b3463441f9bd921c060dd8416d_Out_0, _Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2);
            float _Saturate_d8d4d558771848188e391dd978f456f7_Out_1;
            Unity_Saturate_float(_Divide_75f7229e432548d2be3d9f4bf365ffd1_Out_2, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1);
            float _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_d8d4d558771848188e391dd978f456f7_Out_1, _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3);
            surface.Alpha = _Smoothstep_5f2efeb4252647489bd0a0d6b2f9bd89_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.WorldSpaceNormal =                           TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
            output.WorldSpacePosition =                         TransformObjectToWorld(input.positionOS);
            output.TimeParameters =                             _TimeParameters.xyz;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    CustomEditorForRenderPipeline "UnityEditor.ShaderGraphUnlitGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}