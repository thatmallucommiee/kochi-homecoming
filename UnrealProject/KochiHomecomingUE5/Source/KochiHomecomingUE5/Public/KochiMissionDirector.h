#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "KochiMissionDirector.generated.h"

class UStaticMeshComponent;
class USceneComponent;
class UStaticMesh;

UCLASS()
class KOCHIHOMECOMINGUE5_API AKochiMissionDirector : public AActor
{
    GENERATED_BODY()

public:
    AKochiMissionDirector();
    virtual void Tick(float DeltaSeconds) override;
    void TryInteract();
    int32 GetObjectiveIndex() const { return ObjectiveIndex; }

private:
    UPROPERTY(VisibleAnywhere)
    TObjectPtr<USceneComponent> SceneRoot;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UStaticMeshComponent> WaypointBeam;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UStaticMeshComponent> WaypointCap;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> CubeMesh;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> SphereMesh;

    int32 ObjectiveIndex = 0;
    float DistanceForObjective = 0.f;
    FVector LastPlayerLocation = FVector::ZeroVector;
    bool bHaveLastLocation = false;
    float MarkerTime = 0.f;

    FVector GetObjectiveLocation() const;
    bool ObjectiveHasMarker() const;
    bool IsAtObjectiveLocation(const FVector& PlayerLocation, float Radius) const;
    void AdvanceObjective(const FText& StoryMessage);
    void RefreshHUD();
};