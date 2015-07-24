Unit TERRA_AudioConverter;

{$I terra.inc}

Interface
Uses TERRA_Utils, TERRA_AudioBuffer;

Const
  BUF_SIZE = $100000;

Type
  TACSFilterWindowType = (fwHamming, fwHann, fwBlackman);

  StereoAudioSampleDouble = Record
    Left : Double;
    Right : Double;
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


  AudioRateConverter = Class(TERRAObject)
  Private
    FOutSampleRate : Integer;
    EndOfInput : Boolean;
    remainder : Integer;
    InBufM, OutBufM:PMonoAudioArray16;
    InBufS, OutBufS:PStereoAudioArray16;

    DAM :Array of Double;
    DAS :Array of StereoAudioSampleDouble;
    Kernel :Array of Double;
    _KernelWidth : Integer;
    FFilterWindow : TACSFilterWindowType;
    Tail : Pointer;
    LBS:StereoAudioSample16;

    _Input:AudioBuffer;

    function ConvertFreqs16Mono(InSize : Integer): Integer;
    function ConvertFreqs16Stereo(InSize : Integer): Integer;

  Public
    Constructor Create(Input:AudioBuffer);
    Procedure Release(); override;

    Function Convert(OutSampleRate:Cardinal):AudioBuffer;

    property FilterWindow : TACSFilterWindowType read FFilterWindow write FFilterWindow;
  End;

Implementation

Const
  TwoPi = 6.28318530718;

Procedure HannWindow(OutData:PMonoAudioArrayDouble; Width:Integer; Symmetric:Boolean);
Var
  i, n:Integer;
Begin
  If Symmetric Then
    n := Width-1
  Else
    n := Width;

  For i := 0 to Width-1 do
    OutData[i] := (1-Cos(TwoPi*i/n))/2;
End;

Procedure HammingWindow(OutData:PMonoAudioArrayDouble; Width:Integer; Symmetric:Boolean);
Var
  i, n:Integer;
Begin
  If Symmetric Then
    n := Width-1
  Else
    n := Width;

  For i := 0 to Width-1 Do
    OutData[i] := 0.54-0.46*Cos(TwoPi*i/n);
End;

Procedure BlackmanWindow(OutData:PMonoAudioArrayDouble; Width:Integer; Symmetric:Boolean);
Var
  i, n:Integer;
Begin
  If Symmetric Then
    n := Width-1
  Else
    n := Width;

  For i := 0 to Width-1 Do
    OutData[i] := 0.42-0.5*Cos(TwoPi*i/n) + 0.08*Cos(2*TwoPi*i/n);
End;

Procedure CalculateSincKernel(OutData:PMonoAudioArrayDouble; CutOff:Double; Width:Integer; WType:TACSFilterWindowType);
Var
  i:Integer;
  S:Double;
  Window:Array Of Double;
Begin
  SetLength(Window, Width);
  Case WType of
    fwHamming : HammingWindow(@Window[0], Width, False);
    fwHann : HannWindow(@Window[0], Width, False);
    fwBlackman : BlackmanWindow(@Window[0], Width, False);
  End;

  S := 0;
  For i := 0 to Width-1 do
  Begin
    If i-(Width shr 1) <> 0 then
      OutData[i] := Sin(TwoPi*CutOff*(i-(Width shr 1)))/(i-(Width shr 1))*Window[i]
    Else
      OutData[i] := TwoPi*CutOff*Window[i];

    S := S + OutData[i];
  End;

  For i := 0 to Width-1 Do
    OutData[i] := OutData[i]/S;
End;

Constructor AudioRateConverter.Create(Input:AudioBuffer);
Begin
  _Input := Input;

  If (Input.SampleCount>2000) Then
    _KernelWidth := 30
  Else
    _KernelWidth := 2;
    
  FFilterWindow := fwBlackman;
End;

Procedure AudioRateConverter.Release();
Begin
  Kernel := nil;
  DAS := nil;
  DAM := nil;
End;

Function AudioRateConverter.Convert(OutSampleRate:Cardinal):AudioBuffer;
Var
  Ratio:Single;
  TailSize, NewSize:Integer;
  L, InSize:Integer;
  //P : PACSBuffer8;
