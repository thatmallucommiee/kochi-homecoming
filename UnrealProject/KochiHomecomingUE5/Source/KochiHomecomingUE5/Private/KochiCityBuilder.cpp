#include "KochiCityBuilder.h"
#include "Components/HierarchicalInstancedStaticMeshComponent.h"
#include "Components/SceneComponent.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/SkyLightComponent.h"
#include "Components/ExponentialHeightFogComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Engine/StaticMesh.h"
#include "Materials/Material.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

const FVector AKochiCityBuilder::FamilyHomeLocation(4500.f, 7230.f, 0.f);
const FVector AKochiCityBuilder::GarageLocation(18000.f, 4500.f, 0.f);
const FVector AKochiCityBuilder::CrashSiteLocation(-18000.f, 4500.f, 0.f);

namespace
{
    constexpr float StreetGrid = 9000.f;
    constexpr float RoadWidth = 1200.f;
    constexpr float SidewalkWidth = 300.f;
    const FLinearColor Asphalt(0.075f, 0.085f, 0.09f);
    const FLinearColor Pavement(0.31f, 0.31f, 0.29f);
    const FLinearColor LaneWhite(0.78f, 0.76f, 0.69f);
    const FLinearColor LaneYellow(0.91f, 0.62f, 0.12f);
    const FLinearColor Glass(0.07f, 0.15f, 0.17f);
    const FLinearColor Wood(0.22f, 0.12f, 0.065f);
    const FLinearColor Leaf(0.11f, 0.24f, 0.10f);
    const FLinearColor BrickRed(0.30f, 0.105f, 0.075f);
}

