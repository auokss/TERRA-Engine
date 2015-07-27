Unit TERRA_DemoApplication;

{$I terra.inc}

Interface
Uses TERRA_Utils, TERRA_Object, TERRA_String, TERRA_Application, TERRA_OS, TERRA_Scene,
  TERRA_Vector3D, TERRA_Color,
  TERRA_Font, TERRA_FontRenderer, TERRA_Skybox, TERRA_Viewport, TERRA_Lights, TERRA_Mesh, TERRA_Texture;

Type
  DemoApplication = Class;

  DemoScene = Class(TERRAScene)
    Private
      _Owner:DemoApplication;
      _Sky:TERRASkybox;
      _Sun:DirectionalLight;
      _GroundInstance:MeshInstance;
      _Main:TERRAViewport;

      Function CreateMainViewport(Const Name:TERRAString; Width, Height:Integer):TERRAViewport;

    Public
      Constructor Create(Owner:DemoApplication);
      Procedure Release; Override;

      Procedure RenderSprites(V:TERRAViewport); Override;
      Procedure RenderViewport(V:TERRAViewport); Override;

      Property Sun:DirectionalLight Read _Sun;
      Property MainViewport:TERRAViewport Read _Main;
  End;

  DemoApplication = Class(Application)
    Protected
      _Scene:DemoScene;
      _Font:TERRAFont;
      _FontRenderer:FontRenderer;

    Public
			Procedure OnCreate; Override;
			Procedure OnDestroy; Override;
			Procedure OnIdle; Override;

      Function GetWidth:Word; Override;
      Function GetHeight:Word; Override;

      Procedure OnRender(V:TERRAViewport); Virtual;

      Property Font:TERRAFont Read _Font;
      Property Scene:DemoScene Read _Scene;
  End;

Implementation
Uses TERRA_FileManager, TERRA_InputManager, TERRA_GraphicsManager;

{ Demo }
Function DemoApplication.GetWidth: Word;
Begin
//  Result := 420;
  Result := 800;
End;

Function DemoApplication.GetHeight: Word;
Begin
  //Result := 340;
  Result := 600;
End;

Procedure DemoApplication.OnCreate;
Begin
  Inherited;

  FileManager.Instance.AddPath('Assets');

  _Font := FontManager.Instance.DefaultFont;
  _FontRenderer := FontRenderer.Create();
  _FontRenderer.SetFont(_Font);

  _Scene := DemoScene.Create(Self);
  GraphicsManager.Instance.Scene := _Scene;
End;

Procedure DemoApplication.OnDestroy;
Begin
  ReleaseObject(_Scene);
  ReleaseObject(_FontRenderer);
End;

Procedure DemoApplication.OnIdle;
Begin
  If InputManager.Instance.Keys.WasPressed(keyEscape) Then
    Application.Instance.Terminate();

  GraphicsManager.Instance.TestDebugKeys();

  _Scene.MainViewport.Camera.FreeCam;
End;

{ DemoScene }
Constructor DemoScene.Create(Owner:DemoApplication);
Begin
  Inherited Create();

  Self._Owner := Owner;
  _Sun := DirectionalLight.Create(VectorCreate(-0.25, 0.75, 0.0));
  _Sky := TERRASkybox.Create('sky');

  _Main := Self.CreateMainViewport('main', GraphicsManager.Instance.Width, GraphicsManager.Instance.Height);
  _Main.SetPostProcessingState(True);

  _GroundInstance := MeshInstance.Create(MeshManager.Instance.PlaneMesh);
  _GroundInstance.SetScale(VectorConstant(40));
  _GroundInstance.SetDiffuseMap(0, TextureManager.Instance.GetTexture('cobble'));
  _GroundInstance.SetUVScale(0, 4, 4);
End;

Procedure DemoScene.Release;
Begin
  Inherited;

  ReleaseObject(_GroundInstance);
  ReleaseObject(_Sun);
  ReleaseObject(_Sky);
End;

Function DemoScene.CreateMainViewport(Const Name:TERRAString; Width, Height:Integer):TERRAViewport;
Begin
  Result := TERRAViewport.Create(Name, Width, Height);
  Result.SetTarget(GraphicsManager.Instance.DeviceViewport, 0.0, 0.0, 1.0, 1.0);
  GraphicsManager.Instance.AddViewport(Result);
  Result.Visible := True;
  Result.EnableDefaultTargets();
  Result.BackgroundColor := ColorGreen;
End;

Procedure DemoScene.RenderSprites(V: TERRAViewport);
Begin
  _Owner._FontRenderer.DrawText(5, 5, 50, 'FPS: '+IntToString(GraphicsManager.Instance.Renderer.Stats.FramesPerSecond));
End;

Procedure DemoScene.RenderViewport(V: TERRAViewport);
Begin
  GraphicsManager.Instance.AddRenderable(V, _Sky);
  GraphicsManager.Instance.AddRenderable(V, _GroundInstance);
  LightManager.Instance.AddLight(V, Sun);

  _Owner.OnRender(V);
End;

Procedure DemoApplication.OnRender(V: TERRAViewport);
Begin
End;

End.
