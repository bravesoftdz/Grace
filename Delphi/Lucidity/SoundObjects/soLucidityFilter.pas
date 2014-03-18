unit soLucidityFilter;

interface

{$INCLUDE Defines.inc}

uses
  VamLib.Utils,
  VamLib.MoreTypes,
  uConstants,
  uLucidityEnums,
  Math,
  Lucidity.Types,
  eeVirtualCV,
  FilterCore.SimperSVF,
  soFilter.Test,
  soFilter.MoogLadder,
  soFilter.LofiA,
  soFilter.RingModA,
  soFilter.DistortionA,
  soFilter.CombA,
  soFilter.LowPassA,
  soFilter.LowPassB,
  soFilter.BandPassA,
  soFilter.HighPassA;

type
  TLucidityFilter = class
  private
    fSampleRate: single;
    fFilterType: TFilterType;
    fKeyFollow: single;

    procedure SetSampleRate(const Value: single);
    procedure SetFilterType(const Value: TFilterType);
    procedure SetKeyFollow(const Value: single);
  protected
    DistortionA : TDistortionA;
    RingModA    : TRingModA;
    LofiA       : TLofiA;
    CombA       : TCombA;
    LowPassA    : TLowPassA;
    BandPassA   : TBandPassA;
    HighPassA   : THighPassA;
    LowPassB    : TLowPassB;
    MoogLadder  : TMoogLadder;

    TestFilter : TTestFilter;

    ModuleIndex  : integer;
    ParValueData : PModulatedPars;     // Raw parameter values. The values are identical for all voices in the voice group.
    ParModData   : PParModulationData; // stores the summed modulation input for each parameter. (Most parameters will be zero)

    DummyModValue : single; //TODO: Delete this.

    VoiceModPoints : PVoiceModulationPoints;
  public
    constructor Create(const aVoiceModPoints : PVoiceModulationPoints);
    destructor Destroy; override;

    procedure Init(const aModuleIndex : integer; const aPars : PModulatedPars; const aModData : PParModulationData);

    function GetModPointer(const Name:string):PSingle;

    procedure Reset;

    property SampleRate : single read fSampleRate write SetSampleRate;

    procedure AudioRateStep(var x1, x2 : single); {$IFDEF AudioInline}inline;{$ENDIF}
    procedure FastControlProcess; {$IFDEF AudioInline}inline;{$ENDIF}
    procedure SlowControlProcess; {$IFDEF AudioInline}inline;{$ENDIF}

    //==== Parameters ====
    property FilterType : TFilterType read fFilterType write SetFilterType;
    property KeyFollow  : single      read fKeyFollow  write SetKeyFollow;  //range 0..1.


  end;

implementation

uses
  {$IFDEF Logging}SmartInspectLogging,{$ENDIF}
  eeDsp,
  SysUtils;

{ TLucidityFilter }

constructor TLucidityFilter.Create(const aVoiceModPoints : PVoiceModulationPoints);
begin
  VoiceModPoints := aVoiceModPoints;

  TestFilter := TTestFilter.Create;
  RingModA   := TRingModA.Create;
  DistortionA := TDistortionA.Create;
  LofiA       := TLofiA.Create;
  CombA       := TCombA.Create;
  LowPassA   := TLowPassA.Create;
  BandPassA  := TBandPassA.Create;
  HighPassA  := THighPassA.Create;
  LowPassB    := TLowPassB.Create;
  MoogLadder := TMoogLadder.Create;
end;

destructor TLucidityFilter.Destroy;
begin
  TestFilter.Free;
  LowPassA.Free;
  BandPassA.Free;
  HighPassA.Free;
  LofiA.Free;
  CombA.Free;
  RingModA.Free;
  DistortionA.Free;
  LowPassB.Free;
  MoogLadder.Free;
  inherited;
end;

procedure TLucidityFilter.Reset;
begin
  DistortionA.Reset;
  RingModA.Reset;
  LowPassA.Reset;
  LowPassB.Reset;
  BandPassA.Reset;
  HighPassA.Reset;
  MoogLadder.Reset;
end;

function TLucidityFilter.GetModPointer(const Name: string): PSingle;
begin
  if Name ='Par1Mod' then exit(@DummyModValue);
  if Name ='Par2Mod' then exit(@DummyModValue);  if Name ='Par3Mod' then exit(@DummyModValue);  if Name ='Par4Mod' then exit(@DummyModValue);
  raise Exception.Create('ModPointer (' + Name + ') doesn''t exist.');  result := nil;end;

procedure TLucidityFilter.Init(const aModuleIndex : integer; const aPars: PModulatedPars; const aModData: PParModulationData);
begin
  assert(ModuleIndex >= 0);
  assert(ModuleIndex <= 1);

  self.ModuleIndex   := aModuleIndex;
  self.ParValueData  := aPars;
  self.ParModData    := aModData;
end;

