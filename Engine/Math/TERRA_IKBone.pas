{***********************************************************************************************************************
 *
 * TERRA Game Engine
 * ==========================================
 *
 * Copyright (C) 2003, 2014 by Sérgio Flores (relfos@gmail.com)
 *
 ***********************************************************************************************************************
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 **********************************************************************************************************************
 * TERRA_IK
 * Implements inverse kinematics
 ***********************************************************************************************************************
}
Unit TERRA_IKBone;

{$I terra.inc}

Interface
Uses TERRA_Utils, TERRA_Object, TERRA_Vector2D, TERRA_Vector3D, TERRA_Matrix3x3;

Type
  IKBone = Class(TERRAObject)
    Protected
      _Parent:IKBone;
      _Child:IKBone;

      _ChainSize:Integer;

      _Position:Vector2D;
      _Rotation:Single;

    	// DOF CONSTRAINTS
      _MaxRot:Single;
      _MinRot:Single;

      // DAMPENING SETTINGS
      _DampWidth:Single;
      _DampStrength:Single;

      Function GetEffector():IKBone;

    Public
      Constructor Create(ChainSize:Integer; Parent:IKBone = Nil);
      Procedure Release(); Override;

      Function GetRelativeMatrix:Matrix3x3;
      Function GetAbsoluteMatrix:Matrix3x3;

      Function GetChainBone(Index:Integer):IKBone;

      Function Solve(TargetX, TargetY:Single; ApplyDamping, ApplyDOF:Boolean):Boolean;

      Property Position:Vector2D Read _Position Write _Position;
      Property Rotation:Single Read _Rotation;

      Property ChainSize:Integer Read _ChainSize;

      Property Parent:IKBone Read _Parent;
      Property Child:IKBone Read _Child;
  End;

Implementation
Uses TERRA_Math;

Const
  MAX_IK_TRIES  =	100;		// max iteratiors for the CCD loop (TRIES = # / LINKS)
  IK_POS_THRESH	= 1.0;	// angle thresold for sucess

{ IKBone }
Constructor IKBone.Create(ChainSize:Integer; Parent:IKBone = Nil);
Begin
  Self._Parent := Parent;
  Self._ChainSize := ChainSize;

  If ChainSize>0 Then
    Self._Child := IKBone.Create(Pred(ChainSize), Self)
  Else
    Self._Child := Nil;

  _DampWidth := 5.0 * RAD;

  // default DOF restrictions
  _MinRot := -30 * RAD;
  _MaxRot := 30 * RAD;
End;

Procedure IKBone.Release;
Begin
  If Assigned(_Child) Then
    ReleaseObject(_Child);
End;

Function IKBone.GetAbsoluteMatrix: Matrix3x3;
Begin
  Result := Self.GetRelativeMatrix();
  If Assigned(Self.parent) Then
    Result := MatrixMultiply3x3(Parent.GetAbsoluteMatrix(), Result);
End;

Function IKBone.GetRelativeMatrix: Matrix3x3;
Begin
  Result := MatrixRotation2D(_Rotation);
  Result.SetTranslation(_Position);
End;

Function IKBone.GetEffector():IKBone;
Begin
  If Self.Child = Nil Then
    Result := Self
  Else
    Result := Self.Child.GetEffector();
End;

Function IKBone.Solve(TargetX, TargetY: Single; ApplyDamping, ApplyDOF:Boolean): Boolean;
Var
	endPos, rootPos,curEnd, desiredEnd:Vector2D;
  targetVector,curVector:Vector2D;
  crossResult:Vector3D;
	cosAngle,turnAngle:Double;
	Effector, Link:IKBone;
  Tries:Integer;
Begin
  EndPos := VectorCreate2D(TargetX, TargetY);

	// START AT THE LAST LINK IN THE CHAIN

  Effector := Self.GetEffector();
	Link := Effector;
	Tries := 0;						// LOOP COUNTER SO I KNOW WHEN TO QUIT
	Repeat
		// THE COORDS OF THE X,Y,Z POSITION OF THE ROOT OF THIS BONE IS IN THE MATRIX
		// TRANSLATION PART WHICH IS IN THE 12,13,14 POSITION OF THE MATRIX
		rootPos := Link.GetAbsoluteMatrix().GetTranslation;

		// POSITION OF THE END EFFECTOR
		curEnd := Effector.GetAbsoluteMatrix().GetTranslation;

		// DESIRED END EFFECTOR POSITION
		desiredEnd := endPos;

		// SEE IF I AM ALREADY CLOSE ENOUGH
		If (VectorSubtract2D(curEnd, desiredEnd).LengthSquared > IK_POS_THRESH) Then
    Begin
			// CREATE THE VECTOR TO THE CURRENT EFFECTOR POS
			curVector := VectorSubtract2D(curEnd, rootPos);

			// CREATE THE DESIRED EFFECTOR POSITION VECTOR
			targetVector := VectorSubtract2D(endPos, rootPos);

			// NORMALIZE THE VECTORS (EXPENSIVE, REQUIRES A SQRT)
			curVector.Normalize;
			targetVector.Normalize;

			// THE DOT PRODUCT GIVES ME THE COSINE OF THE DESIRED ANGLE
			cosAngle := VectorDot2D(targetVector, curVector);

			// IF THE DOT PRODUCT RETURNS 1.0, I DON'T NEED TO ROTATE AS IT IS 0 DEGREES
			if (cosAngle < 0.99999) Then
			Begin
				// USE THE CROSS PRODUCT TO CHECK WHICH WAY TO ROTATE
				crossResult := VectorCross(VectorCreate(targetVector.X, targetVector.Y, 0), VectorCreate(curVector.X, curVector.Y, 0));
				If (crossResult.z > 0.0)	Then // IF THE Z ELEMENT IS POSITIVE, ROTATE CLOCKWISE
				Begin
					turnAngle := arccos(cosAngle);	// GET THE ANGLE

					// DAMPING
					if (ApplyDamping) And (turnAngle > Link._DampWidth) Then
						turnAngle := Link._DampWidth;

					Link._Rotation := Link._Rotation - turnAngle;	// ACTUALLY TURN THE LINK

					// DOF RESTRICTIONS
					If (ApplyDOF) And (Link._Rotation < Link._MinRot) Then
            Link._Rotation := Link._MinRot;

				End Else
        if (crossResult.z < 0.0) Then	// ROTATE COUNTER CLOCKWISE
				Begin
					turnAngle := ArcCos(cosAngle);
					// DAMPING
					If (ApplyDamping) And (turnAngle > Link._DampWidth) Then
						turnAngle := Link._DampWidth;

				  Link._Rotation := Link._Rotation + turnAngle;	// ACTUALLY TURN THE LINK

					// DOF RESTRICTIONS
					if (ApplyDOF) And (Link._Rotation > Link._MaxRot) Then
						Link._Rotation := Link._MaxRot;
				End;

			End;

      Link := Link.Parent;

			If (Link = Nil) Then
        Link := Effector;	// START OF THE CHAIN, RESTART
    End;

	  // QUIT IF I AM CLOSE ENOUGH OR BEEN RUNNING LONG ENOUGH
    Inc(Tries);
	Until  (tries >= MAX_IK_TRIES) Or (VectorSubtract2D(curEnd, desiredEnd).LengthSquared <= IK_POS_THRESH);

	Result := True;
End;

Function IKBone.GetChainBone(Index: Integer): IKBone;
Begin
  If (Index = 0) Then
    Result := Self
  Else
  If (Index<0) Or (_Child = Nil) Then
    Result := Nil
  Else
    Result := _Child.GetChainBone(Pred(Index));
End;

End.
