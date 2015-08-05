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
 * TERRA_Assimp
 * Implements Assimp model importing (requires DLL)
 ***********************************************************************************************************************
}
Unit TERRA_Assimp;

{$I terra.inc}

Interface
Uses TERRA_Mesh, TERRA_Object, TERRA_String, TERRA_Math, TERRA_Utils, TERRA_Stream,
  TERRA_FileStream, TERRA_FileUtils, TERRA_MeshFilter, TERRA_OS, TERRA_Quaternion, TERRA_Renderer,
  TERRA_Vector2D, TERRA_Vector3D, TERRA_Vector4D, TERRA_Color, TERRA_Matrix4x4, TERRA_VertexFormat,
  AssimpDelphi;
  //Assimp, aiTypes, aiMatrix4x4, aiMatrix3x3, aiMesh, aiScene, aiMaterial, aiColor4d, aiVector3D;

Type
  AssimpBone = Class(TERRAObject)
    Name:TERRAString;
    LocalTransform:Matrix4x4;
    GlobalTransform:Matrix4x4;
    Parent:AssimpBone;
    Level:Integer;
    Node:PAINode;

    Function GetParentCount():Integer;
  End;

  AssimpFilter = Class(MeshFilter)
    Protected
      scene:PaiScene;

      Bones:Array Of AssimpBone;
      BoneCount:Integer;

      RootTransform:Matrix4x4;

      Function FindNode(Name:TERRAString; Root:pAiNode):pAiNode;

      //Function GetBoneAt(Var BoneID:Integer):Integer;
      Function GetBoneIDByName(Name:TERRAString):Integer;

    Public
      Function Load(Source:Stream):Boolean; Override;
      Procedure Release; Override;

      Function GetGroupCount:Integer; Override;
      Function GetGroupName(GroupID:Integer):TERRAString; Override;
      Function GetGroupFlags(GroupID:Integer):Cardinal; Override;
      Function GetGroupBlendMode(GroupID:Integer):Cardinal; Override;

      Function GetTriangleCount(GroupID:Integer):Integer; Override;
      Function GetTriangle(GroupID, Index:Integer):Triangle; Override;

      Function GetVertexCount(GroupID:Integer):Integer; Override;
      //Function GetVertexFormat(GroupID:Integer):VertexFormat; Override;
      Function GetVertexPosition(GroupID, Index:Integer):Vector3D; Override;
      Function GetVertexNormal(GroupID, Index:Integer):Vector3D; Override;
      Function GetVertexTangent(GroupID, Index:Integer):Vector4D; Override;
      Function GetVertexBone(GroupID, Index:Integer):Integer; Override;
      Function GetVertexColor(GroupID, Index:Integer):Color; Override;
      Function GetVertexUV(GroupID, Index, Channel:Integer):Vector2D; Override;

      Function GetDiffuseColor(GroupID:Integer):Color; Override;
      Function GetDiffuseMapName(GroupID:Integer):TERRAString; Override;
      Function GetSpecularMapName(GroupID:Integer):TERRAString; Override;
      Function GetEmissiveMapName(GroupID:Integer):TERRAString; Override;

      Function GetAnimationCount():Integer; Override;
      Function GetAnimationName(Index:Integer):TERRAString; Override;
      Function GetAnimationDuration(Index:Integer):Single; Override;

      Function GetPositionKeyCount(AnimationID, BoneID:Integer):Integer; Override;
      Function GetRotationKeyCount(AnimationID, BoneID:Integer):Integer; Override;
      Function GetScaleKeyCount(AnimationID, BoneID:Integer):Integer; Override;

      Function GetPositionKey(AnimationID, BoneID:Integer; Index:Integer):MeshVectorKey; Override;
      Function GetScaleKey(AnimationID, BoneID:Integer; Index:Integer):MeshVectorKey; Override;
      Function GetRotationKey(AnimationID, BoneID:Integer; Index:Integer):MeshVectorKey; Override;

      Function GetBoneCount():Integer; Override;
      Function GetBoneName(BoneID:Integer):TERRAString; Override;
      Function GetBoneParent(BoneID:Integer):Integer; Override;
      Function GetBoneOffsetMatrix(BoneID:Integer):Matrix4x4; Override;
  End;


Implementation
Uses TERRA_GraphicsManager;

