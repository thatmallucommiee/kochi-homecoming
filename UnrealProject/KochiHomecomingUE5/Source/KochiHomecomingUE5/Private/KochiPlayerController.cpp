#include "KochiPlayerController.h"
#include "KochiMobileHUD.h"
#include "KochiPlayerCharacter.h"
#include "KochiVehiclePawn.h"
#include "KochiMissionDirector.h"
#include "EngineUtils.h"
#include "Kismet/GameplayStatics.h"

AKochiPlayerController::AKochiPlayerController()
{
    PrimaryActorTick.bCanEverTick = true;
    bEnableTouchEvents = true;
    bEnableClickEvents = true;
    bShowMouseCursor = false;
}

void AKochiPlayerController::BeginPlay()
{
    Super::BeginPlay();
    if (!IsLocalController()) return;

    FInputModeGameAndUI InputMode;
    InputMode.SetHideCursorDuringCapture(true);
    InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::LockInFullscreen);
    SetInputMode(InputMode);
    MobileHUD = CreateWidget<UKochiMobileHUD>(this, UKochiMobileHUD::StaticClass());
    if (MobileHUD)
    {
        MobileHUD->AddToViewport(10);
        MobileHUD->OnInteractRequested.AddDynamic(this, &AKochiPlayerController::HandleInteractRequested);
        MobileHUD->OnDriveRequested.AddDynamic(this, &AKochiPlayerController::HandleDriveRequested);
        MobileHUD->OnRunPressed.AddDynamic(this, &AKochiPlayerController::HandleRunPressed);
        MobileHUD->OnRunReleased.AddDynamic(this, &AKochiPlayerController::HandleRunReleased);
        MobileHUD->SetDriveButtonVisible(false);
        MobileHUD->SetObjectiveText(FText::FromString(TEXT("KOCHI: HOMECOMING\nPROLOGUE — THE RETURN\nTake a look around the street")));
        MobileHUD->ShowStoryMessage(FText::FromString(TEXT("Kochi, 2026. Vivek returns after his father's death.")), 6.f);
    }
}

void AKochiPlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();
    if (!InputComponent) return;
    InputComponent->BindAction(TEXT("Interact"), IE_Pressed, this, &AKochiPlayerController::InteractAction);
    InputComponent->BindAction(TEXT("Drive"), IE_Pressed, this, &AKochiPlayerController::DriveAction);
    InputComponent->BindAction(TEXT("Sprint"), IE_Pressed, this, &AKochiPlayerController::SprintStart);
    InputComponent->BindAction(TEXT("Sprint"), IE_Released, this, &AKochiPlayerController::SprintStop);
}

void AKochiPlayerController::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    PromptRefreshTimer += DeltaSeconds;
    if (PromptRefreshTimer >= 0.2f)
    {
        PromptRefreshTimer = 0.f;
        RefreshDrivePrompt();
    }
}

void AKochiPlayerController::RefreshDrivePrompt()
{
    if (!MobileHUD || !GetPawn()) return;
    if (Cast<AKochiVehiclePawn>(GetPawn()))
    {
        MobileHUD->SetDriveButtonText(FText::FromString(TEXT("EXIT CAR")));
        MobileHUD->SetDriveButtonVisible(true);
        return;
    }

    AKochiVehiclePawn* Nearest = nullptr;
    float NearestDistance = 500.f;
    for (TActorIterator<AKochiVehiclePawn> It(GetWorld()); It; ++It)
    {
        if (It->IsOccupied()) continue;
        const float Distance = FVector::Dist2D(GetPawn()->GetActorLocation(), It->GetActorLocation());
        if (Distance < NearestDistance)
        {
            NearestDistance = Distance;
            Nearest = *It;
        }
    }
    MobileHUD->SetDriveButtonVisible(Nearest != nullptr);
    MobileHUD->SetDriveButtonText(FText::FromString(TEXT("DRIVE")));
}

void AKochiPlayerController::InteractAction() { HandleInteractRequested(); }
void AKochiPlayerController::DriveAction() { HandleDriveRequested(); }
void AKochiPlayerController::SprintStart() { HandleRunPressed(); }
void AKochiPlayerController::SprintStop() { HandleRunReleased(); }

void AKochiPlayerController::HandleInteractRequested()
{
    if (Cast<AKochiVehiclePawn>(GetPawn())) return;
    if (AKochiMissionDirector* Director = Cast<AKochiMissionDirector>(
            UGameplayStatics::GetActorOfClass(this, AKochiMissionDirector::StaticClass())))
    {
        Director->TryInteract();
    }
}

void AKochiPlayerController::HandleDriveRequested() { TryDriveOrExit(); }

void AKochiPlayerController::TryDriveOrExit()
{
    if (AKochiVehiclePawn* CurrentVehicle = Cast<AKochiVehiclePawn>(GetPawn()))
    {
        CurrentVehicle->ExitVehicle(this);
        return;
    }

    AKochiPlayerCharacter* Character = Cast<AKochiPlayerCharacter>(GetPawn());
    if (!Character) return;
    AKochiVehiclePawn* Nearest = nullptr;
    float NearestDistance = 500.f;
    for (TActorIterator<AKochiVehiclePawn> It(GetWorld()); It; ++It)
    {
        if (It->IsOccupied()) continue;
        const float Distance = FVector::Dist2D(Character->GetActorLocation(), It->GetActorLocation());
        if (Distance < NearestDistance)
        {
            NearestDistance = Distance;
            Nearest = *It;
        }
    }
    if (Nearest) Nearest->EnterVehicle(this, Character);
}

void AKochiPlayerController::HandleRunPressed()
{
    if (AKochiPlayerCharacter* Character = Cast<AKochiPlayerCharacter>(GetPawn()))
    {
        Character->SetSprinting(true);
    }
}

void AKochiPlayerController::HandleRunReleased()
{
    if (AKochiPlayerCharacter* Character = Cast<AKochiPlayerCharacter>(GetPawn()))
    {
        Character->SetSprinting(false);
    }
}