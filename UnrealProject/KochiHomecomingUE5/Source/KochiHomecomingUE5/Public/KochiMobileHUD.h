#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "KochiMobileHUD.generated.h"

class UButton;
class UCanvasPanel;
class UTextBlock;

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FKochiHUDAction);

UCLASS()
class KOCHIHOMECOMINGUE5_API UKochiMobileHUD : public UUserWidget
{
    GENERATED_BODY()

public:
    virtual void NativeConstruct() override;
    virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;

    UPROPERTY(BlueprintAssignable, Category="Kochi|Input")
    FKochiHUDAction OnInteractRequested;

    UPROPERTY(BlueprintAssignable, Category="Kochi|Input")
    FKochiHUDAction OnDriveRequested;

    UPROPERTY(BlueprintAssignable, Category="Kochi|Input")
    FKochiHUDAction OnRunPressed;

    UPROPERTY(BlueprintAssignable, Category="Kochi|Input")
    FKochiHUDAction OnRunReleased;

    void SetObjectiveText(const FText& Text);
    void ShowStoryMessage(const FText& Text, float Duration = 4.f);
    void SetDriveButtonVisible(bool bVisible);
    void SetDriveButtonText(const FText& Text);

private:
    UPROPERTY(Transient)
    TObjectPtr<UCanvasPanel> RootCanvas;

    UPROPERTY(Transient)
    TObjectPtr<UTextBlock> ObjectiveLabel;

    UPROPERTY(Transient)
    TObjectPtr<UTextBlock> StoryLabel;

    UPROPERTY(Transient)
    TObjectPtr<UButton> DriveButton;

    UPROPERTY(Transient)
    TObjectPtr<UTextBlock> DriveButtonLabel;

    UButton* AddButton(const FName Name, const FText& Text, const FAnchors& Anchors,
                       const FMargin& Offsets);
    void AddText(const FName Name, UCanvasPanel* Canvas, const FText& Text,
                 const FAnchors& Anchors, const FMargin& Offsets, int32 FontSize);
    UFUNCTION() void HandleInteractClicked();
    UFUNCTION() void HandleDriveClicked();
    UFUNCTION() void HandleRunPressed();
    UFUNCTION() void HandleRunReleased();

    float StorySecondsRemaining = 0.f;
};