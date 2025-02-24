using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using System.IO;

public class PostProcessBuild
{
    [PostProcessBuild]
    public static void OnPostProcessBuild(BuildTarget target, string path)
    {
        if (target == BuildTarget.iOS)
        {
            string projPath = PBXProject.GetPBXProjectPath(path);
            PBXProject proj = new PBXProject();
            proj.ReadFromFile(projPath);

            // UnityFrameworkターゲットを取得
            string frameworkTarget = proj.GetUnityFrameworkTargetGuid();
            string mainTarget = proj.GetUnityMainTargetGuid();

            // Swiftファイルをコピー
            string swiftFile = "Assets/Plugins/iOS/UnityBridge.swift";
            string destPath = Path.Combine(path, "UnityBridge.swift");
            if (File.Exists(swiftFile))
            {
                File.Copy(swiftFile, destPath, true);
                proj.AddFileToBuild(frameworkTarget, proj.AddFile("UnityBridge.swift", "UnityBridge.swift"));
                proj.AddFileToBuild(mainTarget, proj.AddFile("UnityBridge.swift", "UnityBridge.swift"));
            }

            proj.WriteToFile(projPath);
        }
    }
}