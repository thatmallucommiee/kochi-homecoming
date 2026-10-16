namespace KochiHomecoming.Interaction
{
    public interface IWorldInteractable
    {
        string GetPrompt();
        bool CanInteract(UnityEngine.Transform interactor);
        void Interact(UnityEngine.Transform interactor);
    }
}
