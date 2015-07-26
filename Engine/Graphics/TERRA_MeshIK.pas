Unit TERRA_MeshIK;

{$I terra.inc}

Interface
Uses TERRA_String, TERRA_Object, TERRA_Vector2D, TERRA_Vector3D, TERRA_Quaternion, TERRA_Math,
  TERRA_MeshSkeleton, TERRA_IKBone3D, TERRA_MeshAnimation, TERRA_MeshAnimationNodes;

Type
  MeshIKChain = Class(TERRAObject)
    Protected
      _Root:MeshBone;
      _Effector:MeshBone;

      _IKChain:IKBone3D;

      Procedure SetChainPositions();

    Public
      Constructor Create(Effector:MeshBone; ChainSize:Integer);
      Procedure Release(); Override;

      Function Solve(TargetEffectorPosition:Vector3D):Boolean;

      Property Root:MeshBone Read _Root;
      Property Effector:MeshBone Read _Effector;
      Property IKChain:IKBone3D Read _IKChain;
  End;

  MeshIKController = Class(AnimationObject)
    Protected
      _Target:MeshSkeleton;

      _Chains:Array Of MeshIKChain;
      _ChainCount:Integer;

    Public
      Constructor Create(Target:MeshSkeleton);

      Function AddChain(const BoneName:TERRAString; ChainSize: Integer):MeshIKChain;

      Function GetTransform(BoneIndex:Integer):AnimationTransformBlock; Override;
  End;

Implementation

{ MeshIKChain }
Constructor MeshIKChain.Create(Effector:MeshBone; ChainSize:Integer);
Var
  Bone:MeshBone;
  Child:IKBone3D;
Begin
  _IKChain := IKBone3D.Create(ChainSize);
  _Effector := Effector;

  Bone := _Effector;
  While (ChainSize>0) Do
  Begin
    Dec(ChainSize);

    Child := _IKChain.GetChainBone(ChainSize);
    Child.Name := 'IK_'+Bone.Name;

    If ChainSize>0 Then
      Bone := Bone.Parent;
  End;

  _Root := Bone;

  Self.SetChainPositions();
End;


Procedure MeshIKChain.Release;
Begin
  ReleaseObject(_IKChain);
End;

{ Copies 3d bones positions to IK bone chain }
Procedure MeshIKChain.SetChainPositions;
Var
  Index, ChainSize:Integer;
  Pos:Vector3D;
  Child:IKBone3D;
  Bone:MeshBone;

  RootPos:Vector3D;
Begin
  RootPos := _Root.GetAbsolutePosition();

  Index := 0;
  ChainSize := Self._IKChain.ChainSize;
  Bone := _Effector;
  While (ChainSize>0) Do
  Begin
    Dec(ChainSize);

    Pos := Bone.GetAbsolutePosition();
    Pos.Subtract(RootPos);
    Child := _IKChain.GetChainBone(ChainSize);
    Child.Position := VectorCreate2D(Pos.X, Pos.Y);

    Bone := Bone.Parent;
  End;
End;

Function MeshIKChain.Solve(TargetEffectorPosition: Vector3D):Boolean;
Var
  TargetX, TargetY:Single;
Begin
  Self.SetChainPositions();

  TargetEffectorPosition.Subtract(_Root.GetAbsolutePosition());

  TargetX := TargetEffectorPosition.X;
  TargetY := TargetEffectorPosition.Y;
  Result := _IKChain.Solve(TargetX, TargetY, True, True);
End;

{ MeshIKController }
Function MeshIKController.AddChain(const BoneName: TERRAString; ChainSize: Integer):MeshIKChain;
Var
  Bone:MeshBone;
Begin
  Bone := _Target.GetBoneByName(BoneName);
  If Bone = Nil Then
  Begin
    Result := Nil;
    Exit;
  End;

  Result := MeshIKChain.Create(Bone, ChainSize);

  Inc(_ChainCount);
  SetLength(_Chains, _ChainCount);
  _Chains[Pred(_ChainCount)] := Result;
End;

Constructor MeshIKController.Create(Target: MeshSkeleton);
Begin
  _Target := Target;
End;

Function MeshIKController.GetTransform(BoneIndex: Integer): AnimationTransformBlock;
Var
  TargetBone:MeshBone;
  ChainBone:IKBone3D;
  I, ChainIndex:Integer;
Begin
  Result.Translation := VectorZero;
  Result.Scale := VectorConstant(1.0);
  Result.Rotation := QuaternionZero;

  For I:=0 To Pred(_ChainCount) Do
  Begin
    TargetBone := _Chains[I].Effector;
    ChainIndex := _Chains[I].IKChain.ChainSize;
    While (ChainIndex>0) Do
    Begin
      Dec(ChainIndex);

      If (TargetBone.Index = BoneIndex) Then
      Begin
        ChainBone := _Chains[I].IKChain.GetChainBone(ChainIndex);
        Result.Rotation := QuaternionRotation(VectorCreate(0, 0, ChainBone.Rotation));
        Exit;
      End;

      TargetBone := TargetBone.Parent;
    End;
  End;

End;

End.
