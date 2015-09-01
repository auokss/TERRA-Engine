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
    SampleBuffer:Array Of Single;
    BufferLength:Cardinal;

    // The echo is two tap. The delay is the number of samples from before the current offset
    Tap:Array[0..1] Of ALTap;

    Offset:Cardinal;

    // The panning gains for the two taps
    PanningGain:Array[0..1] Of AudioChannelGain;

    FeedGain:Single;

    Filter:AudioFilterState;

    Delay:Single;
    LRDelay:Single;

    Damping:Single;
    Feedback:Single;

    Spread:Single;

    Procedure Release(); Override;

    Function deviceUpdate(Target:TERRAAudioBuffer):Boolean; Override;
    Procedure Update(Target:TERRAAudioBuffer); Override;
    Procedure Process(Target:TERRAAudioBuffer; samplesToDo:Integer; samplesIn:PSingleArray; Var samplesOut:AudioEffectBuffer; numChannels:Cardinal); Override;

    Procedure SetParamf(param:Integer; Const val:Single); Override;
    Procedure getParamf(param:Integer; Out val:Single); Override;
  End;

Implementation
Uses TERRA_Math;

Procedure AudioEchoEffect.Release();
Begin
  SetLength(SampleBuffer, 0);
End;

Function AudioEchoEffect.deviceUpdate(Target:TERRAAudioBuffer):Boolean;
Var
  maxlen, i:Integer;
Begin
  // Use the next power of 2 for the buffer length, so the tap offsets can be
  // wrapped using a mask instead of a modulo
  maxlen := Trunc(AL_ECHO_MAX_DELAY * Target.Frequency) + 1;
  maxlen := maxlen + Trunc(AL_ECHO_MAX_LRDELAY * Target.Frequency) + 1;
  maxlen  := NextPowerOfTwo(maxlen);

  If (maxlen <> Self.BufferLength) Then
  Begin
    SetLength(SampleBuffer, maxlen);
    Self.BufferLength := maxlen;
  End;

  For I:=0 To Pred(BufferLength) Do
    Self.SampleBuffer[i] := 0.0;

  Result := True;
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

  Self.FeedGain := Self.Feedback;

  Self.Filter.setParams(ALfilterType_HighShelf, 1.0 - Self.Damping, LOWPASSFREQREF/frequency, 0.0);

  // First tap panning
  pandir.X := -lrpan;
  ComputeDirectionalGains(Target, pandir, gain, Self.PanningGain[0]);

  // Second tap panning
  pandir.X := +lrpan;
  ComputeDirectionalGains(Target, pandir, gain, Self.PanningGain[1]);
End;

Procedure AudioEchoEffect.Process(Target:TERRAAudioBuffer; samplesToDo:Integer; samplesIn:PSingleArray; Var samplesOut:AudioEffectBuffer; numChannels:Cardinal);
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
  mask := Self.BufferLength-1;
  tap1 := Self.Tap[0].delay;
  tap2 := Self.Tap[1].delay;
  offset := Self.Offset;

  Base := 0;
  While (Base<SamplesToDo) Do
  Begin
    td := IntMin(128, SamplesToDo - base);

    For I:=0 To Pred(Td) Do
    Begin
      // First tap
      temps[i][0] := Self.SampleBuffer[(offset-tap1) And mask];

      // Second tap
      temps[i][1] := Self.SampleBuffer[(offset-tap2) And mask];

      // Apply damping and feedback gain to the second tap, and mix in the new sample
      smp := Self.Filter.processSingle(temps[i, 1] + SamplesIn[i+base]);
      Self.SampleBuffer[offset And mask] := smp * Self.FeedGain;
      Inc(offset);
    End;

    For K:=0 To Pred(NumChannels) Do
    Begin
      gain := Self.PanningGain[0][k];

      If (Abs(gain) > GAIN_SILENCE_THRESHOLD) Then
      Begin
        For I:=0 To Pred(Td) Do
        Begin
          N := SamplesOut.Samples[k][ i + base];
          N := N + temps[i, 0] * gain;
          SamplesOut.Samples[k][ i + base] := N;
        End;
      End;

      gain := Self.PanningGain[1][k];
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

  Self.Offset := offset;
End;

Procedure AudioEchoEffect.SetParamf(param:Integer; Const val:Single);
Begin
  Case param Of
    AL_ECHO_DELAY:
      If (Val >= AL_ECHO_MIN_DELAY) And (val <= AL_ECHO_MAX_DELAY) Then
        Self.Delay := val;

    AL_ECHO_LRDELAY:
      If (val >= AL_ECHO_MIN_LRDELAY) And (val <= AL_ECHO_MAX_LRDELAY) Then
        Self.LRDelay := val;

    AL_ECHO_DAMPING:
      If (val >= AL_ECHO_MIN_DAMPING) And (val <= AL_ECHO_MAX_DAMPING) Then
        Self.Damping := val;

    AL_ECHO_FEEDBACK:
      If (val >= AL_ECHO_MIN_FEEDBACK) And (val <= AL_ECHO_MAX_FEEDBACK) Then
        Self.Feedback := val;

    AL_ECHO_SPREAD:
      If (val >= AL_ECHO_MIN_SPREAD) And (val <= AL_ECHO_MAX_SPREAD) Then
        Self.Spread := val;
  End;
End;


Procedure AudioEchoEffect.getParamf(param:Integer; Out val:Single);
Begin
  Case param Of
    AL_ECHO_DELAY:
      val := Self.Delay;

    AL_ECHO_LRDELAY:
      val := Self.LRDelay;

    AL_ECHO_DAMPING:
      val := Self.Damping;

    AL_ECHO_FEEDBACK:
      val := Self.Feedback;

    AL_ECHO_SPREAD:
      val := Self.Spread;

  Else
    Val := 0;
  End;
End;


End.