{ AssimpBone }
Function AssimpBone.GetParentCount: Integer;
Var
  Bone:AssimpBone;
Begin
  Result := 0;
  Bone := Self.Parent;
  While Assigned(Bone) Do
  Begin
    Inc(Result);
    Bone := Bone.Parent;
  End;
End;

(*Function ASSIMP_Import(SourceFile, TargetDir:TERRAString):TERRAString;
Var
  dest:FileStream;
  mymesh:TERRAMesh;
  group:MeshGroup;
  I, J, K, N:Integer;
  X,Y,Z:Single;
  T:Triangle;
  Filter:MeshFilter;
Begin
  WriteLn('ASSIMP_Import: ',SourceFile);
  filter := ASSimpFilter.Create(SourceFile);
  If Assigned(ASSimpFilter(Filter).scene) Then
  Begin
    MyMesh := Mesh.CreateFromFilter(Filter);

    //ModelMilkshape3D.Save(TargetDir + PathSeparator + GetFileName(SourceFile, True)+'.ms3d', Filter);

    WriteLn('Saving...');
    Result := TargetDir + PathSeparator + GetFileName(SourceFile, True)+'.mesh';
    Dest := FileStream.Create(Result);
    MyMesh.Save(Dest);
    Dest.Release;
    MyMesh.Release;

    Filter.Release;
  End Else
  Begin
    Writeln('ASSIMP:Error!');
    Result := '';
  End;
End;*)

(*Var
  c:aiLogStream;*)

{ AssimpFilter }
Function AssimpFilter.Load(Source:Stream):Boolean;
Var
  Flags:Cardinal;
  I, J, N:Integer;
  node, P:PAInode;
  S:TERRAString;
  M:Matrix4x4;
  Temp:AssimpBone;
Begin
  flags := 	aiProcess_CalcTangentSpace Or
	aiProcess_GenSmoothNormals				Or
//	aiProcess_JoinIdenticalVertices			Or
	aiProcess_ImproveCacheLocality			Or
	aiProcess_LimitBoneWeights				Or
	aiProcess_RemoveRedundantMaterials  Or
	aiProcess_SplitLargeMeshes				Or
	aiProcess_Triangulate					Or
	aiProcess_GenUVCoords            Or
	aiProcess_SortByPType            Or
	//aiProcess_FindDegenerates        Or
	aiProcess_FindInvalidData;

  scene := aiImportFile(PAnsiChar(Source.Name), flags);
  If (Scene = Nil) Then
    Exit;

  BoneCount := 0;
(*  For I:=0 To Pred(scene.mNumMeshes) Do
  If (scene.mMeshes[I].mNumBones>0) Then
  Begin
    BoneCount := 1;
    SetLength(Bones, BoneCount);
    Bones[0] := AssimpBone.Create;
    Bones[0].Name := aiStringGetValue(Scene.mRootNode.mName);
    Bones[0].Parent := Nil;
    Bones[0].Node := Scene.mRootNode;
    Bones[0].GlobalTransform := Matrix4x4Rotation(0, 90*RAD, 90*RAD); //Scene.mRootNode.mTransformation;
    Break;
  End;*)

  For I:=0 To Pred(scene.mNumMeshes) Do
    For J:=0 To Pred(Scene.mMeshes[I].mNumBones) Do
    If (Self.GetBoneIDByName(aiStringGetValue(Scene.mMeshes[I].mBones[J].mName))<0) Then
    Begin
      Inc(BoneCount);
      SetLength(Bones, BoneCount);
      Bones[Pred(BoneCount)] := AssimpBone.Create;
      Bones[Pred(BoneCount)].Name := aiStringGetValue(Scene.mMeshes[I].mBones[J].mName);
      Bones[Pred(BoneCount)].Parent := Nil;
      Bones[Pred(BoneCount)].Node := Self.FindNode(Bones[Pred(BoneCount)].Name, Scene.mRootNode);
      Bones[Pred(BoneCount)].GlobalTransform := Matrix4x4Inverse(Matrix4x4Transpose(Scene.mMeshes[I].mBones[J].mOffsetMatrix));
   End;

  For I:=1 To Pred(BoneCount) Do
  Begin
    Node := Bones[I].Node;

    //N := Self.GetBoneIDByName(aiStringGetValue(Node.mName));
    If Assigned(Node.mParent) Then
    Begin
      N := Self.GetBoneIDByName(Node.mParent.mName.data);
      If (N>=0) Then
      Begin
        Bones[I].Parent := Bones[N];
      //  WriteLn(Bones[I].Name ,' parent is ', Bones[N].Name);
      End;
    End; //Else      Bones[I].Parent := Bones[0];
  End;

  For I:=0 To Pred(BoneCount) Do
  Begin
    Bones[I].Level := Bones[I].GetParentCount();

    If Assigned(Bones[I].Parent) Then
    Begin
      Bones[I].LocalTransform := Matrix4x4Multiply4x3(Matrix4x4Inverse(Bones[I].Parent.GlobalTransform), Bones[I].GlobalTransform);
    End Else
      Bones[I].LocalTransform := Bones[I].GlobalTransform;
  End;

  For J:=1 To Pred(BoneCount) Do
    For I:=J+1 To Pred(BoneCount) Do
    If (Bones[I].Level<Bones[J].Level) Then
    Begin
      Temp := Bones[I];
      Bones[I] := Bones[J];
      Bones[J] := Temp;
    End;

