{$I terra.inc}
{$IFDEF MOBILE}Library{$ELSE}Program{$ENDIF} MaterialDemo;

Uses
{$IFDEF DEBUG_LEAKS}MemCheck,{$ELSE}  TERRA_MemoryManager,{$ENDIF}
  TERRA_DemoApplication, TERRA_Utils, TERRA_Object, TERRA_GraphicsManager,
  TERRA_OS, TERRA_Vector3D, TERRA_Font, TERRA_UI, TERRA_Lights, TERRA_Viewport,
  TERRA_JPG, TERRA_PNG, TERRA_String, Math,
  TERRA_Vector2D, TERRA_Mesh, TERRA_MeshSkeleton, TERRA_MeshAnimation, TERRA_MeshAnimationNodes,
  TERRA_FileManager, TERRA_Color, TERRA_DebugDraw, TERRA_Resource, TERRA_Ray,
  TERRA_ScreenFX, TERRA_Math, TERRA_Matrix3x3, TERRA_Matrix4x4, TERRA_Quaternion, TERRA_InputManager,
  TERRA_FileStream, TERRA_Texture, TERRA_SpriteMAnager, TERRA_IK;

Type
  MyDemo = Class(DemoApplication)
    Public

			Procedure OnCreate; Override;
			Procedure OnDestroy; Override;

			Procedure OnMouseDown(X,Y:Integer;Button:Word); Override;
			Procedure OnMouseUp(X,Y:Integer;Button:Word); Override;
			Procedure OnMouseMove(X,Y:Integer); Override;

      Procedure OnRender(V:TERRAViewport); Override;
  End;

Const
  SnakeSize = 100;
  CHAIN_SIZE = 8;

Var
  SnakeBones:Array[0..Pred(CHAIN_SIZE)] Of IKBone;

  BodyTex, HeadTex:TERRATexture;
  Dragging:Boolean;


Procedure DrawBone(Bone:IKBone; V:TERRAViewport);
Var
  Mat:Matrix3x3;
  S:QuadSprite;
  Visual:TERRATexture;
Begin
  Mat := Bone.GetAbsoluteMatrix();

  If Bone.Child = Nil Then
    Visual := HeadTex
  Else
    Visual := BodyTex;

  S := SpriteManager.Instance.DrawSprite(0, 0, 10, Visual);
  S.Anchor := VectorCreate2D(0.5, 0.5);
  S.Rect.Width := SnakeSize;
  S.Rect.Height:= SnakeSize;
  S.SetTransform(Mat);

  If Assigned(Bone.Child) Then
    DrawBone(Bone.Child, V);
End;



{ MyDemo }
Procedure MyDemo.OnCreate;
Var
  I:Integer;
Begin
  Inherited;

  BodyTex := TextureManager.Instance.GetTexture('snake_body');
  HeadTex := TextureManager.Instance.GetTexture('snake_head');

	SnakeBones[0] := IKBone.Create(Nil);

  For I:=1 To Pred(CHAIN_SIZE) Do
  Begin
	  SnakeBones[I] := IKBone.create(SnakeBones[Pred(I)]);
  	SnakeBones[I].Position := VectorCreate2D(0, SnakeSize - 20);
  End;
End;

Procedure MyDemo.OnDestroy;
Begin
  Inherited;
End;

Procedure MyDemo.OnMouseDown(X, Y: Integer; Button: Word);
Begin
  If Button = keyMouseRight Then
  Begin
    SnakeBones[0].Solve(X, Y, True, True);
    Exit;
  End;

  Dragging := True;
End;

Procedure MyDemo.OnMouseMove(X, Y: Integer);
Begin
  If Not Dragging Then
    Exit;

  SnakeBones[0].Solve(X, Y, True, True);
End;

Procedure MyDemo.OnMouseUp(X, Y: Integer; Button: Word);
Begin
  Dragging := False;
End;

Procedure MyDemo.OnRender(V:TERRAViewport);
Begin
  SnakeBones[0].Position := VectorCreate2D(V.Width  * 0.5, -SnakeSize * 0.5);
  DrawBone(SnakeBones[0], V);
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

