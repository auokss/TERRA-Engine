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
  RescaleDuration = 2000;

Var
  ClonedInstance:MeshInstance;
  OriginalInstance:MeshInstance;

  SelectedBone:Integer = 0;


Boo:Boolean;

Procedure TwistAnimation(State:AnimationState; Bone:AnimationBoneState; Block:AnimationTransformBlock; Out FrameRelativeMatrix:Matrix4x4);
Var
  TargetInstance, SourceInstance:MeshInstance;
  TargetBone, SourceBone:MeshBone;

  Q, QB, QC:Quaternion;
  Angles:Vector3D;
  SourceAxis, TargetAxis, Direction:Vector3D;
  PX, PY, PZ:Integer;
  M:Matrix4x4;
  T:Single;
Begin
  FrameRelativeMatrix := Matrix4x4Multiply4x3(Matrix4x4Translation(Bone._BindTranslation), QuaternionMatrix4x4(Bone._BindOrientation));

  If (State = OriginalInstance.Animation) Then
  Begin
    SourceInstance := OriginalInstance;
    TargetInstance := ClonedInstance;
  End Else
  Begin
    SourceInstance := ClonedInstance;
    TargetInstance := OriginalInstance;
  End;

  SourceBone := SourceInstance.Geometry.Skeleton.GetBoneByName(Bone.Name);
  If SourceBone = Nil Then
    Exit;

  TargetBone := TargetInstance.Geometry.Skeleton.GetBoneByName(Bone.Name);
  If TargetBone = Nil Then
    Exit;

  If StringContains('Head', Bone.Name) Then
  Begin
    (*Angles := QuaternionToEuler(Bone._BindOrientation);
    Angles.Scale(DEG);
    PX := Trunc(Angles.X);
    PY := Trunc(Angles.Y);
    PZ := Trunc(Angles.Z);
    IntToString(px+py+pz);*)

    Boo := Not Boo;

    T := Sin(Application.GetTime() / 1000);

    Angles := VectorCreate(-90*RAD * T, 0, 0); // lion

    (*If InputManager.Instance.Keys.IsDown(keyB) Then
      Q := Bone._BindOrientation
    Else
      Q := QuaternionMultiply(Bone._BindOrientation, QuaternionRotation(Angles));*)

    If InputManager.Instance.Keys.IsDown(keyB) Then
      Q := QuaternionZero
    Else
      Q := QuaternionRotation(Angles);

    SourceAxis := SourceBone.Normal;
    TargetAxis := TargetBone.Normal;

(*    If Boo Then
    Begin
      QC := QuaternionFromToRotation(SourceAxis, TargetAxis);
      QB := Bone._BindOrientation;

//      QB := QuaternionMultiply(QC, QB);

      Q := QuaternionMultiply(Q, QB);
    End;*)

    //FrameRelativeMatrix := Matrix4x4Multiply4x3(Matrix4x4Translation(Bone._BindTranslation), QuaternionMatrix4x4(Q));
    FrameRelativeMatrix := Matrix4x4Multiply4x3(Matrix4x4Translation(Bone._BindTranslation), QuaternionMatrix4x4(Bone._BindOrientation));

    //FrameRelativeMatrix := Matrix4x4Multiply4x3(FrameRelativeMatrix, QuaternionMatrix4x4(Q));

    If InputManager.Instance.Keys.IsDown(keyN) Then
      Direction := SourceAxis
    Else
      //Direction := QuaternionMatrix4x4(Q).Transform(SourceAxis);
      Direction := FrameRelativeMatrix.Transform(SourceAxis);

    DrawAxis(MyDemo(Application.Instance).Scene.MainViewport, VectorAdd(SourceInstance.Position, SourceBone.AbsolutePosition), Direction);
  End;


End;

Procedure RetargetAnimation(State:AnimationState; Bone:AnimationBoneState; Block:AnimationTransformBlock; Out FrameRelativeMatrix:Matrix4x4);
Var
  TargetBone, OtherBone:MeshBone;
  OtherState:AnimationBoneState;

  QA, QB, QC:Quaternion;
 Angles, T:Vector3D;
Begin
  FrameRelativeMatrix := Matrix4x4Identity;

  OtherBone := OriginalInstance.Geometry.Skeleton.GetBoneByName(Bone.Name);
  If OtherBone = Nil Then
    Exit;

  TargetBone := ClonedInstance.Geometry.Skeleton.GetBoneByName(Bone.Name);
  If TargetBone = Nil Then
    Exit;

    If OtherBone.Parent = Nil Then
      Exit;


    {Block.Rotation -> old.bone_space
    Block.Rotation ->}

  Angles := QuaternionToEuler(Block.Rotation);

  QC := QuaternionRotation(Angles);

  QA := QuaternionMultiply(Bone._BindOrientation, QC);
  T := Bone._BindTranslation;

  QB := QuaternionFromToRotation(TargetBone.Normal, OtherBone.Normal);
  QB := QuaternionZero;

  If Assigned(OtherBone.Parent) Then
    QA := QuaternionMultiply(QA, QB);

  FrameRelativeMatrix := Matrix4x4Multiply4x3(Matrix4x4Translation(T), QuaternionMatrix4x4(QA));

  //FrameRelativeMatrix := Matrix4x4Multiply4x3(Matrix4x4Translation(Block.Translation), FrameRelativeMatrix);
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
  OriginalInstance.Animation.Processor := TwistAnimation;

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

  ClonedInstance.Animation.Play(RetargetedAnimation, RescaleDuration);
  ClonedInstance.Animation.Processor := TwistAnimation; //RetargetAnimation;
End;

Procedure MyDemo.OnDestroy;
Begin
  Inherited;
  ReleaseObject(OriginalInstance);
  ReleaseObject(ClonedInstance);
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
//  DrawSkeleton(V, OriginalInstance.Geometry.Skeleton,  OriginalInstance.Animation, OriginalInstance.Transform, ColorRed, 4.0);
 // DrawSkeleton(V, ClonedInstance.Geometry.Skeleton,  ClonedInstance.Animation, ClonedInstance.Transform, ColorRed, 4.0);

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

