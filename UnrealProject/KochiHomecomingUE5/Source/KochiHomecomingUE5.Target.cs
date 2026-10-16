using UnrealBuildTool;
using System.Collections.Generic;

public class KochiHomecomingUE5Target : TargetRules
{
    public KochiHomecomingUE5Target(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8;
        ExtraModuleNames.Add("KochiHomecomingUE5");
    }
}