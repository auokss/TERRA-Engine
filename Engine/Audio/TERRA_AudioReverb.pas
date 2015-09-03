//https://github.com/mono/opentk/blob/master/Source/OpenTK/Audio/OpenAL/AL/EffectsExtensionPresets.cs

Unit TERRA_AudioReverb;

Interface
{$I terra.inc}

Uses TERRA_Utils, TERRA_Vector3D, TERRA_AudioBuffer, TERRA_AudioPanning;

Const
  OUTPUT_CHANNELS  = 2;
  REVERB_BUFFERSIZE = 2048;

Type
  ALfilterType = (
    // EFX-style low-pass filter, specifying a gain and reference frequency.
    ALfilterType_HighShelf,
    // EFX-style high-pass filter, specifying a gain and reference frequency.
    ALfilterType_LowShelf
  );

  FilterState = Object
    x:Array[0..1] Of Single; // History of two last input samples
    y:Array[0..1] Of Single; // History of two last output samples
    a:Array[0..2] Of Single; // Transfer function coefficients "a"
    b:Array[0..2] Of Single; // Transfer function coefficients "b"

    Function Process(Const sample:Single):Single;
    Procedure SetParams(FilterType:ALfilterType; gain, freq_mult, bandwidth:Single);
    Procedure Clear();
  End;

  ReverbSettings = Record
    Density:Single;
    Diffusion:Single;
    Gain:Single;
    GainHF:Single;
    DecayTime:Single;
    DecayHFRatio:Single;
    ReflectionsGain:Single;
    ReflectionsDelay:Single;
    LateReverbGain:Single;
    LateReverbDelay:Single;
    AirAbsorptionGainHF:Single;
    RoomRolloffFactor:Single;
    DecayHFLimit:Boolean;

    GainLF:Single;
    DecayLFRatio:Single;
    ReflectionsPan:Vector3D;
    LateReverbPan:Vector3D;
    EchoTime:Single;
    EchoDepth:Single;
    ModulationTime:Single;
    ModulationDepth:Single;
    HFReference:Single;
    LFReference:Single;
  End;

  DelayLine = Record
    // The delay lines use sample lengths that are powers of 2 to allow the
    // use of bit-masking instead of a modulus for wrapping.
    Mask:Cardinal;
    Line:PSingle;
    Offset:Cardinal;
  End;

  Modulator = Record
    // Modulator delay line.
    Delay:DelayLine;

    // The vibrato time is tracked with an index over a modulus-wrapped range (in samples).
    Index:Cardinal;
    Range:Cardinal;

    // The depth of frequency change (also in samples) and its filter.
    Depth:Single;
    Coeff:Single;
    Filter:Single;
  End;

  AudioEarlyReflection = Record
        // Output gain for early reflections.
        Gain:Single;

        // Early reflections are done with 4 delay lines.
        Coeff:Array[0..3] Of Single;
        Delay:Array[0..3] Of DelayLine;
        Offset:Array[0..3] Of Integer;

        // The gain for each output channel based on 3D panning (only for the EAX path).
        PanGain:MixingAudioSample;
  End;


  AudioLateReverb = Record
        // Output gain for late reverb.
        Gain:Single;

        // Attenuation to compensate for the modal density and decay rate of
        // the late lines.
        DensityGain:Single;

        // The feed-back and feed-forward all-pass coefficient.
        ApFeedCoeff:Single;

        // Mixing matrix coefficient.
        MixCoeff:Single;

        // Late reverb has 4 parallel all-pass filters.
        ApCoeff:Array[0..3] Of Single;
        ApDelay:Array[0..3] Of DelayLine;
        ApOffset:Array[0..3] Of Integer;

        // In addition to 4 cyclical delay lines.
        Coeff:Array[0..3] Of Single;
        Delay:Array[0..3] Of DelayLine;
        Offset:Array[0..3] Of Integer;

        // The cyclical delay lines are 1-pole low-pass filtered.
        LpCoeff:Array[0..3] Of Single;
        LpSample:Array[0..3] Of Single;

        // The gain for each output channel based on 3D panning
        PanGain:MixingAudioSample;
  End;

  ReverbEcho = Record
        // Attenuation to compensate for the modal density and decay rate of
        // the echo line.
        DensityGain:Single;

        // Echo delay and all-pass lines.
        Delay:DelayLine;
        ApDelay:DelayLine;

        Coeff:Single;
        ApFeedCoeff:Single;
        ApCoeff:Single;

        Offset:Integer;
        ApOffset:Integer;

        // The echo line is 1-pole low-pass filtered.
        LpCoeff:Single;
        LpSample:Single;

        // Echo mixing coefficients.
        MixCoeff:Array[0..1] Of Single;
  End;

  AudioReverbEffect = Class(TERRAObject)
    Protected
      _settings:ReverbSettings;

      // All delay lines are allocated as a single buffer to reduce memory
      // fragmentation and management code.
      _SampleBuffer:Array Of Single;
      _TotalSamples:Cardinal;

      // Master effect filters
      _LpFilter:FilterState;
      _HpFilter:FilterState;

      _Mod:Modulator;

      // Initial effect delay.
      _Delay:DelayLine;

      // The tap points for the initial delay.  First tap goes to early reflections, the last to late reverb.
      _DelayTap:Array[0..1] Of Integer;

      _Early:AudioEarlyReflection;

      // Decorrelator delay line.
      _Decorrelator:DelayLine;

      // There are actually 4 decorrelator taps, but the first occurs at the initial sample.
      _DecoTap:Array[0..2] Of Cardinal;

      _Late:AudioLateReverb;

      _Echo:ReverbEcho;

      // The current read offset for all delay lines.
      _Offset:Integer;

      // Temporary storage used when processing, before deinterlacing.
      _ReverbSamples:Array[0..3] Of Single;
      _EarlySamples:Array[0..Pred(REVERB_BUFFERSIZE), 0..3] Of Single;

      Procedure AllocLines(frequency:Cardinal);

      Function EAXModulation(Const input:Single):Single;

      Function EarlyDelayLineOut(index:Cardinal):Single;
      Procedure EarlyReflection(Const input:Single; Out output:Single);

      Function LateAllPassInOut(index:Cardinal; Const input:Single):Single;
      Function LateDelayLineOut(index:Cardinal):Single;

      Function LateLowPassInOut(index:Cardinal; Const input:Single):Single;
      Procedure LateReverb(Const input:Single; Out output:Single);

      Procedure EAXEcho(Const input:Single; Out late:Single);
      Procedure EAXVerbPass(Const input:Single; Out early, late:Single);

      Procedure VerbPass(Const input:Single; Out output:Single);

      Procedure UpdateDelayLine(earlyDelay, lateDelay:Single; frequency:Cardinal);
      Procedure UpdateModulator(modTime, modDepth:Single; frequency:Cardinal);
      Procedure UpdateEarlyLines(reverbGain, earlyGain, lateDelay:Single);
      Procedure UpdateDecorrelator(density:Single; frequency:Cardinal);
      Procedure UpdateLateLines(reverbGain, lateGain, xMix, density, decayTime, diffusion, hfRatio, cw:Single; frequency:Cardinal);
      Procedure UpdateEchoLine(reverbGain, lateGain, echoTime, decayTime, diffusion, echoDepth, hfRatio, cw:Single; frequency:Cardinal);

      Procedure Update3DPanning(ReflectionsPan, LateReverbPan:PSingleArray; Gain:Single);

    Public
        Constructor Create(frequency:Cardinal);
        Procedure Release(); Override;

        Procedure Process(SamplesToDo:Integer; SamplesIn, SamplesOut:PSingleArray);
        Procedure Update(frequency:Cardinal);

        Procedure LoadPreset(Const environment:Integer; Const environmentSize, environmentDiffusion:Single; Const room, roomHF, roomLF:Integer;
                        Const decayTime, decayHFRatio, decayLFRatio:Single;
                        Const reflections:Integer; Const reflectionsDelay:Single; Const reflectionsPan:Vector3D;
                        Const reverb:Integer; Const reverbDelay:Single; Const reverbPan:Vector3D;
                        Const echoTime, echoDepth, modulationTime, modulationDepth, airAbsorptionHF:Single;
                        Const hfReference, lfReference, roomRolloffFactor:Single);

  End;