Begin
  FOutSampleRate := OutSampleRate;

  EndOfInput := False;
  Ratio := FOutSampleRate/_Input.Frequency;

  If _Input.Stereo Then
  Begin
    If Ratio < 1.0 then
      TailSize := (_KernelWidth-1)*4
    Else
    Begin
      SetLength(DAS, (BUF_SIZE div 4)+ _KernelWidth);
      TailSize := (_KernelWidth-1)*16;
    End;
  End Else
  Begin
    If Ratio < 1.0 then
      TailSize := (_KernelWidth-1)*2
    Else
    Begin
      SetLength(DAM, (BUF_SIZE div 2)+ _KernelWidth);
      TailSize := (_KernelWidth-1)*8;
    End;

    FillChar(DAM[0], Length(DAM)*Sizeof(DAM[0]), 0);
  End;

  GetMem(Tail, TailSize);
  FillChar(Tail^, TailSize, 0);

  NewSize := Round(_Input.SampleCount * Ratio);
  Result := AudioBuffer.Create(NewSize, Self.FOutSampleRate, _Input.Stereo);
  Remainder := -1;

  If Ratio > 1.0 Then
    Ratio := 1/Ratio;

  Ratio := Ratio*0.4;

  SetLength(Kernel, _KernelWidth);
  CalculateSincKernel(@Kernel[0], Ratio, _KernelWidth, FFilterWindow);

  InSize := _Input.SampleCount;
  If _Input.Stereo then
  Begin
    InBufS := _Input.Samples;
    OutBufS := Result.Samples;
    ConvertFreqs16Stereo(InSize);
  End Else
  Begin
    InBufM := _Input.Samples ;
    OutBufM := Result.Samples;
    ConvertFreqs16Mono(InSize);
  End;

  // clean up
  FreeMem(Tail);
End;

Function AudioRateConverter.ConvertFreqs16Mono(InSize : Integer): Integer;
Var
  i, step, j, k, s, m : Integer;
  D : Double;
  TailMono:PMonoAudioArray16;
  TailMonoD:PMonoAudioArrayDouble;
Begin
  TailMono := Tail;
  s := InSize shr 1;

  If _Input.Frequency > FOutSampleRate Then
  Begin
    step := _Input.Frequency - FOutSampleRate;
    j := 0;
    If remainder < 0 Then
      remainder := FOutSampleRate;

    For I:=0 To s - 1 Do
    Begin
      If remainder > FOutSampleRate Then
        Dec(remainder, FOutSampleRate)
      Else
      Begin
        D := 0;
        For k := 0 to _KernelWidth - 1 Do
        If i-k >= 0 Then
          D := D + InBufM[i-k] * Kernel[_KernelWidth - 1 - k]
        Else
          D := D + TailMono[_KernelWidth-1+i-k]*Kernel[_KernelWidth - 1 - k];

        OutBufM[j] := Round(D);
        Inc(j);
        Inc(remainder, step);
      End;
    End;

    For i := 0 to _KernelWidth-2 Do
      TailMono[i] := InBufM[i+s-_KernelWidth+1]
  End Else
  Begin
    TailMonoD := Tail;
    FillChar(DAM[0], Length(DAM)*8, 0);
    For i := 0 to _KernelWidth-2 do
    Begin
      DAM[i] := TailMonoD[i];
      TailMonoD[i] := 0;
    End;
    Step := _Input.Frequency;
    j := 0;
    If remainder < 0 Then
      remainder := 0;

    While remainder < FOutSampleRate Do
    Begin
      m := Round(((FOutSampleRate - remainder)*LBS.Left +  remainder*InBufM[0])/FOutSampleRate);
      for k := 0 to _KernelWidth-1 do
        DAM[j+k] := DAM[j+k] + m*Kernel[k];

      Inc(j);
      Inc(remainder, step);
    End;

    Dec(remainder, FOutSampleRate);
    For i := 0 to s - 2 Do
    Begin
      while remainder < FOutSampleRate do
      Begin
        m := Round(((FOutSampleRate - remainder)*InBufM[i] +  remainder*InBufM[i+1])/FOutSampleRate);
        for k := 0 to _KernelWidth-1 do
          DAM[j+k] := DAM[j+k] + m*Kernel[k];

        Inc(j);
        Inc(remainder, step);
      End;

      Dec(remainder, FOutSampleRate);
    End;

    LBS.Left := InBufM[s-1];
    For i := 0 to j-1 do
      OutBufM[i] := Round(DAM[i]);

    For i := 0 to _KernelWidth-2 Do
      TailMonoD[i] := DAM[i+j];
  End;

  Result := j shl 1;
