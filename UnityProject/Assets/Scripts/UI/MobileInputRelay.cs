using UnityEngine;
using KochiHomecoming.Player;

namespace KochiHomecoming.UI
{
    // Wire UI joystick/button callbacks to these methods in the Unity Inspector.
    // Keep movement, camera-look, run, and interaction hit areas separate.
    public sealed class MobileInputRelay : MonoBehaviour
    {
        [SerializeField] private ThirdPersonMotor motor;
        [SerializeField] private OrbitCamera orbitCamera;

        public void Move(Vector2 normalizedDirection)
        {
            if (motor != null) motor.SetMoveInput(normalizedDirection);
        }

        public void RunPressed()
        {
            if (motor != null) motor.SetRunHeld(true);
        }

        public void RunReleased()
        {
            if (motor != null) motor.SetRunHeld(false);
        }

        public void LookDrag(Vector2 pixelDelta)
        {
            if (orbitCamera != null) orbitCamera.SetLookInput(pixelDelta);
        }

        public void LookReleased()
        {
            if (orbitCamera != null) orbitCamera.ClearLookInput();
        }
    }
}