Implementation
Uses TERRA_Math;

Const
  F_2PI  = 6.28318530717958647692;
  FLT_EPSILON = 1.19209290E-07;

  SPEEDOFSOUNDMETRESPERSEC = 343.3;

  GAIN_SILENCE_THRESHOLD  = 0.00001;

// This is a user config option for modifying the overall output of the reverb effect.
  ReverbBoost = 1.0;

// Effect parameter ranges and defaults.
EAXREVERB_MIN_DENSITY                 = 0.0;
EAXREVERB_MAX_DENSITY                 = 1.0;
EAXREVERB_DEFAULT_DENSITY             = 1.0;

EAXREVERB_MIN_DIFFUSION               = 0.0;
EAXREVERB_MAX_DIFFUSION               = 1.0;
EAXREVERB_DEFAULT_DIFFUSION           = 1.0;

EAXREVERB_MIN_GAIN                    = 0.0;
EAXREVERB_MAX_GAIN                    = 1.0;
EAXREVERB_DEFAULT_GAIN                = 0.32;

EAXREVERB_MIN_GAINHF                  = 0.0;
EAXREVERB_MAX_GAINHF                  = 1.0;
EAXREVERB_DEFAULT_GAINHF              = 0.89;

EAXREVERB_MIN_GAINLF                  = 0.0;
EAXREVERB_MAX_GAINLF                  = 1.0;
EAXREVERB_DEFAULT_GAINLF              = 1.0;

