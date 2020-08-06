using NUnit.Framework;
using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
public class ExtendShaderGUI : ShaderGUI
{
    public MaterialProperty[] properties;
    public MaterialEditor materialEditor;
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.properties = properties;
        this.materialEditor = materialEditor;
        base.OnGUI(materialEditor, properties);
    }

    public MaterialProperty FindProperty(string propertyName, bool propertyIsMandatory = false)
    {
        return FindProperty(propertyName, properties, propertyIsMandatory);
    }

    public static ExtendShaderGUI Get(MaterialEditor editor)
    {
        if (editor.customShaderGUI != null && editor.customShaderGUI is ExtendShaderGUI)
        {
            ExtendShaderGUI gui = editor.customShaderGUI as ExtendShaderGUI;
            return gui;
        }
        else
        {
            Debug.LogWarning("Please add \'CustomEditor \"ExtendShaderGUI\"\' in your shader!");
            return null;
        }
    }
}

public class HideIfDrawer : ShowIfDrawer
{
    public HideIfDrawer(string target) : this(target, 1) { }
    public HideIfDrawer(string target, string target2) : this(target, 1, target2, 1) { }
    public HideIfDrawer(string target, string target2, string target3) : this(target, 1, target2, 1, target3, 1) { }
    public HideIfDrawer(string target, float value) : base(target, value, true) { }
    public HideIfDrawer(string target, float value, string target2, float value2) : base(target, value, target2, value2, true) { }
    public HideIfDrawer(string target, float value, string target2, float value2, string target3, float value3) : base(target, value, target2, value2, target3, value3, true) { }
}

public class ShowIfDrawer : MaterialPropertyDrawer
{
    string[] targets;
    float[] values;
    bool invent;

    public ShowIfDrawer(string target) : this(target, 1) { }
    public ShowIfDrawer(string target, string target2) : this(target, 1, target2, 1) { }
    public ShowIfDrawer(string target, string target2, string target3) : this(target, 1, target2, 1 , target3, 1) { }
    public ShowIfDrawer(string target, float value) : this(target, value, false) { }
    public ShowIfDrawer(string target, float value, string target2, float value2) : this(target, value, target2, value2, false) { }
    public ShowIfDrawer(string target, float value, string target2, float value2, string target3, float value3) : this(target, value, target2, value2, target3, value3, false) { }

    protected ShowIfDrawer(string target, float value, bool invent)
    {
        this.targets = new string[] { target };
        this.values = new float[] { value };
        this.invent = invent;
    }
    protected ShowIfDrawer(string target, float value, string target2, float value2, bool invent)
    {
        this.targets = new string[] { target, target2 };
        this.values = new float[] { value, value2 };
        this.invent = invent;
    }
    protected ShowIfDrawer(string target, float value, string target2, float value2, string target3, float value3, bool invent)
    {
        this.targets = new string[] { target, target2, target3 };
        this.values = new float[] { value, value2, value3 };
        this.invent = invent;
    }

    private bool NeedShow(MaterialEditor editor)
    {
        for (int i = 0;i < targets.Length;i++)
        {
            string target = targets[i];
            float value = values[i];
            var property = ExtendShaderGUI.Get(editor)?.FindProperty(target);
            if (property == null)
                return false;

            bool result = false;
            switch (property.type)
            {
                case MaterialProperty.PropType.Color:
                    result = property.colorValue == new Color(value, value, value, value); break;
                case MaterialProperty.PropType.Vector:
                    result = property.vectorValue == new Vector4(value, value, value, value); break;
                case MaterialProperty.PropType.Float:
                case MaterialProperty.PropType.Range:
                    result = property.floatValue == value; break;
                case MaterialProperty.PropType.Texture:
                    result = property.textureValue != null;break;
            }
            if (!invent)
            {
                if (!result)
                    return false;
            }
            else
            {
                if (result)
                    return false;
            }
        }
        return true;
    }

    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return NeedShow(editor) ? MaterialEditor.GetDefaultPropertyHeight(prop) : -2;
    }
    public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
    {
        if (!NeedShow(editor))
        {
            return;
        }

        EditorGUI.indentLevel++;
        editor.DefaultShaderProperty(position, prop, label.text);
        EditorGUI.indentLevel--;
    }
}

