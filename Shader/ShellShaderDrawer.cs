using UnityEngine;

public class ShellShaderDrawer : MonoBehaviour
{
    public SkinnedMeshRenderer skinRenderer;
    public Material furMaterial; 
    [Range(1, 50)] public int layerCount = 40;

    void Start()
    {
        Material[] mats = new Material[layerCount];
        for (int i = 0; i < layerCount; i++)
        {
            mats[i] = furMaterial;
        }
        skinRenderer.materials = mats;

        MaterialPropertyBlock block = new MaterialPropertyBlock();
        for (int i = 0; i < layerCount; i++)
        {
            float ratio = (float)i / (layerCount - 1);
            
            block.SetFloat("_LayerRatio", ratio);
            
            skinRenderer.SetPropertyBlock(block, i);
        }
    }
}
