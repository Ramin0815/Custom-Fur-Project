Shader "Custom/ShellFurShader"
{
    Properties
    {
        // 기본 변수
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.1
        _Cutoff("Alpha Clipping", Range(0.0, 1.0)) = 0

        [HideInInspector] _WorkflowMode("Workflow Mode", Float) = 1.0

        // PBRMap
        _SpecularMap("Specular Map", 2D) = "white" {}
        _SpecColor("Specular Color", Color) = (0,0,0,0)
        _MetallicMap("Metallic Map", 2D) = "white" {}
        _MetallicScale("Metallic Scale", Range(0.0, 1.0)) = 0
        _BumpMap("Normal Map", 2D) = "bump" {}
        _OcclusionMap("Occlusion Map", 2D) = "white" {}
        _ParallaxMap("Height Map", 2D) = "grey" {} // Height Map

        [Toggle(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("Specular Highlights", Float) = 0.0
        [Toggle(_ENVIRONMENTREFLECTIONS_OFF)] _EnvironmentReflections("Environment Reflections", Float) = 0.0

        // Detail Inputs
        _DetailMask("Detail Mask", 2D) = "white" {}
        _DetailAlbedoMap("Detail Albedo", 2D) = "grey" {}
        _DetailNormalMap("Detail Normal", 2D) = "bump" {}

        // 에미션
        [Toggle(_EMISSION_ON)] _EmissionEnabled("Emission Enabled", Float) = 0
        _EmissionColor("Emission Color", Color) = (0,0,0,1)
        _EmissionMap("Emission Map", 2D) = "white" {}

        // 털 데이터
        _FurLength("Fur Length", Float) = 0.3
        _FurCount("Layer Count", Int) = 20
        _MaskThreshold("Mask Threshold", Float) = 0.5
        _GravityStrength("Gravity Strength", Range(0.0, 2.0)) = 0.5
        _Occlusion("Occlusion", Range(0.0, 1.0)) = 1.0
        _FurDirectionMap("Fur Direction", 2D) = "bump" {}
        _NoiseMap("Fur Noise Map", 2D) = "white" {}
        _FurLengthMap("Fur Length Map", 2D) = "white" {}

        // 인터랙션
        _LerpData("Interaction Lerp Data", Float) = 2.0
        
        // 코드 제어용
        [HideInInspector] _LayerRatio("Layer Ratio", Float) = 0.0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }

        Pass
        {

            Name "UniversalForward"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            // 인스턴싱 및 렌더링 레이어
            #pragma multi_compile_instancing

            // 조명 및 그림자
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma target 4.5
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma shader_feature_local_fragment _EMISSION_ON
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _METALLIC
            #pragma shader_feature_local _SPECULAR
            #pragma shader_feature_local _DETAIL

            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
            
        
            // 포그 및 기본 컴파일
            #pragma multi_compile_fog
            
            #pragma vertex vert
            #pragma fragment frag

            // URP 기본 라이브러리
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"

            // 버텍스 셰이더로 들어오는 입력 데이터
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangent      : TANGENT;
                float2 uv           : TEXCOORD0;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // 버텍스 셰이더에서 프래그먼트 셰이더로 넘겨주는 데이터
            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float2 uv           : TEXCOORD2;
                float  layerRatio   : TEXCOORD3;
                float  fogCoord     : TEXCOORD4;
                float4 shadowCoord  : TEXCOORD5;
                float3 tangentWS    : TEXCOORD6;   
                float3 bitangentWS  : TEXCOORD7;
                UNITY_VERTEX_OUTPUT_STEREO 
            };

            //맵들 선언

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);

            TEXTURE2D(_FurLengthMap);
            SAMPLER(sampler_FurLengthMap);

            TEXTURE2D(_FurDirectionMap);
            SAMPLER(sampler_FurDirectionMap);

            TEXTURE2D(_EmissionMap);
            SAMPLER(sampler_EmissionMap);

            TEXTURE2D(_NoramlMap);
            SAMPLER(sampler_NoramlMap);

            TEXTURE2D(_MetallicMap);
            SAMPLER(sampler_MetallicMap);

            TEXTURE2D(_SpecularMap);
            SAMPLER(sampler_SpecularMap);

            TEXTURE2D(_BumpMap);             
            SAMPLER(sampler_BumpMap);

            TEXTURE2D(_OcclusionMap);        
            SAMPLER(sampler_OcclusionMap);

            TEXTURE2D(_DetailMap);        
            SAMPLER(sampler_DetailMap);

            TEXTURE2D(_ParallaxMap);        
            SAMPLER(sampler_ParallaxMap);

            // 변수 선언 (SRP 배처를 깨지 않기 위해 CBUFFER 사용)
            sampler2D _BaseMap;
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4  _BaseColor;
                float _FurLength;
                int _FurCount;
                half   _Smoothness;
                float _MaskThreshold; 
                float4 _NoiseMap_ST;
                float4 _FurLengthMap_ST;
                float4 _FurDirectionMap_ST;
                float _GravityStrength;
                float _Cutoff;
                float _Occlusion;
                float _LerpData;
                float _LayerRatio;
                float _EmissionEnabled;
                half4 _EmissionColor;
                float4 _EmissionMap_ST;
                float4 _DetailAlbedoMap_ST;
                float _MetallicScale;
                half4 _SpecColor;
            CBUFFER_END

            float4 _RightInteractionPos;
            float4 _RightHandVector;
            float4 _LeftInteractionPos;
            float4 _LeftHandVector;
            float _InteractionRadius;

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                // VR 렌더링 초기화
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                // surface data map들이 공유하는 base map의 tiling 및 offset
                float2 baseUV = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;

                half lengthValue = SAMPLE_TEXTURE2D_LOD(_FurLengthMap, sampler_FurLengthMap, baseUV, 0).r;
                half heightValue = SAMPLE_TEXTURE2D_LOD(_ParallaxMap, sampler_ParallaxMap, baseUV, 0).r;

                // 현재 그려지고 있는 층의 비율값 가져오기
                float currentLayerRatio = _LayerRatio;
                // 버텍스를 노말 방향으로 밀어내기
                float4 dirSample = SAMPLE_TEXTURE2D_LOD(_FurDirectionMap, sampler_FurDirectionMap, TRANSFORM_TEX(input.uv, _FurDirectionMap),0);
                float3 localDir = dirSample.rgb * 2.0 - 1.0;
                float3 objectBitangent = cross(input.normalOS, input.tangent) * input.tangent.w;
                float3 objectFurDir = (localDir.x * input.tangent) + 
                          (localDir.y * objectBitangent) + 
                          (localDir.z * input.normalOS);

                float3 gravityDirWS = float3(0, -1, 0);
    
                float3 gravityDirOS = TransformWorldToObjectDir(gravityDirWS);
                float gravityEffect = pow(currentLayerRatio, 2) * _GravityStrength;
                float3 extrusion = (objectFurDir * _FurLength * currentLayerRatio +  gravityDirOS * gravityEffect) * lengthValue * heightValue;                

                // 양손과의 거리를 각각 계산
                float3 posWS = TransformObjectToWorld(input.positionOS);
                float distLeft = distance(posWS, _LeftInteractionPos.xyz);
                float distRight = distance(posWS, _RightInteractionPos.xyz);

                // 둘 중 더 가까운 거리를 채택
                float dist = min(distLeft, distRight);
                float3 activeHandVector = TransformWorldToObjectDir((distLeft < distRight) ? _LeftHandVector : _RightHandVector);

                if(dist<_InteractionRadius*_LerpData){
                    float3 newExtrusion = (normalize(objectFurDir + (activeHandVector * 0.8)) * _FurLength * currentLayerRatio + gravityDirOS * gravityEffect )* lengthValue * heightValue;
                    extrusion = lerp(extrusion, newExtrusion, (_InteractionRadius*_LerpData - dist)/(_InteractionRadius*0.5));
                }

                float3 newPosOS = input.positionOS.xyz + extrusion;
                
                // URP 내장 함수를 이용한 공간 변환 
                VertexPositionInputs vertexInput = GetVertexPositionInputs(newPosOS);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                
                // 포그 및 그림자 좌표 계산
                output.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);
                output.shadowCoord = GetShadowCoord(vertexInput);
                
                output.layerRatio = currentLayerRatio;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // VR: 프래그먼트 단계에서 눈 인덱스 설정
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.uv;
                float2 detailUV = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;

                // 텍스처 색상 추출
                half4 texColor = tex2D(_BaseMap, detailUV) * _BaseColor;
                clip(texColor.a - _Cutoff);

                float2 noiseUV = input.uv * _NoiseMap_ST.xy + _NoiseMap_ST.zw;
                half noiseValue = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, noiseUV).r;

                half furMask = noiseValue - (input.layerRatio * _MaskThreshold);
                if (input.layerRatio > 0.0)
                {
                    clip(furMask); 
                }

                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = texColor.rgb;
                surfaceData.alpha = texColor.a;
                surfaceData.metallic = 0.0; 
                surfaceData.smoothness = _Smoothness;
                float occlusion = lerp(_Occlusion, 1.0, input.layerRatio);
                surfaceData.occlusion = lerp(_Occlusion, 1.0, input.layerRatio);

                // Emission
                #if defined(_EMISSION_ON)
                    float2 emiUV = input.uv * _EmissionMap_ST.xy + _EmissionMap_ST.zw;
                    surfaceData.emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, emiUV).rgb * _EmissionColor.rgb;
                #else
                    surfaceData.emission = half3(0, 0, 0);
                #endif

                // Detail
                #if defined(_DETAIL)
                    half detailMask = SAMPLE_TEXTURE2D_LOD(_DetailMask, sampler_DetailMask, uv, 0).a;
                    half3 detailAlbedo = SAMPLE_TEXTURE2D_LOD(_DetailAlbedoMap, sampler_DetailAlbedoMap, detailUV, 0).rgb;
                    
                    surfaceData.albedo = lerp(texColor.rgb, texColor.rgb * detailAlbedo * 2.0, detailMask);
                #else
                    surfaceData.albedo = texColor.rgb;
                #endif

                #if defined(_METALLIC)
                    half4 metallicGloss = SAMPLE_TEXTURE2D_LOD(_MetallicMap, sampler_MetallicMap, uv, 0);
                    surfaceData.metallic = metallicGloss.r * _MetallicScale;
                    surfaceData.smoothness = metallicGloss.a * _Smoothness;
                    surfaceData.specular = 0.0;
                #else
                    half4 specularGloss = SAMPLE_TEXTURE2D_LOD(_SpecularMap, sampler_SpecularMap, uv, 0);
                    surfaceData.specular = specularGloss.rgb * _SpecColor.rgb;
                    surfaceData.smoothness = specularGloss.a * _Smoothness;
                    surfaceData.metallic = 0.0;
                #endif

                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;

                #if defined(_NORMALMAP)
                    half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D_LOD(_BumpMap, sampler_BumpMap, uv, 0), 1.0);
                    
                    // 디테일 노말 맵 섞기
                    #if defined(_DETAIL)
                        half3 detailNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D_LOD(_DetailNormalMap, sampler_BumpMap, detailUV, 0), 1.0);
                        // RNM 블렌딩
                        normalTS = lerp(normalTS, BlendNormalRNM(normalTS, detailNormalTS), detailMask);
                    #endif

                    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS, input.bitangentWS, input.normalWS));
                    inputData.normalWS = normalize(inputData.normalWS);
                #else
                    inputData.normalWS = normalize(input.normalWS);
                #endif
                
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                inputData.shadowCoord = input.shadowCoord;
                inputData.fogCoord = input.fogCoord;
                inputData.shadowMask = half4(1, 1, 1, 1);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.bakedGI = SampleSH(inputData.normalWS);
                
                BRDFData brdfData;
                InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, half3(0,0,0), surfaceData.smoothness, surfaceData.alpha, brdfData);

                half3 finalLighting = half3(0, 0, 0);
                finalLighting += UniversalFragmentPBR(inputData, surfaceData);
               

                half4 color = half4(finalLighting, 1.0);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return color;
            }
            ENDHLSL
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
    CustomEditor "CustomFurShaderGUI"
    
}
