{$I terra.inc}
{$IFDEF MOBILE}Library{$ELSE}Program{$ENDIF} MaterialDemo;

Uses
{$IFDEF DEBUG_LEAKS}MemCheck,{$ELSE}  TERRA_MemoryManager,{$ENDIF}
  TERRA_DemoApplication, TERRA_Utils, TERRA_Object, TERRA_GraphicsManager,
  TERRA_OS, TERRA_Vector3D, TERRA_Font, TERRA_UI, TERRA_Lights, TERRA_Viewport,
  TERRA_JPG, TERRA_PNG, TERRA_String,
  TERRA_Vector2D, TERRA_Mesh, TERRA_MeshSkeleton, TERRA_MeshAnimation, TERRA_MeshAnimationNodes,
  TERRA_FileManager, TERRA_Color, TERRA_DebugDraw, TERRA_Resource,
  TERRA_ScreenFX, TERRA_Math, TERRA_Matrix3x3, TERRA_Matrix4x4, TERRA_Quaternion, TERRA_InputManager,
  TERRA_FileStream;

Type
  MyDemo = Class(DemoApplication)
    Public

			Procedure OnCreate; Override;
			Procedure OnDestroy; Override;

      Procedure OnRender(V:TERRAViewport); Override;
  End;


Const
  RescaleDuration = 4000;

Var
  ClonedInstance:MeshInstance;
  OriginalInstance:MeshInstance;

  GlobalAngles:Array Of Vector3D;
  Dest:FileStream;

  Saved:Boolean;

  SelectedBone:Integer = 4;

Function GetBoneAngle(Const BoneKeyframe, BoneAbsolute, ParentKeyFrame, ParentAbsolute:Matrix4x4):Vector3D; Overload;
Var
  A,B:Vector3D;
  M:Matrix4x4;
Begin
  M := Matrix4x4Multiply4x3(BoneKeyframe, BoneAbsolute);
  A := M.Transform(VectorZero);

  M :=  Matrix4x4Multiply4x3(ParentKeyFrame, ParentAbsolute);
  B := M.Transform(VectorZero);

  Result := VectorSubtract(A, B);
  Result.Normalize();

(*  Result.X := VectorAngle2D(VectorCreate2D(A.Y, A.Z), VectorCreate2D(B.Y, B.Z));
  Result.Y := VectorAngle2D(VectorCreate2D(A.X, A.Z), VectorCreate2D(B.X, B.Z));
  Result.Z := VectorAngle2D(VectorCreate2D(A.X, A.Y), VectorCreate2D(B.X, B.Y));*)

(*  If (Result.X>180*RAD) Then
    Result.X := (360*RAD) - Result.X;

  If (Result.Y>180*RAD) Then
    Result.Y := (360*RAD) - Result.Y;

  If (Result.Z>180*RAD) Then
    Result.Z := (360*RAD) - Result.Z;*)
End;

Function GetBoneAngle(Bone:MeshBone; State:AnimationState):Vector3D; Overload;
Begin
  If (Bone = Nil) Or (Bone.Parent = Nil) Then
  Begin
    Result := VectorZero;
    Exit;
  End;

  Result := GetBoneAngle(State.Transforms[Bone.Index+1], Bone.AbsoluteMatrix, State.Transforms[Bone.Parent.Index+1], Bone.Parent.AbsoluteMatrix);
End;


Function RetargetAnimation(State:AnimationState; Bone:AnimationBoneState; Block:AnimationTransformBlock):Matrix4x4;
Var
  TargetBone, OtherBone:MeshBone;
  targetLocalRot:Quaternion;

  Angle, ParentAngle:Vector3D;
  OtherMat:Matrix4x4;
  T:Single;
Begin
  Result := Matrix4x4Identity;

  OtherBone := OriginalInstance.Geometry.Skeleton.GetBone(Bone._BoneName);
  If OtherBone = Nil Then
    Exit;

  TargetBone := ClonedInstance.Geometry.Skeleton.GetBone(Bone._BoneName);
  If TargetBone = Nil Then
    Exit;

  If Assigned(Dest) Then
  Begin
    Saved := True;
    Dest.WriteLine(Bone._BoneName);
//    Dest.WriteLine(FloatToString(OtherBone.StartRotation.X * DEG)+'    ' + FloatToString(OtherBone.StartRotation.Y * DEG)+'    ' + FloatToString(OtherBone.StartRotation.Z * DEG));
    Angle := QuaternionToEuler(Block.Rotation);
    Dest.WriteLine(FloatToString(Angle.X * DEG)+'    ' + FloatToString(Angle.Y * DEG)+'    ' + FloatToString(Angle.Z * DEG));
    Dest.WriteLine();
  End;

//  Block.Rotation := QuaternionMultiply(CreateRetargetChain(State, Bone), Block.Rotation);

  Result := QuaternionMatrix4x4(Block.Rotation);

  T := Sin(Application.GetTime() / 3000);

