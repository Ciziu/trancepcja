﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum FlapAction
{
    None = 0,
    FlapLeft,
    FlapRight,
    FlapBoth
}

public class BatController : MonoBehaviour
{
	[SerializeField]
	public float ControllerDeadzone = 0.5f;
	
    [SerializeField]
    public string PlayerNumber = "1";

    [SerializeField]
    public float TurnForce = 0.5f;
    [SerializeField]
    public float MoveForceSingleWing = 10.0f;
    [SerializeField]
    public float PushForceSingleWing = 13.0f;
    [SerializeField]
    public float MoveForceBothWings = 15.0f;

    public float CounterAngleTurnForce = .5f;

    bool LeftPressed = false;
    bool RightPressed = false;

    bool LeftChanged = false;
    bool RightChanged = false;
    
    Rigidbody Rigidbody;
    
    float Timer = 0f;
    public float InputLag = 0.05f;

    [SerializeField]
    LayerMask LayerMask;

    Animator AnimationController;
    BatState BatState;

    [SerializeField]
    float MassPerCarriedPoint = 0.1f;
    float StartMass;
    
    bool InverseDirections = true;

    public AudioClip FlapSound;

    private void Start()
    {
        Rigidbody = GetComponent<Rigidbody>();
        AnimationController = GetComponentInChildren<Animator>();
        BatState = GetComponent<BatState>();
        StartMass = Rigidbody.mass;
        if (Match.Instance)
            InverseDirections = Match.Instance.inverseDirections[GetComponent<BatState>().ownerId];
    }

    private void Update()
    {
        if (Input.GetButtonDown("Invert" + PlayerNumber))
        {
            InverseDirections = !InverseDirections;

            if (Match.Instance)
                Match.Instance.inverseDirections[GetComponent<BatState>().ownerId] = InverseDirections;
        }

        CaptureInput();

        if (Timer > 0f)
        {
            Timer -= Time.deltaTime;

            if (Timer <= 0f)
            {
                HandleAction(GetAction());
                ResetInput();
            }
        }
        else if (LeftChanged || RightChanged)
        {
            StartTimer();

            AudioManager.Play(FlapSound, 0.8f, 1f);
        }

        Rigidbody.mass = StartMass + BatState.CarriedPoints * MassPerCarriedPoint;
    }

    private FlapAction GetAction()
    {
        bool left = LeftChanged && LeftPressed;
        bool right = RightChanged && RightPressed;
        bool both = left && right;

        if (InverseDirections)
        {
            if (both) return FlapAction.FlapBoth;
            else if (left) return FlapAction.FlapRight;
            else if (right) return FlapAction.FlapLeft;
            else return FlapAction.None;
        }
        else
        {
            if (both) return FlapAction.FlapBoth;
            else if (left) return FlapAction.FlapLeft;
            else if (right) return FlapAction.FlapRight;
            else return FlapAction.None;
        }
    }

    private void StartTimer()
    {
        Timer = InputLag;
    }

    private void CaptureInput()
    {
        bool left = Input.GetAxisRaw("FlapL" + PlayerNumber) > ControllerDeadzone;
        bool right = Input.GetAxisRaw("FlapR" + PlayerNumber) > ControllerDeadzone;
        
        if (left != LeftPressed)
        {
            LeftPressed = !LeftPressed;
            if (!LeftChanged && LeftPressed)
            {
                LeftChanged = true;
            }
        }

        if (right != RightPressed)
        {
            RightPressed = !RightPressed;
            if (!RightChanged && RightPressed)
            {
                RightChanged = true;
            }
        }
    }

    internal void ResetInput()
    {
        RightChanged = false;
        LeftChanged = false;
    }

    private void HandleAction(FlapAction action)
    {
        if (action == FlapAction.FlapLeft)
        {
            Flip(1f);
            AnimationController.SetTrigger("FlapL");
            AnimationController.SetTrigger("Bob");
        }
        else if (action == FlapAction.FlapRight)
        {
            Flip(-1f);
            AnimationController.SetTrigger("FlapR");
            AnimationController.SetTrigger("Bob");
        }
        else if (action == FlapAction.FlapBoth)
        {
            var moveVector = Vector3.up * PushForceSingleWing * 0.5f + transform.up * MoveForceBothWings;
            Rigidbody.AddForce(moveVector, ForceMode.Impulse);

            AnimationController.SetTrigger("FlapL");
            AnimationController.SetTrigger("FlapR");
            AnimationController.SetTrigger("Bob");
        }
    }

    private void Flip(float direction)
    {
        float CounterForce = Vector3.Dot(transform.up, new Vector3(direction, 0f, 0f)) * CounterAngleTurnForce;

        Rigidbody.AddTorque(direction * transform.forward * (TurnForce + CounterForce), ForceMode.Impulse);
        var moveVector = Vector3.up * PushForceSingleWing + transform.forward * PushForceSingleWing;
        Rigidbody.AddForce(moveVector, ForceMode.Impulse);

        RaycastHit hit;
        if (Physics.Raycast(new Ray(transform.position, direction * transform.right), out hit, 0.4f, LayerMask))
        {
            Rigidbody.AddTorque(direction * transform.forward * TurnForce * 3f, ForceMode.Impulse);
            Rigidbody.AddForce(Vector3.up * PushForceSingleWing, ForceMode.Impulse);
        }
    }
}