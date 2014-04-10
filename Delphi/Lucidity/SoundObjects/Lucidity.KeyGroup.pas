unit Lucidity.KeyGroup;

interface

uses
  Lucidity.Types,
  VamGuiControlInterfaces,
  Lucidity.SequencerDataObject,
  LucidityGui.VectorSequence,
  Lucidity.Interfaces, LucidityModConnections,
  VamLib.MoreTypes, eeGlobals,
  eeVoiceLogic, eeVstParameter,
  eeVstParameterList, eePatchObject,
  uConstants,
  Lucidity.SampleMap,
  soLevelMeter,
  soLucidityVoice, soLucidityVoiceParameterWrapper,
  uModularConnectionManager,
  uLucidityStepSequencer,
  uGuiFeedbackData;

type
  // redeclare ISampleGroup for convenience.
  IKeyGroup = Lucidity.Interfaces.IKeyGroup;

type
  TKeyGroup = class;

  TKeyGroup = class(TInterfacedObject, IKeyGroup)
  private
    fTriggeredNoteCount : cardinal;
    fName     : string;
    fSampleMap: TSampleMap;
    fVoiceParameters: TLucidityVoiceParameterWrapper;
    fModConnections: TModConnections;
    fLevelMonitor: TLevelMonitor;

    function GetObject : TObject;
    function GetTriggeredNoteCount:cardinal;
    procedure IncTriggeredNoteCount;
    function GetModConnections:TModConnections;
    function GetModConnectionsPointer : PModConnections;
    function GetModulatedParameters : PModulatedPars;

    function GetSequenceData(SeqIndex : integer):IStepSequenceDataObject;

    procedure SampleRateChanged(Sender:TObject);
  protected
    FSeq1Data : TSequencerDataObject;
    FSeq2Data : TSequencerDataObject;
    Globals : TGlobals;
    GlobalModPoints : PGlobalModulationPoints;

    ModulatedParameters: TModulatedPars;

    function GetName:string;
    procedure SetName(Value : string);

    //TODO: Delete this.
    property SampleMap : TSampleMap read fSampleMap write fSampleMap;

    procedure Handle_ModConnectionsChanged(Sender : TObject);



  public
    constructor Create(const aVoices:PArrayOfLucidityVoice; const aGlobalModPoints : PGlobalModulationPoints; const aGlobals: TGlobals);
    destructor Destroy; override;
    procedure AssignFrom(const Source : TKeyGroup);

    procedure SetPatch(var Data:TPatchNode);
    procedure GetPatch(var Data:TPatchNode);

    function GetModParValue(const ModParIndex : integer):single;
    procedure SetModParValue(const ModParIndex : integer; const Value:single);
    procedure SetModParModAmount(const ModParIndex, ModSlot : integer; const Value:single);
    function GetModParModAmount(const ModParIndex, ModSlot : integer):single;
    procedure GetModParModMinMax(const ModParIndex : integer; out ModMin, ModMax:single);

    procedure GetGuiFeedBack(const FeedbackData:TGuiFeedBackData);
    procedure GetFilterInfo(const Info : PFilterParameterInfo);

    property VoiceParameters : TLucidityVoiceParameterWrapper read fVoiceParameters;
    property ModConnections  : TModConnections                read fModConnections;

    property Name : string read fName;

    property Seq1Data : TSequencerDataObject read FSeq1Data;
    property Seq2Data : TSequencerDataObject read FSeq1Data;

    property LevelMonitor     : TLevelMonitor            read fLevelMonitor     write fLevelMonitor;
  end;

implementation

uses
  SysUtils, eeCustomGlobals,
  uLucidityEnums;

{ TLucidityEngine }

