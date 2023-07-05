using UnityEngine;
using UnityEngine.Events;

public class UserInterfaceRayActivation : MonoBehaviour
{
    [SerializeField] private Transform linkedHandPosition;
    [SerializeField] private LayerMask layerToHit;
    [SerializeField] private float maxDistanceFromCanvas;

    [Header("UI Hover Events")]
    public UnityEvent onUIHoverStart;
    public UnityEvent onUIHoverEnd;

    enum CurrentInteractionState
    {
        DefautMode,
        UIMode
    }
    private CurrentInteractionState currentInteractionMode;

    private void Awake() => currentInteractionMode = CurrentInteractionState.DefautMode;

    private void FixedUpdate()
    {
        RaycastHit hit;

        if(Physics.Raycast(linkedHandPosition.position, linkedHandPosition.forward, out hit, maxDistanceFromCanvas, layerToHit))
        {
            if(currentInteractionMode != CurrentInteractionState.UIMode)
            {
                onUIHoverStart.Invoke();
                currentInteractionMode = CurrentInteractionState.UIMode;
            }
        }
        else
        {
            if(currentInteractionMode == CurrentInteractionState.UIMode)
            {
                onUIHoverEnd.Invoke();
                currentInteractionMode = CurrentInteractionState.DefautMode;
            }
        }
    }
}
