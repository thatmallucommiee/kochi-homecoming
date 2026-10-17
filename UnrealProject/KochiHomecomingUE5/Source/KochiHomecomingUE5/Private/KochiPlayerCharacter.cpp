#include "KochiPlayerCharacter.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/Material.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
    UMaterialInstanceDynamic* MakeTintedMaterial(UObject* Owner, const FLinearColor& Color)
    {
        UMaterialInterface* Base = LoadObject<UMaterialInterface>(
            nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
        if (!Base)
        {
            Base = UMaterial::GetDefaultMaterial(MD_Surface);
        }
        UMaterialInstanceDynamic* Material = UMaterialInstanceDynamic::Create(Base, Owner);
        if (Material)
        {
            Material->SetVectorParameterValue(TEXT("Color"), Color);
        }
        return Material;
    }
}

AKochiPlayerCharacter::AKochiPlayerCharacter()
{
    PrimaryActorTick.bCanEverTick = true;
    GetCapsuleComponent()->InitCapsuleSize(34.f, 94.f);
    GetCharacterMovement()->MaxWalkSpeed = WalkSpeed;
    GetCharacterMovement()->MaxAcceleration = 1600.f;
    GetCharacterMovement()->BrakingDecelerationWalking = 1850.f;
    GetCharacterMovement()->bOrientRotationToMovement = true;
    GetCharacterMovement()->RotationRate = FRotator(0.f, 560.f, 0.f);
    bUseControllerRotationPitch = false;
    bUseControllerRotationYaw = false;
    bUseControllerRotationRoll = false;

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(GetCapsuleComponent());
    CameraBoom->TargetArmLength = 410.f;
    CameraBoom->SetRelativeLocation(FVector(0.f, 0.f, 52.f));
    CameraBoom->SetRelativeRotation(FRotator(-11.f, 0.f, 0.f));
    CameraBoom->bUsePawnControlRotation = true;
    CameraBoom->bEnableCameraLag = true;
    CameraBoom->CameraLagSpeed = 9.f;
    CameraBoom->bDoCollisionTest = true;

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeRef(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeRef.Succeeded()) CubeMesh = CubeRef.Object;
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereRef(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    if (SphereRef.Succeeded()) SphereMesh = SphereRef.Object;

    BuildVisualModel();
}

UStaticMeshComponent* AKochiPlayerCharacter::MakePart(
    const FName Name,
    UStaticMesh* Mesh,
    const FVector& RelativeLocation,
    const FVector& DimensionsCm,
    const FLinearColor& Color,
    USceneComponent* Parent)
{
    UStaticMeshComponent* Part = CreateDefaultSubobject<UStaticMeshComponent>(Name);
    Part->SetupAttachment(Parent ? Parent : GetCapsuleComponent());
    Part->SetStaticMesh(Mesh);
    Part->SetRelativeLocation(RelativeLocation);
    Part->SetRelativeScale3D(DimensionsCm / 100.f);
    Part->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Part->SetGenerateOverlapEvents(false);
    Part->CastShadow = true;
    if (UMaterialInstanceDynamic* Material = MakeTintedMaterial(this, Color))
    {
        Part->SetMaterial(0, Material);
    }
    return Part;
}

void AKochiPlayerCharacter::BuildVisualModel()
{
    // A temporary, self-contained visual body keeps the UE project asset-free and cookable.
    // Replace these primitives with a rigged character asset in the art pass.
    MakePart(TEXT("Torso"), CubeMesh, FVector(0.f, 0.f, 5.f), FVector(44.f, 31.f, 59.f), FLinearColor(0.13f, 0.29f, 0.38f));
    MakePart(TEXT("Waist"), CubeMesh, FVector(0.f, 0.f, -28.f), FVector(40.f, 30.f, 24.f), FLinearColor(0.13f, 0.16f, 0.18f));
    MakePart(TEXT("Head"), SphereMesh, FVector(0.f, 0.f, 51.f), FVector(28.f, 27.f, 31.f), FLinearColor(0.47f, 0.29f, 0.20f));
    MakePart(TEXT("Hair"), CubeMesh, FVector(-1.f, 0.f, 64.f), FVector(30.f, 29.f, 12.f), FLinearColor(0.035f, 0.03f, 0.025f));
    MakePart(TEXT("LeftEye"), SphereMesh, FVector(13.f, -6.f, 53.f), FVector(3.f, 3.f, 3.f), FLinearColor::Black);
    MakePart(TEXT("RightEye"), SphereMesh, FVector(13.f, 6.f, 53.f), FVector(3.f, 3.f, 3.f), FLinearColor::Black);

    LeftArmPivot = CreateDefaultSubobject<USceneComponent>(TEXT("LeftArmPivot"));
    LeftArmPivot->SetupAttachment(GetCapsuleComponent());
    LeftArmPivot->SetRelativeLocation(FVector(0.f, -25.f, 26.f));
    MakePart(TEXT("LeftArm"), CubeMesh, FVector(0.f, 0.f, -21.f), FVector(15.f, 16.f, 43.f), FLinearColor(0.13f, 0.29f, 0.38f), LeftArmPivot);
    MakePart(TEXT("LeftHand"), SphereMesh, FVector(0.f, 0.f, -44.f), FVector(12.f, 12.f, 12.f), FLinearColor(0.47f, 0.29f, 0.20f), LeftArmPivot);

    RightArmPivot = CreateDefaultSubobject<USceneComponent>(TEXT("RightArmPivot"));
    RightArmPivot->SetupAttachment(GetCapsuleComponent());
    RightArmPivot->SetRelativeLocation(FVector(0.f, 25.f, 26.f));
    MakePart(TEXT("RightArm"), CubeMesh, FVector(0.f, 0.f, -21.f), FVector(15.f, 16.f, 43.f), FLinearColor(0.13f, 0.29f, 0.38f), RightArmPivot);
    MakePart(TEXT("RightHand"), SphereMesh, FVector(0.f, 0.f, -44.f), FVector(12.f, 12.f, 12.f), FLinearColor(0.47f, 0.29f, 0.20f), RightArmPivot);

    LeftLegPivot = CreateDefaultSubobject<USceneComponent>(TEXT("LeftLegPivot"));
    LeftLegPivot->SetupAttachment(GetCapsuleComponent());
    LeftLegPivot->SetRelativeLocation(FVector(0.f, -12.f, -37.f));
    MakePart(TEXT("LeftLeg"), CubeMesh, FVector(0.f, 0.f, -22.f), FVector(17.f, 17.f, 49.f), FLinearColor(0.12f, 0.14f, 0.16f), LeftLegPivot);
    MakePart(TEXT("LeftShoe"), CubeMesh, FVector(9.f, 0.f, -47.f), FVector(27.f, 19.f, 11.f), FLinearColor(0.025f, 0.025f, 0.025f), LeftLegPivot);

    RightLegPivot = CreateDefaultSubobject<USceneComponent>(TEXT("RightLegPivot"));
    RightLegPivot->SetupAttachment(GetCapsuleComponent());
    RightLegPivot->SetRelativeLocation(FVector(0.f, 12.f, -37.f));
    MakePart(TEXT("RightLeg"), CubeMesh, FVector(0.f, 0.f, -22.f), FVector(17.f, 17.f, 49.f), FLinearColor(0.12f, 0.14f, 0.16f), RightLegPivot);
    MakePart(TEXT("RightShoe"), CubeMesh, FVector(9.f, 0.f, -47.f), FVector(27.f, 19.f, 11.f), FLinearColor(0.025f, 0.025f, 0.025f), RightLegPivot);
}

void AKochiPlayerCharacter::BeginPlay()
{
    Super::BeginPlay();
}

void AKochiPlayerCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    const float Speed = GetVelocity().Size2D();
    const float Swing = (Speed > 18.f) ? FMath::Sin(GetWorld()->GetTimeSeconds() * (Speed > SprintSpeed ? 12.f : 8.f)) * 24.f : 0.f;
    // Vivek faces local +X, so the limbs swing forward/back around local Y (pitch).
    if (LeftArmPivot) LeftArmPivot->SetRelativeRotation(FRotator(0.f, Swing, 0.f));
    if (RightArmPivot) RightArmPivot->SetRelativeRotation(FRotator(0.f, -Swing, 0.f));
    if (LeftLegPivot) LeftLegPivot->SetRelativeRotation(FRotator(0.f, -Swing * 0.7f, 0.f));
    if (RightLegPivot) RightLegPivot->SetRelativeRotation(FRotator(0.f, Swing * 0.7f, 0.f));
}

