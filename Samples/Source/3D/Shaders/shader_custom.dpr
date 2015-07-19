{$I terra.inc}
{$IFDEF MOBILE}Library{$ELSE}Program{$ENDIF} MaterialDemo;

uses
  TERRA_MemoryManager,
  TERRA_DemoApplication,
  TERRA_Object,
  TERRA_Utils,
  TERRA_String,
  TERRA_ResourceManager,
  TERRA_GraphicsManager,
  TERRA_OS,
  TERRA_Vector2D,
  TERRA_Vector3D,
  TERRA_Vector4D,
  TERRA_Font,
  TERRA_UI,
  TERRA_Lights,
  TERRA_Viewport,
  TERRA_JPG,
  TERRA_PNG,
  TERRA_Texture,
  TERRA_Renderer,
  TERRA_FileManager,
  TERRA_FileStream,
  TERRA_Stream,
  TERRA_Scene,
  TERRA_Mesh,
  TERRA_Skybox,
  TERRA_Color,
  TERRA_Matrix4x4,
  TERRA_ShaderNode,
  TERRA_ShaderCompiler,
  TERRA_GLSLCompiler,
  TERRA_ScreenFX,
  TERRA_InputManager;

Type
  MyDemo = Class(DemoApplication)
    Public
			Procedure OnCreate; Override;
			Procedure OnDestroy; Override;
      Procedure OnRender(V:TERRAViewport); Override;
  End;


Var
  Solid:MeshInstance;

  DiffuseTex:TERRATexture;
  GlowTex:TERRATexture;

{ Game }
Procedure MyDemo.OnCreate;
Begin
  Inherited;

  GraphicsManager.Instance.Renderer.Settings.NormalMapping.SetValue(True);
  GraphicsManager.Instance.Renderer.Settings.PostProcessing.SetValue(True);

  DiffuseTex := TextureManager.Instance.GetTexture('cobble');
  GlowTex := TextureManager.Instance.GetTexture('cobble_glow');

  Solid := MeshInstance.Create(MeshManager.Instance.SphereMesh);
  Solid.SetDiffuseMap(0, DiffuseTex);
  Solid.SetGlowMap(0, GlowTex);
  Solid.SetPosition(VectorCreate(0, -30, -80));
  Solid.SetScale(VectorConstant(20.0));
End;

Procedure MyDemo.OnDestroy;
Begin
  Inherited;
  ReleaseObject(Solid);
End;

Procedure MyDemo.OnRender(V: TERRAViewport);
Begin
  GraphicsManager.Instance.AddRenderable(V, Solid);
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

