using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class MulaiController : MonoBehaviour
{
   public void MulaiButton()
    {
        SceneManager.LoadScene("level1");
    }
}
