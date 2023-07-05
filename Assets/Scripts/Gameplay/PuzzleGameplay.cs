using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class PuzzleGameplay : MonoBehaviour
{
    [SerializeField] private int numberOfTasksComplete;
    private int currentlyCompletedTask = 0;

    [Header("Complete Events")]
    public UnityEvent onPuzzleCompletion;
    public GameObject WinUI;
    public GameObject Timer;
    public GameObject DialogBoxUI;

    public void CompletePuzzleTask()
    {
        currentlyCompletedTask++;
        checkForPuzzleCompletion();
    }

    private void checkForPuzzleCompletion()
    {
        if(currentlyCompletedTask >= numberOfTasksComplete)
        {
            DialogBoxUI.SetActive(false);
            WinUI.SetActive(true);
            Timer.SetActive(false);
        }
    }

    public void puzzlePieceRemoved()
    {
        currentlyCompletedTask--;
    }
}
