unit soLfo.SlopeGen;

interface

{$INCLUDE Defines.inc}
{$EXCESSPRECISION OFF}
{$SCOPEDENUMS ON}

//TODO:
// The slope gen needs to know when the note-off event occurs!

uses
  Math,
  VamLib.Utils,
  B2.Filter.CriticallyDampedLowpass,
  eeOscPhaseCounter,
  eeDsp;

type
  TSlopeMode = (AR, AD, Cycle);

  TSlopeGen = class
  private
    fSampleRate: single;
    fBpm: single;
    fCurve: single;
    fSlopeMode: TSlopeMode;
    fMinTotalTime: single;
    fEnvRate: single;
    fBias: single;
    procedure SetSampleRate(const Value: single);
    procedure SetMinTotalTime(const Value: single);
    procedure SetEnvRate(const Value: single);
    procedure SetBias(const Value: single);
    procedure SetCurve(const Value: single);

  protected type
    TEnvStage = (Attack, Sustrain, Release, Off);
  protected
    EnvStage : TEnvStage;

    CurrentValue   : single;
    AttackStepSize : single;
    DecayStepSize  : single;

    CurveFactor : single;


    procedure UpdateEnvStepSizes; {$IFDEF AudioInline}inline;{$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;

    procedure Trigger;
    procedure Release;
    procedure Kill;

    function Step(out CycleEnd : boolean): single; overload; {$IFDEF AudioInline}inline;{$ENDIF}
    function Step: single; overload; {$IFDEF AudioInline}inline;{$ENDIF}

    property Bpm          : single read fBpm           write fBpm;
    property SampleRate   : single read fSampleRate    write SetSampleRate;

    // MinTotalTime is used as a reference when calculating how fast any RATE value is.
    property MinTotalTime : single read fMinTotalTime  write SetMinTotalTime;  //milliseconds.
    property EnvRate      : single read fEnvRate       write SetEnvRate; // range 0..1
    property Bias         : single read fBias          write SetBias;    // range 0..1
    property Curve        : single read fCurve         write SetCurve;         // Envelope curve. 0..1 range. 0.5 is a straight line.


    property SlopeMode : TSlopeMode read fSlopeMode    write fSlopeMode;

  end;

implementation

uses
  SysUtils;

{ TSlopeGen }

constructor TSlopeGen.Create;
begin
  CurrentValue   := 0;
  AttackStepSize := 0;
  DecayStepSize  := 0;
end;

destructor TSlopeGen.Destroy;
begin

  inherited;
end;

procedure TSlopeGen.Kill;
begin
  CurrentValue := 0;
end;

procedure TSlopeGen.UpdateEnvStepSizes;
var
  TotalTime : single;
  AttackTime : single;
  DecayTime  : single;
  ModBias : single;
begin
  if fEnvRate >= 0.01 then
  begin
    TotalTime := fMinTotalTime / fEnvRate;
    TotalTime := TotalTime;
    assert(TotalTime > 0, 'Total Time is smaller than zero!');

    ModBias := Bias * 0.8 + 0.1;

    AttackTime := TotalTime * ModBias;
    DecayTime  := TotalTime * (1 - ModBias);

    AttackStepSize := 1 / (fSampleRate * AttackTime * 0.001);
    DecayStepSize  := 1 / (fSampleRate * DecayTime * 0.001);

    assert(AttackStepSize <= 1, 'Slope Step Size is larger than 1.');
    assert(DecayStepSize <= 1, 'Slope Step Size is larger than 1.');
  end else
  begin
    AttackStepSize := 0;
    DecayStepSize  := 0;
  end;
end;

procedure TSlopeGen.SetBias(const Value: single);
begin
  fBias := Value;
  UpdateEnvStepSizes;
end;

procedure TSlopeGen.SetCurve(const Value: single);
var
  ValueMod : single;
begin
  assert(Value >= 0);
  assert(Value <= 1);
  fCurve := Value;

  // Fast Curve Code.
  // kvr DSP forum - topic "Help required to optimize code"
  ValueMod := Value * 0.8 + 0.1;
  CurveFactor := 1-(1/ValueMod);
end;

procedure TSlopeGen.SetEnvRate(const Value: single);
begin
  fEnvRate := Value;
  UpdateEnvStepSizes;
end;

procedure TSlopeGen.SetMinTotalTime(const Value: single);
begin
  fMinTotalTime := Value;
  UpdateEnvStepSizes;
end;

procedure TSlopeGen.SetSampleRate(const Value: single);
begin
  fSampleRate := value;
end;

procedure TSlopeGen.Trigger;
begin
  EnvStage := TEnvStage.Attack;
end;

procedure TSlopeGen.Release;
begin
  if SlopeMode = TSlopeMode.AR
    then EnvStage := TEnvStage.Release;
end;



function TSlopeGen.Step: single;
var
  x : boolean;
begin
  result := Step(x);
end;

function TSlopeGen.Step(out CycleEnd: boolean): single;
begin
  CycleEnd := false;

  case EnvStage of
    TSlopeGen.TEnvStage.Attack:
    begin
      CurrentValue := CurrentValue + AttackStepSize;
      if CurrentValue >= 1 then
      begin
        CurrentValue := 1;
        if SlopeMode = TSlopeMode.AR
          then EnvStage := TEnvStage.Sustrain
          else EnvStage := TEnvStage.Release;
      end;
    end;

    TSlopeGen.TEnvStage.Sustrain:
    begin

    end;

    TSlopeGen.TEnvStage.Release:
    begin
      CurrentValue := CurrentValue - DecayStepSize;
      if CurrentValue <= 0 then
      begin
        CurrentValue := 0;
        if SlopeMode = TSlopeMode.Cycle
          then EnvStage := TEnvStage.Attack
          else EnvStage := TEnvStage.Off;
      end;
    end;

    TSlopeGen.TEnvStage.Off:
    begin

    end;
  else
    raise Exception.Create('Type not handled.');
  end;


  //result := CurrentValue;
  result := CurrentValue / (CurrentValue + CurveFactor * (CurrentValue-1));
end;





end.
