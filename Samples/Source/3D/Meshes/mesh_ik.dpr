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
  TERRA_FileStream, TERRA_IKBone, TERRA_MeshIK;

Type
  MyDemo = Class(DemoApplication)
    Public

			Procedure OnCreate; Override;
			Procedure OnDestroy; Override;

      Procedure OnRender(V:TERRAViewport); Override;

			Procedure OnMouseDown(X,Y:Integer;Button:Word); Override;
			Procedure OnMouseUp(X,Y:Integer;Button:Word); Override;
			Procedure OnMouseMove(X,Y:Integer); Override;
  End;


Var
  TargetInstance:MeshInstance;
  SelectedBone:Integer = 0;

  Chain:MeshIKChain;


{ MyDemo }
Procedure MyDemo.OnCreate;
Var
  MyMesh:TERRAMesh;
  Skeleton:MeshSkeleton;
Begin
  Inherited;

  Self.Scene.MainViewport.Camera.SetPosition(VectorCreate(0, 8, -12));
  Self.Scene.MainViewport.Camera.SetView(VectorCreate(0, -0.25, 1));

  MyMesh := MeshManager.Instance.GetMesh('ninja');
  If Assigned(MyMesh) Then
  Begin
    TargetInstance :=MeshInstance.Create(MyMesh);
    TargetInstance.SetPosition(VectorCreate(0, 0, 0));
  End Else
    TargetInstance := Nil;

  Skeleton := TargetInstance.Geometry.Skeleton;
  Skeleton.NormalizeJoints();

  Chain := MeshIKChain.Create(Skeleton.GetBoneByName('lwrist'), 3);

  TargetInstance.Animation.Root := Chain;
End;

Procedure MyDemo.OnDestroy;
Begin
  Inherited;

  ReleaseObject(TargetInstance);
  //ReleaseObject(Chain);
End;

Procedure MyDemo.OnRender(V:TERRAViewport);
Var
  Bone:MeshBone;
Begin
  If (V<>Self._Scene.MainViewport) Then
    Exit;

  If (InputManager.Instance.Keys.WasPressed(keyU)) And (SelectedBone>0) Then
    Dec(SelectedBone);
  If InputManager.Instance.Keys.WasPressed(keyI) Then
    Inc(SelectedBone);

  DrawSkeleton(V, TargetInstance.Geometry.Skeleton,  TargetInstance.Animation, TargetInstance.Transform, ColorRed, 4.0);

  GraphicsManager.Instance.AddRenderable(V, TargetInstance);
  Exit;

(*  AnimationNode(TargetInstance.Animation.Root).SetCurrentFrame(5);
  AnimationNode(ClonedInstance.Animation.Root).SetCurrentFrame(5);*)

  DrawBone(V, TargetInstance.Geometry.Skeleton.GetBoneByIndex(SelectedBone),  TargetInstance.Animation, TargetInstance.Transform, ColorWhite, 4.0);

  Bone := TargetInstance.Geometry.Skeleton.GetBoneByIndex(SelectedBone);

  Self._FontRenderer.SetTransform(MatrixScale2D(2.0));
  Self._FontRenderer.DrawText(50, 250, 10, Bone.Name);
End;

procedure MyDemo.OnMouseDown(X, Y: Integer; Button: Word);
begin
  inherited;

end;

procedure MyDemo.OnMouseMove(X, Y: Integer);
begin
  inherited;

end;

procedure MyDemo.OnMouseUp(X, Y: Integer; Button: Word);
begin
  inherited;

end;

{$IFDEF IPHONE}
Procedure StartGame; cdecl; export;
{$ENDIF}
Begin
  MyDemo.Create();
{$IFDEF IPHONE}
End;
{$ENDIF}
End.