End;

Function AudioRateConverter.ConvertFreqs16Stereo(InSize : Integer): Integer;
Var
  i, step, j, k, s, m1, m2 : Integer;
  D1, D2 : Double;
  TailStereo:PStereoAudioArray16;
  TailStereoD:PStereoAudioArrayDouble;
Begin
  TailStereo := Tail;
  s := InSize shr 1;
  If _Input.Frequency > FOutSampleRate Then
  Begin
    step := _Input.Frequency - FOutSampleRate;
    j := 0;
    If remainder < 0 Then
      remainder := FOutSampleRate;

    For i := 0 to s - 1 do
    Begin
      If remainder > FOutSampleRate then
        Dec(remainder, FOutSampleRate)
      Else
      Begin
        D1 := 0;
        D2 := 0;
        For k := 0 to _KernelWidth - 1 do
        If i-k >= 0 then
        Begin
          D1 := D1 + InBufS[i-k].Left*Kernel[_KernelWidth - 1 - k];
          D2 := D2 + InBufS[i-k].Right*Kernel[_KernelWidth - 1 - k];
        End Else
        begin
          D1 := D1 + TailStereo[_KernelWidth-1+i-k].Left*Kernel[_KernelWidth - 1 - k];
          D2 := D2 + TailStereo[_KernelWidth-1+i-k].Right*Kernel[_KernelWidth - 1 - k];
        end;

        OutBufS[j].Left := Round(D1);
        OutBufS[j].Right := Round(D2);
        Inc(j);
        Inc(remainder, step);
      end;
    end;

    for i := 0 to _KernelWidth-2 do
      TailStereo[i] := InBufS[i+s-_KernelWidth+1];
  End Else
  Begin
    TailStereoD := Tail;
    FillChar(DAS[0], Length(DAS)*16, 0);
    For i := 0 to _KernelWidth-2 do
    begin
      DAS[i] := TailStereoD[i];
      TailStereoD[i].Left := 0;
      TailStereoD[i].Right := 0;
    End;

    Step := _Input.Frequency;
    j := 0;
    If remainder < 0 then
      remainder := 0;

    While remainder < FOutSampleRate Do
    Begin
      m1 := Round(((FOutSampleRate - remainder)*LBS.Left +  remainder*InBufS[0].Left)/FOutSampleRate);
      m2 := Round(((FOutSampleRate - remainder)*LBS.Right +  remainder*InBufS[0].Right)/FOutSampleRate);
      for k := 0 to _KernelWidth-1 do
      Begin
        DAS[j+k].Left := DAS[j+k].Left + m1*Kernel[k]; //InBufS[i].Left*Kernel[k];
        DAS[j+k].Right := DAS[j+k].Right + m2*Kernel[k]; //InBufS[i].Right*Kernel[k];
      End;

      Inc(j);
      Inc(remainder, step);
    End;

    Dec(remainder, FOutSampleRate);
    For i := 0 to s - 2 do
    Begin
      While remainder < FOutSampleRate do
      Begin
        m1 := Round(((FOutSampleRate - remainder)*InBufS[i].Left +  remainder*InBufS[i+1].Left)/FOutSampleRate);
        m2 := Round(((FOutSampleRate - remainder)*InBufS[i].Right +  remainder*InBufS[i+1].Right)/FOutSampleRate);
        For k := 0 to _KernelWidth-1 do
        Begin
          DAS[j+k].Left := DAS[j+k].Left + m1*Kernel[k]; //InBufS[i].Left*Kernel[k];
          DAS[j+k].Right := DAS[j+k].Right + m2*Kernel[k]; //InBufS[i].Right*Kernel[k];
        End;

        Inc(j);
        Inc(remainder, step);
      End;

      Dec(remainder, FOutSampleRate);
    End;

    LBS := InBufS[s-1];
    For i := 0 to j-1 do
    begin
      OutBufS[i].Left := Round(DAS[i].Left);
      OutBufS[i].Right := Round(DAS[i].Right);
    End;

    For i := 0 to _KernelWidth-2 do
      TailStereoD[i] := DAS[i+j];
  End;

  Result := j shl 2;
End;

End.
