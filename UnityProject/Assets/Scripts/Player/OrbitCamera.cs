using UnityEngine;

namespace KochiHomecoming.Player
{
    public sealed class OrbitCamera : MonoBehaviour
    {
        [SerializeField] private Transform target;
        [SerializeField] private Vector3 targetOffset = new Vector3(0f, 1.55f, 0f);
        [SerializeField, Min(0.1f)] private float distance = 4.2f;
        [SerializeField] private float sensitivity = 0.12f;
        [SerializeField] private float minPitch = -25f;
        [SerializeField] private float maxPitch = 65f;
        [SerializeField, Min(0f)] private float followSharpness = 16f;
        [SerializeField] private LayerMask obstructionMask = ~0;

        private float yaw;
        private float pitch = 12f;
        private Vector2 lookInput;

        public void SetLookInput(Vector2 delta) => lookInput = delta;
        public void ClearLookInput() => lookInput = Vector2.zero;

        private void LateUpdate()
        {
            if (target == null) return;

            yaw += lookInput.x * sensitivity;
            pitch = Mathf.Clamp(pitch - lookInput.y * sensitivity, minPitch, maxPitch);
            lookInput = Vector2.zero;

            Quaternion rotation = Quaternion.Euler(pitch, yaw, 0f);
            Vector3 focus = target.position + targetOffset;
            Vector3 desired = focus - rotation * Vector3.forward * distance;

            if (Physics.SphereCast(focus, 0.2f, (desired - focus).normalized,
                    out RaycastHit hit, distance, obstructionMask, QueryTriggerInteraction.Ignore))
                desired = focus - rotation * Vector3.forward * Mathf.Max(0.35f, hit.distance - 0.12f);

            float blend = 1f - Mathf.Exp(-followSharpness * Time.deltaTime);
            transform.position = Vector3.Lerp(transform.position, desired, blend);
            transform.rotation = rotation;
        }

        public void SetTarget(Transform newTarget) => target = newTarget;
    }
}
