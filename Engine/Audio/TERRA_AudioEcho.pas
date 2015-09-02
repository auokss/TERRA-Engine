Unit TERRA_AudioEcho;

Interface
Uses TERRA_Utils, TERRA_AudioFilter, TERRA_AudioBuffer, TERRA_AudioPanning, TERRA_Vector3D;

Const
  // Echo effect parameters
  AL_ECHO_DELAY                            = $0001;
  AL_ECHO_LRDELAY                          = $0002;
  AL_ECHO_DAMPING                          = $0003;
  AL_ECHO_FEEDBACK                         = $0004;
  AL_ECHO_SPREAD                           = $0005;

  AL_ECHO_MIN_DELAY                        = 0.0;
  AL_ECHO_MAX_DELAY                        = 0.207;
  AL_ECHO_DEFAULT_DELAY                    = 0.1;

  AL_ECHO_MIN_LRDELAY                      = 0.0;
  AL_ECHO_MAX_LRDELAY                      = 0.404;
  AL_ECHO_DEFAULT_LRDELAY                  = 0.1;

  AL_ECHO_MIN_DAMPING                      = 0.0;
  AL_ECHO_MAX_DAMPING                      = 0.99;
  AL_ECHO_DEFAULT_DAMPING                  = 0.5;

  AL_ECHO_MIN_FEEDBACK                     = 0.0;
  AL_ECHO_MAX_FEEDBACK                     = 1.0;
  AL_ECHO_DEFAULT_FEEDBACK                 = 0.5;

  AL_ECHO_MIN_SPREAD                       = -1.0;
  AL_ECHO_MAX_SPREAD                       = 1.0;
  AL_ECHO_DEFAULT_SPREAD                   = -1.0;

Type
  ALTap = Record
    Delay:Cardinal;
  End;

  AudioEchoEffect = Class(AudioFilter)
  private
    procedure SetDamping(const Value: Single);
    procedure SetDelay(const Value: Single);
    procedure SetFeedback(const Value: Single);
    procedure SetLRDelay(const Value: Single);
    procedure SetSpread(const Value: Single);
    Protected
      _SampleBuffer:Array Of Single;
      _BufferLength:Cardinal;

      // The echo is two tap. The delay is the number of samples from before the current offset
      Tap:Array[0..1] Of ALTap;

      _Offset:Cardinal;

      // The panning gains for the two taps
      _PanningGain:Array[0..1] Of AudioChannelGain;

      _FeedGain:Single;

      _Delay:Single;
      _LRDelay:Single;

      _Damping:Single;
      _Feedback:Single;

      _Spread:Single;

    Public
      Function Initialize(Target:TERRAAudioBuffer):Boolean; Override;
      Procedure Release(); Override;

      Procedure Update(Target:TERRAAudioBuffer); Override;
      Procedure Process(samplesToDo:Integer; samplesIn:PSingleArray; Var samplesOut:AudioEffectBuffer; numChannels:Cardinal); Override;

      Property Delay:Single Read _Delay Write SetDelay;
      Property LRDelay:Single Read _LRDelay Write SetLRDelay;

      Property Spread:Single Read _Spread Write SetSpread;
      Property Damping:Single Read _Damping Write SetDamping;

      Property Feedback:Single Read _Feedback Write SetFeedback;
  End;

Implementation
Uses TERRA_Math;

Function AudioEchoEffect.Initialize(Target:TERRAAudioBuffer):Boolean;
Var
  maxlen, i:Integer;
Begin
  // Use the next power of 2 for the buffer length, so the tap offsets can be
  // wrapped using a mask instead of a modulo
  maxlen := Trunc(AL_ECHO_MAX_DELAY * Target.Frequency) + 1;
  maxlen := maxlen + Trunc(AL_ECHO_MAX_LRDELAY * Target.Frequency) + 1;
  maxlen  := NextPowerOfTwo(maxlen);

  SetLength(_SampleBuffer, maxlen);
  _BufferLength := maxlen;

  For I:=0 To Pred(_BufferLength) Do
    _SampleBuffer[i] := 0.0;

  Result := True;
End;

Procedure AudioEchoEffect.Release();
Begin
  SetLength(_SampleBuffer, 0);
End;

Procedure AudioEchoEffect.update(Target:TERRAAudioBuffer);
Var
  pandir:Vector3D;
  frequency:Cardinal;
  lrpan, Gain:Single;
