using UnityEngine;

namespace KochiHomecoming.Interaction
{
    public sealed class HomecomingMissionSystem : MonoBehaviour
    {
        [SerializeField] private string missionTitle = "KOCHI: HOMECOMING";
        [SerializeField, TextArea] private string currentObjective = "Return to the family home.";
        [SerializeField] private string toastMessage = "";
        private float toastUntil;

        public string MissionTitle => missionTitle;
        public string CurrentObjective => currentObjective;
        public string ActiveToast => Time.unscaledTime < toastUntil ? toastMessage : "";

        public void SetObjective(string value)
        {
            if (!string.IsNullOrWhiteSpace(value))
                currentObjective = value.Trim();
        }

        public void ShowToast(string value, float duration = 3.5f)
        {
            toastMessage = value ?? "";
            toastUntil = Time.unscaledTime + Mathf.Max(0.5f, duration);
        }
    }
}
