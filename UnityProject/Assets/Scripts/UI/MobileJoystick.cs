using System;
using UnityEngine;
using UnityEngine.EventSystems;

namespace KochiHomecoming.UI
{
    public sealed class MobileJoystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
    {
        [SerializeField] private RectTransform knob;
        [SerializeField, Range(0.1f, 1f)] private float deadZone = 0.08f;

        private RectTransform rect;
        private Action<Vector2> onValueChanged;
        private float radius = 80f;

        public void Initialize(RectTransform knobTransform, Action<Vector2> callback)
        {
            knob = knobTransform;
            onValueChanged = callback;
            rect = transform as RectTransform;
            if (rect != null) radius = Mathf.Min(rect.rect.width, rect.rect.height) * 0.34f;
        }

        public void OnPointerDown(PointerEventData eventData) => UpdateInput(eventData);
        public void OnDrag(PointerEventData eventData) => UpdateInput(eventData);

        public void OnPointerUp(PointerEventData eventData)
        {
            if (knob != null) knob.anchoredPosition = Vector2.zero;
            onValueChanged?.Invoke(Vector2.zero);
        }

        private void UpdateInput(PointerEventData eventData)
        {
            if (rect == null) rect = transform as RectTransform;
            if (rect == null) return;

            if (!RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    rect, eventData.position, eventData.pressEventCamera, out Vector2 local))
                return;

            Vector2 normalized = new Vector2(
                local.x / Mathf.Max(1f, rect.rect.width * 0.5f),
                local.y / Mathf.Max(1f, rect.rect.height * 0.5f));

            Vector2 value = Vector2.ClampMagnitude(normalized, 1f);
            if (value.magnitude < deadZone) value = Vector2.zero;

            if (knob != null) knob.anchoredPosition = value * radius;
            onValueChanged?.Invoke(value);
        }
    }
}