Begin
  pandir := VectorZero;

  frequency := Target.Frequency;
  gain := Self.Gain;

  Tap[0].delay := Trunc(Self.Delay * frequency) + 1;
  Tap[1].delay := Trunc(Self.LRDelay * frequency);
  Tap[1].delay := Tap[1].delay + Tap[0].delay;

  lrpan := Self.Spread;

  Self._FeedGain := Self.Feedback;

  Self.setParams(ALfilterType_HighShelf, 1.0 - Self.Damping, LOWPASSFREQREF/frequency, 0.0);

  // First tap panning
  pandir.X := -lrpan;
  ComputeDirectionalGains(Target, pandir, gain, _PanningGain[0]);

  // Second tap panning
  pandir.X := +lrpan;
  ComputeDirectionalGains(Target, pandir, gain, _PanningGain[1]);
End;

Procedure AudioEchoEffect.Process(samplesToDo:Integer; samplesIn:PSingleArray; Var samplesOut:AudioEffectBuffer; numChannels:Cardinal);
Var
  mask:Cardinal;
  tap1:Cardinal;
  tap2:Cardinal;
  offset:Cardinal;
  smp, N:Single;
  base, i, k, td:Integer;
  temps:Array[0..127, 0..1] Of Single;
  gain:Single;
Begin
  mask := _BufferLength-1;
  tap1 := Self.Tap[0].delay;
  tap2 := Self.Tap[1].delay;
  offset := _Offset;

  Base := 0;
  While (Base<SamplesToDo) Do
  Begin
    td := IntMin(128, SamplesToDo - base);

    For I:=0 To Pred(Td) Do
    Begin
      // First tap
      temps[i][0] := _SampleBuffer[(offset-tap1) And mask];

      // Second tap
      temps[i][1] := _SampleBuffer[(offset-tap2) And mask];

      // Apply damping and feedback gain to the second tap, and mix in the new sample
      smp := Self.processSingle(temps[i, 1] + SamplesIn[i+base]);
      _SampleBuffer[offset And mask] := smp * _FeedGain;
      Inc(offset);
    End;

    For K:=0 To Pred(NumChannels) Do
    Begin
      gain := _PanningGain[0][k];

      If (Abs(gain) > GAIN_SILENCE_THRESHOLD) Then
      Begin
        For I:=0 To Pred(Td) Do
        Begin
          N := SamplesOut.Samples[k][ i + base];
          N := N + temps[i, 0] * gain;
          SamplesOut.Samples[k][ i + base] := N;
        End;
      End;

      gain := _PanningGain[1][k];
      If (Abs(gain) > GAIN_SILENCE_THRESHOLD) Then
      Begin
        For I:=0 To Pred(Td) Do
        Begin
          N := SamplesOut.Samples[k][i + base];
          N := N + temps[i, 1] * gain;
          SamplesOut.Samples[k][i + base] := N;
        End;

      End;
    End;

    Inc(base, td);
  End;

  _Offset := offset;
End;

Procedure AudioEchoEffect.SetDamping(const Value: Single);
Begin
  If (value >= AL_ECHO_MIN_DAMPING) And (value <= AL_ECHO_MAX_DAMPING) Then
    _Damping := Value;
End;

procedure AudioEchoEffect.SetDelay(const Value: Single);
Begin
  If (Value >= AL_ECHO_MIN_DELAY) And (Value <= AL_ECHO_MAX_DELAY) Then
    _Delay := Value;
End;

Procedure AudioEchoEffect.SetLRDelay(const Value: Single);
Begin
  If (Value >= AL_ECHO_MIN_LRDELAY) And (Value <= AL_ECHO_MAX_LRDELAY) Then
    _LRDelay := Value;
End;

Procedure AudioEchoEffect.SetFeedback(const Value: Single);
Begin
  If (Value >= AL_ECHO_MIN_FEEDBACK) And (Value <= AL_ECHO_MAX_FEEDBACK) Then
    _Feedback := Value;
End;

Procedure AudioEchoEffect.SetSpread(const Value: Single);
Begin
  If (Value >= AL_ECHO_MIN_SPREAD) And (Value <= AL_ECHO_MAX_SPREAD) Then
    _Spread := Value;
End;

End.
