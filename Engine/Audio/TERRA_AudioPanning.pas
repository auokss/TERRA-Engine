Unit TERRA_AudioPanning;

Interface
Uses TERRA_AudioBuffer, TERRA_Vector3D;

Const
  MAX_OUTPUT_CHANNELS = 2;

Type
  AudioChannelGain = Array[0.. Pred(MAX_OUTPUT_CHANNELS)] Of Single;

Procedure ComputeDirectionalGains(Target:TERRAAudioBuffer; dir:Vector3D; ingain:Single; Out gains:AudioChannelGain);

Implementation

// The maximum number of Ambisonics coefficients. For a given order (o), the  size needed will be (o+1)**2, thus zero-order has 1, first-order has 4,  second-order has 9, and third-order has 16.
Const
  MAX_AMBI_COEFFS = 16;

Type
  AudioChannelConfig = Array[0..Pred(MAX_AMBI_COEFFS)] Of Single;

Var
  AmbiCoeffs:Array[0..Pred(MAX_OUTPUT_CHANNELS)] Of AudioChannelConfig;


Procedure ComputeDirectionalGains(Target:TERRAAudioBuffer; dir:Vector3D; ingain:Single; Out gains:AudioChannelGain);
Var
  i, j:Integer;
  coeffs:Array[0..Pred(MAX_AMBI_COEFFS)] Of Single;
  x, y, z:Single;
  gain:Single;
Begin
  // Convert from OpenAL coords to Ambisonics.
  x := -dir.Z;
  y := -dir.X;
  z := dir.Y;

  // Zeroth-order
  coeffs[0] := 0.7071; // W = sqrt(1.0 / 2.0)

  // First-order
  coeffs[1] := y; // Y = Y
  coeffs[2] := z; // Z = Z
  coeffs[3] := x; // X = X

  // Second-order
  coeffs[4] := 2.0 * x * y;             // V = 2*X*Y
  coeffs[5] := 2.0 * y * z;             // T = 2*Y*Z
  coeffs[6] := 0.5 * (3.0 *z*z - 1.0);  // R = 0.5 * (3*Z*Z - 1)
  coeffs[7] := 2.0 * z * x;             // S = 2*Z*X
  coeffs[8] := x*x - y*y;               // U = X*X - Y*Y

  // Third-order
  coeffs[9] := y * (3.0*x*x - y*y);             // Q = Y * (3*X*X - Y*Y)
  coeffs[10] := 5.1962 * x * y * z;             // O = sqrt(27) * X * Y * Z 
  coeffs[11] := 0.7262 * y * (5.0*z*z - 1.0); // M = sqrt(135.0 / 256.0) * Y * (5*Z*Z - 1)
  coeffs[12] := 0.5 * z * (5.0*z*z - 3.0);    // K = 0.5 * Z * (5*Z*Z - 3)
  coeffs[13] := 0.7262 * x * (5.0*z*z - 1.0); // L = sqrt(135.0 / 256.0) * X * (5*Z*Z - 1)
  coeffs[14] := 2.5981 * z * (x*x - y*y);       // N = sqrt(27.0 / 4.0) * Z * (X*X - Y*Y)
  coeffs[15] := x * (x*x - 3.0*y*y);            // P = X * (X*X - 3*Y*Y)

  For I:=0 To Pred(MAX_OUTPUT_CHANNELS) Do
  Begin
    gain := 0.0;
    For J:=0 To Pred(MAX_AMBI_COEFFS) Do
      gain := gain +  AmbiCoeffs[i, j] *coeffs[j];

    gains[I] := gain * ingain;
  End;
End;

End.