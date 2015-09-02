Unit TERRA_AudioBuffer;

{$I terra.inc}

Interface
Uses TERRA_Utils;

Type
  AudioSample = SmallInt;
  PAudioSample = ^AudioSample;

  FloatAudioSample = Single;
  PFloatAudioSample = ^FloatAudioSample;

  UnclippedAudioSample = Single;

Const
  MinSampleValue = -1.0;
  MaxSampleValue = 1.0;

  SampleConvertFactor = 1.0 / 32767.0;

Type
  StereoAudioSampleDouble = Record
    Left:Double;
    Right:Double;
  End;

  StereoAudioSample16 = packed record
    Left, Right : AudioSample;
  End;

  MonoAudioArray16 = Array[0..100000] Of AudioSample;
  PMonoAudioArray16 = ^MonoAudioArray16;

  StereoAudioArray16 = Array[0..100000] Of StereoAudioSample16;
  PStereoAudioArray16 = ^StereoAudioArray16;


  MonoAudioArrayDouble = Array[0..100000] Of Double;
  PMonoAudioArrayDouble = ^MonoAudioArrayDouble;

  StereoAudioArrayDouble = Array[0..100000] Of StereoAudioSampleDouble;
  PStereoAudioArrayDouble = ^StereoAudioArrayDouble;

  { TERRAAudioBuffer }
  TERRAAudioBuffer = Class(TERRAObject)
    Protected
      _Samples:Array Of AudioSample;
      _SampleCount:Cardinal;

      _Frequency:Cardinal;
      _Stereo:Boolean;

      _AllocatedSamples:Cardinal;
      _TotalSize:Cardinal;

      Function GetSamples: Pointer;

      Procedure AllocateSamples();

    Public
      Constructor Create(SampleCount, Frequency:Cardinal; Stereo:Boolean);
      Procedure Release(); Override;

      Function GetSampleAt(Offset, Channel:Cardinal):PAudioSample;

      // in milisseconds
      Function GetLength: Cardinal;

      Property Samples:Pointer Read GetSamples;
      Property SampleCount:Cardinal Read _SampleCount;
      Property Frequency:Cardinal Read _Frequency;
      Property Stereo:Boolean Read _Stereo;

      Property SizeInBytes:Cardinal Read _TotalSize;
  End;

  { TERRAAudioMixingBuffer }
  TERRAAudioMixingBuffer = Class(TERRAObject)
    Protected
      _Samples:Array Of FloatAudioSample;
      _SampleCount:Cardinal;

      _AllocatedSamples:Cardinal;

      _Frequency:Cardinal;

      _TotalSize:Cardinal;

      _NoiseReductionLeft:AudioSample;
      _NoiseReductionRight:AudioSample;

      Function GetSamples: Pointer;

      Procedure AllocateSamples();

      Procedure SetSampleCount(Const Count:Cardinal);

      Procedure MixMonoSamplesWithShifting(Const SrcOffset:Cardinal; Src:TERRAAudioBuffer; DestBuffer:PFloatAudioSample; SampleTotalToCopy:Cardinal; Const SampleIncr, VolumeLeft, VolumeRight:Single);
      Procedure MixStereoSamplesWithShifting(Const SrcOffset:Cardinal; Src:TERRAAudioBuffer; DestBuffer:PFloatAudioSample; SampleTotalToCopy:Cardinal; Const SampleIncr, VolumeLeft, VolumeRight:Single);

      Procedure MixSamplesDirectMonoToStereo(SrcBuffer:PAudioSample; DestBuffer:PFloatAudioSample; SampleTotalToCopy:Cardinal; Const VolumeLeft, VolumeRight:Single);
      Procedure MixSamplesDirectStereoToStereo(SrcBuffer:PAudioSample; DestBuffer:PFloatAudioSample; SampleTotalToCopy:Cardinal; Const VolumeLeft, VolumeRight:Single);

    Public
      Constructor Create(SampleCount, Frequency:Cardinal);
      Procedure Release(); Override;

      Function GetSampleAt(Offset, Channel:Cardinal):PFloatAudioSample;

      Procedure FillSamples(Offset, Count:Cardinal);
      Procedure ClearSamples();

      Function MixSamples(DestOffset:Cardinal; Src:TERRAAudioBuffer; SrcOffset, SampleTotalToCopy:Cardinal; Const VolumeLeft, VolumeRight:Single):Cardinal;

      // in milisseconds
      Function GetLength: Cardinal;

      Property Samples:Pointer Read GetSamples;
      Property SampleCount:Cardinal Read _SampleCount Write SetSampleCount;
      Property Frequency:Cardinal Read _Frequency;

      Property SizeInBytes:Cardinal Read _TotalSize;
  End;

