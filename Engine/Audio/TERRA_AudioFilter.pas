Unit TERRA_AudioFilter;

Interface
Uses TERRA_Utils, TERRA_AudioBuffer, TERRA_AudioPanning;

Const
  LOWPASSFREQREF  = 5000.0;
  HIGHPASSFREQREF  = 250.0;

  BUFFERSIZE  = 2048;

  GAIN_SILENCE_THRESHOLD  = 0.00001; // -100dB

  SPEEDOFSOUNDMETRESPERSEC = 343.3;
  AIRABSORBGAINHF          = 0.99426; // -0.05dB 

  // Listener properties.
  AL_METERS_PER_UNIT                       = $20004;

  // Source properties.
  AL_DIRECT_FILTER                         = $20005;
  AL_AUXILIARY_SEND_FILTER                 = $20006;
  AL_AIR_ABSORPTION_FACTOR                 = $20007;
  AL_ROOM_ROLLOFF_FACTOR                   = $20008;
  AL_CONE_OUTER_GAINHF                     = $20009;
  AL_DIRECT_FILTER_GAINHF_AUTO             = $2000A;
  AL_AUXILIARY_SEND_FILTER_GAIN_AUTO       = $2000B;
  AL_AUXILIARY_SEND_FILTER_GAINHF_AUTO     = $2000C;


// Effect properties.

  // Reverb effect parameters
  AL_EAXREVERB_DENSITY                     = $0001;
  AL_EAXREVERB_DIFFUSION                   = $0002;
  AL_EAXREVERB_GAIN                        = $0003;
  AL_EAXREVERB_GAINHF                      = $0004;
  AL_EAXREVERB_GAINLF                      = $0005;
  AL_EAXREVERB_DECAY_TIME                  = $0006;
  AL_EAXREVERB_DECAY_HFRATIO               = $0007;
  AL_EAXREVERB_DECAY_LFRATIO               = $0008;
  AL_EAXREVERB_REFLECTIONS_GAIN            = $0009;
  AL_EAXREVERB_REFLECTIONS_DELAY           = $000A;
  AL_EAXREVERB_REFLECTIONS_PAN             = $000B;
  AL_EAXREVERB_LATE_REVERB_GAIN            = $000C;
  AL_EAXREVERB_LATE_REVERB_DELAY           = $000D;
  AL_EAXREVERB_LATE_REVERB_PAN             = $000E;
  AL_EAXREVERB_ECHO_TIME                   = $000F;
  AL_EAXREVERB_ECHO_DEPTH                  = $0010;
  AL_EAXREVERB_MODULATION_TIME             = $0011;
  AL_EAXREVERB_MODULATION_DEPTH            = $0012;
  AL_EAXREVERB_AIR_ABSORPTION_GAINHF       = $0013;
  AL_EAXREVERB_HFREFERENCE                 = $0014;
  AL_EAXREVERB_LFREFERENCE                 = $0015;
  AL_EAXREVERB_ROOM_ROLLOFF_FACTOR         = $0016;
  AL_EAXREVERB_DECAY_HFLIMIT               = $0017;

  // Chorus effect parameters
  AL_CHORUS_WAVEFORM                       = $0001;
  AL_CHORUS_PHASE                          = $0002;
  AL_CHORUS_RATE                           = $0003;
  AL_CHORUS_DEPTH                          = $0004;
  AL_CHORUS_FEEDBACK                       = $0005;
  AL_CHORUS_DELAY                          = $0006;

  // Distortion effect parameters
  AL_DISTORTION_EDGE                       = $0001;
  AL_DISTORTION_GAIN                       = $0002;
  AL_DISTORTION_LOWPASS_CUTOFF             = $0003;
  AL_DISTORTION_EQCENTER                   = $0004;
  AL_DISTORTION_EQBANDWIDTH                = $0005;


  // Flanger effect parameters
  AL_FLANGER_WAVEFORM                      = $0001;
  AL_FLANGER_PHASE                         = $0002;
  AL_FLANGER_RATE                          = $0003;
  AL_FLANGER_DEPTH                         = $0004;
  AL_FLANGER_FEEDBACK                      = $0005;
  AL_FLANGER_DELAY                         = $0006;

  // Frequency shifter effect parameters
  AL_FREQUENCY_SHIFTER_FREQUENCY           = $0001;
  AL_FREQUENCY_SHIFTER_LEFT_DIRECTION      = $0002;
  AL_FREQUENCY_SHIFTER_RIGHT_DIRECTION     = $0003;

  // Vocal morpher effect parameters
  AL_VOCAL_MORPHER_PHONEMEA                = $0001;
  AL_VOCAL_MORPHER_PHONEMEA_COARSE_TUNING  = $0002;
  AL_VOCAL_MORPHER_PHONEMEB                = $0003;
  AL_VOCAL_MORPHER_PHONEMEB_COARSE_TUNING  = $0004;
  AL_VOCAL_MORPHER_WAVEFORM                = $0005;
  AL_VOCAL_MORPHER_RATE                    = $0006;

  // Pitchshifter effect parameters
  AL_PITCH_SHIFTER_COARSE_TUNE             = $0001;
  AL_PITCH_SHIFTER_FINE_TUNE               = $0002;

  // Ringmodulator effect parameters
  AL_RING_MODULATOR_FREQUENCY              = $0001;
  AL_RING_MODULATOR_HIGHPASS_CUTOFF        = $0002;
  AL_RING_MODULATOR_WAVEFORM               = $0003;

  // Autowah effect parameters
  AL_AUTOWAH_ATTACK_TIME                   = $0001;
  AL_AUTOWAH_RELEASE_TIME                  = $0002;
  AL_AUTOWAH_RESONANCE                     = $0003;
  AL_AUTOWAH_PEAK_GAIN                     = $0004;

  // Compressor effect parameters
  AL_COMPRESSOR_ONOFF                      = $0001;

  // Equalizer effect parameters
  AL_EQUALIZER_LOW_GAIN                    = $0001;
  AL_EQUALIZER_LOW_CUTOFF                  = $0002;
  AL_EQUALIZER_MID1_GAIN                   = $0003;
  AL_EQUALIZER_MID1_CENTER                 = $0004;
  AL_EQUALIZER_MID1_WIDTH                  = $0005;
  AL_EQUALIZER_MID2_GAIN                   = $0006;
  AL_EQUALIZER_MID2_CENTER                 = $0007;
  AL_EQUALIZER_MID2_WIDTH                  = $0008;
  AL_EQUALIZER_HIGH_GAIN                   = $0009;
  AL_EQUALIZER_HIGH_CUTOFF                 = $000A;

  // Effect type
  AL_EFFECT_FIRST_PARAMETER                = $0000;
  AL_EFFECT_LAST_PARAMETER                 = $8000;
  AL_EFFECT_TYPE                           = $8001;

  // Effect types, used with the AL_EFFECT_TYPE property
  AL_EFFECT_NULL                           = $0000;
  AL_EFFECT_REVERB                         = $0001;
  AL_EFFECT_CHORUS                         = $0002;
  AL_EFFECT_DISTORTION                     = $0003;
  AL_EFFECT_ECHO                           = $0004;
  AL_EFFECT_FLANGER                        = $0005;
  AL_EFFECT_FREQUENCY_SHIFTER              = $0006;
  AL_EFFECT_VOCAL_MORPHER                  = $0007;
  AL_EFFECT_PITCH_SHIFTER                  = $0008;
  AL_EFFECT_RING_MODULATOR                 = $0009;
  AL_EFFECT_AUTOWAH                        = $000A;
  AL_EFFECT_COMPRESSOR                     = $000B;
  AL_EFFECT_EQUALIZER                      = $000C;
  AL_EFFECT_EAXREVERB                      = $8000;

  // Auxiliary Effect Slot properties.
  AL_EFFECTSLOT_EFFECT                     = $0001;
  AL_EFFECTSLOT_GAIN                       = $0002;
  AL_EFFECTSLOT_AUXILIARY_SEND_AUTO        = $0003;

  // NULL Auxiliary Slot ID to disable a source send.
  AL_EFFECTSLOT_NULL                       = $0000;


  // Filter properties.
  // Lowpass filter parameters
  AL_LOWPASS_GAIN                          = $0001;
  AL_LOWPASS_GAINHF                        = $0002;

  // Highpass filter parameters
  AL_HIGHPASS_GAIN                         = $0001;
  AL_HIGHPASS_GAINLF                       = $0002;

  // Bandpass filter parameters
  AL_BANDPASS_GAIN                         = $0001;
  AL_BANDPASS_GAINLF                       = $0002;
  AL_BANDPASS_GAINHF                       = $0003;

  // Filter type
  AL_FILTER_FIRST_PARAMETER                = $0000;
  AL_FILTER_LAST_PARAMETER                 = $8000;
  AL_FILTER_TYPE                           = $8001;

  // Filter types, used with the AL_FILTER_TYPE property
  AL_FILTER_NULL                           = $0000;
  AL_FILTER_LOWPASS                        = $0001;
  AL_FILTER_HIGHPASS                       = $0002;
  AL_FILTER_BANDPASS                       = $0003;

