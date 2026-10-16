using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using KochiHomecoming.Interaction;
using KochiHomecoming.Player;
using KochiHomecoming.Vehicles;

namespace KochiHomecoming.UI
{
    public sealed class MobileHUD : MonoBehaviour
    {
        [SerializeField] private ThirdPersonMotor motor;
        [SerializeField] private Transform playerRoot;
        [SerializeField] private OrbitCamera orbitCamera;
        [SerializeField] private VehicleDriveController vehicle;
        [SerializeField] private HomecomingMissionSystem missionSystem;

        private Text missionText;
        private Text promptText;
        private Text toastText;
        private Text vehicleButtonText;
        private Text interactButtonText;
        private Button vehicleButton;
        private Button brakeButton;
        private float nextPromptRefresh;
        private float toastVisibleUntil;
        private BasicWorldInteractable nearbyInteractable;
        private readonly Collider[] interactionHits = new Collider[48];

        public void Configure(ThirdPersonMotor playerMotor, Transform player,
            OrbitCamera cameraRig, VehicleDriveController car, HomecomingMissionSystem missions)
        {
            motor = playerMotor;
            playerRoot = player;
            orbitCamera = cameraRig;
            vehicle = car;
            missionSystem = missions;
        }

        private void Awake()
        {
            Screen.orientation = ScreenOrientation.LandscapeLeft;
            Screen.sleepTimeout = SleepTimeout.NeverSleep;
            Application.targetFrameRate = 60;
            CreateHud();
        }

        private void Update()
        {
            if (missionText != null && missionSystem != null)
                missionText.text = missionSystem.MissionTitle + "\n" + missionSystem.CurrentObjective;

            if (Time.unscaledTime >= nextPromptRefresh)
            {
                nextPromptRefresh = Time.unscaledTime + 0.16f;
                RefreshNearbyInteractable();
            }

            if (vehicleButtonText != null)
            {
                if (vehicle != null && vehicle.IsOccupied)
                    vehicleButtonText.text = "EXIT CAR";
                else if (vehicle != null && playerRoot != null &&
                         Vector3.Distance(playerRoot.position, vehicle.transform.position) <= 4.2f)
                    vehicleButtonText.text = "ENTER CAR";
                else
                    vehicleButtonText.text = "CAR";
            }

            if (interactButtonText != null)
                interactButtonText.text = nearbyInteractable != null
                    ? nearbyInteractable.GetPrompt().ToUpperInvariant()
                    : "INTERACT";

            if (toastText != null && missionSystem != null)
            {
                toastText.text = missionSystem.ActiveToast;
                toastText.enabled = !string.IsNullOrEmpty(toastText.text);
            }

            if (brakeButton != null)
                brakeButton.gameObject.SetActive(vehicle != null && vehicle.IsOccupied);
        }

        private void CreateHud()
        {
            GameObject canvasObject = new GameObject("Homecoming Mobile HUD",
                typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            Canvas canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 10;

            CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920f, 1080f);
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
            scaler.matchWidthOrHeight = 0.45f;

            if (FindFirstObjectByType<EventSystem>() == null)
            {
                GameObject eventSystem = new GameObject("EventSystem",
                    typeof(EventSystem), typeof(StandaloneInputModule));
                eventSystem.transform.SetParent(canvasObject.transform, false);
            }

            // The right half is a camera-look surface. Buttons created afterwards sit above it.
            Image lookImage = CreateImage("Camera Look Area", canvas.transform,
                new Vector2(0.38f, 0f), new Vector2(1f, 1f),
                new Vector2(1f, 0.5f), Vector2.zero, new Vector2(0.01f, 0f, 0f, 0.025f));
            lookImage.raycastTarget = true;
            CameraLookPad lookPad = lookImage.gameObject.AddComponent<CameraLookPad>();
            lookPad.Initialize(delta => { if (orbitCamera != null) orbitCamera.SetLookInput(delta); });

            Image missionPanel = CreateImage("Objective Panel", canvas.transform,
                new Vector2(0f, 1f), new Vector2(0f, 1f),
                new Vector2(0f, 1f), new Vector2(30f, -28f), new Vector2(620f, 126f),
                new Color(0.035f, 0.045f, 0.055f, 0.84f));
            missionPanel.raycastTarget = false;
            missionText = CreateText("Objective Text", missionPanel.transform,
                new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f),
                new Vector2(20f, 12f), Vector2.zero, 26, TextAnchor.MiddleLeft,
                new Color(0.96f, 0.93f, 0.84f));
            missionText.raycastTarget = false;