(*  For I:=0 To Pred(BoneCount) Do
  Begin
    WriteLn(Bones[I].Name,'   ', Bones[I].Level);
  End;
  //ReadLn;*)
End;

Procedure AssimpFilter.Release;
Begin
    aiReleaseImport(scene);
End;

Function AssimpFilter.GetDiffuseColor(GroupID: Integer): Color;
Begin
  Result := ColorWhite;
End;

Function AssimpFilter.GetDiffuseMapName(GroupID: Integer):TERRAString;
Var
  prop:PAImaterialProperty;
Begin
  aiGetMaterialProperty(scene.mMaterials[scene.mMeshes[GroupID].mMaterialIndex], _AI_MATKEY_TEXTURE_BASE, aiTextureType_DIFFUSE, 0, prop);
  If Assigned(Prop) Then
  Begin
    SetLength(Result, Prop.mDataLength);
    Move(Prop.mData^, Result[1], Prop.mDataLength);
    Result := StringTrim(Result);
    Result := GetFileName(Result, False);
    StringTofloat(Result);
  End Else
    Result := '';
End;

Function AssimpFilter.GetEmissiveMapName(GroupID: Integer):TERRAString;
Begin
  Result := '';
End;

Function AssimpFilter.GetGroupBlendMode(GroupID: Integer): Cardinal;
Begin
  Result := blendBlend;
End;

Function AssimpFilter.GetGroupCount: Integer;
Begin
  Result := Scene.mNumMeshes;
End;

Function AssimpFilter.GetGroupFlags(GroupID: Integer): Cardinal;
Begin
  Result := meshGroupCastShadow Or meshGroupPick;
End;

function AssimpFilter.GetGroupName(GroupID: Integer):TERRAString;
begin
  Result := aiStringGetValue(scene.mMeshes[GroupID].mName);
  Result := StringTrim(Result);
  If (Result='') Then
    Result := 'group'+IntToString(GroupID);
end;

Function AssimpFilter.GetSpecularMapName(GroupID: Integer):TERRAString;
Begin
  Result := '';
End;

function AssimpFilter.GetTriangle(GroupID, Index: Integer): Triangle;
begin
  Result.Indices[0] := scene.mMeshes[GroupID].mFaces[Index].mIndices[0];
  Result.Indices[1] := scene.mMeshes[GroupID].mFaces[Index].mIndices[1];
  Result.Indices[2] := scene.mMeshes[GroupID].mFaces[Index].mIndices[2];
end;

function AssimpFilter.GetTriangleCount(GroupID: Integer): Integer;
begin
  Result := scene.mMeshes[GroupID].mNumFaces;
end;

Function AssimpFilter.GetVertexBone(GroupID, Index: Integer): Integer;
Var
  I, J ,K:Integer;
  W:Single;
Begin
  Result := -1;
  If (GroupID<0) Or (GroupID>=scene.mNumMeshes) Or (scene = Nil) Then
    Exit;

  W := -1;
  K := GroupID;
  For I:=0 To Pred(scene.mMeshes[K].mNumBones) Do
  Begin
    For J:=0 To Pred(scene.mMeshes[K].mBones[I].mNumWeights) Do
    Begin
      If (scene.mMeshes[K].mBones[I].mWeights[J].mVertexId=Index) And (scene.mMeshes[K].mBones[I].mWeights[J].mWeight>W) Then
      Begin
        Result := GetBoneIDByName(aiStringGetValue(scene.mMeshes[K].mBones[I].mName));
        W := scene.mMeshes[K].mBones[I].mWeights[J].mWeight;
      End;
    End;
  End;
End;

Function AssimpFilter.GetVertexColor(GroupID, Index: Integer): Color;
Begin
  Result := ColorWhite;
End;

Function AssimpFilter.GetVertexCount(GroupID: Integer): Integer;
Begin
  Result := scene.mMeshes[GroupID].mNumVertices;
End;

(*Function AssimpFilter.GetVertexFormat(GroupID: Integer): VertexFormat;
Begin
  Result := meshFormatNormal Or meshFormatTangent Or meshFormatUV1;
End;*)

function AssimpFilter.GetVertexNormal(GroupID, Index: Integer): Vector3D;
begin
  Result.X := scene.mMeshes[GroupID].mNormals[Index].X;
  Result.Y := scene.mMeshes[GroupID].mNormals[Index].Y;
  Result.Z := scene.mMeshes[GroupID].mNormals[Index].Z;
end;

Function AssimpFilter.GetVertexPosition(GroupID, Index: Integer): Vector3D;
begin
  Result.X := scene.mMeshes[GroupID].mVertices[Index].X;
  Result.Y := scene.mMeshes[GroupID].mVertices[Index].Y;
  Result.Z := scene.mMeshes[GroupID].mVertices[Index].Z;
end;

Function AssimpFilter.GetVertexTangent(GroupID, Index: Integer): Vector4D;
begin
  Result.X := scene.mMeshes[GroupID].mTangents[Index].X;
  Result.Y := scene.mMeshes[GroupID].mTangents[Index].Y;
  Result.Z := scene.mMeshes[GroupID].mTangents[Index].Z;
  Result.W := 1;
end;

Function AssimpFilter.GetVertexUV(GroupID, Index, Channel: Integer): Vector2D;
begin
  If (Channel<Length(scene.mMeshes[GroupID].mTextureCoords)) And (Assigned(scene.mMeshes[GroupID].mTextureCoords[Channel])) Then
  Begin
    Result.X := scene.mMeshes[GroupID].mTextureCoords[Channel][Index].X;
    Result.Y := 1.0 - scene.mMeshes[GroupID].mTextureCoords[Channel][Index].Y;
  End;
end;

Function AssimpFilter.GetAnimationCount():Integer;
Begin
  Result := Scene.mNumAnimations;
End;

Function AssimpFilter.GetAnimationName(Index:Integer):TERRAString;
Begin
  Result := aiStringGetValue(Scene.mAnimations[Index].mName);
End;

Function AssimpFilter.GetBoneCount: Integer;
Begin
  Result := Self.BoneCount;
end;

Function AssimpFilter.GetBoneName(BoneID: Integer):TERRAString;
Begin
  Result := Bones[boneID].Name;
End;

Function AssimpFilter.GetAnimationDuration(Index:Integer):Single;
Begin
  If Index<Scene.mNumAnimations Then
    Result := Scene.mAnimations[Index].mDuration
  Else
    Result := 0;
End;

Function AssimpFilter.GetPositionKeyCount(AnimationID, BoneID:Integer):Integer;
Var
  Channel:Integer;
Begin
  If (AnimationID>=Scene.mNumAnimations) Then
  Begin
    Result := 0;
    Exit;
  End;

  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Bones[BoneID].Name);
  If (Channel<0) Then
  Begin
    Result := 0;
    Exit;
  End;
  Result := Scene.mAnimations[AnimationID].mChannels[Channel].mNumPositionKeys;
