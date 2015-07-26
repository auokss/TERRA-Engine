{$I terra.inc}
{$IFDEF MOBILE}Library{$ELSE}Program{$ENDIF} MaterialDemo;

Uses
{$IFDEF DEBUG_LEAKS}MemCheck,{$ELSE}  TERRA_MemoryManager,{$ENDIF}
  TERRA_DemoApplication, TERRA_Utils, TERRA_Object, TERRA_GraphicsManager,
  TERRA_OS, TERRA_Vector3D, TERRA_Font, TERRA_UI, TERRA_Lights, TERRA_Viewport,
  TERRA_JPG, TERRA_PNG, TERRA_String,
  TERRA_Vector2D, TERRA_Mesh, TERRA_MeshSkeleton, TERRA_MeshAnimation, TERRA_MeshAnimationNodes,
  TERRA_FileManager, TERRA_Color, TERRA_DebugDraw, TERRA_Resource, TERRA_Ray,
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

  SelectedBone:Integer = 0;

Function RetargetAnimation(State:AnimationState; Bone:AnimationBoneState; Block:AnimationTransformBlock):Matrix4x4;
Var
  TargetBone, OtherBone:MeshBone;
  OtherState:AnimationBoneState;
  OldFrame, NewFrame, OldRel, NewRel:Matrix4x4;

  OldNormal, NewNormal:Vector3D;

  Axis, Pos:Vector3D;
  Rot:Quaternion;
  Retarget, OldBasis, NewBasis:Matrix4x4;
Begin
  Result := Matrix4x4Identity;

  OtherBone := OriginalInstance.Geometry.Skeleton.GetBoneByName(Bone._BoneName);
  If OtherBone = Nil Then
    Exit;

  TargetBone := ClonedInstance.Geometry.Skeleton.GetBoneByName(Bone._BoneName);
  If TargetBone = Nil Then
    Exit;

  OldRel := OtherBone.RelativeMatrix;
  NewRel := Bone._BindRelativeMatrix;


  (*OldNormal := OtherBone.GetNormal();
  NewNormal := TargetBone.GetNormal();
  Block.Rotation := QuaternionMultiply(Block.Rotation, QuaternionFromToRotation(OldNormal, NewNormal));*)

  Retarget := Matrix4x4Inverse(OtherBone.RelativeMatrix);

  OldFrame := Matrix4x4Multiply4x3(Matrix4x4Translation(Block.Translation), QuaternionMatrix4x4(Block.Rotation));

  NewFrame := OldFrame;

  OtherState := OriginalInstance.Animation.GetBoneByName(OtherBone.Name);

  Newrel := Matrix4x4Multiply4x3(OldRel, Retarget);

  // Add the animation state to the rest position
  Result := Matrix4x4Multiply4x3(NewRel, NewFrame);

  //Bone._BindAbsoluteMatrix := OtherBone.AbsoluteMatrix;
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

  MyMesh := MeshManager.Instance.GetMesh('monster');
  ClonedMesh := TERRAMesh.Create(rtDynamic, '');
  ClonedMesh.Clone(MyMesh);
  If Assigned(ClonedMesh) Then
  Begin
    ClonedInstance :=MeshInstance.Create(ClonedMesh);
    ClonedInstance.SetPosition(VectorCreate(-5, 0, 0));
  End Else
    ClonedInstance := Nil;


  //ClonedInstance.Geometry.Skeleton.NormalizeJoints();
  //RetargetedAnimation := OriginalAnimation.Retarget(OriginalInstance.Geometry.Skeleton, ClonedInstance.Geometry.Skeleton);
  RetargetedAnimation := Animation.Create(rtDynamic, ''); RetargetedAnimation.Clone(OriginalAnimation);

//  ClonedInstance.Animation.Play(RetargetedAnimation, RescaleDuration);
  //ClonedInstance.Animation.Processor := RetargetAnimation;
End;

Procedure MyDemo.OnDestroy;
Begin
  Inherited;
  ReleaseObject(OriginalInstance);
  ReleaseObject(ClonedInstance);
End;

Procedure DrawAxis(V:TERRAViewport; Bone:MeshBone; Transform:Matrix4x4; State:AnimationState);
Var
  P, N, T, B:Vector3D;
  Temp:AnimationBoneState;
  M:Matrix4x4;
Begin
  Temp := State.GetBoneByName(Bone.Name);

  M := Matrix4x4Multiply4x3(Transform, Matrix4x4Multiply4x3(State.Transforms[Bone.Index+1], Bone.AbsoluteMatrix));

  //P := Transform.Transform(Bone.GetPosition());
  P := M.Transform(VectorZero);

  N := M.TransformNormal(Bone.GetNormal());
  T := M.TransformNormal(Bone.GetTangent());
  B := M.TransformNormal(Bone.GetBiTangent());

  DrawRay(V, RayCreate(P, N), ColorRed, 1, 5);
  DrawRay(V, RayCreate(P, T), ColorBlue, 1, 5);
  DrawRay(V, RayCreate(P, B), ColorGreen, 1, 5);
End;

Procedure MyDemo.OnRender(V:TERRAViewport);
Var
  Bone:MeshBone;
Begin
  If V <> Self._Scene.MainViewport Then
    Exit;

  If (InputManager.Instance.Keys.WasPressed(keyU)) And (SelectedBone>0) Then
    Dec(SelectedBone);
  If InputManager.Instance.Keys.WasPressed(keyI) Then
    Inc(SelectedBone);

  //DrawLine2D(V, VectorCreate2D(100, 100), VectorCreate2D(InputManager.Instance.Mouse.X, InputManager.Instance.Mouse.Y), ColorWhite);

  //DrawBoundingBox(V, OriginalInstance.GetBoundingBox, ColorBlue);
  DrawSkeleton(V, OriginalInstance.Geometry.Skeleton,  OriginalInstance.Animation, OriginalInstance.Transform, ColorRed, 4.0);
//  DrawSkeleton(V, ClonedInstance.Geometry.Skeleton,  ClonedInstance.Animation, ClonedInstance.Transform, ColorRed, 4.0);

  GraphicsManager.Instance.AddRenderable(V, OriginalInstance);
  GraphicsManager.Instance.AddRenderable(V, ClonedInstance);

  Exit;

(*  AnimationNode(OriginalInstance.Animation.Root).SetCurrentFrame(5);
  AnimationNode(ClonedInstance.Animation.Root).SetCurrentFrame(5);*)

  DrawBone(V, OriginalInstance.Geometry.Skeleton.GetBoneByIndex(SelectedBone),  OriginalInstance.Animation, OriginalInstance.Transform, ColorWhite, 4.0);
  DrawBone(V, ClonedInstance.Geometry.Skeleton.GetBoneByIndex(SelectedBone),  ClonedInstance.Animation, ClonedInstance.Transform, ColorWhite, 4.0);


  Bone := OriginalInstance.Geometry.Skeleton.GetBoneByIndex(SelectedBone);
//  DrawAxis(V, Bone, OriginalInstance.Transform, OriginalInstance.Animation);

  Bone := ClonedInstance.Geometry.Skeleton.GetBoneByIndex(SelectedBone);
  //DrawAxis(V, Bone, ClonedInstance.Transform, ClonedInstance.Animation);

  Self._FontRenderer.SetTransform(MatrixScale2D(2.0));
  Self._FontRenderer.DrawText(50, 250, 10, Bone.Name);
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

