Unit TERRA_WinMMAudioDriver;

Interface

Uses Windows, Messages, MMSystem, TERRA_Utils, TERRA_Sound, TERRA_AudioMixer, TERRA_AudioBuffer;

Const
  WaveBufferCount = 4;
  InternalBufferSampleCount = 1024;

Type
  WindowsAudioDriver = Class(TERRAAudioDriver)
    Protected
       _WaveFormat:TWaveFormatEx;
       _WaveHandle:Cardinal;
       _WaveOutHandle:Cardinal;
       _WaveHandler:Array[0..Pred(WaveBufferCount)] Of TWAVEHDR;
       _Buffers:Array[0..Pred(WaveBufferCount)] Of TERRAAudioBuffer;

       Function QueueBuffer():Boolean;

    Public
      Function Reset(Frequency, MaxSamples:Cardinal; Mixer:TERRAAudioMixer):Boolean; Override;
      Procedure Release; Override;

      Procedure Update(); Override;

    End;

Implementation

(*Procedure waveOutProc(hWaveOut:HWAVEOUT; uMsg, dwInstance, dwParam1, dwParam2:Cardinal); Stdcall;
Var
  Driver:WindowsAudioDriver;
Begin
  IntToString(uMsg);
End;*)

{ WindowsAudioDriver }
Function WindowsAudioDriver.Reset(Frequency, MaxSamples:Cardinal; Mixer:TERRAAudioMixer):Boolean;
Var
  I:Integer;
Begin
  Self._Frequency := Frequency;
  Self._Mixer := Mixer;

  _WaveFormat.wFormatTag := WAVE_FORMAT_PCM;
  _WaveFormat.nChannels := 2;
  _WaveFormat.wBitsPerSample := 16;

  _WaveFormat.nBlockAlign := _WaveFormat.nChannels * _WaveFormat.wBitsPerSample DIV 8;
  _WaveFormat.nSamplesPerSec := _Frequency;
  _WaveFormat.nAvgBytesPerSec := _WaveFormat.nSamplesPerSec * _WaveFormat.nBlockAlign;
  _WaveFormat.cbSize := 0;
  _WaveHandle := waveOutOpen(@_WaveOutHandle, WAVE_MAPPER, @_WaveFormat, {PtrUInt(@waveOutProc), PtrUInt(Self), CALLBACK_FUNCTION }0, 0, 0);

  For I:=0 To Pred(WaveBufferCount) Do
  Begin
    _WaveHandler[I].dwFlags := WHDR_DONE;

    //GetMem(_WaveHandler[I].lpData, _OutputBufferSize);

    _Buffers[I] := TERRAAudioBuffer.Create(InternalBufferSampleCount, Frequency, True);
    _WaveHandler[I].lpData := _Buffers[I].Samples;

    _WaveHandler[I].dwBufferLength := _Buffers[I].SizeInBytes;
    _WaveHandler[I].dwBytesRecorded := 0;
    _WaveHandler[I].dwUser := 0;
    _WaveHandler[I].dwLoops := 0;


    waveOutPrepareHeader(_WaveOutHandle, @_WaveHandler[I], SizeOf(TWAVEHDR));
    _WaveHandler[I].dwFlags := _WaveHandler[I].dwFlags Or WHDR_DONE;
  End;

  For I:=1 To WaveBufferCount Div 2 Do
    Self.QueueBuffer();

  Result := True;
End;

Procedure WindowsAudioDriver.Release;
Var
  I:Integer;
Begin
  waveOutReset(_WaveOutHandle);
  For I:=0 To Pred(WaveBufferCount) Do
  Begin
    While waveOutUnprepareHeader(_WaveOutHandle, @_WaveHandler[I], SIZEOF(TWAVEHDR))=WAVERR_STILLPLAYING Do
    Begin
     Sleep(25);
    End;
  End;
  waveOutReset(_WaveOutHandle);
  waveOutClose(_WaveOutHandle);
  For I:=0 To Pred(WaveBufferCount) Do
  Begin
    ReleaseObject(_Buffers[I]);
  End;
End;

Procedure WindowsAudioDriver.Update();
Begin
  While Self.QueueBuffer() Do;
End;

Function WindowsAudioDriver.QueueBuffer():Boolean;
Var
  I:Integer;
Begin
  For I:=0 To Pred(WaveBufferCount) Do
  If (_WaveHandler[I].dwFlags And WHDR_DONE)<>0 Then
  Begin
    //If waveOutUnprepareHeader(_WaveOutHandle, _WaveHandler[I], SizeOf(TWAVEHDR)) <> WAVERR_STILLPLAYING Then
    Begin
      _WaveHandler[I].dwFlags := _WaveHandler[I].dwFlags Xor WHDR_DONE;
      _Mixer.RequestSamples(_Buffers[I]);
      //waveOutPrepareHeader(_WaveOutHandle, _WaveHandler[I], SizeOf(TWAVEHDR));
      waveOutWrite(_WaveOutHandle, @_WaveHandler[I], SizeOf(TWAVEHDR));

      Result := True;
      Exit;
    End;
  End;

  Result := False;
End;

End.
