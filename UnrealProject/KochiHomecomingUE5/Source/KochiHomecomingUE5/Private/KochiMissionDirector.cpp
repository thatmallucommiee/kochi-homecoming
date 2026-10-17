#include "KochiMissionDirector.h"
#include "KochiCityBuilder.h"
#include "KochiPlayerController.h"
#include "KochiPlayerCharacter.h"
#include "KochiVehiclePawn.h"
#include "KochiMobileHUD.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/World.h"
#include "Engine/StaticMesh.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/Material.h"
#include "Kismet/GameplayStatics.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
    const FVector HomeDoor(4500.f, 8050.f, 0.f);
    const FVector HomeInterior(4500.f, 7130.f, 100.f);
    const FVector FamilyPhoto(5150.f, 6536.f, 0.f);
    const FVector HomeExit(4500.f, 7970.f, 0.f);
    const FVector RafiAtGarage(17200.f, 4200.f, 0.f);
}

AKochiMissionDirector::AKochiMissionDirector()
{
    PrimaryActorTick.bCanEverTick = true;
    SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("SceneRoot"));
    SetRootComponent(SceneRoot);

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeRef(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeRef.Succeeded()) CubeMesh = CubeRef.Object;
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereRef(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (SphereRef.Succeeded()) SphereMesh = SphereRef.Object;

    WaypointBeam = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("WaypointBeam"));
    WaypointBeam->SetupAttachment(SceneRoot);
    WaypointBeam->SetStaticMesh(CubeMesh);
    WaypointBeam->SetRelativeScale3D(FVector(0.24f, 0.24f, 2.8f));
    WaypointBeam->SetRelativeLocation(FVector(0.f, 0.f, 145.f));
    WaypointBeam->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    WaypointBeam->CastShadow = false;

    WaypointCap = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("WaypointCap"));
    WaypointCap->SetupAttachment(SceneRoot);
    WaypointCap->SetStaticMesh(SphereMesh);
    WaypointCap->SetRelativeScale3D(FVector(0.44f, 0.44f, 0.44f));
    WaypointCap->SetRelativeLocation(FVector(0.f, 0.f, 300.f));
    WaypointCap->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    WaypointCap->CastShadow = false;

    if (UMaterialInterface* Base = LoadObject<UMaterialInterface>(
            nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial")))
    {
        if (UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(Base, this))
        {
            Material->SetVectorParameterValue(TEXT("Color"), FLinearColor(1.f, 0.54f, 0.12f));
            WaypointBeam->SetMaterial(0, Material);
            WaypointCap->SetMaterial(0, Material);
        }
    }
}

void AKochiMissionDirector::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    AKochiPlayerController* PC = Cast<AKochiPlayerController>(UGameplayStatics::GetPlayerController(this, 0));
    APawn* Pawn = PC ? PC->GetPawn() : nullptr;
    if (!Pawn) return;

    const FVector Position = Pawn->GetActorLocation();
    if (bHaveLastLocation)
    {
        const float Step = FVector::Dist2D(Position, LastPlayerLocation);
        if (Step < 2000.f) DistanceForObjective += Step;
    }
    LastPlayerLocation = Position;
    bHaveLastLocation = true;

    switch (ObjectiveIndex)
    {
        case 0:
            if (DistanceForObjective >= 1400.f)
                AdvanceObjective(FText::FromString(TEXT("The neighborhood carries on around Vivek. Find Abraham's house.")));
            break;
        case 1:
            if (IsAtObjectiveLocation(Position, 820.f))
                AdvanceObjective(FText::FromString(TEXT("This is the house where Vivek grew up.")));
            break;
        case 3:
            if (Position.X > 3350.f && Position.X < 5650.f
                && Position.Y > 6400.f && Position.Y < 7950.f
                && DistanceForObjective >= 500.f)
                AdvanceObjective(FText::FromString(TEXT("A family photograph sits near the old furniture.")));
            break;
        case 6:
            if (IsAtObjectiveLocation(Position, 1100.f))
                AdvanceObjective(FText::FromString(TEXT("Rafi is outside the garage. Talk to him.")));
            break;
        case 8:
            if (IsAtObjectiveLocation(Position, 1000.f))
                AdvanceObjective(FText::FromString(TEXT("This is the road where Abraham's car was found.")));
            break;
        default:
            break;
    }

    if (WaypointBeam && WaypointCap)
    {
        const bool bShowMarker = ObjectiveHasMarker() && ObjectiveIndex < 10;
        WaypointBeam->SetVisibility(bShowMarker);
        WaypointCap->SetVisibility(bShowMarker);
        if (bShowMarker)
        {
            SetActorLocation(GetObjectiveLocation());
            MarkerTime += DeltaSeconds;
            const float Pulse = 1.f + FMath::Sin(MarkerTime * 2.8f) * 0.06f;
            WaypointBeam->SetRelativeScale3D(FVector(0.24f * Pulse, 0.24f * Pulse, 2.8f));
            WaypointCap->SetRelativeRotation(FRotator(0.f, MarkerTime * 45.f, 0.f));
        }
    }
}

FVector AKochiMissionDirector::GetObjectiveLocation() const
{
    switch (ObjectiveIndex)
    {
        case 1: return HomeDoor;
        case 2: return HomeDoor;
        case 4: return FamilyPhoto;
        case 5: return HomeExit;
        case 6: return AKochiCityBuilder::GarageLocation;
        case 7: return RafiAtGarage;
        case 8: return AKochiCityBuilder::CrashSiteLocation;
        case 9: return AKochiCityBuilder::CrashSiteLocation;
        default: return FVector::ZeroVector;
    }
}