EAXREVERB_MIN_DECAY_TIME              = 0.1;
EAXREVERB_MAX_DECAY_TIME              = 20.0;
EAXREVERB_DEFAULT_DECAY_TIME          = 1.49;

EAXREVERB_MIN_DECAY_HFRATIO           = 0.1;
EAXREVERB_MAX_DECAY_HFRATIO           = 2.0;
EAXREVERB_DEFAULT_DECAY_HFRATIO       = 0.83;

EAXREVERB_MIN_DECAY_LFRATIO           = 0.1;
EAXREVERB_MAX_DECAY_LFRATIO           = 2.0;
EAXREVERB_DEFAULT_DECAY_LFRATIO       = 1.0;

EAXREVERB_MIN_REFLECTIONS_GAIN        = 0.0;
EAXREVERB_MAX_REFLECTIONS_GAIN        = 3.16;
EAXREVERB_DEFAULT_REFLECTIONS_GAIN    = 0.05;

EAXREVERB_MIN_REFLECTIONS_DELAY       = 0.0;
EAXREVERB_MAX_REFLECTIONS_DELAY       = 0.3;
EAXREVERB_DEFAULT_REFLECTIONS_DELAY   = 0.007;

EAXREVERB_DEFAULT_REFLECTIONS_PAN_XYZ = 0.0;

EAXREVERB_MIN_LATE_REVERB_GAIN        = 0.0;
EAXREVERB_MAX_LATE_REVERB_GAIN        = 10.0;
EAXREVERB_DEFAULT_LATE_REVERB_GAIN    = 1.26;

EAXREVERB_MIN_LATE_REVERB_DELAY       = 0.0;
EAXREVERB_MAX_LATE_REVERB_DELAY       = 0.1;
EAXREVERB_DEFAULT_LATE_REVERB_DELAY   = 0.011;

EAXREVERB_DEFAULT_LATE_REVERB_PAN_XYZ = 0.0;

EAXREVERB_MIN_ECHO_TIME               = 0.075;
EAXREVERB_MAX_ECHO_TIME               = 0.25;
EAXREVERB_DEFAULT_ECHO_TIME           = 0.25;

EAXREVERB_MIN_ECHO_DEPTH              = 0.0;
EAXREVERB_MAX_ECHO_DEPTH              = 1.0;
EAXREVERB_DEFAULT_ECHO_DEPTH          = 0.0;

EAXREVERB_MIN_MODULATION_TIME         = 0.04;
EAXREVERB_MAX_MODULATION_TIME         = 4.0;
EAXREVERB_DEFAULT_MODULATION_TIME     = 0.25;

EAXREVERB_MIN_MODULATION_DEPTH        = 0.0;
EAXREVERB_MAX_MODULATION_DEPTH        = 1.0;
EAXREVERB_DEFAULT_MODULATION_DEPTH    = 0.0;

EAXREVERB_MIN_AIR_ABSORPTION_GAINHF   = 0.892;
EAXREVERB_MAX_AIR_ABSORPTION_GAINHF   = 1.0;
EAXREVERB_DEFAULT_AIR_ABSORPTION_GAINHF = 0.994;

EAXREVERB_MIN_HFREFERENCE             = 1000.0;
EAXREVERB_MAX_HFREFERENCE             = 20000.0;
EAXREVERB_DEFAULT_HFREFERENCE         = 5000.0;

