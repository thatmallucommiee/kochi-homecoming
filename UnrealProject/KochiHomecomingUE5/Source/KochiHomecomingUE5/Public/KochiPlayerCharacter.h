#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "KochiPlayerCharacter.generated.h"

class UCameraComponent;
class USpringArmComponent;
class UStaticMeshComponent;
class USceneComponent;

UCLASS()
class KOCHIHOMECOMINGUE5_API AKochiPlayerCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AKochiPlayerCharacter();
    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;
    void SetSprinting(bool bEnabled);

protected:
    virtual void BeginPlay() override;

private:
    void MoveForward(float Value);
    void MoveRight(float Value);
    void LookYaw(float Value);
    void LookPitch(float Value);
    void BuildVisualModel();
    UStaticMeshComponent* MakePart(
        const FName Name,
        UStaticMesh* Mesh,
        const FVector& RelativeLocation,
        const FVector& DimensionsCm,
        const FLinearColor& Color,
        USceneComponent* Parent = nullptr);

    UPROPERTY(VisibleAnywhere, Category="Camera")
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere, Category="Camera")
    TObjectPtr<UCameraComponent> FollowCamera;

    UPROPERTY(Transient)
    TObjectPtr<USceneComponent> LeftArmPivot;

    UPROPERTY(Transient)
    TObjectPtr<USceneComponent> RightArmPivot;

    UPROPERTY(Transient)
    TObjectPtr<USceneComponent> LeftLegPivot;

    UPROPERTY(Transient)
    TObjectPtr<USceneComponent> RightLegPivot;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> CubeMesh;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> SphereMesh;

    float WalkSpeed = 365.f;
    float SprintSpeed = 620.f;
};