Implementation
Uses TERRA_Math;

{ TERRAAudioBuffer }
Constructor TERRAAudioBuffer.Create(SampleCount, Frequency: Cardinal; Stereo: Boolean);
Begin
  Self._Frequency := Frequency;
  Self._Stereo := Stereo;

  _SampleCount := SampleCount;
  Self.AllocateSamples();
End;

Procedure TERRAAudioBuffer.AllocateSamples;
Var
  TargetLen:Integer;
Begin
  TargetLen := _SampleCount;
  If Self.Stereo Then
    TargetLen := TargetLen * 2;

  If _AllocatedSamples = 0 Then
    _AllocatedSamples := TargetLen;

  While _AllocatedSamples<TargetLen Do
    _AllocatedSamples := _AllocatedSamples * 2;

  _TotalSize := _SampleCount * SizeOf(AudioSample);
  If Self.Stereo Then
    _TotalSize := _TotalSize * 2;


  SetLength(_Samples, _AllocatedSamples);
End;

procedure TERRAAudioBuffer.Release;
Begin
  If Assigned(_Samples) Then
  Begin
    SetLength(_Samples, 0);
    _Samples := Nil;
  End;
End;

function TERRAAudioBuffer.GetLength: Cardinal;
Begin
  Result := Trunc((_SampleCount*1000)/ _Frequency);
End;

(*Function Sound.GetBufferSize(Length,Channels,BitsPerSample,Frequency:Cardinal):Cardinal;
Begin
  Result := Round((Length/1000)*Frequency*Self.SampleSize*Self.Channels);
End;*)

function TERRAAudioBuffer.GetSamples: Pointer;
Begin
  Result := @(_Samples[0]);
End;

function TERRAAudioBuffer.GetSampleAt(Offset, Channel: Cardinal): PAudioSample;
Begin
  If (Offset >= _AllocatedSamples) Then
    Self.AllocateSamples();

  If (Offset >= _SampleCount) Then
    _SampleCount := Succ(Offset);

  If _Stereo Then
    Offset := Offset * 2 + Channel;

   Result := @(_Samples[Offset]);
End;


{ TERRAAudioMixingBuffer }
Constructor TERRAAudioMixingBuffer.Create(SampleCount, Frequency: Cardinal);
Begin
  Self._Frequency := Frequency;

  _SampleCount := SampleCount;
  Self.AllocateSamples();

  Self.ClearSamples();
End;

procedure TERRAAudioMixingBuffer.AllocateSamples;
Var
  TargetLen:Integer;
Begin
  TargetLen := _SampleCount * 2;

  If _AllocatedSamples = 0 Then
    _AllocatedSamples := TargetLen;

  While _AllocatedSamples<TargetLen Do
    _AllocatedSamples := _AllocatedSamples * 2;

  _TotalSize := _SampleCount * SizeOf(AudioSample) * 2;

  SetLength(_Samples, _AllocatedSamples);
End;

Procedure TERRAAudioMixingBuffer.SetSampleCount(const Count: Cardinal);
Begin
  While (Count > Self._SampleCount) Do
    Self.AllocateSamples();

  _SampleCount := Count;