constructor TKeyGroup.Create(const aVoices:PArrayOfLucidityVoice; const aGlobalModPoints : PGlobalModulationPoints; const aGlobals: TGlobals);
begin
  Globals := aGlobals;
  GlobalModPoints := aGlobalModPoints;
  Globals.AddEventListener(TPluginEvent.SampleRateChanged, SampleRateChanged);

  fModConnections := TModConnections.Create;
  fModConnections.OnChanged := Handle_ModConnectionsChanged;

  fVoiceParameters := TLucidityVoiceParameterWrapper.Create(aVoices, self);

  FSeq1Data := TSequencerDataObject.Create;
  FSeq2Data := TSequencerDataObject.Create;

  fTriggeredNoteCount := 0;

  fLevelMonitor := TLevelMonitor.Create;
end;

destructor TKeyGroup.Destroy;
begin
  FSeq1Data.Free;
  FSeq2Data.Free;
  fVoiceParameters.Free;
  fModConnections.Free;
  fLevelMonitor.Free;
  inherited;
end;

procedure TKeyGroup.AssignFrom(const Source: TKeyGroup);
begin
  self.VoiceParameters.AssignFrom(Source.VoiceParameters);
end;





procedure TKeyGroup.GetPatch(var Data: TPatchNode);
//var
//  ChildModule : TPatchNode;
begin
  //ChildModule := Data.NewChildNode('SampleMap');
  //SampleMap.GetPatchData(ChildModule);
end;


function TKeyGroup.GetTriggeredNoteCount: cardinal;
begin
  result := fTriggeredNoteCount;
end;

function TKeyGroup.GetSequenceData(SeqIndex: integer): IStepSequenceDataObject;
begin
  case SeqIndex of
    0: result := self.FSeq1Data;
    1: result := self.FSeq2Data;
  else
    raise Exception.Create('SeqIndex not handled.');
  end;
end;


procedure TKeyGroup.IncTriggeredNoteCount;
begin
  inc(fTriggeredNoteCount);
end;

procedure TKeyGroup.SetPatch(var Data: TPatchNode);
//var
//  ChildModule : TPatchNode;
begin
  //ChildModule := Data.FindChildNode('SampleMap');
  //if assigned(ChildModule) then SampleMap.SetPatchData(ChildModule);
end;



procedure TKeyGroup.GetFilterInfo(const Info: PFilterParameterInfo);
// TODO: it's possible that this method can be deleted.
  procedure GetFullName(const FilterType : TFilterType; ps1, ps2, ps3 : PString);
  begin
    case FilterType of
      ftNone:
      begin
        ps1^ := '-';
        ps2^ := '-';
        ps3^ := '-';
      end;

      ftLofiA:
      begin
        ps1^ := 'Sample Rate';
        ps2^ := 'Bit Depth';
        ps3^ := '';
      end;

      ftRingModA:
      begin
        ps1^ := 'Mod Freq';
        ps2^ := 'Mod Depth';
        ps3^ := '';
      end;

      {
      ftDistA:
      begin
        ps1^ := '';
        ps2^ := 'Input Gain';
        ps3^ := 'Output Gain';
      end;
      }
      ftCombA:
      begin
        ps1^ := 'Frequency';
        ps2^ := 'Feedback';
        ps3^ := '';
      end;

    else
      raise Exception.Create('Filter type not handled.');
    end;
  end;

  procedure GetShortName(const FilterType : TFilterType; ps1, ps2, ps3 : PString);
  begin
    case FilterType of
      ftNone:
      begin
        ps1^ := '';
        ps2^ := '';
        ps3^ := '';
      end;

      ftLofiA:
      begin
        ps1^ := 'SR';
        ps2^ := 'BITS';
        ps3^ := '';
      end;

      ftRingModA:
      begin
        ps1^ := 'HZ';
        ps2^ := 'AMT';
        ps3^ := '';
      end;

      {
      ftDistA:
      begin
        ps1^ := '';
        ps2^ := 'G1';
        ps3^ := 'G2';
      end;
      }
      ftCombA:
      begin
        ps1^ := 'HZ';
        ps2^ := 'FB';
        ps3^ := '';
      end;

    else
      raise Exception.Create('Filter type not handled.');
    end;

  end;
