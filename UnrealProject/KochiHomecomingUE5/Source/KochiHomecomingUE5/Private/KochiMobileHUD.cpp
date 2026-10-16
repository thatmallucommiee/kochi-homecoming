#include "KochiMobileHUD.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/TextBlock.h"
#include "Components/Border.h"
#include "Blueprint/WidgetTree.h"

void UKochiMobileHUD::NativeConstruct()
{
    Super::NativeConstruct();
    if (!WidgetTree) return;

    RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("RootCanvas"));
    WidgetTree->RootWidget = RootCanvas;

    AddText(TEXT("ObjectiveLabel"), RootCanvas,
        FText::FromString(TEXT("KOCHI: HOMECOMING\nPROLOGUE — THE RETURN")),
        FAnchors(0.f, 0.f, 0.f, 0.f), FMargin(24.f, 20.f, 650.f, 112.f), 22);

    StoryLabel = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), TEXT("StoryMessage"));
    StoryLabel->SetColorAndOpacity(FSlateColor(FLinearColor(1.f, 0.82f, 0.53f)));
    StoryLabel->SetJustification(ETextJustify::Center);
    StoryLabel->SetAutoWrapText(true);
    UCanvasPanelSlot* StorySlot = RootCanvas->AddChildToCanvas(StoryLabel);
    StorySlot->SetAnchors(FAnchors(0.5f, 0.f, 0.5f, 0.f));
    StorySlot->SetAlignment(FVector2D(0.5f, 0.f));
    StorySlot->SetOffsets(FMargin(-360.f, 24.f, 360.f, 110.f));
    StoryLabel->SetVisibility(ESlateVisibility::Collapsed);

    UButton* RunButton = AddButton(TEXT("RunButton"), FText::FromString(TEXT("RUN")),
        FAnchors(0.f, 0.f, 0.f, 0.f), FMargin(24.f, 144.f, 176.f, 204.f));
    RunButton->OnPressed.AddDynamic(this, &UKochiMobileHUD::HandleRunPressed);
    RunButton->OnReleased.AddDynamic(this, &UKochiMobileHUD::HandleRunReleased);

    UButton* InteractButton = AddButton(TEXT("InteractButton"), FText::FromString(TEXT("INTERACT")),
        FAnchors(1.f, 0.f, 1.f, 0.f), FMargin(-196.f, 24.f, -24.f, 92.f));
    InteractButton->OnClicked.AddDynamic(this, &UKochiMobileHUD::HandleInteractClicked);

    DriveButton = AddButton(TEXT("DriveButton"), FText::FromString(TEXT("DRIVE")),
        FAnchors(1.f, 0.f, 1.f, 0.f), FMargin(-196.f, 104.f, -24.f, 172.f));
    DriveButton->OnClicked.AddDynamic(this, &UKochiMobileHUD::HandleDriveClicked);
    DriveButtonLabel = Cast<UTextBlock>(DriveButton->GetChildAt(0));
    DriveButton->SetVisibility(ESlateVisibility::Collapsed);
}

UButton* UKochiMobileHUD::AddButton(const FName Name, const FText& Text,
                                    const FAnchors& Anchors, const FMargin& Offsets)
{
    UButton* Button = WidgetTree->ConstructWidget<UButton>(UButton::StaticClass(), Name);
    UTextBlock* Label = WidgetTree->ConstructWidget<UTextBlock>(
        UTextBlock::StaticClass(), *FString::Printf(TEXT("%sLabel"), *Name.ToString()));
    Label->SetText(Text);
    Label->SetJustification(ETextJustify::Center);
    Label->SetColorAndOpacity(FSlateColor(FLinearColor(0.98f, 0.95f, 0.86f)));
    Button->AddChild(Label);

    UCanvasPanelSlot* Slot = RootCanvas->AddChildToCanvas(Button);
    Slot->SetAnchors(Anchors);
    Slot->SetOffsets(Offsets);
    return Button;
}

void UKochiMobileHUD::AddText(const FName Name, UCanvasPanel* Canvas, const FText& Text,
                              const FAnchors& Anchors, const FMargin& Offsets, int32 FontSize)
{
    UTextBlock* Label = WidgetTree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), Name);
    Label->SetText(Text);
    Label->SetColorAndOpacity(FSlateColor(FLinearColor(0.96f, 0.92f, 0.82f)));
    Label->SetAutoWrapText(true);
    Label->SetFont(FSlateFontInfo());
    Label->SetJustification(ETextJustify::Left);
    ObjectiveLabel = Label;

    UCanvasPanelSlot* Slot = Canvas->AddChildToCanvas(Label);
    Slot->SetAnchors(Anchors);
    Slot->SetOffsets(Offsets);
}

void UKochiMobileHUD::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
    Super::NativeTick(MyGeometry, InDeltaTime);
    if (StorySecondsRemaining > 0.f)
    {
        StorySecondsRemaining -= InDeltaTime;
        if (StorySecondsRemaining <= 0.f && StoryLabel)
        {
            StoryLabel->SetVisibility(ESlateVisibility::Collapsed);
        }
    }
}

void UKochiMobileHUD::SetObjectiveText(const FText& Text)
{
    if (ObjectiveLabel) ObjectiveLabel->SetText(Text);
}

void UKochiMobileHUD::ShowStoryMessage(const FText& Text, float Duration)
{
    if (!StoryLabel) return;
    StoryLabel->SetText(Text);
    StoryLabel->SetVisibility(ESlateVisibility::HitTestInvisible);
    StorySecondsRemaining = FMath::Max(1.f, Duration);
}

void UKochiMobileHUD::SetDriveButtonVisible(bool bVisible)
{
    if (DriveButton)
    {
        DriveButton->SetVisibility(bVisible ? ESlateVisibility::Visible : ESlateVisibility::Collapsed);
    }
}

void UKochiMobileHUD::SetDriveButtonText(const FText& Text)
{
    if (DriveButtonLabel) DriveButtonLabel->SetText(Text);
}

void UKochiMobileHUD::HandleInteractClicked() { OnInteractRequested.Broadcast(); }
void UKochiMobileHUD::HandleDriveClicked() { OnDriveRequested.Broadcast(); }
void UKochiMobileHUD::HandleRunPressed() { OnRunPressed.Broadcast(); }
void UKochiMobileHUD::HandleRunReleased() { OnRunReleased.Broadcast(); }