Unit TERRA_AudioBuffer;

{$I terra.inc}

Interface
Uses TERRA_Utils;

Type
  AudioSample = SmallInt;
  PAudioSample = ^AudioSample;

  AudioBuffer = Class(TERRAObject)
    Protected
      _Samples:Array Of AudioSample;
      _SampleCount:Cardinal;

      _AllocatedSamples:Cardinal;

      _Frequency:Cardinal;
      _Stereo:Boolean;

      _TotalSize:Cardinal;

      _NoiseReductionLeft:AudioSample;
      _NoiseReductionRight:AudioSample;

      Function GetSamples: Pointer;

      Procedure AllocateSamples();

    Public
      Constructor Create(SampleCount, Frequency:Cardinal; Stereo:Boolean);
      Procedure Release(); Override;

      Function GetSampleAt(Offset, Channel:Cardinal):PAudioSample;

      Procedure ClearSamples();

      Procedure Upsample(Const CurrentSample:Single; Out SrcSampleLeft, SrcSampleRight:AudioSample; Volume:Single);

      Function MixSamples(DestOffset:Cardinal; Src:AudioBuffer; SrcOffset, SampleTotalToCopy:Cardinal; Volume:Single):Cardinal;

      // in milisseconds
      Function GetLength: Cardinal;

      Property Samples:Pointer Read GetSamples;
      Property SampleCount:Cardinal Read _SampleCount;
      Property Frequency:Cardinal Read _Frequency;
      Property Stereo:Boolean Read _Stereo;

      Property SizeInBytes:Cardinal Read _TotalSize;
  End;

Implementation
Uses TERRA_Math;

Constructor AudioBuffer.Create(SampleCount, Frequency: Cardinal; Stereo: Boolean);
Begin
  Self._Frequency := Frequency;
  Self._Stereo := Stereo;

  _SampleCount := SampleCount;
  Self.AllocateSamples();

  Self.ClearSamples();
End;

Procedure AudioBuffer.AllocateSamples();
Begin
  If _AllocatedSamples = 0 Then
  Begin
    _AllocatedSamples := _SampleCount;
  End Else
    _AllocatedSamples := _AllocatedSamples * 2;

  _TotalSize := _SampleCount * SizeOf(AudioSample);
  If Stereo Then
    _TotalSize := _TotalSize * 2;

  SetLength(_Samples, _AllocatedSamples * 2);
End;

Procedure AudioBuffer.ClearSamples;
Var
  I, TotalSamples:Integer;
Begin
  TotalSamples := _SampleCount;
  If Self.Stereo Then
    TotalSamples := TotalSamples Shl 1;

  For I:=0 To Pred(TotalSamples) Do
    _Samples[I] := 0;
End;

Procedure AudioBuffer.Release;
Begin
  If Assigned(_Samples) Then
  Begin
    SetLength(_Samples, 0);
    _Samples := Nil;
  End;
End;

Function AudioBuffer.GetLength: Cardinal;
Begin
  Result := Trunc((_SampleCount*1000)/ _Frequency);
End;

(*Function Sound.GetBufferSize(Length,Channels,BitsPerSample,Frequency:Cardinal):Cardinal;
Begin
  Result := Round((Length/1000)*Frequency*Self.SampleSize*Self.Channels);
End;*)

Function AudioBuffer.GetSamples: Pointer;
Begin
  Result := @(_Samples[0]);
End;

Function AudioBuffer.GetSampleAt(Offset, Channel: Cardinal): PAudioSample;
Begin
  If (Offset >= _AllocatedSamples) Then
    Self.AllocateSamples();

  If (Offset >= _SampleCount) Then
    _SampleCount := Succ(Offset);

  If _Stereo Then
    Offset := Offset * 2 + Channel;

   Result := @(_Samples[Offset]);
End;

Function AudioBuffer.MixSamples(DestOffset:Cardinal; Src:AudioBuffer; SrcOffset, SampleTotalToCopy:Cardinal; Volume:Single):Cardinal;
Var
  SrcBuffer, DestBuffer:PAudioSample;
  SrcSampleLeft, SrcSampleRight:AudioSample;
  CurrentValue:Integer;
  CurrentSample, SampleIncr:Single;
Begin
  If (Src.Frequency < Self.Frequency) Then
  Begin
    SampleIncr := Src.Frequency / Self.Frequency;
    Result := Trunc(SampleTotalToCopy * SampleIncr);
  End Else
  Begin
    Result := SampleTotalToCopy;
    SampleIncr := 1.0;
  End;

  If (SrcOffset + SampleTotalToCopy > Src.SampleCount) Then
    SampleTotalToCopy := Src.SampleCount  - SrcOffset;

  If (DestOffset + SampleTotalToCopy > Self.SampleCount) Then
    SampleTotalToCopy := Self.SampleCount - DestOffset;


  DestBuffer := Self.GetSampleAt(DestOffset, 0);
  SrcBuffer := Src.GetSampleAt(SrcOffset, 0);

  CurrentSample := SrcOffset;
  While SampleTotalToCopy>0 Do
  Begin
    If SampleIncr < 1.0 Then
      Src.Upsample(CurrentSample, SrcSampleLeft, SrcSampleRight, Volume)
    Else
    Begin
      SrcSampleLeft := Trunc((SrcBuffer^) * Volume);
      If Src.Stereo Then
      Begin
        Inc(SrcBuffer);
        SrcSampleRight := Trunc((SrcBuffer^) * Volume);
      End  Else
        SrcSampleRight := SrcSampleLeft;

      Inc(SrcBuffer);
    End;

    CurrentValue := DestBuffer^ + SrcSampleLeft;
    If (CurrentValue>High(AudioSample)) Then
      CurrentValue := High(AudioSample);

    DestBuffer^ := CurrentValue;
    Inc(DestBuffer);

    If (Self.Stereo) Then
    Begin
      CurrentValue := DestBuffer^ + SrcSampleRight;
      If (CurrentValue>High(AudioSample)) Then
        CurrentValue := High(AudioSample);

      DestBuffer^ := CurrentValue;
      Inc(DestBuffer);
    End;

    CurrentSample := CurrentSample + SampleIncr;
    Dec(SampleTotalToCopy);
  End;
End;

//  src     X  X
//  Dest    XXXXXXX
Procedure AudioBuffer.Upsample(Const CurrentSample:Single; Out SrcSampleLeft, SrcSampleRight:AudioSample; Volume:Single);
Var
  Delta:Single;
  SrcData:PAudioSample;
  SampleA, SampleB, Value:AudioSample;
  LeftOffset, RightOffset, CenterOffset:Cardinal;
Begin
  Delta := Frac(CurrentSample);
  LeftOffset := Trunc(CurrentSample);
  If (LeftOffset < (Self._SampleCount - 2)) Then
    RightOffset := Succ(LeftOffset)
  Else
    RightOffset := LeftOffset;

  SrcData := Self.GetSampleAt(LeftOffset, 0);

  SampleA := SrcData^;
  SampleB := SrcData^;

  SampleA := Trunc(SampleA * 0.5);
  SampleB := Trunc(SampleB * 0.5);

  SrcSampleLeft := Trunc((SampleA * (1.0 - Delta) + SampleB * Delta) * Volume);
  //SrcSampleLeft := Trunc(CubicInterpolate(SampleA, SampleA, SampleB, SampleB, Delta));

(*  SrcSampleLeft := SrcData^;

  If Self.Stereo Then
  Begin
    Inc(SrcData);
    SrcSampleRight := SrcData^;
  End Else*)
    SrcSampleRight := SrcSampleLeft;
End;



End.