var
  ps1, ps2, ps3 : PString;
begin
  ps1 := @Info.Filter1Par1FullName;
  ps2 := @Info.Filter1Par2FullName;
  ps3 := @Info.Filter1Par3FullName;

  GetFullName(VoiceParameters.Filter1Type, ps1, ps2, ps3);

  ps1 := @Info.Filter1Par1ShortName;
  ps2 := @Info.Filter1Par2ShortName;
  ps3 := @Info.Filter1Par3ShortName;

  GetShortName(VoiceParameters.Filter1Type, ps1, ps2, ps3);

  ps1 := @Info.Filter2Par1FullName;
  ps2 := @Info.Filter2Par2FullName;
  ps3 := @Info.Filter2Par3FullName;

  GetFullName(VoiceParameters.Filter2Type, ps1, ps2, ps3);

  ps1 := @Info.Filter2Par1ShortName;
  ps2 := @Info.Filter2Par2ShortName;
  ps3 := @Info.Filter2Par3ShortName;

  GetShortName(VoiceParameters.Filter2Type, ps1, ps2, ps3);
end;

procedure TKeyGroup.GetGuiFeedBack(const FeedbackData: TGuiFeedBackData);
begin
end;

function TKeyGroup.GetModConnections: TModConnections;
begin
  result := fModConnections;
end;

function TKeyGroup.GetModConnectionsPointer: PModConnections;
begin
  result := @fModConnections;
end;

function TKeyGroup.GetModParValue(const ModParIndex: integer): single;
begin
  result := ModulatedParameters[ModParIndex].ParValue;
end;

function TKeyGroup.GetModulatedParameters: PModulatedPars;
begin
  result := @self.ModulatedParameters;
end;

procedure TKeyGroup.SetModParValue(const ModParIndex: integer; const Value: single);
begin
  ModulatedParameters[ModParIndex].ParValue := Value;
end;

procedure TKeyGroup.SampleRateChanged(Sender: TObject);
begin
  LevelMonitor.SampleRate := Globals.SampleRate
end;

procedure TKeyGroup.SetModParModAmount(const ModParIndex, ModSlot: integer; const Value: single);
var
  aMin, aMax : single;
  c1: Integer;
  tx : single;
begin
  ModulatedParameters[ModParIndex].ModAmount[ModSlot] := Value;
  if assigned(fVoiceParameters)
    then fVoiceParameters.UpdateModConnections;

  //==== Calculate the min/max modulation amounts =======
  aMin := 0;
  aMax := 0;
  for c1 := 0 to kModSlotCount-1 do
  begin
    tx := ModulatedParameters[ModParIndex].ModAmount[c1];
    if aMin > tx then aMin := tx;
    if aMax < tx then aMax := tx;
  end;

  ModulatedParameters[ModParIndex].ModMin := aMin;
  ModulatedParameters[ModParIndex].ModMax := aMax;
  //=====================================================
end;

function TKeyGroup.GetModParModAmount(const ModParIndex, ModSlot: integer): single;
begin
  result := ModulatedParameters[ModParIndex].ModAmount[ModSlot];
end;

procedure TKeyGroup.GetModParModMinMax(const ModParIndex : integer;  out ModMin, ModMax:single);
begin
  ModMin := ModulatedParameters[ModParIndex].ModMin;
  ModMax := ModulatedParameters[ModParIndex].ModMax;
end;

procedure TKeyGroup.SetName(Value: string);
begin
  fName := Value;
end;

function TKeyGroup.GetName: string;
begin
  result := fName;
end;

function TKeyGroup.GetObject: TObject;
begin
  result := self;
end;

procedure TKeyGroup.Handle_ModConnectionsChanged(Sender: TObject);
begin
  if assigned(fVoiceParameters)
    then fVoiceParameters.UpdateModConnections;
end;



end.