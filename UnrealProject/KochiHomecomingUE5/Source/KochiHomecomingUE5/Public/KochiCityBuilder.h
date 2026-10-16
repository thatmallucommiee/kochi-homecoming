#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "KochiCityBuilder.generated.h"

class UHierarchicalInstancedStaticMeshComponent;
class USceneComponent;
class UStaticMesh;
class UTextRenderComponent;

UCLASS()
class KOCHIHOMECOMINGUE5_API AKochiCityBuilder : public AActor
{
    GENERATED_BODY()

public:
    AKochiCityBuilder();
    virtual void BeginPlay() override;

    static const FVector FamilyHomeLocation;
    static const FVector GarageLocation;
    static const FVector CrashSiteLocation;

private:
    UPROPERTY(Transient)
    TObjectPtr<USceneComponent> SceneRoot;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> CubeMesh;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> CylinderMesh;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> SphereMesh;

    UPROPERTY(Transient)
    TMap<FName, TObjectPtr<UHierarchicalInstancedStaticMeshComponent>> Instancers;

    UHierarchicalInstancedStaticMeshComponent* GetInstancer(
        const FName Style, UStaticMesh* Mesh, const FLinearColor& Color, bool bCollision);
    void AddBox(FName Style, const FVector& Location, const FVector& DimensionsCm,
                const FLinearColor& Color, float Yaw = 0.f, bool bCollision = true);
    void AddCylinder(FName Style, const FVector& Location, float DiameterCm, float HeightCm,
                     const FLinearColor& Color, bool bCollision = false);
    void AddSphere(FName Style, const FVector& Location, const FVector& DimensionsCm,
                   const FLinearColor& Color, bool bCollision = false);
    void BuildGroundAndRoads();
    void BuildBuildings();
    void BuildStreetLife();
    void BuildFamilyHome();
    void BuildRafiGarage();
    void BuildCrashSite();
    void BuildTeaStall();
    void AddSign(const FString& Text, const FVector& Location, const FRotator& Rotation);
    bool IsReservedLandmark(const FVector& Location) const;
    void AddGenericBuilding(const FVector& Center, float Width, float Depth, float Height,
                            bool bFacingY, int32 PaletteIndex);
};