            toastText = CreateText("Toast Text", canvas.transform,
                new Vector2(0.5f, 0.15f), new Vector2(0.5f, 0.15f), new Vector2(0.5f, 0.5f),
                Vector2.zero, new Vector2(900f, 90f), 29, TextAnchor.MiddleCenter,
                new Color(1f, 0.9f, 0.64f));
            toastText.raycastTarget = false;
            toastText.enabled = false;

            Image joystickBase = CreateImage("Movement Joystick", canvas.transform,
                new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(0f, 0f),
                new Vector2(150f, 145f), new Vector2(250f, 250f),
                new Color(0.10f, 0.12f, 0.14f, 0.48f));
            joystickBase.raycastTarget = true;

            Image joystickKnob = CreateImage("Joystick Knob", joystickBase.transform,
                new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
                Vector2.zero, new Vector2(94f, 94f), new Color(0.9f, 0.84f, 0.68f, 0.74f));
            joystickKnob.raycastTarget = false;
            MobileJoystick joystick = joystickBase.gameObject.AddComponent<MobileJoystick>();
            joystick.Initialize(joystickKnob.rectTransform, OnMoveInput);

            CreateHoldButton("RUN", canvas.transform, new Vector2(1f, 0f),
                new Vector2(1f, 0f), new Vector2(1f, 0f),
                new Vector2(-165f, 248f), new Vector2(142f, 106f),
                new Color(0.43f, 0.22f, 0.12f, 0.88f), OnRunHeld, 27);

            Button interactButton = CreateButton("Interaction Button", "INTERACT", canvas.transform,
                new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(1f, 0f),
                new Vector2(-165f, 120f), new Vector2(220f, 100f),
                new Color(0.12f, 0.28f, 0.27f, 0.92f), Interact, 23);
            interactButtonText = interactButton.GetComponentInChildren<Text>();

            vehicleButton = CreateButton("Vehicle Button", "CAR", canvas.transform,
                new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(1f, 0f),
                new Vector2(-405f, 120f), new Vector2(190f, 100f),
                new Color(0.16f, 0.20f, 0.25f, 0.92f), ToggleVehicle, 23);
            vehicleButtonText = vehicleButton.GetComponentInChildren<Text>();

            brakeButton = CreateHoldButton("BRAKE", canvas.transform, new Vector2(1f, 0f),
                new Vector2(1f, 0f), new Vector2(1f, 0f),
                new Vector2(-405f, 248f), new Vector2(190f, 96f),
                new Color(0.50f, 0.12f, 0.10f, 0.91f), OnBrakeHeld, 23).GetComponent<Button>();
            brakeButton.gameObject.SetActive(false);

