using UnityEngine;

namespace KochiHomecoming.Interaction
{
    public sealed class BasicWorldInteractable : MonoBehaviour, IWorldInteractable
    {
        [SerializeField] private string prompt = "Inspect";
        [SerializeField, TextArea] private string response = "You look around.";
        [SerializeField] private string nextObjective = "";
        [SerializeField] private HomecomingMissionSystem missionSystem;

        public string GetPrompt() => prompt;

        public bool CanInteract(Transform interactor)
        {
            return interactor != null && Vector3.Distance(interactor.position, transform.position) <= 3.4f;
        }

        public void Interact(Transform interactor)
        {
            if (!CanInteract(interactor)) return;

            if (missionSystem != null)
            {
                if (!string.IsNullOrWhiteSpace(nextObjective))
                    missionSystem.SetObjective(nextObjective);
                missionSystem.ShowToast(response);
            }
            else
            {
                Debug.Log(response);
            }
        }

        public void Configure(string interactionPrompt, string interactionResponse,
            string objectiveAfterInteraction, HomecomingMissionSystem system)
        {
            prompt = interactionPrompt;
            response = interactionResponse;
            nextObjective = objectiveAfterInteraction;
            missionSystem = system;
        }
    }
}