EAXREVERB_MIN_LFREFERENCE             = 20.0;
EAXREVERB_MAX_LFREFERENCE             = 1000.0;
EAXREVERB_DEFAULT_LFREFERENCE         = 250.0;

EAXREVERB_MIN_ROOM_ROLLOFF_FACTOR     = 0.0;
EAXREVERB_MAX_ROOM_ROLLOFF_FACTOR     = 10.0;
EAXREVERB_DEFAULT_ROOM_ROLLOFF_FACTOR = 0.0;

EAXREVERB_MIN_DECAY_HFLIMIT           = False;
EAXREVERB_MAX_DECAY_HFLIMIT           = True;
EAXREVERB_DEFAULT_DECAY_HFLIMIT       = True;


(* This coefficient is used to define the maximum frequency range controlled
 * by the modulation depth.  The current value of 0.1 will allow it to swing
 * from 0.9x to 1.1x.  This value must be below 1.  At 1 it will cause the
 * sampler to stall on the downswing, and above 1 it will cause it to sample
 * backwards.
 *)
  MODULATION_DEPTH_COEFF = 0.1;

(* A filter is used to avoid the terrible distortion caused by changing
 * modulation time and/or depth.  To be consistent across different sample
 * rates, the coefficient must be raised to a constant divided by the sample
 * rate:  coeff^(constant / rate).
 *)
  MODULATION_FILTER_COEFF = 0.048;
  MODULATION_FILTER_CONST = 100000.0;

// When diffusion is above 0, an all-pass filter is used to take the edge off
// the echo effect.  It uses the following line length (in seconds).
  ECHO_ALLPASS_LENGTH = 0.0133;

// Input into the late reverb is decorrelated between four channels.  Their
// timings are dependent on a fraction and multiplier.  See the
// UpdateDecorrelator() routine for the calculations involved.
  DECO_FRACTION = 0.15;
  DECO_MULTIPLIER = 2.0;

// All delay line lengths are specified in seconds.

// The lengths of the early delay lines.
  EARLY_LINE_LENGTH:Array[0..3] Of Single  = (0.0015, 0.0045, 0.0135, 0.0405);

// The lengths of the late all-pass delay lines.
  ALLPASS_LINE_LENGTH:Array[0..3] Of Single = (0.0151, 0.0167, 0.0183, 0.0200);

// The lengths of the late cyclical delay lines.
  LATE_LINE_LENGTH:Array[0..3] Of Single = (0.0211, 0.0311, 0.0461, 0.0680);

// The late cyclical delay lines have a variable length dependent on the
// effect's density parameter (inverted for some reason) and this multiplier.
  LATE_LINE_MULTIPLIER = 4.0;

Function eaxDbToAmp(Const eaxDb:Single):Single;
Begin
  Result := Power(10.0,  eaxDb / 2000.0);
End;

Function FilterState.Process(Const sample:Single):Single;
Begin
  Result := b[0] * sample + b[1] * x[0] + b[2] * x[1] - a[1] * y[0] - a[2] * y[1];
  x[1] := x[0];
  x[0] := sample;
  y[1] := y[0];
  y[0] := Result;
End;

Procedure FilterState.Clear();
Begin
  x[0] := 0.0;
  x[1] := 0.0;
  y[0] := 0.0;
  y[1] := 0.0;
End;

Procedure FilterState.SetParams(FilterType:ALfilterType; gain, freq_mult, bandwidth:Single);
Var
  alpha, w0:Single;
