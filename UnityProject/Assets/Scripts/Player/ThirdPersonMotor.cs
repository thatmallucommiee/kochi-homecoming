using UnityEngine;

namespace KochiHomecoming.Player
{
    [RequireComponent(typeof(CharacterController))]
    public sealed class ThirdPersonMotor : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private Transform cameraTransform;
        [SerializeField] private Animator animator;

        [Header("Movement")]
        [SerializeField, Min(0f)] private float walkSpeed = 2.2f;
        [SerializeField, Min(0f)] private float runSpeed = 4.8f;
        [SerializeField, Min(0f)] private float rotationSharpness = 14f;
        [SerializeField] private float gravity = -22f;

        private CharacterController controller;
        private Vector2 moveInput;
        private bool runHeld;
        private float verticalVelocity;
        private bool inputEnabled = true;

        public void SetMoveInput(Vector2 value) => moveInput = Vector2.ClampMagnitude(value, 1f);
        public void SetRunHeld(bool value) => runHeld = value;
        public void SetInputEnabled(bool value)
        {
            inputEnabled = value;
            if (!value) { moveInput = Vector2.zero; runHeld = false; }
        }

        private void Awake()
        {
            controller = GetComponent<CharacterController>();
            if (cameraTransform == null && Camera.main != null)
                cameraTransform = Camera.main.transform;
        }

        private void Update()
        {
            Vector2 input = inputEnabled ? moveInput : Vector2.zero;
            Vector3 forward = cameraTransform != null ? cameraTransform.forward : transform.forward;
            Vector3 right = cameraTransform != null ? cameraTransform.right : transform.right;
            forward.y = 0f;
            right.y = 0f;
            forward.Normalize();
            right.Normalize();

            Vector3 planar = Vector3.ClampMagnitude(forward * input.y + right * input.x, 1f);
            float speed = runHeld ? runSpeed : walkSpeed;

            if (planar.sqrMagnitude > 0.001f)
            {
                Quaternion target = Quaternion.LookRotation(planar, Vector3.up);
                transform.rotation = Quaternion.Slerp(transform.rotation, target,
                    1f - Mathf.Exp(-rotationSharpness * Time.deltaTime));
            }

            if (controller.isGrounded && verticalVelocity < 0f) verticalVelocity = -2f;
            verticalVelocity += gravity * Time.deltaTime;
            Vector3 velocity = planar * speed;
            velocity.y = verticalVelocity;
            controller.Move(velocity * Time.deltaTime);

            if (animator != null)
            {
                animator.SetFloat("Speed", planar.magnitude * (runHeld ? 1f : 0.5f),
                    0.1f, Time.deltaTime);
                animator.SetBool("Grounded", controller.isGrounded);
            }
        }
    }
}
