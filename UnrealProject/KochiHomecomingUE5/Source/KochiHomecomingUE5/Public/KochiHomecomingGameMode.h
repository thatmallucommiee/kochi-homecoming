#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "KochiHomecomingGameMode.generated.h"

UCLASS()
class KOCHIHOMECOMINGUE5_API AKochiHomecomingGameMode : public AGameModeBase
{
    GENERATED_BODY()

public:
    AKochiHomecomingGameMode();
    virtual void StartPlay() override;
    virtual AActor* ChoosePlayerStart_Implementation(AController* Player) override;

private:
    bool bWorldActorsSpawned = false;
};