End;

Function AssimpFilter.GetRotationKeyCount(AnimationID, BoneID:Integer):Integer;
Var
  Channel:Integer;
Begin
  If (AnimationID>=Scene.mNumAnimations) Then
  Begin
    Result := 0;
    Exit;
  End;

  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Bones[BoneID].Name);
  If (Channel<0) Then
  Begin
    Result := 0;
    Exit;
  End;
  Result := Scene.mAnimations[AnimationID].mChannels[Channel].mNumRotationKeys;
End;

Function AssimpFilter.GetScaleKeyCount(AnimationID, BoneID:Integer):Integer;
Var
  Channel:Integer;
Begin
  If (AnimationID>=Scene.mNumAnimations) Then
  Begin
    Result := 0;
    Exit;
  End;

  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Bones[BoneID].Name);
  If (Channel<0) Then
  Begin
    Result := 0;
    Exit;
  End;
  Result := Scene.mAnimations[AnimationID].mChannels[Channel].mNumScalingKeys;
End;

Function AssimpFilter.GetPositionKey(AnimationID, BoneID:Integer; Index:Integer):MeshVectorKey;
Var
  Channel:Integer;
Begin
  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Bones[BoneID].Name);
  If (Channel<0) Then
    Exit;

  Result.Value.X := Scene.mAnimations[AnimationID].mChannels[Channel].mPositionKeys[Index].mValue.x;
  Result.Value.Y := Scene.mAnimations[AnimationID].mChannels[Channel].mPositionKeys[Index].mValue.Y;
  Result.Value.Z := Scene.mAnimations[AnimationID].mChannels[Channel].mPositionKeys[Index].mValue.Z;
  Result.Time := Scene.mAnimations[AnimationID].mChannels[Channel].mPositionKeys[Index].mTime;
