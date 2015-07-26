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
 * TERRA_Skeleton
 * Implements the Skeleton class used for mesh skinning
 ***********************************************************************************************************************
}
Unit TERRA_MeshSkeleton;
{$I terra.inc}

Interface
Uses TERRA_String, TERRA_Utils, TERRA_Object, TERRA_Stream, TERRA_Resource, TERRA_Vector3D, TERRA_Math,
  TERRA_Matrix4x4, TERRA_Vector2D, TERRA_Color, TERRA_Quaternion, TERRA_ResourceManager;

Type
  MeshSkeleton = Class;

  MeshBone = Class(TERRAObject)
    Protected
      _Index:Integer;
      _Parent:MeshBone;
      _Owner:MeshSkeleton;

      _Normal:Vector3D;
      _Length:Single;
      _Orientation:Quaternion;

      _AbsoluteMatrix:Matrix4x4;
      _RelativeMatrix:Matrix4x4;

      _Ready:Boolean;

      Procedure Init;

      Function GetLength():Single;

      Function GetRelativePosition():Vector3D;
      Function GetAbsolutePosition():Vector3D;

      Function GetOrientation:Quaternion;

    Public
      Procedure Release; Override;

      Function Read(Source:Stream):TERRAString;
      Procedure Write(Dest:Stream);

      Property Index:Integer Read _Index;
      Property Parent:MeshBone Read _Parent;
      Property Owner:MeshSkeleton Read _Owner;

      Property Normal:Vector3D Read _Normal;
      Property Length:Single Read GetLength;
      Property Orientation:Quaternion Read GetOrientation;

      Property AbsoluteMatrix:Matrix4x4 Read _AbsoluteMatrix;
      Property RelativeMatrix:Matrix4x4 Read _RelativeMatrix;

      Property RelativePosition:Vector3D Read GetRelativePosition;
      Property AbsolutePosition:Vector3D Read GetAbsolutePosition;
  End;

  MeshSkeleton = Class(TERRAObject)
    Protected
      _BoneList:Array Of MeshBone;
      _BoneCount:Integer;

      _Hash:Cardinal;

    Public
      Name:String;
//      BindPose:Array Of Matrix4x4;

      Procedure Release; Override;

      Procedure NormalizeJoints();

      Procedure Init();

      Procedure Clone(Other:MeshSkeleton);

      Procedure Read(Source:Stream);
      Procedure Write(Dest:Stream);

      Function AddBone():MeshBone;

      Function GetBoneByIndex(Index:Integer):MeshBone;
      Function GetBoneByName(Const Name:TERRAString):MeshBone;

      Function GetBoneLength(Index:Integer):Single;

      Property BoneCount:Integer Read _BoneCount;

      Property Hash:Cardinal Read _Hash;
  End;


Implementation
Uses TERRA_Error, TERRA_Log, TERRA_Application, TERRA_OS, TERRA_FileManager,  TERRA_Mesh,
  TERRA_GraphicsManager, TERRA_FileStream, TERRA_FileUtils;

{ MeshBone }
Procedure MeshBone.Release;
Begin
  // do nothing
End;

Function MeshBone.GetLength: Single;
Var
  P:Vector3D;
Begin
  If (Self.Parent=Nil) Then
    Result := 0
  Else
  Begin
    P := VectorSubtract(Self.GetAbsolutePosition(), Parent.GetAbsolutePosition());
    Result := P.Length();
  End;
End;

Procedure MeshBone.Init;
Begin
  If (_Ready) Then
    Exit;

  If (Assigned(Parent)) And (Not Parent._Ready) Then
    Parent.Init;

	// Each bone's final matrix is its relative matrix concatenated onto its
	// parent's final matrix (which in turn is ....)
	If ( Parent = nil ) Then					// this is the root node
  Begin
    _AbsoluteMatrix := _RelativeMatrix;
  End Else									// not the root node
	Begin
    _AbsoluteMatrix := Matrix4x4Multiply4x3(Parent.AbsoluteMatrix, _RelativeMatrix);
	End;

  _Ready := True;
End;

Function MeshBone.Read(Source:Stream):TERRAString;
Var
  I:Integer;
  StartPosition, StartRotation:Vector3D;
Begin
  Source.ReadString(_ObjectName);
  Source.ReadString(Result);
  _Parent := Nil;

  Source.Read(@StartPosition, SizeOf(Vector3D));
  Source.Read(@StartRotation, SizeOf(Vector3D));

  _RelativeMatrix := Matrix4x4Multiply4x3(Matrix4x4Translation(startPosition), Matrix4x4Rotation(startRotation));
  _Ready := False;
End;

Procedure MeshBone.Write(Dest:Stream);
Var
  StartPosition, StartRotation:Vector3D;
Begin
  Dest.WriteString(Name);
  If (Assigned(Parent)) Then
    Dest.WriteString(Parent.Name)
  Else
    Dest.WriteString('');

  StartPosition := Self.RelativeMatrix.GetTranslation();
  StartRotation := Self.RelativeMatrix.GetEulerAngles();

  Dest.Write(@StartPosition, SizeOf(StartPosition));
  Dest.Write(@StartRotation, SizeOf(StartRotation));
End;

Function MeshBone.GetRelativePosition: Vector3D;
Begin
  Self.Init();
  Result := Self.RelativeMatrix.Transform(VectorZero);
End;

Function MeshBone.GetAbsolutePosition: Vector3D;
Begin
  Self.Init();
  Result := Self.AbsoluteMatrix.Transform(VectorZero);
End;

Function MeshBone.GetOrientation: Quaternion;
Begin
  Result := QuaternionFromAxisAngle(_Normal, 0.0);
