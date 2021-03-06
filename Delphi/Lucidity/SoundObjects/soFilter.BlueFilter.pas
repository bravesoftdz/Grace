unit soFilter.BlueFilter;

interface

uses
  Lucidity.Dsp,
  eeDsp,
  eeFastCode,
  FilterCore.SimperSVF;

type
  TBlueFilter = class
  private
    fSampleRate: single;
    fFreq: single;
    fInputGain: single;
    fMix: single;
    procedure SetMix(const Value: single);
  protected
    MixWet, MixDry : single;
    GainIn  : double;
    GainOut : double;
    FilterData1 : TDualSimperSVFData;
    FilterData2 : TDualSimperSVFData;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Reset;
    procedure Step(var x1, x2 : single); inline;

    procedure StepAsLowpass2P(var x1, x2 : single); inline;
    procedure StepAsBandpass2P(var x1, x2 : single); inline;
    procedure StepAsHighpass2P(var x1, x2 : single); inline;

    procedure StepAsLowpass4P(var x1, x2 : single); inline;
    procedure StepAsBandpass4P(var x1, x2 : single); inline;
    procedure StepAsHighpass4P(var x1, x2 : single); inline;

    // Freq range 10?..1/4 Nyquist?
    // Q range 0..1
    // Input gain...
    procedure UpdateParameters(const Freq, Q, InputGain : single);

    property SampleRate : single read fSampleRate write fSampleRate;

    property InputGain : single read fInputGain write fInputGain;
    property Mix : single read fMix write SetMix;
  end;

implementation

uses
  Math;

{ TLowPassA }

constructor TBlueFilter.Create;
begin
  Mix := 1;
end;

destructor TBlueFilter.Destroy;
begin
  inherited;
end;


procedure TBlueFilter.Reset;
begin
  FilterData1.Reset;
  FilterData2.Reset;
end;

procedure TBlueFilter.SetMix(const Value: single);
begin
  assert(Value >= 0);
  assert(Value <= 1);
  fMix := Value;
  ComputeMixBalance(Value, MixDry, MixWet);
end;

procedure TBlueFilter.Step(var x1, x2: single);
begin
  FilterData1.Input[0] := x1 * GainIn + kDenormal;
  FilterData1.Input[1] := x2 * GainIn + kDenormal;

  TSimperVCF.StepAsLowPass(FilterData1);

  FilterData2.Input[0] := FilterData1.Ouput[0] + kDenormal;
  FilterData2.Input[1] := FilterData1.Ouput[1] + kDenormal;

  TSimperVCF.StepAsLowPass(FilterData2);

  x1 := (MixDry * x1) + (MixWet * FilterData2.Ouput[0] * GainOut);
  x2 := (MixDry * x2) + (MixWet * FilterData2.Ouput[1] * GainOut);
end;

procedure TBlueFilter.StepAsLowpass2P(var x1, x2: single);
begin
  FilterData1.Input[0] := x1 * GainIn + kDenormal;
  FilterData1.Input[1] := x2 * GainIn  + kDenormal;

  TSimperVCF.StepAsLowPass(FilterData1);

  x1 := (MixDry * x1) + (MixWet * FilterData1.Ouput[0] * GainOut);
  x2 := (MixDry * x2) + (MixWet * FilterData1.Ouput[1] * GainOut);
end;

procedure TBlueFilter.StepAsBandpass2P(var x1, x2: single);
begin
  FilterData1.Input[0] := x1 * GainIn + kDenormal;
  FilterData1.Input[1] := x2 * GainIn + kDenormal;

  TSimperVCF.StepAsBandPass(FilterData1);

  x1 := (MixDry * x1) + (MixWet * FilterData1.Ouput[0] * GainOut);
  x2 := (MixDry * x2) + (MixWet * FilterData1.Ouput[1] * GainOut);
end;

procedure TBlueFilter.StepAsHighpass2P(var x1, x2: single);
begin
  FilterData1.Input[0] := x1 * GainIn + kDenormal;
  FilterData1.Input[1] := x2 * GainIn  + kDenormal;

  TSimperVCF.StepAsHighPass(FilterData1);

  x1 := (MixDry * x1) + (MixWet * FilterData1.Ouput[0] * GainOut);
  x2 := (MixDry * x2) + (MixWet * FilterData1.Ouput[1] * GainOut);
end;


procedure TBlueFilter.StepAsLowpass4P(var x1, x2: single);
begin
  FilterData1.Input[0] := x1 * GainIn + kDenormal;
  FilterData1.Input[1] := x2 * GainIn + kDenormal;

  TSimperVCF.StepAsLowPass(FilterData1);

  FilterData2.Input[0] := FilterData1.Ouput[0] + kDenormal;
  FilterData2.Input[1] := FilterData1.Ouput[1] + kDenormal;

  TSimperVCF.StepAsLowPass(FilterData2);

  x1 := (MixDry * x1) + (MixWet * FilterData2.Ouput[0] * GainOut);
  x2 := (MixDry * x2) + (MixWet * FilterData2.Ouput[1] * GainOut);
end;

procedure TBlueFilter.StepAsBandpass4P(var x1, x2: single);
begin
  FilterData1.Input[0] := x1 * GainIn + kDenormal;
  FilterData1.Input[1] := x2 * GainIn + kDenormal;

  TSimperVCF.StepAsBandPass(FilterData1);

  FilterData2.Input[0] := FilterData1.Ouput[0] + kDenormal;
  FilterData2.Input[1] := FilterData1.Ouput[1] + kDenormal;

  TSimperVCF.StepAsBandPass(FilterData2);

  x1 := (MixDry * x1) + (MixWet * FilterData2.Ouput[0] * GainOut);
  x2 := (MixDry * x2) + (MixWet * FilterData2.Ouput[1] * GainOut);
end;

procedure TBlueFilter.StepAsHighpass4P(var x1, x2: single);
begin
  FilterData1.Input[0] := x1 * GainIn + kDenormal;
  FilterData1.Input[1] := x2 * GainIn + kDenormal;

  TSimperVCF.StepAsHighPass(FilterData1);

  FilterData2.Input[0] := FilterData1.Ouput[0] + kDenormal;
  FilterData2.Input[1] := FilterData1.Ouput[1] + kDenormal;

  TSimperVCF.StepAsHighPass(FilterData2);

  x1 := (MixDry * x1) + (MixWet * FilterData2.Ouput[0] * GainOut);
  x2 := (MixDry * x2) + (MixWet * FilterData2.Ouput[1] * GainOut);
end;

procedure TBlueFilter.UpdateParameters(const Freq, Q, InputGain: single);
var
  G : single;
  K : single;
begin
  fFreq := Freq;

  //g := tan (pi * Value / samplerate);
  G := Fast_Tan0(pi * Freq / samplerate);

  //Damping factor range is 2..0.    0 = self oscillation.
  K := 2 - (Q * 2);

  FilterData1.SetGK(G, K);
  FilterData2.SetGK(G, K);

  GainIn  := 1 * (1 + (InputGain * 12));
  GainOut := 1 / (1 + (InputGain * 5));
end;

end.
