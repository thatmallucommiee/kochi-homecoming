#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "KochiVehiclePawn.generated.h"

class UBoxComponent;
class USpringArmComponent;
class UCameraComponent;
class UStaticMeshComponent;
class UStaticMesh;
class AKochiPlayerCharacter;
class AKochiPlayerController;

UCLASS()
class KOCHIHOMECOMINGUE5_API AKochiVehiclePawn : public APawn
{
    GENERATED_BODY()

public:
    AKochiVehiclePawn();
    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

    bool IsOccupied() const { return SavedDriver != nullptr; }
    void EnterVehicle(AKochiPlayerController* Controller, AKochiPlayerCharacter* Driver);
    void ExitVehicle(AKochiPlayerController* Controller);

private:
    void SetThrottle(float Value);
    void SetSteering(float Value);
    void BuildCarVisuals();

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UBoxComponent> PhysicsBody;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UStaticMeshComponent> BodyMesh;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere)
    TObjectPtr<UCameraComponent> FollowCamera;

    UPROPERTY(Transient)
    TObjectPtr<AKochiPlayerCharacter> SavedDriver;

    UPROPERTY(Transient)
    TArray<TObjectPtr<UStaticMeshComponent>> Wheels;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> CubeMesh;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> CylinderMesh;

    float ThrottleInput = 0.f;
    float SteeringInput = 0.f;
};