End;

Function AssimpFilter.GetScaleKey(AnimationID, BoneID:Integer; Index:Integer):MeshVectorKey;
Var
  Channel:Integer;
Begin
  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Bones[BoneID].Name);
  If (Channel<0) Then
    Exit;

  Result.Value.X := Scene.mAnimations[AnimationID].mChannels[Channel].mScalingKeys[Index].mValue.x;
  Result.Value.Y := Scene.mAnimations[AnimationID].mChannels[Channel].mScalingKeys[Index].mValue.Y;
  Result.Value.Z := Scene.mAnimations[AnimationID].mChannels[Channel].mScalingKeys[Index].mValue.Z;
  Result.Time := Scene.mAnimations[AnimationID].mChannels[Channel].mScalingKeys[Index].mTime;
End;

Function AssimpFilter.GetRotationKey(AnimationID, BoneID:Integer; Index:Integer):MeshVectorKey;
Var
  Channel:Integer;
  Q:Quaternion;
Begin
  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Bones[BoneID].Name);
  If (Channel<0) Then
    Exit;

  With Scene.mAnimations[AnimationID].mChannels[Channel].mRotationKeys[Index].mValue Do
  Q := QuaternionCreate(x, y, z, w);

  Result.Value := QuaternionToEuler(Q);
  Result.Time := Scene.mAnimations[AnimationID].mChannels[Channel].mRotationKeys[Index].mTime;
End;


Function AssimpFilter.FindNode(Name:TERRAString; Root:pAiNode): pAiNode;
Var
  I:Integer;
Begin
  If (aiStringGetValue(Root.mName) = Name) Then
  Begin
    Result := Root;
    Exit;
  End;

  For I:=0 To Pred(Root.mNumChildren) Do
  Begin
    Result := FindNode(Name, root.mChildren[I]);
    If Assigned(Result) Then
      Exit;
  End;

  Result := Nil;
End;

Function AssimpFilter.GetBoneParent(BoneID: Integer): Integer;
Begin
  If Assigned(Bones[BoneID].Parent) Then
    Result := GetBoneIDByName(Bones[BoneID].Parent.Name)
  Else
    Result := -1;
End;

Function AssimpFilter.GetBoneIDByName(Name:TERRAString): Integer;
Var
  I, J, N:Integer;
Begin
  Result := -1;
  For I:=0 To Pred(BoneCount) Do
  If (Bones[I].Name = Name) Then
  Begin
    Result := I;
    Exit;
  End;
End;

Function AssimpFilter.GetBoneOffsetMatrix(BoneID:Integer):Matrix4x4; 
Begin
  Result := Bones[BoneID].LocalTransform;
End;


Initialization
//  c:= aiGetPredefinedLogStream(aiDefaultLogStream_STDOUT, Nil);
//  aiAttachLogStream(@c);
Finalization
//  aiDetachAllLogStreams();
End.