Unit TERRA_AudioMixer;

{$I terra.inc}

Interface
Uses TERRA_Utils, TERRA_String, TERRA_Threads, TERRA_Mutex, TERRA_Sound, TERRA_SoundSource, TERRA_AudioBuffer;

Const
  {$IFDEF MOBILE}
  DefaultSampleFrequency = 22050;
  {$ELSE}
  DefaultSampleFrequency = 44100;
  {$ENDIF}

  DefaultAudioSampleCount = 1024 * 16;

Type
  TERRAAudioMixer = Class;

  TERRAAudioDriver = Class(TERRAObject)
    Protected
      _Name:TERRAString;
      _Frequency:Cardinal;
      _OutputBufferSize:Cardinal;

      _Mixer:TERRAAudioMixer;

    Public
      Function Reset(Frequency, MaxSamples:Cardinal; Mixer:TERRAAudioMixer):Boolean; Virtual; Abstract;
      Procedure Update(); Virtual; Abstract;
  End;


  TERRAAudioMixer = Class(TERRAObject)
    Protected
       _Ready:Boolean;

       _BufferA:TERRAAudioBuffer;
       _BufferB:TERRAAudioBuffer;
       _CurrentBuffer:TERRAAudioBuffer;

       _Thread:TERRAThread;
       _Mutex:CriticalSection;
       _ThreadTerminated:Boolean;

       _Driver:TERRAAudioDriver;

       _CurrentSample:Cardinal;

       _Sources:Array Of SoundSource;
       _SourceCount:Integer;

       Procedure Update();

       Procedure Enter();
       Procedure Leave();

       Procedure ClearSources();
       Procedure SwapBuffers();

    Public
       Constructor Create(Frequency, MaxSamples:Cardinal);
       Procedure Release(); Override;

       Procedure RequestSamples(Dest:TERRAAudioBuffer);

       Procedure AddSource(Source:SoundSource);
       Procedure RemoveSource(Source:SoundSource);

       Property Buffer:TERRAAudioBuffer Read _CurrentBuffer;
  End;

  AudioMixerThread = Class(TERRAThread)
    Protected
      _Mixer:TERRAAudioMixer;
    Public
      Constructor Create(Mixer:TERRAAudioMixer);
      Procedure Execute; Override;
  End;


Implementation

Uses TERRA_Error, TERRA_Log, TERRA_OS
{$IFDEF WINDOWS}
, TERRA_WinMMAudioDriver
{$ENDIF}

{$IFDEF OSX}
, TERRA_CoreAudioDriver
{$ENDIF}
;

{ TERRAAudioMixer }
Constructor TERRAAudioMixer.Create(Frequency, MaxSamples:Cardinal);
Var
  I:Integer;
Begin
  _BufferA := TERRAAudioBuffer.Create(MaxSamples, Frequency, True);
  _BufferB := TERRAAudioBuffer.Create(MaxSamples, Frequency, True);
  _CurrentBuffer := _BufferA;

  SetLength(_Sources, 8);

	Log(logDebug, 'Audio','Opening sound device');

  {$IFDEF WINDOWS}
  _Driver := WindowsAudioDriver.Create();
  {$ENDIF}

  {$IFDEF OSX}
  _Driver := CoreAudioDriver.Create();
  {$ENDIF}

  _Ready := _Driver.Reset(Frequency, MaxSamples, Self);

  If Not _Ready Then
  Begin
	  Log(logWarning, 'Audio','Failed initializing sound device');
    Exit;
  End;

 _ThreadTerminated := False;
 _Mutex := CriticalSection.Create();
 _Thread := AudioMixerThread.Create(Self);
// CREATE_SUSPENDED
// SetThreadPriority(_ThreadHandle, THREAD_PRIORITY_TIME_CRITICAL);
End;