{/* Filter ranges and defaults. */

/* Lowpass filter */
#define AL_LOWPASS_MIN_GAIN                      (0.0f)
#define AL_LOWPASS_MAX_GAIN                      (1.0f)
#define AL_LOWPASS_DEFAULT_GAIN                  (1.0f)

#define AL_LOWPASS_MIN_GAINHF                    (0.0f)
#define AL_LOWPASS_MAX_GAINHF                    (1.0f)
#define AL_LOWPASS_DEFAULT_GAINHF                (1.0f)

/* Highpass filter */
#define AL_HIGHPASS_MIN_GAIN                     (0.0f)
#define AL_HIGHPASS_MAX_GAIN                     (1.0f)
#define AL_HIGHPASS_DEFAULT_GAIN                 (1.0f)

#define AL_HIGHPASS_MIN_GAINLF                   (0.0f)
#define AL_HIGHPASS_MAX_GAINLF                   (1.0f)
#define AL_HIGHPASS_DEFAULT_GAINLF               (1.0f)

/* Bandpass filter */
#define AL_BANDPASS_MIN_GAIN                     (0.0f)
#define AL_BANDPASS_MAX_GAIN                     (1.0f)
#define AL_BANDPASS_DEFAULT_GAIN                 (1.0f)

#define AL_BANDPASS_MIN_GAINHF                   (0.0f)
#define AL_BANDPASS_MAX_GAINHF                   (1.0f)
#define AL_BANDPASS_DEFAULT_GAINHF               (1.0f)

#define AL_BANDPASS_MIN_GAINLF                   (0.0f)
#define AL_BANDPASS_MAX_GAINLF                   (1.0f)
#define AL_BANDPASS_DEFAULT_GAINLF               (1.0f)


/* Effect parameter ranges and defaults. */

/* Standard reverb effect */
#define AL_REVERB_MIN_DENSITY                    (0.0f)
#define AL_REVERB_MAX_DENSITY                    (1.0f)
#define AL_REVERB_DEFAULT_DENSITY                (1.0f)

#define AL_REVERB_MIN_DIFFUSION                  (0.0f)
#define AL_REVERB_MAX_DIFFUSION                  (1.0f)
#define AL_REVERB_DEFAULT_DIFFUSION              (1.0f)

#define AL_REVERB_MIN_GAIN                       (0.0f)
#define AL_REVERB_MAX_GAIN                       (1.0f)
#define AL_REVERB_DEFAULT_GAIN                   (0.32f)

#define AL_REVERB_MIN_GAINHF                     (0.0f)
#define AL_REVERB_MAX_GAINHF                     (1.0f)
#define AL_REVERB_DEFAULT_GAINHF                 (0.89f)

#define AL_REVERB_MIN_DECAY_TIME                 (0.1f)
#define AL_REVERB_MAX_DECAY_TIME                 (20.0f)
#define AL_REVERB_DEFAULT_DECAY_TIME             (1.49f)

#define AL_REVERB_MIN_DECAY_HFRATIO              (0.1f)
#define AL_REVERB_MAX_DECAY_HFRATIO              (2.0f)
#define AL_REVERB_DEFAULT_DECAY_HFRATIO          (0.83f)

#define AL_REVERB_MIN_REFLECTIONS_GAIN           (0.0f)
#define AL_REVERB_MAX_REFLECTIONS_GAIN           (3.16f)
#define AL_REVERB_DEFAULT_REFLECTIONS_GAIN       (0.05f)

#define AL_REVERB_MIN_REFLECTIONS_DELAY          (0.0f)
#define AL_REVERB_MAX_REFLECTIONS_DELAY          (0.3f)
#define AL_REVERB_DEFAULT_REFLECTIONS_DELAY      (0.007f)

#define AL_REVERB_MIN_LATE_REVERB_GAIN           (0.0f)
#define AL_REVERB_MAX_LATE_REVERB_GAIN           (10.0f)
#define AL_REVERB_DEFAULT_LATE_REVERB_GAIN       (1.26f)

#define AL_REVERB_MIN_LATE_REVERB_DELAY          (0.0f)
#define AL_REVERB_MAX_LATE_REVERB_DELAY          (0.1f)
#define AL_REVERB_DEFAULT_LATE_REVERB_DELAY      (0.011f)

#define AL_REVERB_MIN_AIR_ABSORPTION_GAINHF      (0.892f)
#define AL_REVERB_MAX_AIR_ABSORPTION_GAINHF      (1.0f)
#define AL_REVERB_DEFAULT_AIR_ABSORPTION_GAINHF  (0.994f)

#define AL_REVERB_MIN_ROOM_ROLLOFF_FACTOR        (0.0f)
#define AL_REVERB_MAX_ROOM_ROLLOFF_FACTOR        (10.0f)
#define AL_REVERB_DEFAULT_ROOM_ROLLOFF_FACTOR    (0.0f)

#define AL_REVERB_MIN_DECAY_HFLIMIT              AL_FALSE
#define AL_REVERB_MAX_DECAY_HFLIMIT              AL_TRUE
#define AL_REVERB_DEFAULT_DECAY_HFLIMIT          AL_TRUE

/* EAX reverb effect */
#define AL_EAXREVERB_MIN_DENSITY                 (0.0f)
#define AL_EAXREVERB_MAX_DENSITY                 (1.0f)
#define AL_EAXREVERB_DEFAULT_DENSITY             (1.0f)

#define AL_EAXREVERB_MIN_DIFFUSION               (0.0f)
#define AL_EAXREVERB_MAX_DIFFUSION               (1.0f)
#define AL_EAXREVERB_DEFAULT_DIFFUSION           (1.0f)

#define AL_EAXREVERB_MIN_GAIN                    (0.0f)
#define AL_EAXREVERB_MAX_GAIN                    (1.0f)
#define AL_EAXREVERB_DEFAULT_GAIN                (0.32f)

#define AL_EAXREVERB_MIN_GAINHF                  (0.0f)
#define AL_EAXREVERB_MAX_GAINHF                  (1.0f)
#define AL_EAXREVERB_DEFAULT_GAINHF              (0.89f)

#define AL_EAXREVERB_MIN_GAINLF                  (0.0f)
#define AL_EAXREVERB_MAX_GAINLF                  (1.0f)
#define AL_EAXREVERB_DEFAULT_GAINLF              (1.0f)

#define AL_EAXREVERB_MIN_DECAY_TIME              (0.1f)
#define AL_EAXREVERB_MAX_DECAY_TIME              (20.0f)
#define AL_EAXREVERB_DEFAULT_DECAY_TIME          (1.49f)

#define AL_EAXREVERB_MIN_DECAY_HFRATIO           (0.1f)
#define AL_EAXREVERB_MAX_DECAY_HFRATIO           (2.0f)
#define AL_EAXREVERB_DEFAULT_DECAY_HFRATIO       (0.83f)

#define AL_EAXREVERB_MIN_DECAY_LFRATIO           (0.1f)
#define AL_EAXREVERB_MAX_DECAY_LFRATIO           (2.0f)
#define AL_EAXREVERB_DEFAULT_DECAY_LFRATIO       (1.0f)

#define AL_EAXREVERB_MIN_REFLECTIONS_GAIN        (0.0f)
#define AL_EAXREVERB_MAX_REFLECTIONS_GAIN        (3.16f)
#define AL_EAXREVERB_DEFAULT_REFLECTIONS_GAIN    (0.05f)

#define AL_EAXREVERB_MIN_REFLECTIONS_DELAY       (0.0f)
#define AL_EAXREVERB_MAX_REFLECTIONS_DELAY       (0.3f)
#define AL_EAXREVERB_DEFAULT_REFLECTIONS_DELAY   (0.007f)

#define AL_EAXREVERB_DEFAULT_REFLECTIONS_PAN_XYZ (0.0f)

#define AL_EAXREVERB_MIN_LATE_REVERB_GAIN        (0.0f)
#define AL_EAXREVERB_MAX_LATE_REVERB_GAIN        (10.0f)
#define AL_EAXREVERB_DEFAULT_LATE_REVERB_GAIN    (1.26f)

#define AL_EAXREVERB_MIN_LATE_REVERB_DELAY       (0.0f)
#define AL_EAXREVERB_MAX_LATE_REVERB_DELAY       (0.1f)
#define AL_EAXREVERB_DEFAULT_LATE_REVERB_DELAY   (0.011f)

#define AL_EAXREVERB_DEFAULT_LATE_REVERB_PAN_XYZ (0.0f)

#define AL_EAXREVERB_MIN_ECHO_TIME               (0.075f)
#define AL_EAXREVERB_MAX_ECHO_TIME               (0.25f)
#define AL_EAXREVERB_DEFAULT_ECHO_TIME           (0.25f)

#define AL_EAXREVERB_MIN_ECHO_DEPTH              (0.0f)
#define AL_EAXREVERB_MAX_ECHO_DEPTH              (1.0f)
#define AL_EAXREVERB_DEFAULT_ECHO_DEPTH          (0.0f)

#define AL_EAXREVERB_MIN_MODULATION_TIME         (0.04f)
#define AL_EAXREVERB_MAX_MODULATION_TIME         (4.0f)
#define AL_EAXREVERB_DEFAULT_MODULATION_TIME     (0.25f)

#define AL_EAXREVERB_MIN_MODULATION_DEPTH        (0.0f)
#define AL_EAXREVERB_MAX_MODULATION_DEPTH        (1.0f)
#define AL_EAXREVERB_DEFAULT_MODULATION_DEPTH    (0.0f)

#define AL_EAXREVERB_MIN_AIR_ABSORPTION_GAINHF   (0.892f)
#define AL_EAXREVERB_MAX_AIR_ABSORPTION_GAINHF   (1.0f)
#define AL_EAXREVERB_DEFAULT_AIR_ABSORPTION_GAINHF (0.994f)

#define AL_EAXREVERB_MIN_HFREFERENCE             (1000.0f)
#define AL_EAXREVERB_MAX_HFREFERENCE             (20000.0f)
#define AL_EAXREVERB_DEFAULT_HFREFERENCE         (5000.0f)

#define AL_EAXREVERB_MIN_LFREFERENCE             (20.0f)
#define AL_EAXREVERB_MAX_LFREFERENCE             (1000.0f)
#define AL_EAXREVERB_DEFAULT_LFREFERENCE         (250.0f)

#define AL_EAXREVERB_MIN_ROOM_ROLLOFF_FACTOR     (0.0f)
#define AL_EAXREVERB_MAX_ROOM_ROLLOFF_FACTOR     (10.0f)
#define AL_EAXREVERB_DEFAULT_ROOM_ROLLOFF_FACTOR (0.0f)

#define AL_EAXREVERB_MIN_DECAY_HFLIMIT           AL_FALSE
#define AL_EAXREVERB_MAX_DECAY_HFLIMIT           AL_TRUE
#define AL_EAXREVERB_DEFAULT_DECAY_HFLIMIT       AL_TRUE

/* Chorus effect */
#define AL_CHORUS_WAVEFORM_SINUSOID              (0)
#define AL_CHORUS_WAVEFORM_TRIANGLE              (1)

#define AL_CHORUS_MIN_WAVEFORM                   (0)
#define AL_CHORUS_MAX_WAVEFORM                   (1)
#define AL_CHORUS_DEFAULT_WAVEFORM               (1)

#define AL_CHORUS_MIN_PHASE                      (-180)
#define AL_CHORUS_MAX_PHASE                      (180)
#define AL_CHORUS_DEFAULT_PHASE                  (90)

#define AL_CHORUS_MIN_RATE                       (0.0f)
#define AL_CHORUS_MAX_RATE                       (10.0f)
#define AL_CHORUS_DEFAULT_RATE                   (1.1f)

#define AL_CHORUS_MIN_DEPTH                      (0.0f)
#define AL_CHORUS_MAX_DEPTH                      (1.0f)
#define AL_CHORUS_DEFAULT_DEPTH                  (0.1f)

#define AL_CHORUS_MIN_FEEDBACK                   (-1.0f)
#define AL_CHORUS_MAX_FEEDBACK                   (1.0f)
#define AL_CHORUS_DEFAULT_FEEDBACK               (0.25f)

#define AL_CHORUS_MIN_DELAY                      (0.0f)
#define AL_CHORUS_MAX_DELAY                      (0.016f)
#define AL_CHORUS_DEFAULT_DELAY                  (0.016f)

/* Distortion effect */
#define AL_DISTORTION_MIN_EDGE                   (0.0f)
#define AL_DISTORTION_MAX_EDGE                   (1.0f)
#define AL_DISTORTION_DEFAULT_EDGE               (0.2f)

#define AL_DISTORTION_MIN_GAIN                   (0.01f)
#define AL_DISTORTION_MAX_GAIN                   (1.0f)
#define AL_DISTORTION_DEFAULT_GAIN               (0.05f)

#define AL_DISTORTION_MIN_LOWPASS_CUTOFF         (80.0f)
#define AL_DISTORTION_MAX_LOWPASS_CUTOFF         (24000.0f)
#define AL_DISTORTION_DEFAULT_LOWPASS_CUTOFF     (8000.0f)

#define AL_DISTORTION_MIN_EQCENTER               (80.0f)
#define AL_DISTORTION_MAX_EQCENTER               (24000.0f)
#define AL_DISTORTION_DEFAULT_EQCENTER           (3600.0f)

#define AL_DISTORTION_MIN_EQBANDWIDTH            (80.0f)
#define AL_DISTORTION_MAX_EQBANDWIDTH            (24000.0f)
#define AL_DISTORTION_DEFAULT_EQBANDWIDTH        (3600.0f)


/* Flanger effect */
#define AL_FLANGER_WAVEFORM_SINUSOID             (0)
#define AL_FLANGER_WAVEFORM_TRIANGLE             (1)

#define AL_FLANGER_MIN_WAVEFORM                  (0)
#define AL_FLANGER_MAX_WAVEFORM                  (1)
#define AL_FLANGER_DEFAULT_WAVEFORM              (1)

#define AL_FLANGER_MIN_PHASE                     (-180)
#define AL_FLANGER_MAX_PHASE                     (180)
#define AL_FLANGER_DEFAULT_PHASE                 (0)

#define AL_FLANGER_MIN_RATE                      (0.0f)
#define AL_FLANGER_MAX_RATE                      (10.0f)
#define AL_FLANGER_DEFAULT_RATE                  (0.27f)

#define AL_FLANGER_MIN_DEPTH                     (0.0f)
#define AL_FLANGER_MAX_DEPTH                     (1.0f)
#define AL_FLANGER_DEFAULT_DEPTH                 (1.0f)

#define AL_FLANGER_MIN_FEEDBACK                  (-1.0f)
#define AL_FLANGER_MAX_FEEDBACK                  (1.0f)
#define AL_FLANGER_DEFAULT_FEEDBACK              (-0.5f)

#define AL_FLANGER_MIN_DELAY                     (0.0f)
#define AL_FLANGER_MAX_DELAY                     (0.004f)
#define AL_FLANGER_DEFAULT_DELAY                 (0.002f)

/* Frequency shifter effect */
#define AL_FREQUENCY_SHIFTER_MIN_FREQUENCY       (0.0f)
#define AL_FREQUENCY_SHIFTER_MAX_FREQUENCY       (24000.0f)
#define AL_FREQUENCY_SHIFTER_DEFAULT_FREQUENCY   (0.0f)

#define AL_FREQUENCY_SHIFTER_MIN_LEFT_DIRECTION  (0)
#define AL_FREQUENCY_SHIFTER_MAX_LEFT_DIRECTION  (2)
#define AL_FREQUENCY_SHIFTER_DEFAULT_LEFT_DIRECTION (0)

#define AL_FREQUENCY_SHIFTER_DIRECTION_DOWN      (0)
#define AL_FREQUENCY_SHIFTER_DIRECTION_UP        (1)
#define AL_FREQUENCY_SHIFTER_DIRECTION_OFF       (2)

#define AL_FREQUENCY_SHIFTER_MIN_RIGHT_DIRECTION (0)
#define AL_FREQUENCY_SHIFTER_MAX_RIGHT_DIRECTION (2)
#define AL_FREQUENCY_SHIFTER_DEFAULT_RIGHT_DIRECTION (0)

/* Vocal morpher effect */
#define AL_VOCAL_MORPHER_MIN_PHONEMEA            (0)
#define AL_VOCAL_MORPHER_MAX_PHONEMEA            (29)
#define AL_VOCAL_MORPHER_DEFAULT_PHONEMEA        (0)

#define AL_VOCAL_MORPHER_MIN_PHONEMEA_COARSE_TUNING (-24)
#define AL_VOCAL_MORPHER_MAX_PHONEMEA_COARSE_TUNING (24)
#define AL_VOCAL_MORPHER_DEFAULT_PHONEMEA_COARSE_TUNING (0)

#define AL_VOCAL_MORPHER_MIN_PHONEMEB            (0)
#define AL_VOCAL_MORPHER_MAX_PHONEMEB            (29)
#define AL_VOCAL_MORPHER_DEFAULT_PHONEMEB        (10)

#define AL_VOCAL_MORPHER_MIN_PHONEMEB_COARSE_TUNING (-24)
#define AL_VOCAL_MORPHER_MAX_PHONEMEB_COARSE_TUNING (24)
#define AL_VOCAL_MORPHER_DEFAULT_PHONEMEB_COARSE_TUNING (0)

#define AL_VOCAL_MORPHER_PHONEME_A               (0)
#define AL_VOCAL_MORPHER_PHONEME_E               (1)
#define AL_VOCAL_MORPHER_PHONEME_I               (2)
#define AL_VOCAL_MORPHER_PHONEME_O               (3)
#define AL_VOCAL_MORPHER_PHONEME_U               (4)
#define AL_VOCAL_MORPHER_PHONEME_AA              (5)
#define AL_VOCAL_MORPHER_PHONEME_AE              (6)
#define AL_VOCAL_MORPHER_PHONEME_AH              (7)
#define AL_VOCAL_MORPHER_PHONEME_AO              (8)
#define AL_VOCAL_MORPHER_PHONEME_EH              (9)
#define AL_VOCAL_MORPHER_PHONEME_ER              (10)
#define AL_VOCAL_MORPHER_PHONEME_IH              (11)
#define AL_VOCAL_MORPHER_PHONEME_IY              (12)
#define AL_VOCAL_MORPHER_PHONEME_UH              (13)
#define AL_VOCAL_MORPHER_PHONEME_UW              (14)
#define AL_VOCAL_MORPHER_PHONEME_B               (15)
#define AL_VOCAL_MORPHER_PHONEME_D               (16)
#define AL_VOCAL_MORPHER_PHONEME_F               (17)
#define AL_VOCAL_MORPHER_PHONEME_G               (18)
#define AL_VOCAL_MORPHER_PHONEME_J               (19)
#define AL_VOCAL_MORPHER_PHONEME_K               (20)
#define AL_VOCAL_MORPHER_PHONEME_L               (21)
#define AL_VOCAL_MORPHER_PHONEME_M               (22)
#define AL_VOCAL_MORPHER_PHONEME_N               (23)
#define AL_VOCAL_MORPHER_PHONEME_P               (24)
#define AL_VOCAL_MORPHER_PHONEME_R               (25)
#define AL_VOCAL_MORPHER_PHONEME_S               (26)
#define AL_VOCAL_MORPHER_PHONEME_T               (27)
#define AL_VOCAL_MORPHER_PHONEME_V               (28)
#define AL_VOCAL_MORPHER_PHONEME_Z               (29)

#define AL_VOCAL_MORPHER_WAVEFORM_SINUSOID       (0)
#define AL_VOCAL_MORPHER_WAVEFORM_TRIANGLE       (1)
#define AL_VOCAL_MORPHER_WAVEFORM_SAWTOOTH       (2)

#define AL_VOCAL_MORPHER_MIN_WAVEFORM            (0)
#define AL_VOCAL_MORPHER_MAX_WAVEFORM            (2)
#define AL_VOCAL_MORPHER_DEFAULT_WAVEFORM        (0)

#define AL_VOCAL_MORPHER_MIN_RATE                (0.0f)
#define AL_VOCAL_MORPHER_MAX_RATE                (10.0f)
#define AL_VOCAL_MORPHER_DEFAULT_RATE            (1.41f)

/* Pitch shifter effect */
#define AL_PITCH_SHIFTER_MIN_COARSE_TUNE         (-12)
#define AL_PITCH_SHIFTER_MAX_COARSE_TUNE         (12)
#define AL_PITCH_SHIFTER_DEFAULT_COARSE_TUNE     (12)

#define AL_PITCH_SHIFTER_MIN_FINE_TUNE           (-50)
#define AL_PITCH_SHIFTER_MAX_FINE_TUNE           (50)
#define AL_PITCH_SHIFTER_DEFAULT_FINE_TUNE       (0)

/* Ring modulator effect */
#define AL_RING_MODULATOR_MIN_FREQUENCY          (0.0f)
#define AL_RING_MODULATOR_MAX_FREQUENCY          (8000.0f)
#define AL_RING_MODULATOR_DEFAULT_FREQUENCY      (440.0f)

#define AL_RING_MODULATOR_MIN_HIGHPASS_CUTOFF    (0.0f)
#define AL_RING_MODULATOR_MAX_HIGHPASS_CUTOFF    (24000.0f)
#define AL_RING_MODULATOR_DEFAULT_HIGHPASS_CUTOFF (800.0f)

#define AL_RING_MODULATOR_SINUSOID               (0)
#define AL_RING_MODULATOR_SAWTOOTH               (1)
#define AL_RING_MODULATOR_SQUARE                 (2)

#define AL_RING_MODULATOR_MIN_WAVEFORM           (0)
#define AL_RING_MODULATOR_MAX_WAVEFORM           (2)
#define AL_RING_MODULATOR_DEFAULT_WAVEFORM       (0)

/* Autowah effect */
#define AL_AUTOWAH_MIN_ATTACK_TIME               (0.0001f)
#define AL_AUTOWAH_MAX_ATTACK_TIME               (1.0f)
#define AL_AUTOWAH_DEFAULT_ATTACK_TIME           (0.06f)

#define AL_AUTOWAH_MIN_RELEASE_TIME              (0.0001f)
#define AL_AUTOWAH_MAX_RELEASE_TIME              (1.0f)
#define AL_AUTOWAH_DEFAULT_RELEASE_TIME          (0.06f)

#define AL_AUTOWAH_MIN_RESONANCE                 (2.0f)
#define AL_AUTOWAH_MAX_RESONANCE                 (1000.0f)
#define AL_AUTOWAH_DEFAULT_RESONANCE             (1000.0f)

#define AL_AUTOWAH_MIN_PEAK_GAIN                 (0.00003f)
#define AL_AUTOWAH_MAX_PEAK_GAIN                 (31621.0f)
#define AL_AUTOWAH_DEFAULT_PEAK_GAIN             (11.22f)

/* Compressor effect */
#define AL_COMPRESSOR_MIN_ONOFF                  (0)
#define AL_COMPRESSOR_MAX_ONOFF                  (1)
#define AL_COMPRESSOR_DEFAULT_ONOFF              (1)

/* Equalizer effect */
#define AL_EQUALIZER_MIN_LOW_GAIN                (0.126f)
#define AL_EQUALIZER_MAX_LOW_GAIN                (7.943f)
#define AL_EQUALIZER_DEFAULT_LOW_GAIN            (1.0f)

#define AL_EQUALIZER_MIN_LOW_CUTOFF              (50.0f)
#define AL_EQUALIZER_MAX_LOW_CUTOFF              (800.0f)
#define AL_EQUALIZER_DEFAULT_LOW_CUTOFF          (200.0f)

#define AL_EQUALIZER_MIN_MID1_GAIN               (0.126f)
#define AL_EQUALIZER_MAX_MID1_GAIN               (7.943f)
#define AL_EQUALIZER_DEFAULT_MID1_GAIN           (1.0f)

#define AL_EQUALIZER_MIN_MID1_CENTER             (200.0f)
#define AL_EQUALIZER_MAX_MID1_CENTER             (3000.0f)
#define AL_EQUALIZER_DEFAULT_MID1_CENTER         (500.0f)

#define AL_EQUALIZER_MIN_MID1_WIDTH              (0.01f)
#define AL_EQUALIZER_MAX_MID1_WIDTH              (1.0f)
#define AL_EQUALIZER_DEFAULT_MID1_WIDTH          (1.0f)

#define AL_EQUALIZER_MIN_MID2_GAIN               (0.126f)
#define AL_EQUALIZER_MAX_MID2_GAIN               (7.943f)
#define AL_EQUALIZER_DEFAULT_MID2_GAIN           (1.0f)

#define AL_EQUALIZER_MIN_MID2_CENTER             (1000.0f)
#define AL_EQUALIZER_MAX_MID2_CENTER             (8000.0f)
#define AL_EQUALIZER_DEFAULT_MID2_CENTER         (3000.0f)

#define AL_EQUALIZER_MIN_MID2_WIDTH              (0.01f)
#define AL_EQUALIZER_MAX_MID2_WIDTH              (1.0f)
#define AL_EQUALIZER_DEFAULT_MID2_WIDTH          (1.0f)

#define AL_EQUALIZER_MIN_HIGH_GAIN               (0.126f)
#define AL_EQUALIZER_MAX_HIGH_GAIN               (7.943f)
#define AL_EQUALIZER_DEFAULT_HIGH_GAIN           (1.0f)

#define AL_EQUALIZER_MIN_HIGH_CUTOFF             (4000.0f)
#define AL_EQUALIZER_MAX_HIGH_CUTOFF             (16000.0f)
#define AL_EQUALIZER_DEFAULT_HIGH_CUTOFF         (6000.0f)


/* Source parameter value ranges and defaults. */
#define AL_MIN_AIR_ABSORPTION_FACTOR             (0.0f)
#define AL_MAX_AIR_ABSORPTION_FACTOR             (10.0f)
#define AL_DEFAULT_AIR_ABSORPTION_FACTOR         (0.0f)

#define AL_MIN_ROOM_ROLLOFF_FACTOR               (0.0f)
#define AL_MAX_ROOM_ROLLOFF_FACTOR               (10.0f)
#define AL_DEFAULT_ROOM_ROLLOFF_FACTOR           (0.0f)

#define AL_MIN_CONE_OUTER_GAINHF                 (0.0f)
#define AL_MAX_CONE_OUTER_GAINHF                 (1.0f)
#define AL_DEFAULT_CONE_OUTER_GAINHF             (1.0f)

#define AL_MIN_DIRECT_FILTER_GAINHF_AUTO         AL_FALSE
#define AL_MAX_DIRECT_FILTER_GAINHF_AUTO         AL_TRUE
#define AL_DEFAULT_DIRECT_FILTER_GAINHF_AUTO     AL_TRUE

#define AL_MIN_AUXILIARY_SEND_FILTER_GAIN_AUTO   AL_FALSE
#define AL_MAX_AUXILIARY_SEND_FILTER_GAIN_AUTO   AL_TRUE
#define AL_DEFAULT_AUXILIARY_SEND_FILTER_GAIN_AUTO AL_TRUE

#define AL_MIN_AUXILIARY_SEND_FILTER_GAINHF_AUTO AL_FALSE
#define AL_MAX_AUXILIARY_SEND_FILTER_GAINHF_AUTO AL_TRUE
#define AL_DEFAULT_AUXILIARY_SEND_FILTER_GAINHF_AUTO AL_TRUE


/* Listener parameter value ranges and defaults. */
#define AL_MIN_METERS_PER_UNIT                   FLT_MIN
#define AL_MAX_METERS_PER_UNIT                   FLT_MAX
#define AL_DEFAULT_METERS_PER_UNIT               (1.0f)
}
(* Filters implementation is based on the "Cookbook formulae for audio
   EQ biquad filter coefficients" by Robert Bristow-Johnson
    http://www.musicdsp.org/files/Audio-EQ-Cookbook.txt                   *)

Type
  ALEffectType = (
    AudioEffect_REVERB,
    AudioEffect_AUTOWAH,
    AudioEffect_CHORUS,
    AudioEffect_COMPRESSOR,
    AudioEffect_DISTORTION,
    AudioEffect_ECHO,
    AudioEffect_EQUALIZER,
    AudioEffect_FLANGER,
    AudioEffect_MODULATOR,
    AudioEffect_DEDICATED
  );

  ALfilterType = (
    // EFX-style low-pass filter, specifying a gain and reference frequency.
    ALfilterType_HighShelf,
    // EFX-style high-pass filter, specifying a gain and reference frequency.
    ALfilterType_LowShelf,
    // Peaking filter, specifying a gain, reference frequency, and bandwidth.
    ALfilterType_Peaking,

    // Low-pass cut-off filter, specifying a cut-off frequency and bandwidth.
    ALfilterType_LowPass,
    // High-pass cut-off filter, specifying a cut-off frequency and bandwidth.
    ALfilterType_HighPass,
    // Band-pass filter, specifying a center frequency and bandwidth.
    ALfilterType_BandPass
  );

  AudioEffectBuffer = Record
    Samples:Array[0..Pred(MAX_OUTPUT_CHANNELS)] Of PSingleArray;
  End;

  AudioFilterState = Class(TERRAObject)
    Protected
      _x:Array[0..1] Of Single; // History of two last input samples
      _y:Array[0..1] Of Single; // History of two last output samples
      _a:Array[0..2] Of Single; // Transfer function coefficients "a"
      _b:Array[0..2] Of Single; // Transfer function coefficients "b"

    Public
      Procedure Process(dst, src:PSingleArray; numsamples:Cardinal); Virtual; Abstract;

      Procedure Clear(); Virtual; Abstract;

      Procedure setParams(FilterType:ALfilterType; gain, freq_mult, bandwidth:Single); Virtual; Abstract;

      Function processSingle(Const sample:Single):Single;
  End;


(*
typedef union ALeffectProps {
    struct {
        // Shared Reverb Properties
        ALfloat Density;
        ALfloat Diffusion;
        ALfloat Gain;
        ALfloat GainHF;
        ALfloat DecayTime;
        ALfloat DecayHFRatio;
        ALfloat ReflectionsGain;
        ALfloat ReflectionsDelay;
        ALfloat LateReverbGain;
        ALfloat LateReverbDelay;
        ALfloat AirAbsorptionGainHF;
        ALfloat RoomRolloffFactor;
        ALboolean DecayHFLimit;

        // Additional EAX Reverb Properties
        ALfloat GainLF;
        ALfloat DecayLFRatio;
        ALfloat ReflectionsPan[3];
        ALfloat LateReverbPan[3];
        ALfloat EchoTime;
        ALfloat EchoDepth;
        ALfloat ModulationTime;
        ALfloat ModulationDepth;
        ALfloat HFReference;
        ALfloat LFReference;
    } Reverb;

    struct {
        ALfloat AttackTime;
        ALfloat ReleaseTime;
        ALfloat PeakGain;
        ALfloat Resonance;
    } Autowah;

    struct {
        ALint Waveform;
        ALint Phase;
        ALfloat Rate;
        ALfloat Depth;
        ALfloat Feedback;
        ALfloat Delay;
    } Chorus;

    struct {
        ALboolean OnOff;
    } Compressor;

    struct {
        ALfloat Edge;
        ALfloat Gain;
        ALfloat LowpassCutoff;
        ALfloat EQCenter;
        ALfloat EQBandwidth;
    } Distortion;

    struct {
        ALfloat Delay;
        ALfloat LowCutoff;
        ALfloat LowGain;
        ALfloat Mid1Center;
        ALfloat Mid1Gain;
        ALfloat Mid1Width;
        ALfloat Mid2Center;
        ALfloat Mid2Gain;
        ALfloat Mid2Width;
        ALfloat HighCutoff;
        ALfloat HighGain;
    } Equalizer;

    struct {
        ALint Waveform;
        ALint Phase;
        ALfloat Rate;
        ALfloat Depth;
        ALfloat Feedback;
        ALfloat Delay;
    } Flanger;

    struct {
        ALfloat Frequency;
        ALfloat HighPassCutoff;
        ALint Waveform;
    } Modulator;

    struct {
        ALfloat Gain;
    } Dedicated;
} ALeffectProps;

*)

  AudioFilter = Class(TERRAObject)
    Protected
      _id:Cardinal;

      _EffectType:ALEffectType;
      //EffectProps:ALeffectProps;

      _Gain:Single;
      _AuxSendAuto:Boolean;

      _NeedsUpdate:Boolean;

      _WetBuffer:Array[0..Pred(BUFFERSIZE)] Of Single;
      ID:Integer;

      _Type:ALfilterType; // Filter type (AL_FILTER_NULL, ...)

      _GainHF:Single;
      _HFReference:Single;
      _GainLF:Single;
      _LFReference:Single;

    Public
      Procedure SetParami(param:Integer; Const val:Integer); Virtual; Abstract;
      Procedure SetParamiv(param:Integer; vals:PIntegerArray); Virtual; Abstract;
      Procedure SetParamf(param:Integer; Const val:Single); Virtual; Abstract;
      Procedure SetParamfv(param:Integer; vals:PSingleArray); Virtual; Abstract;

      Procedure GetParami(param:Integer; Out val:Integer); Virtual; Abstract;
      Procedure GetParamiv(param:Integer; vals:PIntegerArray); Virtual; Abstract;
      Procedure GetParamf(param:Integer; Out val:Single); Virtual; Abstract;
      Procedure GetParamfv(param:Integer; vals:PSingleArray); Virtual; Abstract;

      Function DeviceUpdate(Target:TERRAAudioBuffer):Boolean; Virtual; Abstract;
      Procedure Update(Target:TERRAAudioBuffer); Virtual; Abstract;
      Procedure Process(Target:TERRAAudioBuffer; samplesToDo:Integer; samplesIn:PSingleArray; Var samplesOut:AudioEffectBuffer; numChannels:Cardinal); Virtual; Abstract;

      Property Gain:Single Read _Gain;
  End;


Implementation

Function AudioFilterState.processSingle(Const sample:Single):Single;
Begin
  Result := _b[0] * sample + _b[1] * _x[0] + _b[2] * _x[1] -  _a[1] * _y[0] - _a[2] * _y[1];
  _x[1] := _x[0];
  _x[0] := Sample;
  _y[1] := _y[0];
  _y[0] := Result;
End;

//void ALfilterState_processC(ALfilterState *filter, ALfloat *restrict dst, const ALfloat *src, ALuint numsamples);


{struct ALfilter *LookupFilter(ALCdevice *device, ALuint id)
 return (struct ALfilter*)LookupUIntMapKey(&device->FilterMap, id);

inline struct ALfilter *RemoveFilter(ALCdevice *device, ALuint id)
 return (struct ALfilter*)RemoveUIntMapKey(&device->FilterMap, id);

}

End.
