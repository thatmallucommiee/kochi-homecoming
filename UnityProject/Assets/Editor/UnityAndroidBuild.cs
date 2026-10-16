using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace KochiHomecoming.Editor
{
    public static class UnityAndroidBuild
    {
        public static void Build()
        {
            HomecomingSceneSetup.EnsureGeneratedScene();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            string[] scenes = EditorBuildSettings.scenes
                .Where(scene => scene.enabled)
                .Select(scene => scene.path)
                .ToArray();

            if (scenes.Length == 0)
                throw new InvalidOperationException("No enabled scenes were found after scene setup.");

            Directory.CreateDirectory("Build");
            string outputPath = Path.GetFullPath("Build/KochiHomecoming.apk");

            EditorUserBuildSettings.exportAsGoogleAndroidProject = false;
            EditorUserBuildSettings.buildAppBundle = false;

            BuildPlayerOptions options = new BuildPlayerOptions
            {
                scenes = scenes,
                locationPathName = outputPath,
                target = BuildTarget.Android,
                options = BuildOptions.CompressWithLz4HC
            };

            Debug.Log("Building Kochi: Homecoming Android APK from scenes: " + string.Join(", ", scenes));
            BuildReport report = BuildPipeline.BuildPlayer(options);

            if (report.summary.result != BuildResult.Succeeded)
            {
                string message = "Android build failed with result " + report.summary.result
                    + " after " + report.summary.totalErrors + " error(s).";
                Debug.LogError(message);
                throw new InvalidOperationException(message);
            }

            Debug.Log("ANDROID APK READY: " + outputPath
                + " (" + report.summary.totalSize + " bytes).");
        }
    }
}
