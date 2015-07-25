Unit TERRA_AlsaAudioDriver;

Interface

Uses TERRA_Error, TERRA_String, TERRA_AudioMixer, TERRA_AudioBuffer, Alsa;

Const
  InternalBufferSampleCount = 1024 * 4;

Type
  AlsaAudioDriver = Class(TERRAAudioDriver)
    Protected
      _Handle:Psnd_pcm_t;
      _Buffer:PAudioSample;

    Public
      Function Reset(Mixer:TERRAAudioMixer):Boolean; Override;
      Procedure Release; Override;

      Procedure Update(); Override;

    End;

Implementation
Uses TERRA_Log;

//snd_strerror(Status)
{ AlsaAudioDriver }
Function AlsaAudioDriver.Reset(Mixer:TERRAAudioMixer):Boolean;
Var
  Status:Integer;
  hw_params:Psnd_pcm_hw_params_t;
  Freq:Cardinal;
Begin
  Result := False;
  Self._Mixer := Mixer;

  Status := snd_pcm_open(_Handle, 'default', SND_PCM_STREAM_PLAYBACK, 0);
  If (Status<0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot open sound device...');
    Exit;
  End;

  Status := snd_pcm_hw_params_malloc(hw_params);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot allocate hardware parameter structure ...');
    Exit;
  End;

  Status := snd_pcm_hw_params_any (_Handle, hw_params);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot initialize hardware parameter structure  ...');
    Exit;
  End;

  Status := snd_pcm_hw_params_set_access (_Handle, hw_params, SND_PCM_ACCESS_RW_INTERLEAVED);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot set access type...');
    Exit;
  End;

  Status := snd_pcm_hw_params_set_format (_Handle, hw_params, SND_PCM_FORMAT_S16);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot set sample format ...');
    Exit;
  End;

  Freq := _Mixer.Buffer.Frequency;
  Status := snd_pcm_hw_params_set_rate_near(_Handle, hw_params, @Freq, Nil);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot set sample rate ...');
    Exit;
  End;

  Status := snd_pcm_hw_params_set_channels (_Handle, hw_params, 2);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot set channel count ...');
    Exit;
  End;

  Status := snd_pcm_hw_params (_Handle, hw_params);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot set parameters...');
    Exit;
  End;

  snd_pcm_hw_params_free (hw_params);

  Status := snd_pcm_prepare (_Handle);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot prepare audio interface for use...');
    Exit;
  End;

  GetMem(_Buffer, InternalBufferSampleCount * 2 * SizeOf(AudioSample));

  Result := True;
End;

Procedure AlsaAudioDriver.Release;
Begin
  snd_pcm_drain(_Handle);
  snd_pcm_close(_Handle);
  FreeMem(_Buffer);
End;

Procedure AlsaAudioDriver.Update();
Begin
  If Not _Mixer.Active Then
     Exit;

  _Mixer.RequestSamples(_Buffer, InternalBufferSampleCount);
  snd_pcm_writei(_Handle, _Buffer, InternalBufferSampleCount);
End;

End.
