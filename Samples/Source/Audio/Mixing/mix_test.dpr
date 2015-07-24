{$I terra.inc}
{$IFDEF MOBILE}Library{$ELSE}Program{$ENDIF} BasicSample;

Uses TERRA_Application, TERRA_Scene, TERRA_GraphicsManager, TERRA_Viewport,
  TERRA_ResourceManager, TERRA_Color, TERRA_Texture, TERRA_OS, TERRA_PNG,
  TERRA_SpriteManager, TERRA_FileManager, TERRA_Math, TERRA_Vector3D, TERRA_Vector2D,
  TERRA_Renderer, TERRA_InputManager, TERRA_SoundManager, TERRA_Sound, TERRA_WAVE, TERRA_OGG;


Type
  // A client is used to process application events
  Demo = Class(Application)
    Protected
      _Scene:Scene;

			Procedure OnCreate; Override;
			Procedure OnIdle; Override;
  End;

  // A scene is used to render objects
  MyScene = Class(Scene)
      Procedure RenderSprites(V:Viewport); Override;
  End;

Var
  Tex:Texture = Nil;

{ Game }
Procedure Demo.OnCreate;
Begin
  // Added Asset folder to search path
  FileManager.Instance.AddPath('assets');

  // Load a Tex
  Tex := TextureManager.Instance['ghost'];

  // Create a scene and set it as the current scene
  _Scene := MyScene.Create;
  GraphicsManager.Instance.SetScene(_Scene);

  GraphicsManager.Instance.DeviceViewport.BackgroundColor := ColorBlue;
End;

// OnIdle is called once per frame, put your game logic here
Procedure Demo.OnIdle;
Begin
  If InputManager.Instance.Keys.WasPressed(keyEscape) Then
    Application.Instance.Terminate;

  If InputManager.Instance.Keys.WasPressed(keyEnter) Then
  Begin
    SoundManager.Instance.Play('sfx_beep3');
  End;

  If InputManager.Instance.Keys.WasPressed(keyX) Then
    SoundManager.Instance.Play('attack');

  If InputManager.Instance.Keys.WasPressed(keyC) Then
    SoundManager.Instance.Play('ghost2');
End;

{ MyScene }
Procedure MyScene.RenderSprites;
Var
  I:Integer;
  Angle:Single;
  S:QuadSprite;
Begin
  If (Tex = Nil) Then
    Exit;

  // This is how sprite rendering works with TERRA.
  // 1st we ask the Renderer to create a new sprite, using a Tex and position.
  // Note that this sprite instance is only valid during the frame its created.
  // If needed we can configure the sprite properties.

  // Note - The third argument of VectorCreate is the sprite Layer, should be a value between 0 and 100
  //        Sprites with higher layer values appear below the others

  // Create a simple fliped sprite
  S := SpriteManager.Instance.DrawSprite(Sin(Application.GetTime()/4000) *  960 , 200, 50, Tex);
  S.SetScale(2.0);
End;


Begin
  // Start the application
  Demo.Create();
End.
