#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "KochiPlayerController.generated.h"

class UKochiMobileHUD;
class AKochiPlayerCharacter;

UCLASS()
class KOCHIHOMECOMINGUE5_API AKochiPlayerController : public APlayerController
{
    GENERATED_BODY()

public:
    AKochiPlayerController();
    virtual void BeginPlay() override;
    virtual void SetupInputComponent() override;
    virtual void Tick(float DeltaSeconds) override;

    UKochiMobileHUD* GetMobileHUD() const { return MobileHUD; }

private:
    UPROPERTY(Transient)
    TObjectPtr<UKochiMobileHUD> MobileHUD;

    float PromptRefreshTimer = 0.f;

    UFUNCTION() void HandleInteractRequested();
    UFUNCTION() void HandleDriveRequested();
    UFUNCTION() void HandleRunPressed();
    UFUNCTION() void HandleRunReleased();
    void TryDriveOrExit();
    void RefreshDrivePrompt();
    void InteractAction();
    void DriveAction();
    void SprintStart();
    void SprintStop();
};