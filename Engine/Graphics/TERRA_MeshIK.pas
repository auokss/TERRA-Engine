Unit TERRA_MeshIK;

{$I terra.inc}

Interface
Uses TERRA_Object, TERRA_Vector2D, TERRA_Vector3D, TERRA_Quaternion, TERRA_Math,
  TERRA_MeshSkeleton, TERRA_IKBone, TERRA_MeshAnimation, TERRA_MeshAnimationNodes;

Type
  MeshIKChain = Class(AnimationObject)
    Protected
      _Root:MeshBone;
      _Effector:MeshBone;

      _IKChain:IKBone;

      Procedure SetChainPositions();
      Procedure GetChainPositions();

    Public
      Constructor Create(Effector:MeshBone; ChainSize:Integer);
      Procedure Release(); Override;

      Function Solve(Const TargetEffectorPosition:Vector3D):Boolean;

      Function GetTransform(BoneIndex:Integer):AnimationTransformBlock; Override;
  End;

Implementation

{ MeshIKChain }
Constructor MeshIKChain.Create(Effector:MeshBone; ChainSize:Integer);
Var
  Bone:MeshBone;
Begin
  _IKChain := IKBone.Create(ChainSize);
  _Effector := Effector;

  Bone := _Effector;
  While (ChainSize>0) Do
  Begin
    Bone := Bone.Parent;
    Dec(ChainSize);
  End;

  _Root := Bone;
End;

procedure MeshIKChain.SetChainPositions;
Var
  Index, ChainSize:Integer;
  Pos:Vector3D;
  Child:IKBone;
  Bone:MeshBone;
Begin
  Index := 0;
  ChainSize := Self._IKChain.ChainSize;
  Bone := _Effector;
  While (ChainSize>0) Do
  Begin
    Bone := Bone.Parent;
    Dec(ChainSize);

    If ChainSize = 0 Then
      Pos := Bone.GetAbsolutePosition()
    Else
      Pos := Bone.GetRelativePosition();

    Child := _IKChain.GetChainBone(ChainSize);
    Child.Position := VectorCreate2D(Pos.X, Pos.Y);
  End;
End;

procedure MeshIKChain.GetChainPositions;
begin

end;

Procedure MeshIKChain.Release;
Begin
  ReleaseObject(_IKChain);
End;

Function MeshIKChain.Solve(const TargetEffectorPosition: Vector3D):Boolean;
Var
  TargetX, TargetY:Single;
Begin
  TargetX := TargetEffectorPosition.X;
  TargetY := TargetEffectorPosition.Y;
  Result := _IKChain.Solve(TargetX, TargetY, True, True);
End;

Function MeshIKChain.GetTransform(BoneIndex: Integer): AnimationTransformBlock;
Var
  Bone:MeshBone;
Begin
  Result.Translation := VectorZero;
  Result.Scale := VectorConstant(1.0);
  Result.Rotation := QuaternionZero;
    Exit;
  Bone := Self._Effector;
  While (Assigned(Bone)) Do
  Begin
    If (Bone.Index = BoneIndex) Then
    Begin
      Result.Rotation := QuaternionRotation(VectorCreate(90*RAD, 0,  0));
      Exit;
    End;

    If (Bone = Self._Root) Then
      Break;
       
    Bone := Bone.Parent;
  End;
End;

End.