End;

Procedure TERRAAudioMixingBuffer.FillSamples(Offset, Count:Cardinal);
Var
  I:Integer;
  DestSample:PFloatAudioSample;
Begin
  Count := Count * 2;

  DestSample := Self.GetSampleAt(Offset, 0);
  While Count>0 Do
  Begin
    DestSample^ := 0.0;
    Inc(DestSample);
    Dec(Count);
  End;
End;

Procedure TERRAAudioMixingBuffer.ClearSamples;
Begin
  FillSamples(0, _SampleCount);
End;

procedure TERRAAudioMixingBuffer.Release;
Begin
  If Assigned(_Samples) Then
  Begin
    SetLength(_Samples, 0);
    _Samples := Nil;
  End;
End;

function TERRAAudioMixingBuffer.GetLength: Cardinal;
Begin
  Result := Trunc((_SampleCount*1000)/ _Frequency);
End;

(*Function Sound.GetBufferSize(Length,Channels,BitsPerSample,Frequency:Cardinal):Cardinal;
Begin
  Result := Round((Length/1000)*Frequency*Self.SampleSize*Self.Channels);
End;*)

function TERRAAudioMixingBuffer.GetSamples: Pointer;
Begin
  Result := @(_Samples[0]);
End;

Function TERRAAudioMixingBuffer.GetSampleAt(Offset, Channel: Cardinal): PFloatAudioSample;
Begin
  If (Offset >= _AllocatedSamples) Then
    Self.AllocateSamples();

  If (Offset >= _SampleCount) Then
    _SampleCount := Succ(Offset);

  Offset := (Offset Shl 1) + Channel;

  Result := @(_Samples[Offset]);
End;

Function TERRAAudioMixingBuffer.MixSamples(DestOffset: Cardinal; Src: TERRAAudioBuffer; SrcOffset, SampleTotalToCopy: Cardinal; Const VolumeLeft, VolumeRight:Single): Cardinal;
Var
  SrcBuffer:PAudioSample;
  DestBuffer:PFloatAudioSample;
  SampleIncr:Single;
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

  If (VolumeLeft<0.0) And (VolumeRight<=0.0) Then
    Exit;

  If (SrcOffset + Result > Src.SampleCount) Then
    SampleTotalToCopy := Src.SampleCount  - SrcOffset;

  If (DestOffset + Result > Self.SampleCount) Then
    SampleTotalToCopy := Self.SampleCount - DestOffset;

  DestBuffer := Self.GetSampleAt(DestOffset, 0);

  If SampleIncr < 1.0 Then
  Begin
    If Src.Stereo Then
      Self.MixStereoSamplesWithShifting(SrcOffset, Src, DestBuffer, SampleTotalToCopy, SampleIncr, VolumeLeft, VolumeRight)
    Else
      Self.MixMonoSamplesWithShifting(SrcOffset, Src, DestBuffer, SampleTotalToCopy, SampleIncr, VolumeLeft, VolumeRight);
  End Else
  Begin
    SrcBuffer := Src.GetSampleAt(SrcOffset, 0);

    If Src.Stereo Then
      Self.MixSamplesDirectStereoToStereo(SrcBuffer, DestBuffer, SampleTotalToCopy, VolumeLeft, VolumeRight)
    Else
      Self.MixSamplesDirectMonoToStereo(SrcBuffer, DestBuffer, SampleTotalToCopy, VolumeLeft, VolumeRight);
  End;
End;


Procedure TERRAAudioMixingBuffer.MixSamplesDirectMonoToStereo(SrcBuffer:PAudioSample; DestBuffer:PFloatAudioSample; SampleTotalToCopy:Cardinal; Const VolumeLeft, VolumeRight:Single);
Var
  InputSample:AudioSample;
  SrcSampleLeft, SrcSampleRight:FloatAudioSample;
  CurrentValue:UnclippedAudioSample;
