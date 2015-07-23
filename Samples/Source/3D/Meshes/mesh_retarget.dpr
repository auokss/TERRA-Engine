{$I terra.inc}
{$IFDEF MOBILE}Library{$ELSE}Program{$ENDIF} MaterialDemo;

Uses
{$IFDEF DEBUG_LEAKS}MemCheck,{$ELSE}  TERRA_MemoryManager,{$ENDIF}
  TERRA_DemoApplication, TERRA_Utils, TERRA_Object, TERRA_GraphicsManager,
  TERRA_OS, TERRA_Vector3D, TERRA_Font, TERRA_UI, TERRA_Lights, TERRA_Viewport,
  TERRA_JPG, TERRA_PNG, TERRA_Mesh, TERRA_MeshAnimation,
  TERRA_FileManager, TERRA_Color, TERRA_DebugDraw,
  TERRA_ScreenFX, TERRA_InputManager;

Type
  MyDemo = Class(DemoApplication)
    Public

			Procedure OnCreate; Override;
			Procedure OnDestroy; Override;

      Procedure OnRender(V:TERRAViewport); Override;
  End;


Const
  RescaleDuration = 8000;

Var
  NinjaInstance:MeshInstance;
  DwarfInstance:MeshInstance;

{ MyDemo }
Procedure MyDemo.OnCreate;
Var
  MyMesh:TERRAMesh;
Begin
  Inherited;

  MyMesh := MeshManager.Instance.GetMesh('fox');
  If Assigned(MyMesh) Then
  Begin
    DwarfInstance :=MeshInstance.Create(MyMesh);
    DwarfInstance.SetPosition(VectorCreate(5, 0, 0));
    DwarfInstance.Animation.Play('run', RescaleDuration);
  End Else
    DwarfInstance := Nil;

  MyMesh := MeshManager.Instance.GetMesh('monster');
  If Assigned(MyMesh) Then
  Begin
    NinjaInstance :=MeshInstance.Create(MyMesh);
    NinjaInstance.SetPosition(VectorCreate(-5, 0, 0));
    NinjaInstance.Animation.Play(AnimationManager.Instance.GetAnimation('fox_run', False), RescaleDuration);
    NinjaInstance.Animation.Retarget(NinjaInstance.Geometry.Skeleton, DwarfInstance.Geometry.Skeleton);
  End Else
    NinjaInstance := Nil;

  Self.Scene.MainViewport.Camera.SetPosition(VectorCreate(0, 10, 20));
  Self.Scene.MainViewport.Camera.SetView(VectorCreate(0, -0.25, -1));
End;

Procedure MyDemo.OnDestroy;
Begin
  Inherited;
  ReleaseObject(DwarfInstance);
  ReleaseObject(NinjaInstance);
End;

Procedure MyDemo.OnRender(V:TERRAViewport);
Begin
  GraphicsManager.Instance.AddRenderable(V, DwarfInstance);
  GraphicsManager.Instance.AddRenderable(V, NinjaInstance);

(*  DrawSkeleton(V, DwarfInstance.Geometry.Skeleton,  DwarfInstance.Animation, DwarfInstance.Transform, ColorRed, 4.0);
  DrawSkeleton(V, NinjaInstance.Geometry.Skeleton,  NinjaInstance.Animation, NinjaInstance.Transform, ColorRed, 4.0);*)

//  DrawBone(V, DwarfInstance.Geometry.Skeleton.GetBone(1),  DwarfInstance.Animation, DwarfInstance.Transform, ColorRed, 4.0);
//  DrawBone(V, NinjaInstance.Geometry.Skeleton.GetBone(1),  NinjaInstance.Animation, NinjaInstance.Transform, ColorRed, 4.0);
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