AKochiCityBuilder::AKochiCityBuilder()
{
    PrimaryActorTick.bCanEverTick = false;
    SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("SceneRoot"));
    SetRootComponent(SceneRoot);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeRef(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeRef.Succeeded()) CubeMesh = CubeRef.Object;
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderRef(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    if (CylinderRef.Succeeded()) CylinderMesh = CylinderRef.Object;
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereRef(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (SphereRef.Succeeded()) SphereMesh = SphereRef.Object;
}

void AKochiCityBuilder::BeginPlay()
{
    Super::BeginPlay();
    BuildLighting();
    BuildGroundAndRoads();
    BuildBuildings();
    BuildStreetLife();
    BuildFamilyHome();
    BuildRafiGarage();
    BuildCrashSite();
    BuildTeaStall();
    UE_LOG(LogTemp, Display, TEXT("Kochi Homecoming UE5 city initialized."));
}

UHierarchicalInstancedStaticMeshComponent* AKochiCityBuilder::GetInstancer(
    const FName Style, UStaticMesh* Mesh, const FLinearColor& Color, bool bCollision)
{
    if (TObjectPtr<UHierarchicalInstancedStaticMeshComponent>* Existing = Instancers.Find(Style))
    {
        return Existing->Get();
    }
    if (!Mesh || !SceneRoot) return nullptr;

    UHierarchicalInstancedStaticMeshComponent* Component =
        NewObject<UHierarchicalInstancedStaticMeshComponent>(this, Style);
    Component->SetupAttachment(SceneRoot);
    Component->SetStaticMesh(Mesh);
    Component->SetMobility(EComponentMobility::Static);
    Component->SetCollisionEnabled(bCollision ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
    Component->SetCollisionObjectType(ECC_WorldStatic);
    Component->SetCollisionResponseToAllChannels(bCollision ? ECR_Block : ECR_Ignore);
    Component->SetGenerateOverlapEvents(false);
    Component->SetCanEverAffectNavigation(false);
    if (UMaterialInterface* Base = LoadObject<UMaterialInterface>(
            nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial")))
    {
        if (UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(Base, this))
        {
            Material->SetVectorParameterValue(TEXT("Color"), Color);
            Component->SetMaterial(0, Material);
        }
    }
    Component->RegisterComponent();
    Instancers.Add(Style, Component);
    return Component;
}

void AKochiCityBuilder::AddBox(FName Style, const FVector& Location, const FVector& DimensionsCm,
                               const FLinearColor& Color, float Yaw, bool bCollision)
{
    if (UHierarchicalInstancedStaticMeshComponent* Component =
            GetInstancer(Style, CubeMesh, Color, bCollision))
    {
        const FVector Scale(FMath::Max(0.01f, DimensionsCm.X / 100.f),
                            FMath::Max(0.01f, DimensionsCm.Y / 100.f),
                            FMath::Max(0.01f, DimensionsCm.Z / 100.f));
        Component->AddInstance(FTransform(FRotator(0.f, Yaw, 0.f), Location, Scale));
    }
}

void AKochiCityBuilder::AddCylinder(FName Style, const FVector& Location, float DiameterCm,
                                    float HeightCm, const FLinearColor& Color, bool bCollision)
{
    if (UHierarchicalInstancedStaticMeshComponent* Component =
            GetInstancer(Style, CylinderMesh, Color, bCollision))
    {
        Component->AddInstance(FTransform(FRotator::ZeroRotator, Location,
            FVector(DiameterCm / 100.f, DiameterCm / 100.f, HeightCm / 100.f)));
    }
}

void AKochiCityBuilder::AddSphere(FName Style, const FVector& Location, const FVector& DimensionsCm,
                                  const FLinearColor& Color, bool bCollision)
{
    if (UHierarchicalInstancedStaticMeshComponent* Component =
            GetInstancer(Style, SphereMesh, Color, bCollision))
    {
        Component->AddInstance(FTransform(FRotator::ZeroRotator, Location,
            FVector(DimensionsCm.X / 100.f, DimensionsCm.Y / 100.f, DimensionsCm.Z / 100.f)));
    }
}

void AKochiCityBuilder::BuildLighting()
{
    // The engine entry map is intentionally empty, so establish a warm daylight rig here.
    UDirectionalLightComponent* Sun = NewObject<UDirectionalLightComponent>(this, TEXT("KochiSun"));
    Sun->SetupAttachment(SceneRoot);
    Sun->SetMobility(EComponentMobility::Movable);
    Sun->SetRelativeRotation(FRotator(-38.f, -28.f, 0.f));
    Sun->SetLightColor(FLinearColor(1.f, 0.83f, 0.69f));
    Sun->SetIntensity(65000.f);
    Sun->SetCastShadows(true);
    AddInstanceComponent(Sun);
    Sun->RegisterComponent();

    USkyLightComponent* Sky = NewObject<USkyLightComponent>(this, TEXT("KochiSkyLight"));
    Sky->SetupAttachment(SceneRoot);
    Sky->SetMobility(EComponentMobility::Movable);
    Sky->SetSourceType(ESkyLightSourceType::SLS_CapturedScene);
    Sky->SetIntensity(1.15f);
    Sky->bRealTimeCapture = false;
    AddInstanceComponent(Sky);
    Sky->RegisterComponent();
    Sky->RecaptureSky();

    UExponentialHeightFogComponent* Fog = NewObject<UExponentialHeightFogComponent>(this, TEXT("KochiAtmosphere"));
    Fog->SetupAttachment(SceneRoot);
    Fog->SetMobility(EComponentMobility::Movable);
    Fog->SetFogDensity(0.000025f);
    Fog->SetFogHeightFalloff(0.12f);
    Fog->SetFogInscatteringColor(FLinearColor(0.48f, 0.53f, 0.56f));
    AddInstanceComponent(Fog);
    Fog->RegisterComponent();
}

void AKochiCityBuilder::BuildGroundAndRoads()
{
    AddBox(TEXT("Ground"), FVector(0.f, 0.f, -90.f), FVector(72000.f, 72000.f, 160.f),
           FLinearColor(0.16f, 0.21f, 0.13f), 0.f, true);

    for (int32 Index = -3; Index <= 3; ++Index)
    {
        const float Line = static_cast<float>(Index) * StreetGrid;
        AddBox(TEXT("Road"), FVector(0.f, Line, -18.f), FVector(64000.f, RoadWidth, 36.f), Asphalt);
        AddBox(TEXT("Road"), FVector(Line, 0.f, -17.f), FVector(RoadWidth, 64000.f, 36.f), Asphalt);

        for (float Side : {-1.f, 1.f})
        {
            AddBox(TEXT("Sidewalk"), FVector(0.f, Line + Side * 800.f, -1.f),
                   FVector(64000.f, SidewalkWidth, 28.f), Pavement);
            AddBox(TEXT("Sidewalk"), FVector(Line + Side * 800.f, 0.f, -1.f),
                   FVector(SidewalkWidth, 64000.f, 28.f), Pavement);
        }

        for (float Along = -30000.f; Along <= 30000.f; Along += 850.f)
        {
            if (FMath::Abs(Along - Line) < 950.f) continue;
            AddBox(TEXT("LaneYellow"), FVector(Along, Line - 32.f, 2.f), FVector(390.f, 14.f, 4.f), LaneYellow, 0.f, false);
            AddBox(TEXT("LaneYellow"), FVector(Along, Line + 32.f, 2.f), FVector(390.f, 14.f, 4.f), LaneYellow, 0.f, false);
            AddBox(TEXT("LaneWhite"), FVector(Along, Line - 385.f, 2.f), FVector(260.f, 12.f, 4.f), LaneWhite, 0.f, false);
            AddBox(TEXT("LaneWhite"), FVector(Along, Line + 385.f, 2.f), FVector(260.f, 12.f, 4.f), LaneWhite, 0.f, false);
            AddBox(TEXT("LaneYellow"), FVector(Line - 32.f, Along, 2.f), FVector(14.f, 390.f, 4.f), LaneYellow, 0.f, false);
            AddBox(TEXT("LaneYellow"), FVector(Line + 32.f, Along, 2.f), FVector(14.f, 390.f, 4.f), LaneYellow, 0.f, false);
            AddBox(TEXT("LaneWhite"), FVector(Line - 385.f, Along, 2.f), FVector(12.f, 260.f, 4.f), LaneWhite, 0.f, false);
            AddBox(TEXT("LaneWhite"), FVector(Line + 385.f, Along, 2.f), FVector(12.f, 260.f, 4.f), LaneWhite, 0.f, false);
        }
    }
}

bool AKochiCityBuilder::IsReservedLandmark(const FVector& Location) const
{
    return FVector::Dist2D(Location, FamilyHomeLocation) < 2900.f
        || FVector::Dist2D(Location, GarageLocation) < 3200.f
        || FVector::Dist2D(Location, CrashSiteLocation) < 2600.f
        || FVector::Dist2D(Location, FVector(1050.f, 400.f, 0.f)) < 2100.f;
}

void AKochiCityBuilder::AddGenericBuilding(const FVector& Center, float Width, float Depth, float Height,
                                          bool bFacingY, int32 PaletteIndex)
{
    const FLinearColor Palette[] = {
        FLinearColor(0.67f, 0.61f, 0.49f), FLinearColor(0.37f, 0.53f, 0.42f),
        FLinearColor(0.43f, 0.53f, 0.58f), FLinearColor(0.66f, 0.39f, 0.31f),
        FLinearColor(0.72f, 0.68f, 0.56f), FLinearColor(0.78f, 0.76f, 0.67f)
    };
    const FLinearColor Wall = Palette[PaletteIndex % UE_ARRAY_COUNT(Palette)];
    const float Yaw = bFacingY ? 0.f : 90.f;
    const FVector Extents = bFacingY ? FVector(Width, Depth, Height) : FVector(Depth, Width, Height);
    AddBox(FName(*FString::Printf(TEXT("BuildingWall_%d"), PaletteIndex % UE_ARRAY_COUNT(Palette))), Center + FVector(0.f, 0.f, Height * 0.5f), Extents, Wall, Yaw, true);
    AddBox(TEXT("BuildingRoof"), Center + FVector(0.f, 0.f, Height + 12.f),
           FVector(Extents.X + 90.f, Extents.Y + 90.f, 24.f), BrickRed, 0.f, true);

    const float Side = bFacingY ? FMath::Sign(Center.Y - FMath::RoundToFloat(Center.Y / StreetGrid) * StreetGrid)
                                : FMath::Sign(Center.X - FMath::RoundToFloat(Center.X / StreetGrid) * StreetGrid);
    const int32 Floors = FMath::Max(1, FMath::RoundToInt(Height / 300.f));
    for (int32 Floor = 0; Floor < Floors; ++Floor)
    {
        const float Z = 135.f + Floor * 285.f;
        for (float AlongSign : {-1.f, 1.f})
        {
            const FVector WindowPos = bFacingY
                ? FVector(Center.X + AlongSign * Width * 0.25f, Center.Y - Side * (Depth * 0.5f + 3.f), Z)
                : FVector(Center.X - Side * (Depth * 0.5f + 3.f), Center.Y + AlongSign * Width * 0.25f, Z);
            AddBox(TEXT("Window"), WindowPos,
                   bFacingY ? FVector(150.f, 18.f, 135.f) : FVector(18.f, 150.f, 135.f),
                   Glass, 0.f, false);
        }
    }
    AddBox(TEXT("Door"), Center + (bFacingY
        ? FVector(0.f, -Side * (Depth * 0.5f + 8.f), 105.f)
        : FVector(-Side * (Depth * 0.5f + 8.f), 0.f, 105.f)),
        bFacingY ? FVector(100.f, 24.f, 210.f) : FVector(24.f, 100.f, 210.f), Wood, 0.f, false);
}

void AKochiCityBuilder::BuildBuildings()
{
    for (int32 RoadIndex = -3; RoadIndex <= 3; ++RoadIndex)
    {
        const float RoadLine = static_cast<float>(RoadIndex) * StreetGrid;
        for (int32 Segment = -3; Segment < 3; ++Segment)
        {
            const float Along = static_cast<float>(Segment) * StreetGrid + StreetGrid * 0.5f;
            for (int32 SideInt : {-1, 1})
            {
                const float Side = static_cast<float>(SideInt);
                FVector Horizontal(Along, RoadLine + Side * 1770.f, 0.f);
                if (!IsReservedLandmark(Horizontal))
                {
                    const float Depth = 1350.f + static_cast<float>((Segment + RoadIndex + 12) % 4) * 120.f;
                    AddGenericBuilding(Horizontal, 1800.f + static_cast<float>((Segment + 8) % 3) * 250.f,
                        Depth, 300.f + static_cast<float>((RoadIndex + Segment + 8) % 3) * 180.f,
                        true, FMath::Abs(Segment * 3 + RoadIndex * 2));
                }

                FVector Vertical(RoadLine + Side * 1770.f, Along, 0.f);
                if (!IsReservedLandmark(Vertical))
                {
                    const float Depth = 1300.f + static_cast<float>((Segment - RoadIndex + 12) % 4) * 100.f;
                    AddGenericBuilding(Vertical, 1750.f + static_cast<float>((Segment + 10) % 3) * 260.f,
                        Depth, 300.f + static_cast<float>((RoadIndex - Segment + 8) % 3) * 170.f,
                        false, FMath::Abs(Segment * 2 + RoadIndex * 3 + 1));
                }
            }
        }
    }
}

void AKochiCityBuilder::BuildStreetLife()
{
    // Sparse palm clusters and low greenery: instancing keeps draw-call count modest on phones.
    for (int32 LineIndex = -3; LineIndex <= 3; ++LineIndex)
    {
        const float Line = static_cast<float>(LineIndex) * StreetGrid;
        for (int32 Segment = -3; Segment <= 3; ++Segment)
        {
            const float Along = static_cast<float>(Segment) * 8500.f;
            for (float Side : {-1.f, 1.f})
            {
                FVector TreeLocation(Along, Line + Side * 1050.f, 0.f);
                if (!IsReservedLandmark(TreeLocation))
                {
                    AddCylinder(TEXT("PalmTrunk"), TreeLocation + FVector(0.f, 0.f, 240.f),
                                58.f, 480.f, FLinearColor(0.27f, 0.19f, 0.12f), true);
                    AddSphere(TEXT("PalmCrown"), TreeLocation + FVector(0.f, 0.f, 500.f),
                              FVector(260.f, 260.f, 180.f), Leaf);
                    AddSphere(TEXT("Shrub"), TreeLocation + FVector(180.f, 45.f, 40.f),
                              FVector(180.f, 140.f, 80.f), FLinearColor(0.15f, 0.28f, 0.12f));
                }
                FVector OtherSide(Line + Side * 1050.f, Along, 0.f);
                if (!IsReservedLandmark(OtherSide))
                {
                    AddCylinder(TEXT("PalmTrunk"), OtherSide + FVector(0.f, 0.f, 230.f),
                                54.f, 460.f, FLinearColor(0.27f, 0.19f, 0.12f), true);
                    AddSphere(TEXT("PalmCrown"), OtherSide + FVector(0.f, 0.f, 490.f),
                              FVector(240.f, 240.f, 170.f), Leaf);
                }
            }
        }
    }
}

void AKochiCityBuilder::BuildFamilyHome()
{
    const FVector C = FamilyHomeLocation;
    const FLinearColor Wall(0.68f, 0.62f, 0.49f);
    AddBox(TEXT("HomeFloor"), C + FVector(0.f, 0.f, 2.f), FVector(2200.f, 1500.f, 24.f),
           FLinearColor(0.42f, 0.20f, 0.14f), 0.f, true);
    // A deliberate cutaway home: wall sections leave the doorway open and do not trap the camera.
    AddBox(TEXT("HomeWall"), C + FVector(0.f, -735.f, 190.f), FVector(2200.f, 30.f, 380.f), Wall, 0.f, false);
    AddBox(TEXT("HomeWall"), C + FVector(-1085.f, 0.f, 190.f), FVector(30.f, 1500.f, 380.f), Wall, 0.f, false);
    AddBox(TEXT("HomeWall"), C + FVector(1085.f, 0.f, 190.f), FVector(30.f, 1500.f, 380.f), Wall, 0.f, false);
    AddBox(TEXT("HomeWall"), C + FVector(-650.f, 735.f, 190.f), FVector(900.f, 30.f, 380.f), Wall, 0.f, false);
    AddBox(TEXT("HomeWall"), C + FVector(650.f, 735.f, 190.f), FVector(900.f, 30.f, 380.f), Wall, 0.f, false);
    AddBox(TEXT("HomeDoor"), C + FVector(0.f, 720.f, 110.f), FVector(35.f, 24.f, 220.f), Wood, 0.f, false);
    AddBox(TEXT("HomeWindow"), C + FVector(-750.f, 747.f, 245.f), FVector(220.f, 16.f, 150.f), Glass, 0.f, false);
    AddBox(TEXT("HomeWindow"), C + FVector(750.f, 747.f, 245.f), FVector(220.f, 16.f, 150.f), Glass, 0.f, false);

    // Familiar living-room shapes and a framed photograph form an inspectable first interior.
    AddBox(TEXT("Sofa"), C + FVector(-470.f, -440.f, 95.f), FVector(620.f, 180.f, 170.f),
           FLinearColor(0.21f, 0.25f, 0.19f), 0.f, false);
    AddBox(TEXT("Sofa"), C + FVector(-470.f, -530.f, 145.f), FVector(620.f, 45.f, 100.f),
           FLinearColor(0.25f, 0.29f, 0.22f), 0.f, false);
    AddBox(TEXT("CoffeeTable"), C + FVector(300.f, -160.f, 58.f), FVector(410.f, 280.f, 22.f), Wood, 0.f, false);
    AddBox(TEXT("CoffeeLeg"), C + FVector(150.f, -65.f, 28.f), FVector(18.f, 18.f, 55.f), Wood, 0.f, false);
    AddBox(TEXT("CoffeeLeg"), C + FVector(450.f, -65.f, 28.f), FVector(18.f, 18.f, 55.f), Wood, 0.f, false);
    AddBox(TEXT("FamilyPhotoFrame"), C + FVector(650.f, -705.f, 270.f), FVector(220.f, 18.f, 170.f), Wood, 0.f, false);
    AddBox(TEXT("FamilyPhoto"), C + FVector(650.f, -694.f, 270.f), FVector(180.f, 8.f, 130.f),
           FLinearColor(0.75f, 0.67f, 0.48f), 0.f, false);
    AddBox(TEXT("OldTV"), C + FVector(-830.f, -250.f, 120.f), FVector(180.f, 120.f, 130.f),
           FLinearColor(0.055f, 0.06f, 0.055f), 0.f, false);
    AddCylinder(TEXT("PedestalFan"), C + FVector(-830.f, 200.f, 80.f), 20.f, 160.f, Wood, false);
    AddSphere(TEXT("PedestalFanCage"), C + FVector(-830.f, 200.f, 175.f), FVector(95.f, 35.f, 95.f), Glass);
}

void AKochiCityBuilder::BuildRafiGarage()
{
    const FVector C(16450.f, 4500.f, 0.f);
    const FLinearColor Wall(0.45f, 0.48f, 0.42f);
    AddBox(TEXT("GarageWall"), C + FVector(0.f, 0.f, 230.f), FVector(1500.f, 2600.f, 460.f), Wall);
    AddBox(TEXT("GarageRoof"), C + FVector(0.f, 0.f, 475.f), FVector(1600.f, 2700.f, 40.f), BrickRed);
    AddBox(TEXT("GarageDoor"), C + FVector(755.f, 0.f, 170.f), FVector(22.f, 1180.f, 340.f),
           FLinearColor(0.12f, 0.14f, 0.14f), 0.f, false);
    AddBox(TEXT("GarageTrim"), C + FVector(770.f, 0.f, 365.f), FVector(24.f, 1340.f, 24.f),
           FLinearColor(0.75f, 0.65f, 0.38f), 0.f, false);
    AddSign(TEXT("RAFI AUTO WORKS"), FVector(17310.f, 4500.f, 405.f), FRotator::ZeroRotator);

    // Rafi is represented at the garage as a recognizable human-sized figure for the first pass.
    AddBox(TEXT("RafiShirt"), FVector(17200.f, 4200.f, 122.f), FVector(42.f, 46.f, 70.f),
           FLinearColor(0.17f, 0.29f, 0.20f), 0.f, false);
    AddSphere(TEXT("RafiHead"), FVector(17200.f, 4200.f, 174.f), FVector(27.f, 27.f, 29.f),
              FLinearColor(0.47f, 0.29f, 0.20f));
    AddBox(TEXT("RafiHair"), FVector(17196.f, 4200.f, 190.f), FVector(29.f, 29.f, 10.f),
           FLinearColor(0.035f, 0.03f, 0.025f), 0.f, false);
    AddBox(TEXT("RafiLegs"), FVector(17190.f, 4200.f, 52.f), FVector(30.f, 34.f, 55.f),
           FLinearColor(0.12f, 0.13f, 0.12f), 0.f, false);
}

void AKochiCityBuilder::BuildCrashSite()
{
    const FVector C = CrashSiteLocation + FVector(150.f, 580.f, 0.f);
    AddBox(TEXT("WreckBody"), C + FVector(0.f, 0.f, 75.f), FVector(410.f, 180.f, 95.f),
           FLinearColor(0.23f, 0.24f, 0.22f), -17.f, true);
    AddBox(TEXT("WreckCabin"), C + FVector(-38.f, 0.f, 138.f), FVector(205.f, 150.f, 55.f),
           FLinearColor(0.08f, 0.12f, 0.12f), -17.f, false);
    AddBox(TEXT("WreckDoor"), C + FVector(25.f, 96.f, 75.f), FVector(140.f, 18.f, 68.f),
           FLinearColor(0.31f, 0.19f, 0.14f), -24.f, false);
    AddCylinder(TEXT("WreckWheel"), C + FVector(-115.f, 100.f, 25.f), 67.f, 22.f,
                FLinearColor(0.035f, 0.035f, 0.032f), false);
    AddCylinder(TEXT("WreckWheel"), C + FVector(125.f, 100.f, 25.f), 67.f, 22.f,
                FLinearColor(0.035f, 0.035f, 0.032f), false);
    AddBox(TEXT("CrashDebris"), C + FVector(-220.f, -80.f, 10.f), FVector(95.f, 42.f, 8.f),
           FLinearColor(0.39f, 0.34f, 0.25f), 37.f, false);
    AddBox(TEXT("CrashDebris"), C + FVector(220.f, 130.f, 10.f), FVector(75.f, 38.f, 7.f),
           FLinearColor(0.39f, 0.34f, 0.25f), -14.f, false);
}

void AKochiCityBuilder::BuildTeaStall()
{
    const FVector C(-4500.f, 1770.f, 0.f);
    AddBox(TEXT("TeaStallWall"), C + FVector(0.f, 0.f, 170.f), FVector(1200.f, 950.f, 340.f),
           FLinearColor(0.55f, 0.42f, 0.28f), 0.f, true);
    AddBox(TEXT("TeaStallAwning"), C + FVector(0.f, 0.f, 365.f), FVector(1350.f, 1050.f, 35.f),
           FLinearColor(0.63f, 0.20f, 0.13f), 0.f, true);
    AddBox(TEXT("TeaCounter"), C + FVector(0.f, 480.f, 85.f), FVector(1000.f, 90.f, 170.f),
           Wood, 0.f, false);
    AddSign(TEXT("CHAYA KADA"), C + FVector(0.f, 495.f, 290.f), FRotator(0.f, 0.f, 0.f));
}

void AKochiCityBuilder::AddSign(const FString& Text, const FVector& Location, const FRotator& Rotation)
{
    UTextRenderComponent* Sign = NewObject<UTextRenderComponent>(this);
    Sign->SetupAttachment(SceneRoot);
    Sign->SetText(FText::FromString(Text));
    Sign->SetWorldSize(100.f);
    Sign->SetTextRenderColor(FColor(255, 229, 173));
    Sign->SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
    Sign->SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
    Sign->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Sign->SetWorldLocation(Location);
    Sign->SetWorldRotation(Rotation);
    Sign->RegisterComponent();
}