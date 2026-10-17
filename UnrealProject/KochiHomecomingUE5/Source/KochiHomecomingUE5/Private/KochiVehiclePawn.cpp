#include "KochiVehiclePawn.h"
#include "KochiPlayerCharacter.h"
#include "KochiPlayerController.h"
#include "Camera/CameraComponent.h"
#include "Components/BoxComponent.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/Material.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
    UMaterialInstanceDynamic* CarMaterial(UObject* Owner, const FLinearColor& Color)
    {
        UMaterialInterface* Base = LoadObject<UMaterialInterface>(
            nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
        if (!Base) Base = UMaterial::GetDefaultMaterial(MD_Surface);
        UMaterialInstanceDynamic* Result = UMaterialInstanceDynamic::Create(Base, Owner);
        if (Result) Result->SetVectorParameterValue(TEXT("Color"), Color);
        return Result;
    }
}

AKochiVehiclePawn::AKochiVehiclePawn()
{
    PrimaryActorTick.bCanEverTick = true;
    SetReplicates(false);
    AutoPossessPlayer = EAutoReceiveInput::Disabled;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeRef(TEXT("/Engine/BasicShapes/Cube.Cube"));
    if (CubeRef.Succeeded()) CubeMesh = CubeRef.Object;
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderRef(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    if (CylinderRef.Succeeded()) CylinderMesh = CylinderRef.Object;

    // Physics stays on an unscaled root; visual parts remain correctly proportioned.
    PhysicsBody = CreateDefaultSubobject<UBoxComponent>(TEXT("PhysicsBody"));
    SetRootComponent(PhysicsBody);
    PhysicsBody->InitBoxExtent(FVector(210.f, 92.f, 58.f));
    PhysicsBody->SetCollisionProfileName(TEXT("BlockAll"));
    PhysicsBody->SetSimulatePhysics(true);
    PhysicsBody->SetMassOverrideInKg(NAME_None, 1180.f, true);
    PhysicsBody->SetLinearDamping(0.26f);
    PhysicsBody->SetAngularDamping(3.8f);
    PhysicsBody->SetEnableGravity(true);
    PhysicsBody->SetGenerateOverlapEvents(false);

    BodyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("CarBodyVisual"));
    BodyMesh->SetupAttachment(PhysicsBody);
    BodyMesh->SetStaticMesh(CubeMesh);
    BodyMesh->SetRelativeScale3D(FVector(4.10f, 1.82f, 0.54f));
    BodyMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    if (UMaterialInstanceDynamic* Paint = CarMaterial(this, FLinearColor(0.10f, 0.22f, 0.31f)))
    {
        BodyMesh->SetMaterial(0, Paint);
    }

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CarCameraBoom"));
    CameraBoom->SetupAttachment(PhysicsBody);
    CameraBoom->TargetArmLength = 720.f;
    CameraBoom->SetRelativeLocation(FVector(-80.f, 0.f, 200.f));
    CameraBoom->SetRelativeRotation(FRotator(-9.f, 0.f, 0.f));
    CameraBoom->bUsePawnControlRotation = false;
    CameraBoom->bEnableCameraLag = true;
    CameraBoom->CameraLagSpeed = 6.f;

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("CarCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;

    BuildCarVisuals();
}

void AKochiVehiclePawn::BuildCarVisuals()
{
    if (!PhysicsBody || !CubeMesh || !CylinderMesh) return;
    auto AddPart = [this](FName Name, UStaticMesh* Mesh, FVector Location, FVector Dimensions,
                         const FLinearColor& Color, FRotator Rotation = FRotator::ZeroRotator)
    {
        UStaticMeshComponent* Part = CreateDefaultSubobject<UStaticMeshComponent>(Name);
        Part->SetupAttachment(PhysicsBody);
        Part->SetStaticMesh(Mesh);
        Part->SetRelativeLocation(Location);
        Part->SetRelativeRotation(Rotation);
        Part->SetRelativeScale3D(Dimensions / 100.f);
        Part->SetCollisionEnabled(ECollisionEnabled::NoCollision);
        Part->SetGenerateOverlapEvents(false);
        Part->CastShadow = true;
        if (UMaterialInstanceDynamic* Material = CarMaterial(this, Color)) Part->SetMaterial(0, Material);
        return Part;
    };

    const FLinearColor Paint(0.10f, 0.22f, 0.31f);
    const FLinearColor Glass(0.035f, 0.075f, 0.085f);
    const FLinearColor Trim(0.035f, 0.04f, 0.04f);
    const FLinearColor Chrome(0.55f, 0.57f, 0.53f);
    AddPart(TEXT("Bonnet"), CubeMesh, FVector(125.f, 0.f, 18.f), FVector(150.f, 176.f, 23.f), Paint);
    AddPart(TEXT("Boot"), CubeMesh, FVector(-145.f, 0.f, 17.f), FVector(110.f, 176.f, 26.f), Paint);
    AddPart(TEXT("Roof"), CubeMesh, FVector(-15.f, 0.f, 88.f), FVector(165.f, 145.f, 18.f), Paint);
    AddPart(TEXT("FrontGlass"), CubeMesh, FVector(72.f, 0.f, 61.f), FVector(15.f, 142.f, 62.f), Glass, FRotator(0.f, 0.f, -15.f));
    AddPart(TEXT("RearGlass"), CubeMesh, FVector(-100.f, 0.f, 60.f), FVector(14.f, 140.f, 55.f), Glass, FRotator(0.f, 0.f, 18.f));
    for (float Side : {-1.f, 1.f})
    {
        AddPart(Side < 0.f ? TEXT("LeftSideGlass") : TEXT("RightSideGlass"), CubeMesh,
            FVector(-20.f, Side * 74.f, 58.f), FVector(135.f, 10.f, 42.f), Glass);
        AddPart(Side < 0.f ? TEXT("LeftDoorTrim") : TEXT("RightDoorTrim"), CubeMesh,
            FVector(-20.f, Side * 94.f, 0.f), FVector(190.f, 7.f, 12.f), Chrome);
        for (float Longitudinal : {-135.f, 135.f})
        {
            UStaticMeshComponent* Wheel = AddPart(
                FName(*FString::Printf(TEXT("Wheel_%s_%s"), Side < 0.f ? TEXT("L") : TEXT("R"),
                    Longitudinal < 0.f ? TEXT("Rear") : TEXT("Front"))),
                CylinderMesh, FVector(Longitudinal, Side * 87.f, -32.f),
                FVector(66.f, 66.f, 23.f), Trim, FRotator(90.f, 0.f, 0.f));
            Wheels.Add(Wheel);
            AddPart(FName(*FString::Printf(TEXT("Hub_%s_%s"), Side < 0.f ? TEXT("L") : TEXT("R"),
                    Longitudinal < 0.f ? TEXT("Rear") : TEXT("Front"))),
                CylinderMesh, FVector(Longitudinal, Side * 101.f, -32.f),
                FVector(30.f, 30.f, 7.f), Chrome, FRotator(90.f, 0.f, 0.f));
        }
    }
    AddPart(TEXT("FrontBumper"), CubeMesh, FVector(210.f, 0.f, -20.f), FVector(16.f, 182.f, 15.f), Chrome);
    AddPart(TEXT("RearBumper"), CubeMesh, FVector(-210.f, 0.f, -20.f), FVector(16.f, 182.f, 15.f), Chrome);
}

void AKochiVehiclePawn::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (!IsOccupied() || !PhysicsBody || !PhysicsBody->IsSimulatingPhysics()) return;

    const FVector Velocity = PhysicsBody->GetPhysicsLinearVelocity();
    const float Speed2D = FVector(Velocity.X, Velocity.Y, 0.f).Size();
    const FVector Forward = GetActorForwardVector();
    const float SpeedFactor = FMath::Clamp(Speed2D / 2500.f, 0.12f, 1.f);

    if (!FMath::IsNearlyZero(ThrottleInput))
    {
        PhysicsBody->AddForce(Forward * (ThrottleInput * 480000.f));
    }
    if (FMath::Abs(SteeringInput) > 0.02f && Speed2D > 80.f)
    {
        PhysicsBody->AddTorqueInRadians(FVector(0.f, 0.f, SteeringInput * 9500000.f * SpeedFactor));
    }

    if (Speed2D > 4800.f)
    {
        FVector ClampedVelocity = FVector(Velocity.X, Velocity.Y, 0.f).GetSafeNormal() * 4800.f;
        ClampedVelocity.Z = Velocity.Z;
        PhysicsBody->SetPhysicsLinearVelocity(ClampedVelocity);
    }

    const float WheelSpin = Speed2D * DeltaSeconds * 0.08f;
    for (UStaticMeshComponent* Wheel : Wheels)
    {
        if (Wheel) Wheel->AddLocalRotation(FRotator(0.f, WheelSpin, 0.f));
    }
}