Begin
  // Limit gain to -100dB
  gain := FloatMax(gain, 0.00001);

  w0 := F_2PI * freq_mult;

  // Calculate filter coefficients depending on filter type
  Case (FilterType) Of
    ALfilterType_HighShelf:
      Begin
        alpha := Sin(w0)/2.0 * Sqrt((gain + 1.0/gain)*(1.0/0.75 - 1.0) + 2.0);
        b[0] :=       gain*((gain+1.0) + (gain-1.0)*cos(w0) + 2.0*sqrt(gain)*alpha);
        b[1] := -2.0*gain*((gain-1.0) + (gain+1.0)*cos(w0)                         );
        b[2] :=       gain*((gain+1.0) + (gain-1.0)*cos(w0) - 2.0*sqrt(gain)*alpha);
        a[0] :=             (gain+1.0) - (gain-1.0)*cos(w0) + 2.0*sqrt(gain)*alpha;
        a[1] :=  2.0*     ((gain-1.0) - (gain+1.0)*cos(w0)                         );
        a[2] :=             (gain+1.0) - (gain-1.0)*cos(w0) - 2.0*sqrt(gain)*alpha;
      End;

    ALfilterType_LowShelf:
      Begin
        alpha := sin(w0)/2.0*sqrt((gain + 1.0/gain)*(1.0/0.75 - 1.0) + 2.0);
        b[0] :=       gain*((gain+1.0) - (gain-1.0)*cos(w0) + 2.0*sqrt(gain)*alpha);
        b[1] :=  2.0*gain*((gain-1.0) - (gain+1.0)*cos(w0)                         );
        b[2] :=       gain*((gain+1.0) - (gain-1.0)*cos(w0) - 2.0*sqrt(gain)*alpha);
        a[0] :=             (gain+1.0) + (gain-1.0)*cos(w0) + 2.0*sqrt(gain)*alpha;
        a[1] := -2.0*     ((gain-1.0) + (gain+1.0)*cos(w0)                         );
        a[2] :=             (gain+1.0) + (gain-1.0)*cos(w0) - 2.0*sqrt(gain)*alpha;
      End;
  End;

  b[2] := b[2] / a[0];
  b[1] := b[1] / a[0];
  b[0] := b[0] / a[0];
  a[2] := a[2] / a[0];
  a[1] := a[1] / a[0];
  a[0] := a[0] / a[0];
End;

Procedure CalcMatrixCoeffs(Const diffusion:Single; Out x, y:Single);
Var
  n, t:Single;
Begin
  // The matrix is of order 4, so n is sqrt (4 - 1).
  N := sqrt(3.0);
  t := diffusion * Arctan(n);

  // Calculate the first mixing matrix coefficient.
  x := cos(t);

  // Calculate the second mixing matrix coefficient.
  y := sin(t) / n;
End;

// Calculate the length of a delay line and store its mask and offset.
Function CalcLineLength(Const length:Single; offset:Cardinal; frequency:Cardinal; Var Delay:DelayLine):Integer;
Begin
  // All line lengths are powers of 2, calculated from their lengths, with an additional sample in case of rounding errors.
  Result := NextPowerOfTwo(Trunc(length * frequency) + 1);

  // All lines share a single sample buffer.
  Delay.Mask := Result - 1;
  Delay.Offset := offset;
End;

// Given the allocated sample buffer, this function updates each delay line offset.
Procedure RealizeLineOffset(sampleBuffer:PSingleArray; Var Delay:DelayLine);
Begin
  Delay.Line := @(sampleBuffer[Delay.Offset]);
End;

{ AudioReverbEffect }
Constructor AudioReverbEffect.Create(frequency: Cardinal);
Begin

End;

Procedure AudioReverbEffect.AllocLines(frequency: Cardinal);
Var
  totalSamples, index:Integer;
  length:Single;
