using UnityEditor;
using UnityEngine;

public class CustomFurShaderGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        MaterialProperty baseMap = FindProperty("_BaseMap", properties);
        MaterialProperty baseColor = FindProperty("_BaseColor", properties);
        MaterialProperty smoothness = FindProperty("_Smoothness", properties);
        MaterialProperty cutoff = FindProperty("_Cutoff", properties);

        // Rendering Toggles
        MaterialProperty specHighlights = FindProperty("_SpecularHighlights", properties);
        MaterialProperty envReflections = FindProperty("_EnvironmentReflections", properties);

        // Metallic & Specular
        MaterialProperty workflowMode = FindProperty("_WorkflowMode", properties, false); 
        MaterialProperty metallicMap = FindProperty("_MetallicMap", properties);
        MaterialProperty metallicScale = FindProperty("_MetallicScale", properties);
        MaterialProperty specMap = FindProperty("_SpecularMap", properties);
        MaterialProperty specColor = FindProperty("_SpecColor", properties);

        // Normal, Height, Occlusion
        MaterialProperty bumpMap = FindProperty("_BumpMap", properties);
        MaterialProperty occMap = FindProperty("_OcclusionMap", properties);
        MaterialProperty occStrength = FindProperty("_Occlusion", properties);
        MaterialProperty parallaxMap = FindProperty("_ParallaxMap", properties);

        // Emission
        MaterialProperty emiEnabled = FindProperty("_EmissionEnabled", properties);
        MaterialProperty emiColor = FindProperty("_EmissionColor", properties);
        MaterialProperty emiMap = FindProperty("_EmissionMap", properties);

        // Detail Inputs
        MaterialProperty detailMask = FindProperty("_DetailMask", properties);
        MaterialProperty detailAlbedo = FindProperty("_DetailAlbedoMap", properties);
        MaterialProperty detailNormal = FindProperty("_DetailNormalMap", properties);

        // Fur Data
        MaterialProperty furLen = FindProperty("_FurLength", properties);
        MaterialProperty furCount = FindProperty("_FurCount", properties);
        MaterialProperty maskThresh = FindProperty("_MaskThreshold", properties);
        MaterialProperty grav = FindProperty("_GravityStrength", properties);
        MaterialProperty dirMap = FindProperty("_FurDirectionMap", properties);
        MaterialProperty noiseMap = FindProperty("_NoiseMap", properties);
        MaterialProperty lenMap = FindProperty("_FurLengthMap", properties);

        // Interaction
        MaterialProperty lerpData = FindProperty("_LerpData", properties);


        // 렌더링 옵션
        EditorGUILayout.LabelField("Rendering Options", EditorStyles.boldLabel);
        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
        {
            materialEditor.ShaderProperty(specHighlights, "Specular Highlights");
            materialEditor.ShaderProperty(envReflections, "Environment Reflections");
        }
        EditorGUILayout.Space(10);

        // Surface Input 
        EditorGUILayout.LabelField("Surface Input", EditorStyles.boldLabel);
        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
        {
            materialEditor.TexturePropertySingleLine(new GUIContent("Albedo"), baseMap, baseColor);

            if (workflowMode != null)
            {
                EditorGUI.BeginChangeCheck();
                
                string[] options = new string[] { "Specular Workflow", "Metallic Workflow" };
                int currentMode = (int)workflowMode.floatValue;
                currentMode = EditorGUILayout.Popup("Workflow Mode", currentMode, options);

                if (EditorGUI.EndChangeCheck())
                {
                    workflowMode.floatValue = currentMode;
                    
                    // mode 1: Metallic, mode 0: Specular
                    SetKeyword(materialEditor, "_METALLIC", currentMode == 1);
                    SetKeyword(materialEditor, "_SPECULAR", currentMode == 0); 
                }

                EditorGUI.indentLevel++;
                if (currentMode == 1) // Metallic
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map"), metallicMap, metallicScale);
                }
                else // Specular
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Specular Map"), specMap, specColor);
                }
                EditorGUI.indentLevel--;
            }
            else
            {
                materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map"), metallicMap, metallicScale);
                materialEditor.TexturePropertySingleLine(new GUIContent("Specular Map"), specMap, specColor);
            }

            materialEditor.ShaderProperty(smoothness, "Smoothness");

            // Normal, Height, Occlusion
            materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map"), bumpMap);
            materialEditor.TexturePropertySingleLine(new GUIContent("Height Map"), parallaxMap);
            materialEditor.TexturePropertySingleLine(new GUIContent("Occlusion Map"), occMap, occStrength);

            materialEditor.ShaderProperty(cutoff, "Alpha Clipping");

            EditorGUI.BeginChangeCheck(); 
            materialEditor.ShaderProperty(emiEnabled, "Emission");
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword(materialEditor, "_EMISSION_ON", emiEnabled.floatValue == 1.0f);
            }

            if (emiEnabled.floatValue == 1.0f)
            {
                EditorGUI.indentLevel++;
                materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map & Color"), emiMap, emiColor);
                EditorGUI.indentLevel--;
            }
        }
        EditorGUILayout.Space(10);

        // Detail Inputs
        EditorGUILayout.LabelField("Detail Inputs", EditorStyles.boldLabel);
        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
        {
            materialEditor.TexturePropertySingleLine(new GUIContent("Detail Mask"), detailMask);
            materialEditor.TexturePropertySingleLine(new GUIContent("Detail Albedo"), detailAlbedo);
            materialEditor.TexturePropertySingleLine(new GUIContent("Detail Normal"), detailNormal);
        }
        EditorGUILayout.Space(10);

        // Fur Data
        EditorGUILayout.LabelField("Fur Data", EditorStyles.boldLabel);
        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
        {
            materialEditor.ShaderProperty(furLen, "Fur Length");
            materialEditor.ShaderProperty(furCount, "Layer Count");
            materialEditor.ShaderProperty(maskThresh, "Mask Threshold");
            materialEditor.ShaderProperty(grav, "Gravity Offset");
            
            EditorGUILayout.Space(5);
            materialEditor.TexturePropertySingleLine(new GUIContent("Flow Map"), dirMap);
            materialEditor.TexturePropertySingleLine(new GUIContent("Noise Map"), noiseMap);
            EditorGUI.indentLevel++; // 살짝 들여쓰기해서 종속된 느낌 주기
            materialEditor.TextureScaleOffsetProperty(noiseMap); // 타일링 UI 생성
            EditorGUI.indentLevel--;

            materialEditor.TexturePropertySingleLine(new GUIContent("Length Map"), lenMap);
        }
        EditorGUILayout.Space(10);

        // Interaction
        EditorGUILayout.LabelField("Interaction", EditorStyles.boldLabel);
        using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
        {
            materialEditor.ShaderProperty(lerpData, "Interaction Lerp");
        }
    }

    private void SetKeyword(MaterialEditor editor, string keyword, bool state)
    {
        foreach (Material m in editor.targets)
        {
            if (state) m.EnableKeyword(keyword);
            else m.DisableKeyword(keyword);
        }
    }
}
