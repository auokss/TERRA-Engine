Unit TERRA_AudioEcho;

Interface
Uses TERRA_Utils, TERRA_AudioFilter, TERRA_AudioBuffer, TERRA_AudioPanning, TERRA_Vector3D;

Const
  // Echo effect parameters
(*  AL_ECHO_DELAY                            = $0001;
  AL_ECHO_LRDELAY                          = $0002;
  AL_ECHO_DAMPING                          = $0003;
  AL_ECHO_FEEDBACK                         = $0004;
  AL_ECHO_SPREAD                           = $0005;*)

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

  AudioEchoEffect = Class(AudioHighShelfFilter)
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

      Procedure SetDamping(const Value: Single);
      Procedure SetDelay(const Value: Single);
      Procedure SetFeedback(const Value: Single);
      Procedure SetLRDelay(const Value: Single);
      Procedure SetSpread(const Value: Single);
      
    Public
      Function Initialize(Frequency:Cardinal):Boolean; Override;
      Procedure Release(); Override;

      Procedure Update(); Override;
      Procedure Process(samplesToDo:Integer; samplesIn:PSingleArray; Var samplesOut:AudioEffectBuffer); Override;

      Property Delay:Single Read _Delay Write SetDelay;
      Property LRDelay:Single Read _LRDelay Write SetLRDelay;

      Property Spread:Single Read _Spread Write SetSpread;
      Property Damping:Single Read _Damping Write SetDamping;

      Property Feedback:Single Read _Feedback Write SetFeedback;
  End;

Implementation
Uses TERRA_Math;

Function AudioEchoEffect.Initialize(Frequency:Cardinal):Boolean;
Var
  maxlen, i:Integer;
Begin
  Inherited Initialize(Frequency);

  Self.Delay    := AL_ECHO_DEFAULT_DELAY;
  Self.LRDelay  := AL_ECHO_DEFAULT_LRDELAY;
  Self.Damping  := AL_ECHO_DEFAULT_DAMPING;
  Self.Feedback := AL_ECHO_DEFAULT_FEEDBACK;
  Self.Spread   := AL_ECHO_DEFAULT_SPREAD;

  // Use the next power of 2 for the buffer length, so the tap offsets can be
  // wrapped using a mask instead of a modulo
  maxlen := Trunc(AL_ECHO_MAX_DELAY * _TargetFrequency) + 1;
  maxlen := maxlen + Trunc(AL_ECHO_MAX_LRDELAY * _TargetFrequency) + 1;
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

Procedure AudioEchoEffect.update();
Var
  pandir:Vector3D;
  lrpan:Single;
Begin
  pandir := VectorZero;

  Tap[0].delay := Trunc(Self.Delay * _TargetFrequency) + 1;
  Tap[1].delay := Trunc(Self.LRDelay * _TargetFrequency) + Tap[0].delay;

  lrpan := Self.Spread;

  Self._FeedGain := Self.Feedback;

  Self.setParams(1.0 - Self.Damping, LOWPASSFREQREF/_TargetFrequency, 0.0);

  // First tap panning
  pandir.X := -lrpan;
  ComputeDirectionalGains(pandir, gain, _PanningGain[0]);

  // Second tap panning
  pandir.X := +lrpan;
  ComputeDirectionalGains(pandir, gain, _PanningGain[1]);
End;

Procedure AudioEchoEffect.Process(samplesToDo:Integer; samplesIn:PSingleArray; Var samplesOut:AudioEffectBuffer);
Var
  mask:Cardinal;
  tap1:Cardinal;
  tap2:Cardinal;
  offset:Cardinal;
  smp, N:Single;
  KK:Cardinal;
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
      KK := (offset-tap1) And mask;
      temps[i][0] := _SampleBuffer[KK];

      // Second tap
      KK := (offset-tap2) And mask;
      temps[i][1] := _SampleBuffer[KK];

      // Apply damping and feedback gain to the second tap, and mix in the new sample
      smp := Self.processSingle(temps[I, 1] + SamplesIn[I + Base]);
      _SampleBuffer[offset And mask] := smp * _FeedGain;
      Inc(offset);
    End;

    For K:=0 To Pred(MAX_OUTPUT_CHANNELS) Do
    Begin
      gain := _PanningGain[0][k];

      If (Abs(gain) > GAIN_SILENCE_THRESHOLD) Then
      Begin
        For I:=0 To Pred(Td) Do
        Begin
          N := SamplesOut.Channels[k].Samples[ i + base];
          N := N + temps[i, 0] * gain;
          SamplesOut.Channels[k].Samples[ i + base] := N;
        End;
      End;

      gain := _PanningGain[1][k];
      If (Abs(gain) > GAIN_SILENCE_THRESHOLD) Then
      Begin
        For I:=0 To Pred(Td) Do
        Begin
          N := SamplesOut.Channels[k].Samples[i + base];
          N := N + temps[i, 1] * gain;
          SamplesOut.Channels[k].Samples[i + base] := N;
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
