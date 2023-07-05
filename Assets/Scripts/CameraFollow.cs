using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class CameraFollow : MonoBehaviour
{
    public Camera camera;
    public float distance = 0.01F;
    public float smoothTime = 0.3F;
    private Vector3 velocity = Vector3.zero;
    private Transform target;

    void Awake()
    {
        target = camera.transform;
    }

    // Update is called once per frame
    void Update()
    {

        Vector3 targetPosition = camera.transform.TransformPoint(new Vector3(0, (float)0, distance));

        transform.position = Vector3.SmoothDamp(transform.position, targetPosition, ref velocity, smoothTime);
        var lookAtPos = new Vector3(camera.transform.position.x, transform.position.y, camera.transform.position.z);
        transform.LookAt(lookAtPos);

    }
}
