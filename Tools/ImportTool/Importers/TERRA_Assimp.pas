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
  TERRA_MeshAnimationNodes,
  AssimpDelphi;
  //Assimp, aiTypes, aiMatrix4x4, aiMatrix3x3, aiMesh, aiScene, aiMaterial, aiColor4d, aiVector3D;

Type
  AssimpBone = Class(TERRAObject)
    Name:TERRAString;
    Parent:AssimpBone;

    BoneOffset:Matrix4x4;
    FinalTransformation:Matrix4x4;
  End;

  AssimpModel = Class(AnimationProcessor)
    Protected
      Scene:PaiScene;

      Bones:Array Of AssimpBone;
      BoneCount:Integer;

      GlobalTransform:Matrix4x4;
      GlobalInverseTransform:Matrix4x4;

      LastFrame:Cardinal;

      Function FindBone(Name:TERRAString):Integer;

      Procedure LoadBones(MeshIndex:Integer; Mesh:PaiMesh);

      Function FindPosition(AnimationTime:Single; NodeAnim:PaiNodeAnim):Integer;
      Function FindRotation(AnimationTime:Single; NodeAnim:PaiNodeAnim):Integer;
      Function FindScaling(AnimationTime:Single; NodeAnim:PaiNodeAnim):Integer;

      Function CalcInterpolatedPosition(AnimationTime:Single; NodeAnim:PaiNodeAnim):aiVector3D;
      Function CalcInterpolatedRotation(AnimationTime:Single; NodeAnim:PaiNodeAnim):aiQuaternion;
      Function CalcInterpolatedScaling(AnimationTime:Single; NodeAnim:PaiNodeAnim):aiVector3D;

      Procedure BoneTransform(TimeInSeconds:Single);


      Function FindNodeAnim(Animation:PaiAnimation; const NodeName:TERRAString):PaiNodeAnim;
      Procedure ReadNodeHeirarchy(AnimationTime:Single; Node:paiNode; Const ParentTransform:Matrix4x4);

      Procedure InitParents(Node:paiNode; Prev:AssimpBone);

    Public
      Constructor Create(Scene:PaiScene);
      Function FinalTransform(State: AnimationState; Bone: AnimationBoneState): Matrix4x4; Override;

      Procedure Update();
  End;

  AssimpFilter = Class(MeshFilter)
    Protected
      scene:PaiScene;

    Public
      Model:AssimpModel;

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

{ AssimpModel }
Constructor AssimpModel.Create(Scene:pAIScene);
Var
  I:Integer;
Begin
  Self.Scene := Scene;
  GlobalTransform := Matrix4x4Transpose(Scene.mRootNode.mTransformation);
  GlobalInverseTransform := Matrix4x4Inverse(GlobalTransform);

  For I:=0 To Pred(Scene.mNumMeshes) Do
  Begin
    LoadBones(I, Scene.mMeshes[I]);
    Break;
  End;

  Self.InitParents(Scene.mRootNode, Nil);
End;

Function AssimpModel.FindBone(Name:TERRAString): Integer;
Var
  I, J, N:Integer;
Begin
  For I:=0 To Pred(BoneCount) Do
  If (Bones[I].Name = Name) Then
  Begin
    Result := I;
    Exit;
  End;

  Result := -1;
End;

Procedure AssimpModel.LoadBones(MeshIndex:Integer; Mesh:PaiMesh);
Var
  I, BoneIndex:Integer;
  BoneName:TERRAString;
  BoneInfo:AssimpBone;
