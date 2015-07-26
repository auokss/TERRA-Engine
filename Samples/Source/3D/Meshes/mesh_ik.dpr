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
  EFFECTOR_POS = Pred(CHAIN_SIZE);

{  t_Bone = Class
	id:Cardinal;							// BONE ID
	name:String;					// BONE NAME
	flags:Cardinal;						// BONE FLAGS
	// HIERARCHY INFO
	parent:t_Bone;					// POINTER TO PARENT BONE
	child:t_Bone;					// POINTER TO CHILDREN
	rot:Single;						// CURRENT ROTATION FACTORS
	trans:Vector3D;						// CURRENT TRANSLATION FACTORS

	// ANIMATION INFO
(*	long	primChanType;				// WHAT TYPE OF PREIMARY CHAN IS ATTACHED
	float	*primChannel;				// POINTER TO PRIMARY CHANNEL OF ANIMATION
	float 	primFrameCount;				// FRAMES IN PRIMARY CHANNEL
	float	primSpeed;					// CURRENT PLAYBACK SPEED
	float	primCurFrame;				// CURRENT FRAME NUMBER IN CHANNEL
	long	secChanType;				// WHAT TYPE OF SECONDARY CHAN IS ATTACHED
	float	*secChannel;				// POINTER TO SECONDARY CHANNEL OF ANIMATION
	float	secFrameCount;				// FRAMES IN SECONDARY CHANNEL
	float	secCurFrame;				// CURRENT FRAME NUMBER IN CHANNEL
	float	secSpeed;					// CURRENT PLAYBACK SPEED
	float	animBlend;					// BLENDING FACTOR (ANIM WEIGHTING)
  *)
	// DOF CONSTRAINTS
	min_rx, max_rx:Single;				// ROTATION X LIMITS
	min_ry, max_ry:Single;				// ROTATION Y LIMITS
	min_rz, max_rz:Single;				// ROTATION Z LIMITS
	damp_width, damp_strength:Single;	// DAMPENING SETTINGS

	// VISUAL ELEMENTS
	visual:TERRATexture;					// COUNT OF ATTACHED VISUAL ELEMENTS
//	int		*CV_ptr;					// POINTER TO CONTROL VERTICES
//	float	*CV_weight;					// POINTER TO ARRAY OF WEIGHTING VALUES

	// COLLISION ELEMENTS
(*	float	bbox[6];					// BOUNDING BOX (UL XYZ, LR XYZ)
	tVector	center;						// CENTER OF OBJECT (MASS)
	float	bsphere;					// BOUNDING SPHERE (RADIUS)
	// PHYSICS
	tVector	length;						// BONE LENGTH VECTOR
	float	mass;						// MASS
	float	friction;					// STATIC FRICTION
	float	kfriction;					// KINETIC FRICTION
	float	elast;						// ELASTICITY

  *)

  Constructor Create(Parent:t_bone);

  Procedure Draw(V:TERRAViewport);
End;
}

Var
  SnakeBones:Array[0..Pred(CHAIN_SIZE)] Of IKBone;

  m_Damping:Boolean;
	m_DOF_Restrict:Boolean;

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


	// BY DEFAULT NO DAMPING OR DOF RESTRICTION
	m_Damping := True;
	m_DOF_Restrict := True;

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
Var
  joint1,joint2,effector:Vector2D;
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

  Self._FontRenderer.SetTransform(MatrixScale2D(2.0));
//  Self._FontRenderer.DrawText(50, 250, 10, Bone.Name);
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

