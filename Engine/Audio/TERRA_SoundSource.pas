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
 * TERRA_SoundSource
 * Implements a positional sound source
 ***********************************************************************************************************************
}
Unit TERRA_SoundSource;

{$I terra.inc}

Interface
Uses {$IFDEF USEDEBUGUNIT}TERRA_Debug,{$ENDIF}
  TERRA_Utils, TERRA_Math, TERRA_Vector3D, TERRA_Sound,
  TERRA_OS, TERRA_Resource, TERRA_AudioBuffer;

Type
  SoundSource = Class;

  SoundSourceCallback = Procedure(MySource:SoundSource) Of Object;

  SoundSourceMode = (
    soundSource_Static,
    soundSource_Dynamic
  );

  SoundSourceStatus = (
    soundSource_Playing,
    soundSource_Finished,
    soundSource_Paused
  );

  SoundSource = Class(TERRAObject)
    Protected
      _Mode:SoundSourceMode;
      _Status:SoundSourceStatus;

      _Buffer:AudioBuffer;
      _CurrentSample:Cardinal;

      _Pitch:Single;
      _Volume:Single;
      _Loop:Boolean;

      _Position:Vector3D;
      _Velocity:Vector3D;

      _Callback:SoundSourceCallback;

      Procedure SetPitch(Value:Single);
      Procedure SetVolume(Value:Single);
      Procedure SetLoop(Value:Boolean);
      Procedure SetPosition(Position:Vector3D);
      Procedure SetVelocity(Velocity:Vector3D);

      Procedure RequestMoreSamples(); Virtual;

    Public
      Constructor Create(Mode:SoundSourceMode);
      Procedure Release; Override;

      Procedure SetCallback(Callback:SoundSourceCallback);

      Procedure RenderSamples(Dest:AudioBuffer); Virtual;

      Property Status:SoundSourceStatus Read _Status;

      Property Pitch:Single Read _Pitch Write SetPitch;
      Property Volume:Single Read _Volume Write SetVolume;
      Property Loop:Boolean Read _Loop Write SetLoop;

      Property Position:Vector3D Read _Position Write SetPosition;
      Property Velocity:Vector3D Read _Velocity Write SetVelocity;
  End;

  ResourceSoundSource = Class(SoundSource)
    Protected
      _Sound:Sound;

    Public
      Constructor Create(Mode:SoundSourceMode; MySound:Sound);
      Procedure Release; Override;

      Procedure RenderSamples(Dest:AudioBuffer); Override;

      Property Sound:TERRA_Sound.Sound Read _Sound;
  End;

Implementation
Uses TERRA_GraphicsManager, TERRA_SoundManager, TERRA_Log;

{ SoundSource }
Constructor SoundSource.Create(Mode:SoundSourceMode);
Begin
  _Volume := 1.0;
  _Pitch := 1.0;

  _Position := VectorZero; //GraphicsManager.Instance().MainViewport.Camera.Position;
  _Velocity := VectorZero;
  _Loop := False;

  _Status := soundSource_Finished;
  _Mode := Mode;
End;

Procedure SoundSource.SetPitch(Value: Single);
Begin
  If (Value=_Pitch) Then
    Exit;

  _Pitch := Value;
End;

Procedure SoundSource.SetVolume(Value:Single);
Begin
  If (_Volume=Value) Then
    Exit;

  _Volume := Value;
End;

Procedure SoundSource.SetLoop(Value:Boolean);
Begin
  _Loop := Value;
End;

Procedure SoundSource.SetPosition(Position: Vector3D);
Begin
  _Position := Position;
End;

Procedure SoundSource.SetVelocity(Velocity: Vector3D);
Begin
  _Velocity := Velocity;
End;

Procedure SoundSource.SetCallback(Callback: SoundSourceCallback);
Begin
  _Callback := Callback;
End;

Procedure SoundSource.Release;
Begin
  If Assigned(_Callback) Then
  Begin
    _Callback(Self);
    _Callback := Nil;
  End;
End;

Procedure SoundSource.RenderSamples(Dest: AudioBuffer);
Var
  SampleCount, CopyTotal, Temp, Leftovers:Integer;
  FreqRate:Single;
Begin
  FreqRate := _Buffer.Frequency / Dest.Frequency;

  SampleCount := Dest.SampleCount;
  If (Trunc(_CurrentSample + SampleCount * FreqRate) > _Buffer.SampleCount) Then
  Begin
    Temp := SampleCount;
    SampleCount := Trunc((_Buffer.SampleCount - _CurrentSample) / FreqRate);
    LeftOvers := Temp - SampleCount;
  End Else
    Leftovers := 0;

  CopyTotal := Dest.MixSamples(0, _Buffer, _CurrentSample, SampleCount, 0.5);
  Inc(_CurrentSample, CopyTotal);

  If (Leftovers>0) Then
  Begin
    RequestMoreSamples();

    If (_Status = soundSource_Playing) Then
    Begin
      CopyTotal := Dest.MixSamples(SampleCount, _Buffer, _CurrentSample, Leftovers, 0.5);
      Inc(_CurrentSample, CopyTotal);
    End;
  End;

  If (_CurrentSample>=_Buffer.SampleCount)  Then
    RequestMoreSamples();
End;

Procedure SoundSource.RequestMoreSamples();
Begin
  If (Self._Loop) Then
    _CurrentSample := 0
  Else
    _Status := soundSource_Finished;
End;

{ ResourceSoundSource }
Constructor ResourceSoundSource.Create(Mode:SoundSourceMode; MySound:Sound);
Begin
  Inherited Create(Mode);

  If (Not Assigned(MySound)) Then
    Exit;

  Log(logDebug, 'SoundSource', 'Binding '+ MySound.Name);

  _Sound := MySound;
  _Sound.AttachSource(Self);

  _Status := soundSource_Playing;
End;

Procedure ResourceSoundSource.Release;
Begin
  If Assigned(_Sound) Then
    _Sound.RemoveSource(Self);
End;

Procedure ResourceSoundSource.RenderSamples(Dest:AudioBuffer);
Begin
  If (Self._Sound = Nil) Or (Self._Sound.Status = rsInvalid) Then
  Begin
    Self._Status := soundSource_Finished;
    Exit;
  End;

  If (Not Self._Sound.IsReady()) Then
    Exit;

  Self._Buffer := _Sound.Buffer;
  Inherited RenderSamples(Dest);
End;


End.