(*  If (StringContains('Pelvis', OtherBone.Name)) Then
    Result := Matrix4x4Rotation(VectorCreate(0*RAD, 0, 180*T*RAD));*)


End;


{ MyDemo }
Procedure MyDemo.OnCreate;
Var
  MyMesh, ClonedMesh:TERRAMesh;
  OriginalAnimation, RetargetedAnimation:Animation;
Begin
  Inherited;

  Self.Scene.MainViewport.Camera.SetPosition(VectorCreate(0, 10, 20));
  Self.Scene.MainViewport.Camera.SetView(VectorCreate(0, -0.25, -1));

  MyMesh := MeshManager.Instance.GetMesh('fox');
  If Assigned(MyMesh) Then
  Begin
    OriginalInstance :=MeshInstance.Create(MyMesh);
    OriginalInstance.SetPosition(VectorCreate(5, 0, 0));
  End Else
    OriginalInstance := Nil;

  OriginalAnimation := OriginalInstance.Animation.Find('run');
  OriginalInstance.Animation.Play(OriginalAnimation, RescaleDuration);

  ClonedMesh := TERRAMesh.Create(rtDynamic, '');
  ClonedMesh.Clone(MyMesh);
  If Assigned(ClonedMesh) Then
  Begin
    ClonedInstance :=MeshInstance.Create(ClonedMesh);
    ClonedInstance.SetPosition(VectorCreate(-5, 0, 0));
  End Else
    ClonedInstance := Nil;


  ClonedInstance.Geometry.Skeleton.NormalizeJoints();
  //RetargetedAnimation := OriginalAnimation.Retarget(OriginalInstance.Geometry.Skeleton, ClonedInstance.Geometry.Skeleton);
  RetargetedAnimation := Animation.Create(rtDynamic, ''); RetargetedAnimation.Clone(OriginalAnimation);

  ClonedInstance.Animation.Play(RetargetedAnimation, RescaleDuration);
  ClonedInstance.Animation.Processor := RetargetAnimation;
End;

Procedure MyDemo.OnDestroy;
Begin
  Inherited;
  ReleaseObject(OriginalInstance);
  ReleaseObject(ClonedInstance);
End;

Procedure MyDemo.OnRender(V:TERRAViewport);
Var
  Angle:Vector3D;

  Bone:MeshBone;
  I, BoneCount:Integer;
Begin
  DrawSkeleton(V, OriginalInstance.Geometry.Skeleton,  OriginalInstance.Animation, OriginalInstance.Transform, ColorRed, 4.0);
  DrawSkeleton(V, ClonedInstance.Geometry.Skeleton,  ClonedInstance.Animation, ClonedInstance.Transform, ColorRed, 4.0);

  GraphicsManager.Instance.AddRenderable(V, OriginalInstance);
  GraphicsManager.Instance.AddRenderable(V, ClonedInstance);

Exit;
  AnimationNode(OriginalInstance.Animation.Root).SetCurrentFrame(5);
  AnimationNode(ClonedInstance.Animation.Root).SetCurrentFrame(5);

  BoneCount := OriginalInstance.Geometry.Skeleton.BoneCount;
  SetLength(GlobalAngles, BoneCount);
  For I:=0 To Pred(BoneCount) Do
  Begin
    Bone := OriginalInstance.Geometry.Skeleton.GetBone(I);
    GlobalAngles[I] := GetBoneAngle(Bone, OriginalInstance.Animation);
  End;

  DrawBone(V, OriginalInstance.Geometry.Skeleton.GetBone(SelectedBone),  OriginalInstance.Animation, OriginalInstance.Transform, ColorRed, 4.0);
  DrawBone(V, ClonedInstance.Geometry.Skeleton.GetBone(SelectedBone),  ClonedInstance.Animation, ClonedInstance.Transform, ColorRed, 4.0);


  Angle := GlobalAngles[SelectedBone];

  Self._FontRenderer.SetTransform(MatrixScale2D(2.0));
  Self._FontRenderer.DrawText(100, 210, 10, 'X: '+IntToString(Trunc(Angle.X * DEG)));
  Self._FontRenderer.DrawText(100, 230, 10, 'Y: '+IntToString(Trunc(Angle.Y * DEG)));
  Self._FontRenderer.DrawText(100, 250, 10, 'Z: '+IntToString(Trunc(Angle.Z * DEG)));

  If Assigned(Dest) Then
  Begin
    If Saved Then
      ReleaseObject(Dest);
  End Else
  If InputManager.Instance.Keys.WasPressed(keyB) Then
  Begin
    Saved := False;
    Dest := FileStream.Create('bones.txt');
  End;

  If InputManager.Instance.Keys.WasPressed(keyU) Then
    Dec(SelectedBone);
  If InputManager.Instance.Keys.WasPressed(keyI) Then
    Inc(SelectedBone);

End;

{$IFDEF IPHONE}
Procedure StartGame; cdecl; export;
{$ENDIF}
Begin
  MyDemo.Create();
{$IFDEF IPHONE}
End;
{$ENDIF}
End.