End;

{ MeshSkeleton }
Function MeshSkeleton.AddBone:MeshBone;
Begin
  Inc(_BoneCount);
  SetLength(_BoneList, _BoneCount);
  Result := MeshBone.Create;
  _BoneList[ Pred(_BoneCount)] := Result;
End;

Function MeshSkeleton.GetBoneByIndex(Index:Integer):MeshBone;
Begin
  If (Index<0) Or (Index>=_BoneCount) Then
    Result := Nil
  Else
    Result := (_BoneList[Index]);
End;

Function MeshSkeleton.GetBoneByName(Const Name:TERRAString): MeshBone;
Var
  I:Integer;
Begin
  For I:=0 To Pred(_BoneCount) Do
  If (StringEquals(Name, _BoneList[I].Name)) Then
  Begin
    Result := _BoneList[I];
    Exit;
  End;

  Result := Nil;
End;

Procedure MeshSkeleton.Read(Source: Stream);
Var
  Parents:Array Of TERRAString;
  I:Integer;
Begin
  Source.Read(@_BoneCount, 4);
  SetLength(_BoneList, _BoneCount);
  SetLength(Parents, _BoneCount);
  For I:=0 To Pred(_BoneCount) Do
    _BoneList[I] := Nil;

  For I:=0 To Pred(_BoneCount) Do
  Begin
    _BoneList[I] := MeshBone.Create;
    _BoneList[I]._Index := I;
    _BoneList[I]._Owner := Self;
    _BoneList[I]._Ready := False;
    Parents[I] := _BoneList[I].Read(Source);
  End;

  For I:=0 To Pred(_BoneCount) Do
    _BoneList[I]._Parent := Self.GetBoneByName(Parents[I]);

  Self.Init();
End;

Procedure MeshSkeleton.Init;
Var
  I:Integer;
Begin
  For I:=0 To Pred(_BoneCount) Do
    _BoneList[I]._Ready := False;

  For I:=0 To Pred(_BoneCount) Do
    _BoneList[I].Init();

(*  For I:=0 To Pred(_BoneCount) Do
  Begin
    _BoneList[I].StartPosition := _BoneList[I].AbsoluteMatrix.Transform(VectorZero);
    _BoneList[I].StartRotation := VectorZero;
    _BoneList[I].Ready := False;
  End;

  For I:=0 To Pred(_BoneCount) Do
    _BoneList[I].Init();*)
End;

Procedure MeshSkeleton.Write(Dest: Stream);
Var
  I:Integer;
Begin
  Dest.Write(@_BoneCount, 4);
  For I:=0 To Pred(_BoneCount) Do
    _BoneList[I].Write(Dest);
End;

Procedure MeshSkeleton.Release;
Var
  I:Integer;
Begin
  _BoneCount := Length(_BoneList);

  For I:=0 To Pred(_BoneCount) Do
    ReleaseObject(_BoneList[I]);

  SetLength(_BoneList, 0);
End;

Function MeshSkeleton.GetBoneLength(Index: Integer): Single;
Var
  A, B:Vector3D;
Begin
  If (Index<0) Or (_BoneList[Index].Parent = Nil) Then
  Begin
    Result := 0;
    Exit;
  End;

  A := _BoneList[Index].AbsoluteMatrix.Transform(VectorZero);
  B := _BoneList[_BoneList[Index].Parent.Index].AbsoluteMatrix.Transform(VectorZero);
  Result := A.Distance(B);
End;

Procedure MeshSkeleton.Clone(Other: MeshSkeleton);
Var
  I:Integer;
  Bone:MeshBone;
Begin
  If (Other = Nil) Then
    Exit;

  Self.Name := Other.Name;

  Self._Hash := Application.GetTime();

  For I:=0 To Pred(_BoneCount) Do
    ReleaseObject(_BoneList[I]);

  Self._BoneCount := Other._BoneCount;
  SetLength(Self._BoneList, _BoneCount);

  For I:=0 To Pred(_BoneCount) Do
  Begin
    Bone := Other.GetBoneByIndex(I);
    _BoneList[I] := MeshBone.Create;
    _BoneList[I].Name := Bone.Name;
    _BoneList[I]._Index := I;
    _BoneList[I]._Owner := Self;
    _BoneList[I]._Ready := Bone._Ready;
    _BoneList[I]._AbsoluteMatrix := Bone.AbsoluteMatrix;
    _BoneList[I]._RelativeMatrix := Bone.RelativeMatrix;

    If Assigned(Bone.Parent) Then
      _BoneList[I]._Parent := Self.GetBoneByName(Bone.Parent.Name)
    Else
      _BoneList[I]._Parent := Nil;
  End;
End;



Procedure MeshSkeleton.NormalizeJoints;
Var
  I:Integer;
  Bone:MeshBone;
  A, B, C:Matrix4x4;
Begin
  For I:=0 To Pred(Self.BoneCount) Do
  Begin
    Bone := Self.GetBoneByIndex(I);

    If Assigned(Bone.Parent) Then
      Bone._RelativeMatrix := Matrix4x4Translation(VectorSubtract(Bone.AbsoluteMatrix.Transform(VectorZero), Bone.Parent.AbsoluteMatrix.Transform(VectorZero)))
    Else
      Bone._RelativeMatrix := Matrix4x4Translation(Bone.AbsoluteMatrix.Transform(VectorZero));

    Bone._Ready := False;
  End;

  For I:=0 To Pred(Self.BoneCount) Do
  Begin
    Bone := Self.GetBoneByIndex(I);
    Bone.Init();
  End;
End;

End.