Begin
  For I:=0 To Pred(Mesh.mNumBones) Do
  Begin
    BoneIndex := 0;
    BoneName := aiStringGetValue(Mesh.mBones[i].mName);

    If (Self.FindBone(BoneName)<0) Then
    Begin
      // Allocate an index for a new bone
      BoneIndex := BoneCount;

      BoneInfo := AssimpBone.Create();
      BoneInfo.Name := BoneName;
      BoneInfo.BoneOffset := Matrix4x4Transpose(Mesh.mBones[i].mOffsetMatrix);

      Inc(BoneCount);
      SetLength(Bones, BoneCount);
      Bones[BoneIndex] := BoneInfo;
    End;
  End;

    (*
        for (uint j = 0 ; j < pMesh->mBones[i]->mNumWeights ; j++) {
            uint VertexID = m_Entries[MeshIndex].BaseVertex + pMesh->mBones[i]->mWeights[j].mVertexId;
            float Weight  = pMesh->mBones[i]->mWeights[j].mWeight;
            Bones[VertexID].AddBoneData(BoneIndex, Weight);
*)
End;

Function AssimpModel.FindPosition(AnimationTime:Single; NodeAnim:PaiNodeAnim):Integer;
Var
  I:Integer;
Begin
  For I:=0 To (NodeAnim.mNumPositionKeys-2) Do
  If (AnimationTime < NodeAnim.mPositionKeys[i + 1].mTime) Then
  Begin
    Result := I;
    Exit;
  End;


  Result := 0;
End;


Function AssimpModel.FindRotation(AnimationTime:Single; NodeAnim:PaiNodeAnim):Integer;
Var
  I:Integer;
Begin
  For I:=0 To (NodeAnim.mNumRotationKeys-2) Do
  If (AnimationTime < NodeAnim.mRotationKeys[i + 1].mTime) Then
  Begin
    Result := I;
    Exit;
  End;


  Result := 0;
End;

Function AssimpModel.FindScaling(AnimationTime:Single; NodeAnim:PaiNodeAnim):Integer;
Var
  I:Integer;
Begin
  For I:=0 To (NodeAnim.mNumScalingKeys-2) Do
  If (AnimationTime < NodeAnim.mScalingKeys[i + 1].mTime) Then
  Begin
    Result := I;
    Exit;
  End;


  Result := 0;
End;

Function AssimpModel.CalcInterpolatedPosition(AnimationTime:Single; NodeAnim:PaiNodeAnim):aiVector3D;
Var
  PositionIndex, NextPositionIndex:Integer;
  Factor, DeltaTime:Single;
  Start, Dest, Delta:aiVector3D;
Begin
  If (NodeAnim.mNumPositionKeys = 1) Then
  Begin
    Result := NodeAnim.mPositionKeys[0].mValue;
    Exit;
  End;

  PositionIndex := FindPosition(AnimationTime, NodeAnim);
  NextPositionIndex := (PositionIndex + 1);

  DeltaTime := (NodeAnim.mPositionKeys[NextPositionIndex].mTime - NodeAnim.mPositionKeys[PositionIndex].mTime);
  Factor := (AnimationTime - NodeAnim.mPositionKeys[PositionIndex].mTime) / DeltaTime;

  Start := NodeAnim.mPositionKeys[PositionIndex].mValue;
  Dest := NodeAnim.mPositionKeys[NextPositionIndex].mValue;
  Delta := VectorSubtract(Dest, Start);
  Result := VectorAdd(Start, VectorScale(Delta, Factor));
End;


Function AssimpModel.CalcInterpolatedRotation(AnimationTime:Single; NodeAnim:PaiNodeAnim):aiQuaternion;
Var
  RotationIndex, NextRotationIndex:Integer;
  Factor, DeltaTime:Single;
  StartRotation, EndRotation:aiQuaternion;
Begin
	// we need at least two values to interpolate...
  If (NodeAnim.mNumRotationKeys = 1) Then
  Begin
    Result := NodeAnim.mRotationKeys[0].mValue;
    Exit;
  End;

  RotationIndex := FindRotation(AnimationTime, NodeAnim);
  NextRotationIndex := (RotationIndex + 1);

  DeltaTime := (NodeAnim.mRotationKeys[NextRotationIndex].mTime - NodeAnim.mRotationKeys[RotationIndex].mTime);
  Factor := (AnimationTime - NodeAnim.mRotationKeys[RotationIndex].mTime) / DeltaTime;

  StartRotation := NodeAnim.mRotationKeys[RotationIndex].mValue;
  EndRotation := NodeAnim.mRotationKeys[NextRotationIndex].mValue;
  Result := QuaternionSlerp(StartRotation, EndRotation, Factor);
  Result.Normalize();
End;


Function AssimpModel.CalcInterpolatedScaling(AnimationTime:Single; NodeAnim:PaiNodeAnim):aiVector3D;
Var
  ScalingIndex, NextScalingIndex:Integer;
  Factor, DeltaTime:Single;
  Delta, StartScale, EndScale:aiVector3D;
Begin
  If (NodeAnim.mNumScalingKeys = 1) Then
  Begin
    Result := NodeAnim.mScalingKeys[0].mValue;
    Exit;
  End;

  ScalingIndex := FindScaling(AnimationTime, NodeAnim);
  NextScalingIndex := (ScalingIndex + 1);

  DeltaTime := (NodeAnim.mScalingKeys[NextScalingIndex].mTime - NodeAnim.mScalingKeys[ScalingIndex].mTime);
  Factor := (AnimationTime - NodeAnim.mScalingKeys[ScalingIndex].mTime) / DeltaTime;

  StartScale := NodeAnim.mScalingKeys[ScalingIndex].mValue;
  EndScale := NodeAnim.mScalingKeys[NextScalingIndex].mValue;
  Delta := VectorSubtract(EndScale, StartScale);
  Result := VectorAdd(StartScale, VectorScale(Delta, Factor));
End;

Procedure AssimpModel.Update();
Begin
  If (LastFrame = GraphicsManager.Instance.FrameID) Then
    Exit;

  LastFrame := GraphicsManager.Instance.FrameID;

  Self.BoneTransform(Application.GetTime / 1000);
End;


Function AssimpModel.FinalTransform(State: AnimationState; Bone: AnimationBoneState): Matrix4x4;
Begin
  Self.Update();
  Result := Bones[Bone._ID].FinalTransformation;
End;

Procedure AssimpModel.BoneTransform(TimeInSeconds:Single);
Var
  TicksPerSecond, TimeInTicks, AnimationTime:Single;
Begin
  If Scene.mAnimations[0].mTicksPerSecond>Epsilon Then
    TicksPerSecond := Scene.mAnimations[0].mTicksPerSecond
   Else
    TicksPerSecond := 25.0;

  TimeInTicks := TimeInSeconds * TicksPerSecond;
  AnimationTime := TimeInTicks;
  //AnimationTime := FloatMod(TimeInTicks, Scene.mAnimations[0].mDuration);

  ReadNodeHeirarchy(AnimationTime, Scene.mRootNode, Matrix4x4Identity);
End;

Function AssimpModel.FindNodeAnim(Animation:PaiAnimation; const NodeName:TERRAString):PaiNodeAnim;
Var
  I:Integer;
Begin
  For I:=0 To Pred(Animation.mNumChannels) Do
  Begin
    Result := Animation.mChannels[i];

    If (StringEquals(aiStringGetValue(Result.mNodeName) , NodeName)) Then
      Exit;
  End;

  Result := Nil;
End;

Procedure AssimpModel.InitParents(Node:paiNode; Prev:AssimpBone);
Var
  NodeName:TERRAString;
  I, BoneIndex:Integer;
Begin
  NodeName := aiStringGetValue(Node.mName);

  BoneIndex := Self.FindBone(NodeName);
  If BoneIndex>=0 Then
  Begin
    Bones[BoneIndex].Parent := Prev;

    Prev := Bones[BoneIndex];
  End;

  For I:=0 To Pred(Node.mNumChildren) Do
    InitParents(Node.mChildren[I], Prev);
End;

Procedure AssimpModel.ReadNodeHeirarchy(AnimationTime:Single; Node:paiNode; Const ParentTransform:Matrix4x4);
Var
  NodeName:TERRAString;
  I, BoneIndex:Integer;
  Animation:PaiAnimation;
  NodeTransformation, GlobalTransformation:Matrix4x4;
  NodeAnim:PaiNodeAnim;
  Scaling, Translation:aiVector3D;
  ScalingM, RotationM, TranslationM:Matrix4x4;
  RotationQ:aiQuaternion;
Begin
  NodeName := aiStringGetValue(Node.mName);

  Animation := Scene.mAnimations[0];

  NodeTransformation := Matrix4x4Transpose(Node.mTransformation);

  NodeAnim := FindNodeAnim(Animation, NodeName);

  If (Assigned(NodeAnim)) Then
  Begin
    // Interpolate scaling and generate scaling transformation matrix
    Scaling := CalcInterpolatedScaling(AnimationTime, NodeAnim);
    ScalingM := Matrix4x4Scale(Scaling);

    // Interpolate rotation and generate rotation transformation matrix
    RotationQ := CalcInterpolatedRotation(AnimationTime, NodeAnim);
    RotationM := QuaternionMatrix4x4(RotationQ);

    // Interpolate translation and generate translation transformation matrix
    Translation := CalcInterpolatedPosition(AnimationTime, NodeAnim);
    TranslationM := Matrix4x4Translation(Translation);

    // Combine the above transformations
    //NodeTransformation := Matrix4x4Multiply4x3(TranslationM, Matrix4x4Multiply4x3(RotationM, ScalingM));

    //NodeTransformation := Matrix4x4Multiply4x3(TranslationM, RotationM);

    NodeTransformation := TranslationM;
    //NodeTransformation := Matrix4x4Transpose(NodeTransformation);
  End;

  GlobalTransformation := Matrix4x4Multiply4x3(ParentTransform, NodeTransformation);

  BoneIndex := Self.FindBone(NodeName);
  If BoneIndex>=0 Then
  Begin
    //Bones[BoneIndex].FinalTransformation := Matrix4x4Multiply4x3(GlobalInverseTransform, Matrix4x4Multiply4x3(GlobalTransformation, Bones[BoneIndex].BoneOffset));

    //Bones[BoneIndex].FinalTransformation := Matrix4x4Multiply4x3(GlobalTransformation, Bones[BoneIndex].BoneOffset);

    Bones[BoneIndex].FinalTransformation := Matrix4x4Inverse(Bones[BoneIndex].BoneOffset);
  End;

  For I:=0 To Pred(Node.mNumChildren) Do
    ReadNodeHeirarchy(AnimationTime, Node.mChildren[I], GlobalTransformation);
End;

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
 //	aiProcess_GenSmoothNormals				Or
//	aiProcess_JoinIdenticalVertices			Or
	aiProcess_ImproveCacheLocality			Or
//	aiProcess_LimitBoneWeights				Or
//	aiProcess_RemoveRedundantMaterials  Or
	aiProcess_SplitLargeMeshes				Or
	aiProcess_Triangulate					Or
	aiProcess_GenUVCoords            Or
	aiProcess_SortByPType            Or
	//aiProcess_FindDegenerates        Or
	aiProcess_FindInvalidData;

  scene := aiImportFile(PAnsiChar(Source.Name), flags);
  If (Scene = Nil) Then
    Exit;

  Model := AssimpModel.Create(Scene);
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
        Result := Model.FindBone(aiStringGetValue(scene.mMeshes[K].mBones[I].mName));
        W := scene.mMeshes[K].mBones[I].mWeights[J].mWeight;

        Inc(Result);
        Exit;
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
  Result := Self.Model.BoneCount;
end;

Function AssimpFilter.GetBoneName(BoneID: Integer):TERRAString;
Begin
  Result := Model.Bones[boneID].Name;
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

  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Model.Bones[BoneID].Name);
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

  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Model.Bones[BoneID].Name);
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

  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Model.Bones[BoneID].Name);
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
  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Model.Bones[BoneID].Name);
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
  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Model.Bones[BoneID].Name);
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
  Channel := aiAnimationGetChannel(Scene.mAnimations[AnimationID], Model.Bones[BoneID].Name);
  If (Channel<0) Then
    Exit;

  With Scene.mAnimations[AnimationID].mChannels[Channel].mRotationKeys[Index].mValue Do
  Q := QuaternionCreate(x, y, z, w);

  Result.Value := QuaternionToEuler(Q);
  Result.Time := Scene.mAnimations[AnimationID].mChannels[Channel].mRotationKeys[Index].mTime;
End;

(*Function AssimpFilter.FindNode(Name:TERRAString; Root:pAiNode): pAiNode;
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
End;*)

Function AssimpFilter.GetBoneParent(BoneID: Integer): Integer;
Begin
  If Assigned(Model.Bones[BoneID].Parent) Then
    Result := Model.FindBone(Model.Bones[BoneID].Parent.Name)
  Else
    Result := -1;
End;


Function AssimpFilter.GetBoneOffsetMatrix(BoneID:Integer):Matrix4x4;
Begin
  //Result := Matrix4x4Inverse(Model.Bones[BoneID].BoneOffset);
  Result := Matrix4x4Identity;
End;

(*Var
  c:aiLogStream;*)

Initialization
//  c:= aiGetPredefinedLogStream(aiDefaultLogStream_STDOUT, Nil);
//  aiAttachLogStream(@c);
Finalization
//  aiDetachAllLogStreams();
End.