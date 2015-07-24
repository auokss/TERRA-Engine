Unit TERRA_AlsaAudioDriver;

Interface

Uses TERRA_Error, TERRA_String, TERRA_AudioMixer, Alsa;

Type
  AlsaAudioDriver = Class(TERRAAudioDriver)
    Protected
      _Handle:snd_pcm_t;
      _Buffer:PAudioSample;
      _OutputBufferSize:Cardinal;

    Public
      Function Reset(AFrequency, MaxSamples:Cardinal; Mixer:TERRAAudioMixer):Boolean; Override;
      Procedure Release; Override;

      Procedure Update(); Override;

    End;

Implementation
Uses TERRA_Log;

{ AlsaAudioDriver }
Function AlsaAudioDriver.Reset(AFrequency, InitBufferSize:Cardinal; Mixer:TERRAAudioMixer):Boolean;
Var
  Status:Integer;
  hw_param:snd_pcm_hw_params_ts;
Begin
  Result := False;
  Self._Mixer := Mixer;
  Self._Frequency := AFrequency;
  Self._OutputBufferSize := InitBufferSize;

  Status := snd_pcm_open(@_Handle, 'default', SND_PCM_STREAM_PLAYBACK, 0);
  If (Status<0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot open sound device...'+ snd_strerror(Status));
    Exit;
  End;

  Status := snd_pcm_hw_params_malloc(@hw_params);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot allocate hardware parameter structure ...'+ snd_strerror(Status));
    Exit;
  End;

  Status := snd_pcm_hw_params_any (_Handle, hw_params);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot initialize hardware parameter structure  ...'+ snd_strerror(Status));
    Exit;
  End;

  Status := snd_pcm_hw_params_set_access (_Handle, hw_params, SND_PCM_ACCESS_RW_INTERLEAVED);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot set access type...'+ snd_strerror(Status));
    Exit;
  End;

  Status := snd_pcm_hw_params_set_format (_Handle, hw_params, SND_PCM_FORMAT_S16_LE);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot set sample format ...'+ snd_strerror(Status));
    Exit;
  End;

  Status := snd_pcm_hw_params_set_rate_near (_Handle, hw_params, _Frequency, 0);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot set sample rate ...'+ snd_strerror(Status));
    Exit;
  End;

  Status := snd_pcm_hw_params_set_channels (_Handle, hw_params, 2);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot set channel count ...'+ snd_strerror(Status));
    Exit;
  End;

  Status := snd_pcm_hw_params (_Handle, hw_params);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot set parameters...'+ snd_strerror(Status));
    Exit;
  End;

  snd_pcm_hw_params_free (hw_params);

	Status := snd_pcm_prepare (_Handle);
  If (Status < 0) Then
  Begin
    Log(logError, 'ALSA', 'Cannot prepare audio interface for use...'+ snd_strerror(Status));
    Exit;
  End;

  _OutputBufferSize := _Mixer.SampleBufferSize * 4;
  GetMem(_Buffer, _OutputBufferSize);

  Result := True;
End;

Procedure AlsaAudioDriver.Release;
Begin
  snd_pcm_drain(_Handle);
  snd_pcm_close(_Handle);
  FreemMem(_Buffer);
End;

Procedure AlsaAudioDriver.Update();
Begin
  _Mixer.RequestSamples(_Buffer, _OutputBufferSize Shr 2);
  snd_pcm_writei(_Handle, _Buffer, _OutputBufferSize);
End;

End.
