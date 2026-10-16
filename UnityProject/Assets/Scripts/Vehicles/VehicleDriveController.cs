using UnityEngine;

namespace KochiHomecoming.Vehicles
{
    [RequireComponent(typeof(Rigidbody))]
    [RequireComponent(typeof(Collider))]
    public sealed class VehicleDriveController : MonoBehaviour
    {
        [Header("Driving")]
        [SerializeField, Min(1f)] private float acceleration = 11f;
        [SerializeField, Min(1f)] private float maxForwardSpeed = 19f;
        [SerializeField, Min(1f)] private float maxReverseSpeed = 6f;
        [SerializeField, Min(1f)] private float steeringStrength = 68f;
        [SerializeField, Min(0.1f)] private float lateralGrip = 5f;
        [SerializeField, Min(0.1f)] private float brakeStrength = 12f;

        private Rigidbody body;
        private Vector2 input;
        private bool brakeHeld;
        private bool boostHeld;

        public bool IsOccupied { get; private set; }
        public Transform ExitPoint { get; private set; }

        private void Awake()
        {
            body = GetComponent<Rigidbody>();
            body.mass = 1250f;
            body.interpolation = RigidbodyInterpolation.Interpolate;
            body.collisionDetectionMode = CollisionDetectionMode.Continuous;
            body.constraints = RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationZ;
            body.centerOfMass = new Vector3(0f, -0.35f, 0f);
        }

        public void SetExitPoint(Transform exitPoint) => ExitPoint = exitPoint;
        public void SetInput(Vector2 value) => input = IsOccupied ? Vector2.ClampMagnitude(value, 1f) : Vector2.zero;
        public void SetBrakeHeld(bool value) => brakeHeld = IsOccupied && value;
        public void SetBoostHeld(bool value) => boostHeld = IsOccupied && value;

        public bool TryEnter(Transform player)
        {
            if (player == null || IsOccupied || Vector3.Distance(player.position, transform.position) > 4.2f)
                return false;

            IsOccupied = true;
            input = Vector2.zero;
            brakeHeld = false;
            body.WakeUp();
            return true;
        }

        public Vector3 LeavePosition()
        {
            if (ExitPoint != null) return ExitPoint.position;
            return transform.position + transform.right * 2.2f + Vector3.up * 0.1f;
        }

        public void Exit()
        {
            IsOccupied = false;
            input = Vector2.zero;
            brakeHeld = false;
            boostHeld = false;
        }

        private void FixedUpdate()
        {
            if (!IsOccupied)
            {
                input = Vector2.zero;
                return;
            }

            Vector3 planarVelocity = Vector3.ProjectOnPlane(body.linearVelocity, Vector3.up);
            float forwardSpeed = Vector3.Dot(planarVelocity, transform.forward);

            if (brakeHeld)
            {
                body.AddForce(-planarVelocity * brakeStrength, ForceMode.Acceleration);
            }
            else
            {
                float effectiveAcceleration = boostHeld ? acceleration * 1.45f : acceleration;
                if (input.y > 0f && forwardSpeed < maxForwardSpeed)
                    body.AddForce(transform.forward * (input.y * effectiveAcceleration), ForceMode.Acceleration);
                else if (input.y < 0f && forwardSpeed > -maxReverseSpeed)
                    body.AddForce(transform.forward * (input.y * effectiveAcceleration * 0.65f), ForceMode.Acceleration);
            }

            Vector3 localVelocity = transform.InverseTransformDirection(body.linearVelocity);
            localVelocity.x = Mathf.Lerp(localVelocity.x, 0f, lateralGrip * Time.fixedDeltaTime);
            body.linearVelocity = transform.TransformDirection(localVelocity);

            float speedFactor = Mathf.Clamp01(planarVelocity.magnitude / 2f);
            float reverseFactor = forwardSpeed < -0.5f ? -1f : 1f;
            if (Mathf.Abs(input.x) > 0.01f && speedFactor > 0.015f)
            {
                Quaternion turn = Quaternion.Euler(0f,
                    input.x * steeringStrength * speedFactor * reverseFactor * Time.fixedDeltaTime, 0f);
                body.MoveRotation(body.rotation * turn);
            }

            if (planarVelocity.magnitude > maxForwardSpeed * 1.08f)
                body.linearVelocity = Vector3.Lerp(body.linearVelocity,
                    body.linearVelocity.normalized * maxForwardSpeed, 0.15f);
        }
    }
}