Procedure TERRAAudioMixer.Release();
Begin
  If _Ready Then
  Begin
    Self.Enter();
    _ThreadTerminated := True;
    Self.Leave();

    _Thread.Terminate();
    ReleaseObject(_Thread);
    ReleaseObject(_Mutex);
  End;

  Self.ClearSources();

  ReleaseObject(_Driver);

  ReleaseObject(_BufferA);
  ReleaseObject(_BufferB);
End;

Procedure TERRAAudioMixer.ClearSources();
Var
  I:Integer;
Begin
  For I := 0 To Pred(_SourceCount) Do
    ReleaseObject(_Sources[I]);

  SetLength(_Sources, 0);
  _SourceCount := 0;

End;

Procedure TERRAAudioMixer.Enter;
Begin
  _Mutex.Lock();
End;

Procedure TERRAAudioMixer.Leave;
Begin
  _Mutex.Unlock();
End;

Procedure TERRAAudioMixer.Update();
Begin
  Self.Enter();
  Self._Driver.Update();

  If (_CurrentSample>=_CurrentBuffer.SampleCount) Then
  Begin
    SwapBuffers();
  End;

  Self.Leave();
End;

Procedure TERRAAudioMixer.AddSource(Source: SoundSource);
Begin
  If (Source = Nil) Or (Not _Ready) Then
    Exit;

  Self.Enter();

  Inc(_SourceCount);
  If Length(_Sources)<_SourceCount Then
    SetLength(_Sources, Length(_Sources) * 2);
  _Sources[Pred(_SourceCount)] := Source;

  Self.Leave();
End;

Procedure TERRAAudioMixer.RemoveSource(Source: SoundSource);
Var
  N, I:Integer;
Begin
  If (Source = Nil) Or (Not _Ready) Then
    Exit;

  Self.Enter();

  N := -1;
  For I:=0 To Pred(_SourceCount) Do
  If (_Sources[I] = Source) Then
  Begin
    N := I;
    Break;
  End;

  If (N>=0) Then
  Begin
    //ReleaseObject(_Sources[N]);
    _Sources[N] := _Sources[Pred(_SourceCount)];
    _Sources[Pred(_SourceCount)] := Nil;
    Dec(_SourceCount);
  End;

  Self.Leave();
End;

Procedure TERRAAudioMixer.RequestSamples(Dest:TERRAAudioBuffer);
Var
  SampleCount, Leftovers, Temp:Integer;
Begin
  SampleCount := Dest.SampleCount;

  If (SampleCount + _CurrentSample > _CurrentBuffer.SampleCount) Then
  Begin
    Temp := SampleCount;
    SampleCount := _CurrentBuffer.SampleCount - _CurrentSample;
    Leftovers := Temp - SampleCount;
  End Else
    Leftovers := 0;

  Dest.ClearSamples();
  Dest.MixSamples(0, Self._CurrentBuffer, _CurrentSample, SampleCount, 1.0);
  Inc(_CurrentSample, SampleCount);
End;

Procedure TERRAAudioMixer.SwapBuffers;
Var
  I:Integer;
Begin
  _CurrentSample := 0;

  If _CurrentBuffer = _BufferA Then
    _CurrentBuffer := _BufferB
  Else
    _CurrentBuffer := _BufferA;

  _CurrentBuffer.ClearSamples();

  I := 0;
  While (I<_SourceCount) Do
  If (Not _Sources[I].Loop)  And (_Sources[I].Status = soundSource_Finished) Then
  Begin
    ReleaseObject(_Sources[I]);
    _Sources[I] := _Sources[Pred(_SourceCount)];
    Dec(_SourceCount);
  End Else
  Begin
    _Sources[I].RenderSamples(Self._CurrentBuffer);
    Inc(I);
  End;
End;

{ AudioMixerThread }
Constructor AudioMixerThread.Create(Mixer: TERRAAudioMixer);
Begin
  _Mixer := Mixer;

  Inherited Create();
End;

Procedure AudioMixerThread.Execute;
Begin
  While Not _Mixer._ThreadTerminated DO
  Begin
    _Mixer.Update();
    Application.Sleep(50);
  End;
End;

End.
