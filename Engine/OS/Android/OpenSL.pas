Unit OpenSL;

{$MODE objfpc}

Interface

Const
  OpenSLLib = 'libOpenSLES.so';

  SL_BOOLEAN_FALSE = 0;
  SL_BOOLEAN_TRUE = 0;

 SL_RESULT_SUCCESS				= $00000000;
 SL_RESULT_PRECONDITIONS_VIOLATED	= $00000001;
 SL_RESULT_PARAMETER_INVALID		= $00000002;
 SL_RESULT_MEMORY_FAILURE			= $00000003;
 SL_RESULT_RESOURCE_ERROR			= $00000004;
 SL_RESULT_RESOURCE_LOST			= $00000005;
 SL_RESULT_IO_ERROR				= $00000006;
 SL_RESULT_BUFFER_INSUFFICIENT		= $00000007;
 SL_RESULT_CONTENT_CORRUPTED		= $00000008;
 SL_RESULT_CONTENT_UNSUPPORTED		= $00000009;
 SL_RESULT_CONTENT_NOT_FOUND		= $0000000A;
 SL_RESULT_PERMISSION_DENIED		= $0000000B;
 SL_RESULT_FEATURE_UNSUPPORTED		= $0000000C;
 SL_RESULT_INTERNAL_ERROR			= $0000000D;
 SL_RESULT_UNKNOWN_ERROR			= $0000000E;
 SL_RESULT_OPERATION_ABORTED		= $0000000F;
 SL_RESULT_CONTROL_LOST			= $00000010;

  SL_PLAYSTATE_STOPPED	= 1;
  SL_PLAYSTATE_PAUSED	 = 2;
  SL_PLAYSTATE_PLAYING	= 3;


  SL_DATAFORMAT_MIME      = 1;
  SL_DATAFORMAT_PCM		    = 2;
  SL_DATAFORMAT_RESERVED3	= 3;

  SL_DATALOCATOR_ANDROIDSIMPLEBUFFERQUEUE = $800007BD;

  SL_PCMSAMPLEFORMAT_FIXED_8	= $0008;
  SL_PCMSAMPLEFORMAT_FIXED_16	= $0010;
  SL_PCMSAMPLEFORMAT_FIXED_20 = $0014;
  SL_PCMSAMPLEFORMAT_FIXED_24	= $0018;
  SL_PCMSAMPLEFORMAT_FIXED_28 = $001C;
  SL_PCMSAMPLEFORMAT_FIXED_32	= $0020;

  SL_BYTEORDER_BIGENDIAN    = 1;
  SL_BYTEORDER_LITTLEENDIAN = 2;

 SL_SPEAKER_FRONT_LEFT			= $00000001;
 SL_SPEAKER_FRONT_RIGHT			= $00000002;
 SL_SPEAKER_FRONT_CENTER			= $00000004;
 SL_SPEAKER_LOW_FREQUENCY			= $00000008;
 SL_SPEAKER_BACK_LEFT			= $00000010;
 SL_SPEAKER_BACK_RIGHT			= $00000020;
 SL_SPEAKER_FRONT_LEFT_OF_CENTER	= $00000040;
 SL_SPEAKER_FRONT_RIGHT_OF_CENTER	= $00000080;
 SL_SPEAKER_BACK_CENTER			= $00000100;
 SL_SPEAKER_SIDE_LEFT			= $00000200;
 SL_SPEAKER_SIDE_RIGHT			= $00000400;
 SL_SPEAKER_TOP_CENTER			= $00000800;
 SL_SPEAKER_TOP_FRONT_LEFT		= $00001000;
 SL_SPEAKER_TOP_FRONT_CENTER		= $00002000;
 SL_SPEAKER_TOP_FRONT_RIGHT		= $00004000;
 SL_SPEAKER_TOP_BACK_LEFT			= $00008000;
 SL_SPEAKER_TOP_BACK_CENTER		= $00010000;
 SL_SPEAKER_TOP_BACK_RIGHT		= $00020000;

  SL_DATALOCATOR_URI			= $00000001;
  SL_DATALOCATOR_ADDRESS		= $00000002;
 SL_DATALOCATOR_IODEVICE		= $00000003;
 SL_DATALOCATOR_OUTPUTMIX		= $00000004;
 SL_DATALOCATOR_RESERVED5		= $00000005;
 SL_DATALOCATOR_BUFFERQUEUE	= $00000006;
 SL_DATALOCATOR_MIDIBUFFERQUEUE	= $00000007;
 SL_DATALOCATOR_RESERVED8		= $00000008;