void AKochiPlayerCharacter::SetupPlayerInputComponent(UInputComponent* Input)
{
    Super::SetupPlayerInputComponent(Input);
    Input->BindAxis(TEXT("MoveForward"), this, &AKochiPlayerCharacter::MoveForward);
    Input->BindAxis(TEXT("MoveRight"), this, &AKochiPlayerCharacter::MoveRight);
    Input->BindAxis(TEXT("Turn"), this, &AKochiPlayerCharacter::LookYaw);
    Input->BindAxis(TEXT("LookUp"), this, &AKochiPlayerCharacter::LookPitch);
    Input->BindAction(TEXT("Jump"), IE_Pressed, this, &ACharacter::Jump);
    Input->BindAction(TEXT("Jump"), IE_Released, this, &ACharacter::StopJumping);
}

void AKochiPlayerCharacter::MoveForward(float Value)
{
    if (!Controller || FMath::IsNearlyZero(Value)) return;
    const FRotator YawRotation(0.f, Controller->GetControlRotation().Yaw, 0.f);
    AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::X), Value);
}

void AKochiPlayerCharacter::MoveRight(float Value)
{
    if (!Controller || FMath::IsNearlyZero(Value)) return;
    const FRotator YawRotation(0.f, Controller->GetControlRotation().Yaw, 0.f);
    AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::Y), Value);
}

void AKochiPlayerCharacter::LookYaw(float Value)
{
    AddControllerYawInput(Value);
}

void AKochiPlayerCharacter::LookPitch(float Value)
{
    AddControllerPitchInput(Value);
}

void AKochiPlayerCharacter::SetSprinting(bool bEnabled)
{
    if (GetCharacterMovement())
    {
        GetCharacterMovement()->MaxWalkSpeed = bEnabled ? SprintSpeed : WalkSpeed;
    }
}