Begin
  While SampleTotalToCopy>0 Do
  Begin
    // read source sample
    InputSample := SrcBuffer^;
    Inc(SrcBuffer);

    SrcSampleLeft := (InputSample * SampleConvertFactor * VolumeLeft);
    SrcSampleRight := (InputSample * SampleConvertFactor * VolumeRight);

    // left side
    CurrentValue := FloatClamp(DestBuffer^ + SrcSampleLeft, MinSampleValue, MaxSampleValue);
    DestBuffer^ := CurrentValue;
    Inc(DestBuffer);

    // right side
    CurrentValue := FloatClamp(DestBuffer^ + SrcSampleRight, MinSampleValue, MaxSampleValue);
    DestBuffer^ := CurrentValue;
    Inc(DestBuffer);


    Dec(SampleTotalToCopy);
  End;
End;

Procedure TERRAAudioMixingBuffer.MixSamplesDirectStereoToStereo(SrcBuffer:PAudioSample; DestBuffer:PFloatAudioSample; SampleTotalToCopy:Cardinal; Const VolumeLeft, VolumeRight:Single);
Var
  InputSample:AudioSample;
  CurrentValue:UnclippedAudioSample;
  SrcSampleLeft, SrcSampleRight:FloatAudioSample;
Begin
  While SampleTotalToCopy>0 Do
  Begin
    InputSample := SrcBuffer^;
    Inc(SrcBuffer);
    SrcSampleLeft := (InputSample * SampleConvertFactor * VolumeLeft);

    InputSample := SrcBuffer^;
    Inc(SrcBuffer);
    SrcSampleRight := (InputSample * SampleConvertFactor * VolumeRight);

    // left side
    CurrentValue := FloatClamp(DestBuffer^ + SrcSampleLeft, MinSampleValue, MaxSampleValue);
    DestBuffer^ := CurrentValue;
    Inc(DestBuffer);

    // right shide
    CurrentValue := FloatClamp(DestBuffer^ + SrcSampleRight, MinSampleValue, MaxSampleValue);
    DestBuffer^ := CurrentValue;
    Inc(DestBuffer);

    Dec(SampleTotalToCopy);
  End;
End;

Procedure TERRAAudioMixingBuffer.MixMonoSamplesWithShifting(Const SrcOffset:Cardinal; Src:TERRAAudioBuffer; DestBuffer:PFloatAudioSample; SampleTotalToCopy:Cardinal; Const SampleIncr, VolumeLeft, VolumeRight:Single);
Var
  CurrentSample:Single;
  CurrentValue:UnclippedAudioSample;
  SrcSampleLeft, SrcSampleRight:AudioSample;
  TargetOffset:Cardinal;

  SrcData:PAudioSample;
  Delta:Single;
  SampleA, SampleB, Value:AudioSample;
Begin
  CurrentSample := SrcOffset;

  While SampleTotalToCopy>0 Do
  Begin
    TargetOffset := Trunc(CurrentSample);
    Delta := Frac(CurrentSample);
    SrcData := Src.GetSampleAt(TargetOffset, 0);

    SampleA := SrcData^;
    Inc(SrcData);
    SampleB := SrcData^;

    SrcSampleLeft := Trunc(SampleA * (1.0 - Delta) + SampleB * Delta);
    SrcSampleRight := SrcSampleLeft;

    SrcSampleLeft := Trunc(SrcSampleLeft * VolumeLeft);
    SrcSampleRight := Trunc(SrcSampleRight * VolumeRight);

    // left side
    CurrentValue := FloatClamp(DestBuffer^ + SrcSampleLeft, MinSampleValue, MaxSampleValue);
    DestBuffer^ := CurrentValue;
    Inc(DestBuffer);

    // right side
    CurrentValue := FloatClamp(DestBuffer^ + SrcSampleRight, MinSampleValue, MaxSampleValue);
    DestBuffer^ := CurrentValue;
    Inc(DestBuffer);

    CurrentSample := CurrentSample + SampleIncr;
    Dec(SampleTotalToCopy);
  End;