Begin
  // All delay line lengths are calculated to accomodate the full range of lengths given their respective paramters.
  totalSamples := 0;

  // The modulator's line length is calculated from the maximum modulation time and depth coefficient, and halfed for the low-to-high frequency swing.
  // An additional sample is added to keep it stable when there is no modulation.

  length := (EAXREVERB_MAX_MODULATION_TIME*MODULATION_DEPTH_COEFF * 0.5) + (1.0 / frequency);
  Inc(totalSamples, CalcLineLength(length, totalSamples, Frequency, Self._Mod.Delay));

  // The initial delay is the sum of the reflections and late reverb delays.
  length := EAXREVERB_MAX_REFLECTIONS_DELAY + EAXREVERB_MAX_LATE_REVERB_DELAY;
  Inc(totalSamples, CalcLineLength(length, totalSamples, Frequency, Self._Delay));

  // The early reflection lines.
  For Index := 0 To 3 Do
    Inc(totalSamples, CalcLineLength(EARLY_LINE_LENGTH[index], totalSamples, frequency, Self._Early.Delay[index]));

  // The decorrelator line is calculated from the lowest reverb density (a parameter value of 1).
  length := (DECO_FRACTION * DECO_MULTIPLIER * DECO_MULTIPLIER) * LATE_LINE_LENGTH[0] * (1.0 + LATE_LINE_MULTIPLIER);
  Inc(totalSamples, CalcLineLength(length, totalSamples, frequency, _Decorrelator));

  // The late all-pass lines.
  For Index := 0 To 3 Do
    Inc(totalSamples, CalcLineLength(ALLPASS_LINE_LENGTH[index], totalSamples, frequency, _Late.ApDelay[index]));

  // The late delay lines are calculated from the lowest reverb density.
  For Index := 0 To 3 Do
  Begin
    length := LATE_LINE_LENGTH[index] * (1.0 + LATE_LINE_MULTIPLIER);
    Inc(totalSamples, CalcLineLength(length, totalSamples, frequency, _Late.Delay[index]));
  End;

  // The echo all-pass and delay lines.
  Inc(totalSamples, CalcLineLength(ECHO_ALLPASS_LENGTH, totalSamples, frequency, _Echo.ApDelay));
  Inc(totalSamples, CalcLineLength(EAXREVERB_MAX_ECHO_TIME, totalSamples, frequency, _Echo.Delay));

  SetLength(_SampleBuffer, totalSamples);
  _TotalSamples := totalSamples;

  // Update all delays to reflect the new sample buffer.
  RealizeLineOffset(@_SampleBuffer[0], _Delay);
  RealizeLineOffset(@_SampleBuffer[0], _Decorrelator);
  For Index := 0 To 3 Do
  Begin
    RealizeLineOffset(@_SampleBuffer[0], _Early.Delay[index]);
    RealizeLineOffset(@_SampleBuffer[0], _Late.ApDelay[index]);
    RealizeLineOffset(@_SampleBuffer[0], _Late.Delay[index]);
  End;
  RealizeLineOffset(@_SampleBuffer[0], _Mod.Delay);
  RealizeLineOffset(@_SampleBuffer[0], _Echo.ApDelay);
  RealizeLineOffset(@_SampleBuffer[0], _Echo.Delay);

  // Clear the sample buffer.
  For Index := 0 To Pred(TotalSamples) Do
    _SampleBuffer[index] := 0.0;
End;

Procedure AudioReverbEffect.Release;
Begin
  SetLength(_SampleBuffer, 0);
End;

Procedure AudioReverbEffect.LoadPreset(Const environment:Integer; Const environmentSize, environmentDiffusion:Single; Const room, roomHF, roomLF:Integer;
                        Const decayTime, decayHFRatio, decayLFRatio:Single;
                        Const reflections:Integer; Const reflectionsDelay:Single; Const reflectionsPan:Vector3D;
                        Const reverb:Integer; Const reverbDelay:Single; Const reverbPan:Vector3D;
                        Const echoTime, echoDepth, modulationTime, modulationDepth, airAbsorptionHF:Single;
                        Const hfReference, lfReference, roomRolloffFactor:Single);
Begin
  _Settings.Density := 1.0; // todo, currently default
  _Settings.Diffusion := EnvironmentDiffusion;
  _Settings.Gain :=  eaxDbToAmp(room); //0.32f;
  _Settings.GainHF := eaxDbToAmp(roomHF); //0.89f;
  _Settings.GainLF := eaxDbToAmp(roomLF); // 1.0f;
  _Settings.DecayTime := decayTime;
  _Settings.DecayHFRatio := decayHFRatio;
  _Settings.DecayLFRatio := decayLFRatio;
  _Settings.ReflectionsGain := eaxDbToAmp(reflections); // 0.05f;
  _Settings.ReflectionsDelay := reflectionsDelay;
  _Settings.ReflectionsPan := reflectionsPan;
  _Settings.LateReverbGain := eaxDbToAmp(reverb); //1.26f;
  _Settings.LateReverbDelay := reverbDelay;
  _Settings.LateReverbPan := reverbPan;
  _Settings.EchoTime := echoTime;
  _Settings.EchoDepth := echoDepth;
  _Settings.ModulationTime := modulationTime;
  _Settings.ModulationDepth := modulationDepth;
  _Settings.AirAbsorptionGainHF := eaxDbToAmp(airAbsorptionHF); //0.995f;
  _Settings.HFReference := hfReference;
  _Settings.LFReference := lfReference;
  _Settings.RoomRolloffFactor := roomRolloffFactor;
  _Settings.DecayHFLimit := True;
End;

Procedure AudioReverbEffect.Update(frequency: Cardinal);
Var
  lfscale, hfscale, hfRatio:Single;
  cw, x, y:Single;