            CreateText("Control Hint", canvas.transform,
                new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f),
                new Vector2(0f, 24f), new Vector2(600f, 40f), 18, TextAnchor.MiddleCenter,
                new Color(1f, 1f, 1f, 0.72f)).text = "LEFT: MOVE     RIGHT: LOOK";
        }

        private void OnMoveInput(Vector2 input)
        {
            if (vehicle != null && vehicle.IsOccupied)
                vehicle.SetInput(input);
            else if (motor != null)
                motor.SetMoveInput(input);
        }

        private void OnRunHeld(bool held)
        {
            if (vehicle != null && vehicle.IsOccupied)
                vehicle.SetBoostHeld(held);
            else if (motor != null)
                motor.SetRunHeld(held);
        }

        private void OnBrakeHeld(bool held)
        {
            if (vehicle != null) vehicle.SetBrakeHeld(held);
        }

        private void ToggleVehicle()
        {
            if (vehicle == null || playerRoot == null)
            {
                ShowLocalToast("Vehicle not available.");
                return;
            }

            if (vehicle.IsOccupied)
            {
                Vector3 exit = vehicle.LeavePosition();
                vehicle.Exit();
                playerRoot.SetActive(true);
                playerRoot.position = exit;
                playerRoot.rotation = Quaternion.Euler(0f, vehicle.transform.eulerAngles.y, 0f);
                if (motor != null)
                {
                    motor.enabled = true;
                    motor.SetInputEnabled(true);
                    motor.SetMoveInput(Vector2.zero);
                }
                if (orbitCamera != null) orbitCamera.SetTarget(playerRoot);
                ShowLocalToast("You stepped out of the car.");
                return;
            }

            if (Vector3.Distance(playerRoot.position, vehicle.transform.position) > 4.2f)
            {
                ShowLocalToast("Move closer to the car first.");
                return;
            }

            if (vehicle.TryEnter(playerRoot))
            {
                if (motor != null) motor.SetInputEnabled(false);
                playerRoot.SetActive(false);
                if (orbitCamera != null) orbitCamera.SetTarget(vehicle.transform);
                ShowLocalToast("Drive: joystick. RUN adds throttle. BRAKE slows down.");
            }
        }

        private void Interact()
        {
            if (vehicle != null && vehicle.IsOccupied)
            {
                ShowLocalToast("Use EXIT CAR to leave the vehicle.");
                return;
            }

            RefreshNearbyInteractable();
            if (nearbyInteractable != null && playerRoot != null &&
                nearbyInteractable.CanInteract(playerRoot))
            {
                nearbyInteractable.Interact(playerRoot);
            }
            else
            {
                ShowLocalToast("Nothing close enough to interact with.");
            }
        }

        private void RefreshNearbyInteractable()
        {
            nearbyInteractable = null;
            if (playerRoot == null || !playerRoot.gameObject.activeInHierarchy || vehicle != null && vehicle.IsOccupied)
                return;

            Vector3 center = playerRoot.position + Vector3.up * 1f;
            int count = Physics.OverlapSphereNonAlloc(center, 3.5f, interactionHits,
                ~0, QueryTriggerInteraction.Collide);
            float nearest = float.MaxValue;

            for (int i = 0; i < count; i++)
            {
                Collider hit = interactionHits[i];
                if (hit == null) continue;
                MonoBehaviour[] scripts = hit.GetComponentsInParent<MonoBehaviour>();
                foreach (MonoBehaviour script in scripts)
                {
                    if (script is BasicWorldInteractable candidate && candidate.CanInteract(playerRoot))
                    {
                        float distance = Vector3.Distance(playerRoot.position, candidate.transform.position);
                        if (distance < nearest)
                        {
                            nearest = distance;
                            nearbyInteractable = candidate;
                        }
                    }
                }
                interactionHits[i] = null;
            }
        }

        private void ShowLocalToast(string message)
        {
            if (missionSystem != null)
                missionSystem.ShowToast(message);
            else if (toastText != null)
            {
                toastText.text = message;
                toastText.enabled = true;
                toastVisibleUntil = Time.unscaledTime + 3f;
            }
        }

        private static Image CreateImage(string name, Transform parent, Vector2 anchorMin,
            Vector2 anchorMax, Vector2 pivot, Vector2 position, Vector2 size, Color? tint = null)
        {
            GameObject go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            go.transform.SetParent(parent, false);
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.pivot = pivot;
            rect.anchoredPosition = position;
            rect.sizeDelta = size;
            Image image = go.GetComponent<Image>();
            image.color = tint ?? new Color(0.1f, 0.1f, 0.1f, 0.7f);
            return image;
        }

        private static Text CreateText(string name, Transform parent, Vector2 anchorMin,
            Vector2 anchorMax, Vector2 pivot, Vector2 position, Vector2 size, int fontSize,
            TextAnchor alignment, Color color)
        {
            GameObject go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            go.transform.SetParent(parent, false);
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.pivot = pivot;
            rect.anchoredPosition = position;
            rect.sizeDelta = size;
            Text text = go.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = fontSize;
            text.alignment = alignment;
            text.color = color;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            text.supportRichText = false;
            return text;
        }

        private static Button CreateButton(string name, string label, Transform parent,
            Vector2 anchorMin, Vector2 anchorMax, Vector2 pivot, Vector2 position,
            Vector2 size, Color color, UnityEngine.Events.UnityAction action, int fontSize)
        {
            Image image = CreateImage(name, parent, anchorMin, anchorMax, pivot, position, size, color);
            Button button = image.gameObject.AddComponent<Button>();
            button.targetGraphic = image;
            button.onClick.AddListener(action);
            Text text = CreateText(label + " Label", image.transform,
                Vector2.zero, Vector2.one, new Vector2(0.5f, 0.5f),
                Vector2.zero, Vector2.zero, fontSize, TextAnchor.MiddleCenter,
                new Color(1f, 0.97f, 0.9f));
            text.fontStyle = FontStyle.Bold;
            text.raycastTarget = false;
            return button;
        }

        private static HoldButton CreateHoldButton(string label, Transform parent,
            Vector2 anchorMin, Vector2 anchorMax, Vector2 pivot, Vector2 position,
            Vector2 size, Color color, System.Action<bool> heldChanged, int fontSize)
        {
            Button button = CreateButton(label + " Button", label, parent,
                anchorMin, anchorMax, pivot, position, size, color, () => { }, fontSize);
            HoldButton hold = button.gameObject.AddComponent<HoldButton>();
            hold.Initialize(heldChanged);
            return hold;
        }
    }
}