Type
  SLresult = Cardinal;
  SLboolean = Cardinal;
  SLmillisecond = Cardinal;
  PSLboolean = ^SLboolean;

  PSLInterfaceID = ^SLInterfaceID;
  SLInterfaceID = Record
    time_low:Cardinal;
    time_mid:Word;
    time_hi_and_version:Word;
    clock_seq:Word;
    node:Array[0..5] Of Byte;
  End;

  PSLObjectItf = ^SLObjectItf;

// PCM-type-based data format definition where formatType must be SL_DATAFORMAT_PCM
  SLDataFormat_PCM = Record
	  formatType:Cardinal;
  	numChannels:Cardinal;
  	samplesPerSec:Cardinal;
  	bitsPerSample:Cardinal;
  	containerSize:Cardinal;
  	channelMask:Cardinal;
  	endianness:Cardinal;
  End;

  PSLDataSource = ^SLDataSource;
  SLDataSource = Record
	  pLocator:Pointer;
	  pFormat:Pointer;
  End;

  PSLDataSink = ^SLDataSink ;
  SLDataSink = Record
	  pLocator:Pointer;
	  pFormat:Pointer;
  End;

  slObjectCallback = Procedure (caller:PSLObjectItf; pContext:Pointer; event:Cardinal; result:SLresult; param:Cardinal; pInterface:Pointer); CDecl;

  SLObject_Realize = Function (self:PSLObjectItf; async:SLboolean):SLresult; CDecl;
	SLObject_Resume = Function (self:PSLObjectItf;  async:SLboolean):SLresult; CDecl;
	SLObject_GetState = Function (self:PSLObjectItf; Var pState:Cardinal):SLresult; CDecl;
	SLObject_GetInterface = Function(self:PSLObjectItf; iid:PSLInterfaceID; pInterface:Pointer):SLresult; CDecl;
	SLObject_RegisterCallback = Function (self:PSLObjectItf; callback:slObjectCallback; pContext:Pointer):SLresult; CDecl;
  SLObject_AbortAsyncOperation = Procedure (self:PSLObjectItf); Cdecl;
  SLObject_Destroy = Procedure (self:PSLObjectItf); Cdecl;
  SLObject_SetPriority = Function(self:PSLObjectItf; priority:Integer; preemptable:SLboolean):SLResult; CDecl;
  SLObject_GetPriority = Function(self:PSLObjectItf; Var pPriority:Integer; Var pPreemptable:SLboolean):SLResult; CDecl;
  SLObject_SetLossOfControlInterfaces = Function (self:PSLObjectItf; numInterfaces:Integer; Var pInterfaceIDs:SLInterfaceID; enabled:SLboolean):SLResult; CDecl;

  SLObjectItf = Record
    Realize:SLObject_Realize;
    Resume:SLObject_Resume;
    GetState:SLObject_GetState;
    GetInterface:SLObject_GetInterface;
    RegisterCallback:SLObject_RegisterCallback;
    AbortAsyncOperation:SLObject_AbortAsyncOperation;
    Destroy:SLObject_Destroy;
    SetPriority:SLObject_SetPriority;
    GetPriority:SLObject_GetPriority;
    SetLossOfControlInterfaces:SLObject_SetLossOfControlInterfaces;
  End;

  PSLEngineOption = ^SLEngineOption;
  SLEngineOption = Record
	  feature:Cardinal;
	  data:Cardinal;
  End;

  PSLEngineItf = ^SLEngineItf;


	SLEngine_CreateLEDDevice = Function(self:PSLEngineItf; pDevice:PSLObjectItf; deviceID, numInterfaces:Cardinal; pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; CDecl;
	SLEngine_CreateVibraDevice = Function (self:PSLEngineItf; pDevice:PSLObjectItf; deviceID, numInterfaces:Cardinal; pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; CDecl;
	SLEngine_CreateAudioPlayer = Function (self:PSLEngineItf; pPlayer:PSLObjectItf;	pAudioSrc:PSLDataSource; pAudioSnk:PSLDataSink; numInterfaces:Cardinal; pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; CDecl;
	SLEngine_CreateAudioRecorder = Function (self:PSLEngineItf; pRecorder:PSLObjectItf;	pAudioSrc:PSLDataSource; pAudioSnk:PSLDataSink; numInterfaces:Cardinal; pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; CDecl;
  SLEngine_CreateMidiPlayer = Function (self:PSLEngineItf; pPlayer:PSLObjectItf; pMIDISrc:PSLDataSource; pBankSrc:PSLDataSource; pAudioOutput:PSLDataSink; pVibra:PSLDataSink; pLEDArray:PSLDataSink;  numInterfaces:Cardinal; pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; CDecl;
  SLEngine_CreateListener = Function (self:PSLEngineItf; pListener:PSLObjectItf; numInterfaces:Cardinal; pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; CDecl;
  SLEngine_Create3DGroup = Function (self:PSLEngineItf;	pGroup:PSLObjectItf; numInterfaces:Cardinal; pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; CDecl;
  SLEngine_CreateOutputMix = Function (self:PSLEngineItf;	pMix:PSLObjectItf; numInterfaces:Cardinal; pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; CDecl;
  SLEngine_CreateMetadataExtractor = Function (self:PSLEngineItf;	pMetadataExtractor:PSLObjectItf; pDataSource:PSLDataSource; numInterfaces:Cardinal; pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; CDecl;
  SLEngine_CreateExtensionObject = Function (self:PSLEngineItf;	pObject:PSLObjectItf; pParameters:Pointer; objectID:Cardinal; numInterfaces:Cardinal; pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; CDecl;
  SLEngine_QueryNumSupportedInterfaces = Function (self:PSLEngineItf;	objectID:Cardinal; Var numSupporterInterfaces:Cardinal):SLresult; CDecl;
  SLEngine_QuerySupportedInterfaces = Function (self:PSLEngineItf; objectID, index:Cardinal; Var pInterfaceId:SLInterfaceID):SLResult; Cdecl;
  SLEngine_QueryNumSupportedExtensions = Function (self:PSLEngineItf; Var pNumExtensions:Cardinal):SLResult; Cdecl;
  SLEngine_QuerySupportedExtension = Function (self:PSLEngineItf; index:Cardinal; pExtensionName:PAnsiChar; Var pNameLength:Word):SLResult; Cdecl;
  SLEngine_IsExtensionSupported = Function (self:PSLEngineItf; sExtensionName:PAnsiChar; Var pSupported:PSLBoolean):SLResult; Cdecl;

  SLEngineItf = Record
    CreateLEDDevice:SLEngine_CreateLEDDevice;
    CreateVibraDevice:SLEngine_CreateVibraDevice;
    CreateAudioPlayer:SLEngine_CreateAudioPlayer;
    CreateAudioRecorder:SLEngine_CreateAudioRecorder;
    CreateMidiPlayer:SLEngine_CreateMidiPlayer;
    CreateListener:SLEngine_CreateListener;
    Create3DGroup:SLEngine_Create3DGroup;
    CreateOutputMix:SLEngine_CreateOutputMix;
    CreateMetadataExtractor:SLEngine_CreateMetadataExtractor;
    CreateExtensionObject:SLEngine_CreateExtensionObject;
    QueryNumSupportedInterfaces:SLEngine_QueryNumSupportedInterfaces;
    QuerySupportedInterfaces:SLEngine_QuerySupportedInterfaces;
    QueryNumSupportedExtensions:SLEngine_QueryNumSupportedExtensions;
    QuerySupportedExtension:SLEngine_QuerySupportedExtension;
    IsExtensionSupported:SLEngine_IsExtensionSupported;
  End;

  SLDataLocator_AndroidSimpleBufferQueue = Record
    locatorType:Cardinal;
    numBuffers:Cardinal;
  End;

  SLDataLocator_OutputMix = Record
	  locatorType:Cardinal;
	  outputMix:PSLObjectItf;
  End;


  SLBufferQueueState = Record
	  count:Cardinal;
	  playIndex:Cardinal;
  End;


  PSLPlayItf = ^SLPlayItf;
  slPlayCallback = Procedure (caller:PSLPlayItf; pContext:Pointer; event:Cardinal); Cdecl;
  SLPlay_SetPlayState = Function(self:PSLPlayItf; state:Cardinal):SLResult; Cdecl;
  SLPlay_GetPlayState = Function(self:PSLPlayItf; Var state:Cardinal):SLResult; Cdecl;
  SLPlay_GetDuration = Function(self:PSLPlayItf; Var pMSec:SLmillisecond):SLResult; Cdecl;
  SLPlay_GetPosition = Function(self:PSLPlayItf; Var pMSec:SLmillisecond):SLResult; Cdecl;
  SLPlay_RegisterCallback = Function(self:PSLPlayItf; callback:slPlayCallback; pContext:Pointer):SLResult; Cdecl;
  SLPlay_SetCallbackEventsMask = Function(self:PSLPlayItf; eventFlags:Cardinal):SLResult; Cdecl;
  SLPlay_GetCallbackEventsMask = Function(self:PSLPlayItf; Var pEventFlags:Cardinal):SLResult; Cdecl;
  SLPlay_SetMarkerPosition = Function(self:PSLPlayItf; mSec:SLmillisecond):SLResult; Cdecl;
  SLPlay_ClearMarkerPosition = Function(self:PSLPlayItf):SLResult; Cdecl;
  SLPlay_GetMarkerPosition = Function(self:PSLPlayItf; Var  mSec:SLmillisecond):SLResult; Cdecl;
  SLPlay_SetPositionUpdatePeriod = Function(self:PSLPlayItf;  mSec:SLmillisecond):SLResult; Cdecl;
  SLPlay_GetPositionUpdatePeriod = Function(self:PSLPlayItf; Var  mSec:SLmillisecond):SLResult; Cdecl;


  SLPlayItf = Record
    SetPlayState:SLPlay_SetPlayState;
    GetPlayState:SLPlay_GetPlayState;
    GetDuration:SLPlay_GetDuration;
    GetPosition:SLPlay_GetPosition;
    RegisterCallback:SLPlay_RegisterCallback;
    SetCallbackEventsMask:SLPlay_SetCallbackEventsMask;
    GetCallbackEventsMask:SLPlay_GetCallbackEventsMask;
    SetMarkerPosition:SLPlay_SetMarkerPosition;
    ClearMarkerPosition:SLPlay_ClearMarkerPosition;
    GetMarkerPosition:SLPlay_GetMarkerPosition;
    SetPositionUpdatePeriod:SLPlay_SetPositionUpdatePeriod;
    GetPositionUpdatePeriod:SLPlay_GetPositionUpdatePeriod;
  End;

  PSLBufferQueueItf = ^SLBufferQueueItf;
  slBufferQueueCallback = Procedure(caller:PSLBufferQueueItf; pContext:Pointer); CDecl;

  SLBufferQueue_Enqueue = Function (self:PSLBufferQueueItf; pBuffer:Pointer; size:Cardinal):SLResult; Cdecl;
  SLBufferQueue_Clear = Function (self:PSLBufferQueueItf):SLResult; Cdecl;
  SLBufferQueue_GetState = Function (self:PSLBufferQueueItf; Var pState:SLBufferQueueState):SLResult; Cdecl;
  SLBufferQueue_RegisterCallback = Function (self:PSLBufferQueueItf; callback:slBufferQueueCallback; pContext:Pointer):SLResult; Cdecl;

  SLBufferQueueItf = Record
    Enqueue:SLBufferQueue_Enqueue;
    Clear:SLBufferQueue_Clear;
    GetState:SLBufferQueue_GetState;
    RegisterCallback:SLBufferQueue_RegisterCallback;
  End;

Function slCreateEngine(pEngine:PSLObjectItf; numOptions:Cardinal; pEngineOptions:PSLEngineOption;	numInterfaces:Cardinal;	pInterfaceIds:PSLInterfaceID; pInterfaceRequired:PSLboolean):SLresult; Cdecl; External OpenSLLib;

Var
  SL_IID_ENGINE:SLInterfaceID; cvar; external;
  SL_IID_VOLUME:SLInterfaceID; cvar; external;
  SL_IID_ANDROIDSIMPLEBUFFERQUEUE:SLInterfaceID; cvar; external;
  SL_IID_PLAY:SLInterfaceID; cvar; external;


Implementation

End.