Begin
  // Calculate the master low-pass filter (from the master effect HF gain).
  hfscale := _settings.HFReference / frequency;
  _LpFilter.setParams(ALfilterType_HighShelf, _settings.GainHF, hfscale, 0.0);

  lfscale := _settings.LFReference / frequency;
  _HpFilter.setParams(ALfilterType_LowShelf, _settings.GainLF, lfscale, 0.0);

  // Update the modulator line.
  UpdateModulator(_settings.ModulationTime, _settings.ModulationDepth, frequency);

  // Update the initial effect delay.
  UpdateDelayLine(_settings.ReflectionsDelay, _settings.LateReverbDelay, frequency);

  // Update the early lines.
  UpdateEarlyLines(_settings.Gain, _settings.ReflectionsGain, _settings.LateReverbDelay);

  // Update the decorrelator.
  UpdateDecorrelator(_settings.Density, frequency);

  // Get the mixing matrix coefficients (x and y).
  CalcMatrixCoeffs(_settings.Diffusion, x, y);

  // Then divide x into y to simplify the matrix calculation.
  _Late.MixCoeff := y / x;

  // If the HF limit parameter is flagged, calculate an appropriate limit based on the air absorption parameter.
  hfRatio := _settings.DecayHFRatio;

  If (_settings.DecayHFLimit) And (_settings.AirAbsorptionGainHF < 1.0) Then
    hfRatio := CalcLimitedHfRatio(hfRatio, _settings.AirAbsorptionGainHF, _settings.DecayTime);

  cw := Cos(F_2PI * hfscale);
  // Update the late lines.
  UpdateLateLines(_settings.Gain, _settings.LateReverbGain, x, _settings.Density, _settings.DecayTime, _settings.Diffusion, hfRatio, cw, frequency);

  // Update the echo line.
  UpdateEchoLine(_settings.Gain, _settings.LateReverbGain, _settings.EchoTime, _settings.DecayTime, _settings.Diffusion, _settings.EchoDepth, hfRatio, cw, frequency);

  // Update early and late 3D panning.
  Update3DPanning(_settings.ReflectionsPan, _settings.LateReverbPan, ReverbBoost);
End;

Procedure AudioReverbEffect.Process(SamplesToDo: Integer; SamplesIn, SamplesOut: PSingleArray);
Begin
 s
End;



function AudioReverbEffect.EarlyDelayLineOut(index: Cardinal): Single;
begin

end;

procedure AudioReverbEffect.EarlyReflection(const input: Single;
  out output: Single);
begin

end;

procedure AudioReverbEffect.EAXEcho(const input: Single; out late: Single);
begin

end;

function AudioReverbEffect.EAXModulation(const input: Single): Single;
begin

end;

procedure AudioReverbEffect.EAXVerbPass(const input: Single; out early,
  late: Single);
begin

end;

function AudioReverbEffect.LateAllPassInOut(index: Cardinal;
  const input: Single): Single;
begin

end;

function AudioReverbEffect.LateDelayLineOut(index: Cardinal): Single;
begin

end;

function AudioReverbEffect.LateLowPassInOut(index: Cardinal;
  const input: Single): Single;
begin

end;

procedure AudioReverbEffect.LateReverb(const input: Single;
  out output: Single);
begin

end;


procedure AudioReverbEffect.Update3DPanning(ReflectionsPan,
  LateReverbPan: PSingleArray; Gain: Single);
begin

end;

procedure AudioReverbEffect.UpdateDecorrelator(density: Single;
  frequency: Cardinal);
begin

end;

procedure AudioReverbEffect.UpdateDelayLine(earlyDelay, lateDelay: Single;
  frequency: Cardinal);
begin

end;

procedure AudioReverbEffect.UpdateEarlyLines(reverbGain, earlyGain,
  lateDelay: Single);
begin

end;

procedure AudioReverbEffect.UpdateEchoLine(reverbGain, lateGain, echoTime,
  decayTime, diffusion, echoDepth, hfRatio, cw: Single;
  frequency: Cardinal);
begin

end;

procedure AudioReverbEffect.UpdateLateLines(reverbGain, lateGain, xMix,
  density, decayTime, diffusion, hfRatio, cw: Single; frequency: Cardinal);
begin

end;

procedure AudioReverbEffect.UpdateModulator(modTime, modDepth: Single;
  frequency: Cardinal);
begin

end;

procedure AudioReverbEffect.VerbPass(const input: Single;
  out output: Single);
begin

end;

End.
