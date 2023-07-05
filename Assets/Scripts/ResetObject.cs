using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit;

namespace LevelUp.Grabinteraction
{
    public class ResetObject : MonoBehaviour
    {
        XRGrabInteractable m_GrabInteractable;

        [Tooltip("The Transfrom that the object will return to ")]
        [SerializeField] Vector3 returnToPosition;
        [SerializeField] float resetDelayTime;

        protected bool shoulReturnHome { get; set; }
        bool isController;
        private void Awake()
        {
            m_GrabInteractable = GetComponent<XRGrabInteractable>();
            returnToPosition = this.transform.position;
            shoulReturnHome = true;
        }
        private void OnEnable()
        {
            m_GrabInteractable.selectExited.AddListener(OnSelectExit);
            m_GrabInteractable.selectEntered.AddListener(OnSelect);
        }
        private void OnDisable()
        {
            m_GrabInteractable.selectExited.RemoveListener(OnSelectExit);
            m_GrabInteractable.selectEntered.RemoveListener(OnSelect);
        }
        private void OnSelect(SelectEnterEventArgs args0) => CancelInvoke("ReturnHome");
        private void OnSelectExit(SelectExitEventArgs args0) => Invoke(nameof(ReturnHome), resetDelayTime);
        protected virtual void ReturnHome()
        {
            if (shoulReturnHome) transform.position = returnToPosition;
        }

        [System.Obsolete]
        private void OnTriggerEnter(Collider other)
        {
            if (ControllerCheck(other.gameObject))
                return;

            var socketInteractor = other.gameObject.GetComponent<XRBaseInteractor>();

            if (socketInteractor == null)
                shoulReturnHome = true;

            else if (socketInteractor.CanSelect(m_GrabInteractable))
            {
                shoulReturnHome = false;
            }
            else
                shoulReturnHome = true;
        }

        bool ControllerCheck(GameObject collideObject)
        {
            isController = collideObject.gameObject.GetComponent<XRBaseController>() != null ? true : false;
            return isController;
        }
    }
}