End;

Procedure TERRAAudioMixingBuffer.MixStereoSamplesWithShifting(Const SrcOffset:Cardinal; Src:TERRAAudioBuffer; DestBuffer:PFloatAudioSample; SampleTotalToCopy:Cardinal; Const SampleIncr, VolumeLeft, VolumeRight:Single);
Var
  CurrentSample:Single;
  CurrentValue:UnclippedAudioSample;
  SrcSampleLeft, SrcSampleRight:AudioSample;
  TargetOffset:Cardinal;

  SrcData:PAudioSample;
  Delta:Single;
  SampleA, SampleB, Value:AudioSample;
Begin
  CurrentSample := SrcOffset;

  While SampleTotalToCopy>0 Do
  Begin
    TargetOffset := Trunc(CurrentSample);
    Delta := Frac(CurrentSample);
    SrcData := Src.GetSampleAt(TargetOffset, 0);

    SampleA := SrcData^;
    Inc(SrcData, 2);
    SampleB := SrcData^;

    SrcSampleLeft := Trunc(SampleA * (1.0 - Delta) + SampleB * Delta);

    Dec(SrcData);
    SampleA := SrcData^;
    Inc(SrcData, 2);
    SampleB := SrcData^;
    SrcSampleRight := Trunc(SampleA * (1.0 - Delta) + SampleB * Delta);

    SrcSampleLeft := Trunc(SrcSampleLeft * VolumeLeft);
    SrcSampleRight := Trunc(SrcSampleRight * VolumeRight);

    // left side
    CurrentValue := FloatClamp(DestBuffer^ + SrcSampleLeft, MinSampleValue, MaxSampleValue);
    DestBuffer^ := CurrentValue;
    Inc(DestBuffer);

    // right side
    CurrentValue := FloatClamp(DestBuffer^ + SrcSampleRight, MinSampleValue, MaxSampleValue);
    DestBuffer^ := CurrentValue;
    Inc(DestBuffer);

    CurrentSample := CurrentSample + SampleIncr;
    Dec(SampleTotalToCopy);
  End;
End;

(*Function TERRAAudioMixingBuffer.CopySamples(DestOffset: Cardinal; Src: TERRAAudioMixingBuffer; SrcOffset, SampleTotalToCopy: Cardinal): Cardinal;
Var
  SrcBuffer, DestBuffer:PAudioSample;
  SrcSampleLeft, SrcSampleRight:AudioSample;
  CurrentValue:UnclippedAudioSample;
  CurrentSample, SampleIncr:Single;
Begin
  If (Src.Frequency <> Self.Frequency) Or (Src.Stereo <> Self.Stereo) Then
  Begin
    Self.FillSamples(DestOffset, SampleTotalToCopy);
    Result := Self.MixSamples(DestOffset, Src, SrcOffset, SampleTotalToCopy, 1.0, 1.0);
    Exit;
  End;

  If (SrcOffset + SampleTotalToCopy > Src.SampleCount) Then
    SampleTotalToCopy := Src.SampleCount  - SrcOffset;

  If (DestOffset + SampleTotalToCopy > Self.SampleCount) Then
    SampleTotalToCopy := Self.SampleCount - DestOffset;


  DestBuffer := Self.GetSampleAt(DestOffset, 0);
  SrcBuffer := Src.GetSampleAt(SrcOffset, 0);

  Result := SampleTotalToCopy;

  If (Self.Stereo) Then
    SampleTotalToCopy := SampleTotalToCopy Shl 1;

  Move(SrcBuffer^, DestBuffer^, SampleTotalToCopy * SizeOf(AudioSample));
End;*)

End.