procedure TLucidityFilter.SetFilterType(const Value: TFilterType);
begin
  fFilterType := Value;

  LofiA.Reset;
  CombA.Reset;
  LowPassA.Reset;
  LowPassB.Reset;
  BandPassA.Reset;
  HighPassA.Reset;
  RingModA.Reset;
  DistortionA.Reset;
  MoogLadder.Reset;
end;

procedure TLucidityFilter.SetKeyFollow(const Value: single);
begin
  assert(Value >= 0);
  assert(Value <= 1);
  fKeyFollow := Value;
end;

procedure TLucidityFilter.SetSampleRate(const Value: single);
begin
  fSampleRate := Value;

  LowPassA.SampleRate := Value;
  LowPassB.SampleRate := Value;
  BandPassA.SampleRate := Value;
  HighPassA.SampleRate := Value;
  LofiA.SampleRate := Value;
  CombA.SampleRate := Value;
  RingModA.SampleRate := Value;
  DistortionA.SampleRate := Value;
  MoogLadder.SampleRate := value;
end;


procedure TLucidityFilter.FastControlProcess;
const
  kBaseFilterFreq = 4.0878994578;
  kMinFreq = 0.001;
  kMaxFreq = 18000;
  kMinQ = 0;
  kMaxQ = 0.98;
var
  cFreq : single;
  cQ    : single;
  CV    : single;

  //TODO: Delete these old Par1 and Par1Mod parameters.
  Par1 : single;
  Par2 : single;
  Par3 : single;
  Par4 : single;

  Par1Mod: single;
  Par2Mod: single;
  Par3Mod: single;
  Par4Mod: single;

  //TODO: The above parameters will be replaced with these 4.
  mPar1 : single;
  mPar2 : single;
  mPar3 : single;
  mPar4 : single;

  px1 : single;
  px2 : single;
  px3 : single;

  FreqMultFactor : single;