public class HideDrawer : MaterialPropertyDrawer
{
    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return  -2;
    }
    public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
    {
        return;
    }
}

public class HSVDrawer : MaterialPropertyDrawer
{
    public string params2;
    public string property1;
    public string property2;
    public string property3;
    public bool fold = true;
    public HSVDrawer(string property1, string property2, string property3) : this(null, property1, property2, property3) { }
    public HSVDrawer(string params2, string property1, string property2, string property3)
    {
        this.params2 = params2;
        this.property1 = property1;
        this.property2 = property2;
        this.property3 = property3;
    }
    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return 0;
    }
    public override void OnGUI(Rect p, MaterialProperty prop, GUIContent label, MaterialEditor editor)
    {
        var p0 = params2 != null ? ExtendShaderGUI.Get(editor)?.FindProperty(params2) : null;
        var p1 = ExtendShaderGUI.Get(editor)?.FindProperty(property1);
        var p2 = ExtendShaderGUI.Get(editor)?.FindProperty(property2);
        var p3 = ExtendShaderGUI.Get(editor)?.FindProperty(property3);
        EditorGUIUtility.labelWidth = 0;
        EditorGUI.indentLevel++;
        fold = EditorGUILayout.BeginFoldoutHeaderGroup(fold, label.text);
        if (fold)
        {
            EditorGUI.BeginChangeCheck();
            Vector3 v1 = new Vector3();
            Vector3 v2 = new Vector3();
            v1.x = EditorGUILayout.Slider("色相", prop.vectorValue.x, -180f, 180f) ;
            v1.y = EditorGUILayout.Slider("饱和", prop.vectorValue.y, 0, 2);
            v1.z = EditorGUILayout.Slider("明度", prop.vectorValue.z, 0 ,2);
            if (p0 != null)
            {
                v2.x = EditorGUILayout.Slider("青 - 红", p0.vectorValue.x, -1f, 1f);
                v2.y = EditorGUILayout.Slider("洋 - 绿", p0.vectorValue.y, -1f, 1f);
                v2.z = EditorGUILayout.Slider("黄 - 蓝", p0.vectorValue.z, -1f, 1f);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();
            if (EditorGUI.EndChangeCheck())
            {
                prop.vectorValue = v1;
                float h = v1[0];
                float s = v1[1];
                float v = v1[2];
                float vsu = v * s * Mathf.Cos(h * Mathf.PI / 180f);
                float vsw = v * s * Mathf.Sin(h * Mathf.PI / 180f);

                Matrix4x4 hsv = new Matrix4x4(
                    new Vector4(.299f * v + .701f * vsu + .168f * vsw,
                    .587f * v - .587f * vsu + .330f * vsw,
                    .114f * v - .114f * vsu - .497f * vsw, 0),
                    new Vector4(.299f * v - .299f * vsu - .328f * vsw,
                    +.587f * v + .413f * vsu + .035f * vsw,
                    +.114f * v - .114f * vsu + .292f * vsw, 0),
                    new Vector4(.299f * v - .300f * vsu + 1.25f * vsw,
                    +.587f * v - .588f * vsu - 1.05f * vsw,
                    +.114f * v + .886f * vsu - .203f * vsw, 0), 
                    new Vector4(0,0,0,1));
                
                if (p0 != null)
                {
                    p0.vectorValue = v2;
                    float r = v2.x;
                    float g = v2.y;
                    float b = v2.z;
                    Matrix4x4 balance = new Matrix4x4(
                        new Vector4(1 - r   , r * 0.5f, r * 0.5f, 0),
                        new Vector4(g * 0.5f, 1 - g   , g * 0.5f, 0),
                        new Vector4(b * 0.5f, b * 0.5f, 1 - b   , 0),
                        new Vector4(0       , 0       , 0       , 1));
                    hsv = balance * hsv;
                }
                p1.vectorValue = hsv.GetColumn(0);
                p2.vectorValue = hsv.GetColumn(1);
                p3.vectorValue = hsv.GetColumn(2);
            }
        }
        EditorGUI.indentLevel--;
    }
}