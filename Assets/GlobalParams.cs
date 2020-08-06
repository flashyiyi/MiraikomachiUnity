using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class GlobalParams : MonoBehaviour
{
    public Color frontLightColor = Color.white;
    public Color backLightColor = Color.white;
    [Range(0,25)]
    public float additiveLightRimMuit = 1;
    [Range(0, 1)]
    public float additiveLightDarkMuit = 0.5f;
    [Range(0, 1)]
    public float additiveLightSoftBlend = 0.5f;
    [Range(0, 1)]
    public float SHLightSoftBlend = 0f;
    [Range(0, 5)]
    public float maxLightDistanceAttenuation = 1f;
    private void OnEnable()
    {
        RefreshValues();
    }
    void OnValidate()
    {
        RefreshValues();
    }

    void RefreshValues()
    {
        Shader.SetGlobalColor("_FrontLightColor", frontLightColor);
        Shader.SetGlobalColor("_BackLightColor", backLightColor);
        Shader.SetGlobalFloat("_AdditiveLightDarkMuit", additiveLightDarkMuit);
        Shader.SetGlobalFloat("_AdditiveLightSoftBlend", additiveLightSoftBlend);
        Shader.SetGlobalFloat("_AdditiveLightRimLightMuit", additiveLightRimMuit);
        Shader.SetGlobalFloat("_SHLightSoftBlend", SHLightSoftBlend);
        Shader.SetGlobalFloat("_MaxLightDistanceAttenuation", maxLightDistanceAttenuation);
    }
}
