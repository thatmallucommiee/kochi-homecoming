using System;
using UnityEngine;
using UnityEngine.EventSystems;

namespace KochiHomecoming.UI
{
    public sealed class HoldButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, ICancelHandler
    {
        private Action<bool> onHeldChanged;
        public void Initialize(Action<bool> callback) => onHeldChanged = callback;
        public void OnPointerDown(PointerEventData eventData) => onHeldChanged?.Invoke(true);
        public void OnPointerUp(PointerEventData eventData) => onHeldChanged?.Invoke(false);
        public void OnCancel(BaseEventData eventData) => onHeldChanged?.Invoke(false);
        private void OnDisable() => onHeldChanged?.Invoke(false);
    }
}
