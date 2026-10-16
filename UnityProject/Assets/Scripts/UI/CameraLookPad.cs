using System;
using UnityEngine;
using UnityEngine.EventSystems;

namespace KochiHomecoming.UI
{
    public sealed class CameraLookPad : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
    {
        private Action<Vector2> onDragDelta;
        public void Initialize(Action<Vector2> callback) => onDragDelta = callback;
        public void OnPointerDown(PointerEventData eventData) { }
        public void OnDrag(PointerEventData eventData) => onDragDelta?.Invoke(eventData.delta);
        public void OnPointerUp(PointerEventData eventData) { }
    }
}