begin
  if ModuleIndex = 0 then
  begin
    Par1 := ParValueData^[TModParIndex.Filter1Par1].ParValue;
    Par2 := ParValueData^[TModParIndex.Filter1Par2].ParValue;
    Par3 := ParValueData^[TModParIndex.Filter1Par3].ParValue;
    Par4 := ParValueData^[TModParIndex.Filter1Par4].ParValue;

    Par1Mod := ParModData^[TModParIndex.Filter1Par1];
    Par2Mod := ParModData^[TModParIndex.Filter1Par2];
    Par3Mod := ParModData^[TModParIndex.Filter1Par3];
    Par4Mod := ParModData^[TModParIndex.Filter1Par4];

    mPar1 := ParValueData^[TModParIndex.Filter1Par1].ModulatedParValue;
    mPar2 := ParValueData^[TModParIndex.Filter1Par2].ModulatedParValue;
    mPar3 := ParValueData^[TModParIndex.Filter1Par3].ModulatedParValue;
    mPar4 := ParValueData^[TModParIndex.Filter1Par4].ModulatedParValue;
  end else
  begin
    Par1 := ParValueData^[TModParIndex.Filter2Par1].ParValue;
    Par2 := ParValueData^[TModParIndex.Filter2Par2].ParValue;
    Par3 := ParValueData^[TModParIndex.Filter2Par3].ParValue;
    Par4 := ParValueData^[TModParIndex.Filter2Par4].ParValue;

    Par1Mod := ParModData^[TModParIndex.Filter2Par1];
    Par2Mod := ParModData^[TModParIndex.Filter2Par2];
    Par3Mod := ParModData^[TModParIndex.Filter2Par3];
    Par4Mod := ParModData^[TModParIndex.Filter2Par4];

    mPar1 := ParValueData^[TModParIndex.Filter2Par1].ModulatedParValue;
    mPar2 := ParValueData^[TModParIndex.Filter2Par2].ModulatedParValue;
    mPar3 := ParValueData^[TModParIndex.Filter2Par3].ModulatedParValue;
    mPar4 := ParValueData^[TModParIndex.Filter2Par4].ModulatedParValue;
  end;

  FreqMultFactor := LinearInterpolation(1, VoiceModPoints^.KeyFollowFreqMultiplier, fKeyFollow);

  case FilterType of
    ftNone:
    begin
    end;

    ftLowPassA:
    begin
      CV := (Par1 * 15) + AudioRangeToModularVoltage(Par1Mod);
      cFreq := VoltsToFreq(kBaseFilterFreq, CV) * FreqMultFactor;
      cFreq := Clamp(cFreq, kMinFreq, kMaxFreq);

      cQ := (Par2 + Par2Mod) * 0.98;
      cQ := Clamp(cQ, kMinQ, kMaxQ);

      LowPassA.Freq := cFreq;
      LowPassA.Q    := cQ;
    end;

    ftBandPassA:
    begin
      CV := (Par1 * 15) + AudioRangeToModularVoltage(Par1Mod);
      cFreq := VoltsToFreq(kBaseFilterFreq, CV) * FreqMultFactor;
      cFreq := Clamp(cFreq, kMinFreq, kMaxFreq);

      cQ := (Par2 + Par2Mod) * 0.98;
      cQ := Clamp(cQ, kMinQ, kMaxQ);

      BandPassA.Freq := cFreq;
      BandPassA.Q    := cQ;
    end;

    ftHighPassA:
    begin
      CV := (Par1 * 15) + AudioRangeToModularVoltage(Par1Mod);
      cFreq := VoltsToFreq(kBaseFilterFreq, CV) * FreqMultFactor;
      cFreq := Clamp(cFreq, kMinFreq, kMaxFreq);

      cQ := (Par2 + Par2Mod) * 0.98;
      cQ := Clamp(cQ, kMinQ, kMaxQ);

      HighPassA.Freq := cFreq;
      HighPassA.Q    := cQ;
    end;

    ftLofiA:
    begin
      //==== Lofi A ====
      px1 := (Par1 + Par1Mod);
      px1 := Clamp(px1, 0, 1);
      LofiA.RateReduction := px1;

      px2 := Par2 + Par2Mod;
      px2 := clamp(px2, 0, 1);
      LofiA.BitReduction := px2;

      px3 := Par3 + Par3Mod;
      px3 := clamp(px3, 0, 1);
      LofiA.BitEmphasis := px3;
    end;

    ftRingModA:
    begin
      //==== Ring Mod A ====
      CV := (Par1 * 12) + AudioRangeToModularVoltage(Par1Mod);
      cFreq := VoltsToFreq(15, CV)  * FreqMultFactor;
      cFreq := Clamp(cFreq, 15, 18000);
      RingModA.OscFreq := cFreq;

      px2 := Par2 + Par2Mod;
      px2 := clamp(px2, 0, 1);
      RingModA.Depth := px2;
    end;


    {
    ftDistA:
    begin
      //==== Distortion A ====
      px1 := Par1 + Par1Mod;
      Clamp(px1, 0, 1);
      DistortionA.Par1 := px1;

      px2 := Par2 + Par2Mod;
      clamp(px2, 0, 1);
      DistortionA.Par2 := px2;

      px3 := Par3 + Par3Mod;
      clamp(px3, 0, 1);
      DistortionA.Par3 := px3;
    end;
    }

    ftCombA:
    begin
      //==== Comb A ====
      px1 := (Par1 + Par1Mod);
      px1 := Clamp(px1, 0, 1);
      CombA.Par1 := px1;

      px2 := Par2 + Par2Mod;
      px2 := clamp(px2, 0, 1);
      CombA.Par2 := px2;

      px3 := Par3 + Par3Mod;
      px3 := clamp(px3, 0, 1);
      CombA.Par3 := px3;
    end;

    ft2PoleLowPass,
    ft2PoleBandPass,
    ft2PoleHighPass,
    ft4PoleLowPass,
    ft4PoleBandPass,
    ft4PoleHighPass:
    begin
      CV := (Par1 * 15) + AudioRangeToModularVoltage(Par1Mod);
      cFreq := VoltsToFreq(kBaseFilterFreq, CV) * FreqMultFactor;
      cFreq := Clamp(cFreq, kMinFreq, kMaxFreq);

      cQ := (Par2 + Par2Mod);
      cQ := Clamp(cQ, kMinQ, kMaxQ);

      MoogLadder.Freq := cFreq;
      MoogLadder.Q    := cQ;
      MoogLadder.InputGain := DecibelsToLinear(mPar3 * 72 - 12);
    end;

  end;

end;

procedure TLucidityFilter.SlowControlProcess;
begin

end;

procedure TLucidityFilter.AudioRateStep(var x1, x2: single);
begin
  case FilterType of
    ftNone: ;
    ftLowPassA:  LowPassA.Step(x1, x2);
    ftBandPassA: BandPassA.Step(x1, x2);
    ftHighPassA: HighPassA.Step(x1, x2);
    ftLofiA:     LofiA.Step(x1, x2);
    ftRingModA:  RingModA.AudioRateStep(x1, x2);
    //ftDistA:     DistortionA.AudioRateStep(x1, x2);
    ftCombA:     CombA.AudioRateStep(x1, x2);
    ft2PoleLowPass:  MoogLadder.StepAs2PoleLP(x1, x2);
    ft2PoleBandPass: MoogLadder.StepAs2PoleBP(x1, x2);
    ft2PoleHighPass: MoogLadder.StepAs2PoleHP(x1, x2);
    ft4PoleLowPass:  MoogLadder.StepAs4PoleLP(x1, x2);
    ft4PoleBandPass: MoogLadder.StepAs4PoleBP(x1, x2);
    ft4PoleHighPass: MoogLadder.StepAs4PoleHP(x1, x2);
  else
    raise Exception.Create('Unexpected filter type.');
  end;
end;

end.
