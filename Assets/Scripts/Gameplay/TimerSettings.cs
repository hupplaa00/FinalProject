using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class TimerSettings : MonoBehaviour
{
    public Text textTimer;
    public int time;
    public int timeEnd;
    public bool gameActive = true;
    public GameObject LoseUI;
    public GameObject DialogBoxUI;
    // Start is called before the first frame update
    void SetText()
    {
        int menit = Mathf.FloorToInt(time / 60);//1
        int detik = Mathf.FloorToInt(time % 60);//30
        textTimer.text = menit.ToString("00 ") + ":" + detik.ToString(" 00");
    }

    float s;
    private void Update()
    {
        if (gameActive)
        {
            s += Time.deltaTime;
            if (s >= 1)
            {
                time++;
                s = 0;
            }  
        }

        if(gameActive && time == 2)
        {
            DialogBoxUI.SetActive(true);
        }
        
        if (gameActive && time == timeEnd)
        {
            LoseUI.SetActive(true);
            DialogBoxUI.SetActive(false);
            gameActive = false;
        }
       SetText();
    }
}