void AKochiVehiclePawn::SetupPlayerInputComponent(UInputComponent* Input)
{
    Super::SetupPlayerInputComponent(Input);
    Input->BindAxis(TEXT("VehicleThrottle"), this, &AKochiVehiclePawn::SetThrottle);
    Input->BindAxis(TEXT("VehicleSteer"), this, &AKochiVehiclePawn::SetSteering);
    Input->BindAxis(TEXT("Turn"), this, &AKochiVehiclePawn::SetSteering);
}

void AKochiVehiclePawn::SetThrottle(float Value)
{
    ThrottleInput = FMath::Clamp(Value, -1.f, 1.f);
}

void AKochiVehiclePawn::SetSteering(float Value)
{
    SteeringInput = FMath::Clamp(Value, -1.f, 1.f);
}

void AKochiVehiclePawn::EnterVehicle(AKochiPlayerController* Controller, AKochiPlayerCharacter* Driver)
{
    if (!Controller || !Driver || IsOccupied()) return;
    SavedDriver = Driver;
    Driver->SetActorEnableCollision(false);
    Driver->SetActorHiddenInGame(true);
    Driver->SetActorTickEnabled(false);
    Controller->Possess(this);
    ThrottleInput = 0.f;
    SteeringInput = 0.f;
}

void AKochiVehiclePawn::ExitVehicle(AKochiPlayerController* Controller)
{
    if (!Controller || !SavedDriver) return;

    AKochiPlayerCharacter* Driver = SavedDriver;
    SavedDriver = nullptr;
    ThrottleInput = 0.f;
    SteeringInput = 0.f;
    if (PhysicsBody && PhysicsBody->IsSimulatingPhysics())
    {
        PhysicsBody->SetPhysicsLinearVelocity(PhysicsBody->GetPhysicsLinearVelocity() * 0.35f);
        PhysicsBody->SetPhysicsAngularVelocityInRadians(FVector::ZeroVector);
    }

    const FVector ExitLocation = GetActorLocation() - GetActorRightVector() * 270.f + FVector(0.f, 0.f, 115.f);
    Driver->SetActorLocation(ExitLocation, false, nullptr, ETeleportType::TeleportPhysics);
    Driver->SetActorRotation(FRotator(0.f, GetActorRotation().Yaw, 0.f));
    Driver->SetActorHiddenInGame(false);
    Driver->SetActorEnableCollision(true);
    Driver->SetActorTickEnabled(true);
    Controller->Possess(Driver);
}