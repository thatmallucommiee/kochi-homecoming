#include "KochiHomecomingGameMode.h"
#include "KochiPlayerCharacter.h"
#include "KochiPlayerController.h"
#include "KochiCityBuilder.h"
#include "KochiMissionDirector.h"
#include "KochiVehiclePawn.h"
#include "GameFramework/PlayerStart.h"
#include "Engine/World.h"

AKochiHomecomingGameMode::AKochiHomecomingGameMode()
{
    DefaultPawnClass = AKochiPlayerCharacter::StaticClass();
    PlayerControllerClass = AKochiPlayerController::StaticClass();
    bStartPlayersAsSpectators = false;
}

AActor* AKochiHomecomingGameMode::ChoosePlayerStart_Implementation(AController* Player)
{
    if (AActor* Existing = Super::ChoosePlayerStart_Implementation(Player))
    {
        return Existing;
    }

    // The project intentionally opens on an engine entry map; create a deterministic spawn.
    if (GetWorld())
    {
        return GetWorld()->SpawnActor<APlayerStart>(
            APlayerStart::StaticClass(),
            FVector(0.f, 450.f, 110.f),
            FRotator(0.f, 0.f, 0.f));
    }
    return nullptr;
}

void AKochiHomecomingGameMode::StartPlay()
{
    Super::StartPlay();

    if (bWorldActorsSpawned || !GetWorld())
    {
        return;
    }
    bWorldActorsSpawned = true;

    GetWorld()->SpawnActor<AKochiCityBuilder>(
        AKochiCityBuilder::StaticClass(),
        FVector::ZeroVector,
        FRotator::ZeroRotator);

    GetWorld()->SpawnActor<AKochiMissionDirector>(
        AKochiMissionDirector::StaticClass(),
        FVector::ZeroVector,
        FRotator::ZeroRotator);

    // A single starter car gives the player a reachable, optional driving interaction.
    GetWorld()->SpawnActor<AKochiVehiclePawn>(
        AKochiVehiclePawn::StaticClass(),
        FVector(1050.f, 400.f, 115.f),
        FRotator::ZeroRotator);
}