bool AKochiMissionDirector::ObjectiveHasMarker() const
{
    return ObjectiveIndex == 1 || ObjectiveIndex == 2 || ObjectiveIndex == 4
        || ObjectiveIndex == 5 || ObjectiveIndex == 6 || ObjectiveIndex == 7
        || ObjectiveIndex == 8 || ObjectiveIndex == 9;
}

bool AKochiMissionDirector::IsAtObjectiveLocation(const FVector& PlayerLocation, float Radius) const
{
    return FVector::Dist2D(PlayerLocation, GetObjectiveLocation()) <= Radius;
}

void AKochiMissionDirector::TryInteract()
{
    AKochiPlayerController* PC = Cast<AKochiPlayerController>(UGameplayStatics::GetPlayerController(this, 0));
    APawn* Pawn = PC ? PC->GetPawn() : nullptr;
    if (!Pawn || Cast<AKochiVehiclePawn>(Pawn)) return;

    const FVector Position = Pawn->GetActorLocation();
    switch (ObjectiveIndex)
    {
        case 2:
            if (FVector::Dist2D(Position, HomeDoor) <= 650.f)
            {
                Pawn->SetActorLocation(HomeInterior, false, nullptr, ETeleportType::TeleportPhysics);
                AdvanceObjective(FText::FromString(TEXT("Vivek has not been home in years. The silence feels unfamiliar.")));
            }
            else if (PC->GetMobileHUD()) PC->GetMobileHUD()->ShowStoryMessage(FText::FromString(TEXT("Move closer to the front door.")), 2.f);
            break;
        case 4:
            if (FVector::Dist2D(Position, FamilyPhoto) <= 850.f)
            {
                AdvanceObjective(FText::FromString(TEXT("A photograph from an ordinary family day. For now, it is only a memory.")));
            }
            else if (PC->GetMobileHUD()) PC->GetMobileHUD()->ShowStoryMessage(FText::FromString(TEXT("Move closer to the family photograph.")), 2.f);
            break;
        case 5:
            if (FVector::Dist2D(Position, HomeExit) <= 650.f)
            {
                Pawn->SetActorLocation(FVector(4500.f, 8420.f, 105.f), false, nullptr, ETeleportType::TeleportPhysics);
                AdvanceObjective(FText::FromString(TEXT("Outside, the neighborhood carries on as if nothing has changed.")));
            }
            else if (PC->GetMobileHUD()) PC->GetMobileHUD()->ShowStoryMessage(FText::FromString(TEXT("Head back to the front door.")), 2.f);
            break;
        case 7:
            if (FVector::Dist2D(Position, RafiAtGarage) <= 1000.f)
            {
                AdvanceObjective(FText::FromString(TEXT("Rafi knew Abraham, but how much he knows is not clear yet.")));
            }
            else if (PC->GetMobileHUD()) PC->GetMobileHUD()->ShowStoryMessage(FText::FromString(TEXT("Go to Rafi's garage.")), 2.f);
            break;
        case 9:
            if (FVector::Dist2D(Position, AKochiCityBuilder::CrashSiteLocation) <= 850.f)
            {
                AdvanceObjective(FText::FromString(TEXT("The official account says road accident. Vivek has little else to go on.")));
            }
            else if (PC->GetMobileHUD()) PC->GetMobileHUD()->ShowStoryMessage(FText::FromString(TEXT("Move closer to the roadside wreckage.")), 2.f);
            break;
        default:
            if (PC->GetMobileHUD()) PC->GetMobileHUD()->ShowStoryMessage(FText::FromString(TEXT("Follow the waypoint to continue.")), 2.f);
            break;
    }
}

void AKochiMissionDirector::AdvanceObjective(const FText& StoryMessage)
{
    ++ObjectiveIndex;
    DistanceForObjective = 0.f;
    bHaveLastLocation = false;

    AKochiPlayerController* PC = Cast<AKochiPlayerController>(UGameplayStatics::GetPlayerController(this, 0));
    if (PC && PC->GetMobileHUD())
    {
        PC->GetMobileHUD()->ShowStoryMessage(StoryMessage, 4.f);
        RefreshHUD();
    }
}

void AKochiMissionDirector::RefreshHUD()
{
    AKochiPlayerController* PC = Cast<AKochiPlayerController>(UGameplayStatics::GetPlayerController(this, 0));
    if (!PC || !PC->GetMobileHUD()) return;

    const TCHAR* Objectives[] = {
        TEXT("Take a look around the street"),
        TEXT("Find Abraham's house"),
        TEXT("Enter the family home"),
        TEXT("Look around the living room"),
        TEXT("Inspect the family photograph"),
        TEXT("Leave the house"),
        TEXT("Find Rafi's garage"),
        TEXT("Speak to Rafi"),
        TEXT("Visit the road where Abraham's car was found"),
        TEXT("Examine the roadside")
    };
    const FString Objective = ObjectiveIndex < UE_ARRAY_COUNT(Objectives)
        ? FString(Objectives[ObjectiveIndex])
        : FString(TEXT("PROLOGUE COMPLETE"));
    PC->GetMobileHUD()->SetObjectiveText(FText::FromString(
        FString::Printf(TEXT("KOCHI: HOMECOMING   /   PROLOGUE — THE RETURN\n%s"), *Objective)));
}