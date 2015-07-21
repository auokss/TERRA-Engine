Unit TERRA_KeyPairObjects;

{$I terra.inc}
Interface
Uses TERRA_String, TERRA_Object, TERRA_Utils, TERRA_Collections, TERRA_HashMap;

Type
  StringKeyPair = Class(CollectionObject)
    Protected
      Procedure CopyValue(Other:CollectionObject); Override;
      Function Sort(Other:CollectionObject):Integer; Override;

    Public
      Value:TERRAString;

      Constructor Create(Key, Value:TERRAString);
      Function ToString():TERRAString; Override;
  End;

Function LoadKeypairList(SourceFile:TERRAString):HashMap;

Implementation
Uses TERRA_Stream, TERRA_FileStream;

Function LoadKeypairList(SourceFile:TERRAString):HashMap;
Var
  Source:Stream;
  S,S2:TERRAString;
Begin
  S := '';
  Result := HashMap.Create();
  If  (SourceFile<>'') And (FileStream.Exists(SourceFile)) Then
  Begin
    Source :=  FileStream.Open(SourceFile);
    While Not Source.EOF Do
    Begin
      Source.ReadLine(S);
      S2 := StringGetNextSplit(S, Ord(','));
      Result.Add(StringKeyPair.Create(S2,S));
    End;
    ReleaseObject(Source);
  End;
End;

{ StringKeyPair }
Constructor StringKeyPair.Create(Key, Value:TERRAString);
Begin
  Self._ObjectName := Key;
  Self.Value := Value;
End;

Procedure StringKeyPair.CopyValue(Other: CollectionObject);
Begin
  Self._ObjectName := StringKeyPair(Other).Name;
  Self.Value := StringKeyPair(Other).Value;
End;

Function StringKeyPair.Sort(Other: CollectionObject): Integer;
Var
  S:TERRAString;
Begin
  S := StringKeyPair(Other).Name;
  Result := GetStringSort(Self.Name, S);
End;

Function StringKeyPair.ToString:TERRAString;
Begin
  Result := Name;
End;

End.