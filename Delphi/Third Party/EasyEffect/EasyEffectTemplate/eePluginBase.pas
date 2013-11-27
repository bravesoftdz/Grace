unit eePluginBase;

interface

{$INCLUDE Defines.inc}

uses
  eeSyncObjects,
  eeTypes, eeMidiEvents, eePluginSettings,
  eeVstMidiTypes, eeBufferedEventList,
  Classes, MoreTypes, eeGlobals;

  {$IFDEF VER230}
  {$ELSE}
  {$ENDIF}

type
  TResizeGUIWindowEvent = procedure(Sender:TObject; Width, Height:integer; var Allowed:boolean) of object;

  TeePluginBase = class
  private
    fInputCount: integer;
    fOutputCount: integer;
    fPresetName: string;
    fChangeInputCountFunction: TChangePinCountFunction;
    fChangeOutputCountFunction: TChangePinCountFunction;
    fDefaultInputCount: integer;
    fDefaultOutputCount: integer;
    fSetParameter: TSetParameterProcedure;
    fSetParameterAutomated: TSetParameterProcedure;
    fIsGuiOpen: boolean;
    fIsSuspended:boolean;

    BufferedEventList:TBufferedEventList;
    fOnResizeGuiWindow: TResizeGuiWindowEvent;
    fHostPlayState: THostPlayState;
    fAudioEffect: TVstAudioEffect;
    fOnPresetNameChanged: TNotifyEvent;

    function GetSettings: TeePluginSettings;
    procedure SetPresetName(const Value: string);
  protected
    fGlobals:TGlobals;

    procedure SetInitialInputCount(const Value: integer);
    procedure SetInitialOutputCount(const Value: integer);

    procedure SetHostPlayState(const Value: THostPlayState); virtual;
  public
    Inputs  : TArrayOfPSingle;
    Outputs : TArrayOfPSingle;

    constructor Create; virtual;
	  destructor Destroy; override;

      //Not all plugin hosts support changing the input/output configuration once
      //the plugin has been constructed. In these cases the functions will fail and return the current number of inputs/outputs.
    function ChangeInputCount(NewInputCount:integer):integer;
    function ChangeOutputCount(NewOutputCount:integer):integer;

    procedure GetInputPinProperties (Index:integer; Pin:PPinProperties); virtual;
    procedure GetOutputPinProperties(Index:integer; Pin:PPinProperties); virtual;


    //==========================================================================
    // TODO
    // These methods are analogs for the similarly named methods in the VST
    // protocol. GetParameter(), GetParameterName() etc. are all
    // called  by the VST Adapter. These methods in turn find the
    // results in the Globals.VstParameters lists.
    // Now that Globals.VstParameters is a standard part of the EasyEffect
    // template, these intermediate methods could be removed.
    // The VST Adapter class could pull the required information from
    // Globals.VstParameters directly.
    function GetParameter(Index:integer):single; virtual;
    procedure ParameterChanged(Index:integer; Value:single); virtual;

    function GetParameterName(Index : integer):string; virtual;
    function GetParameterDisplay(Index : integer):string; virtual;
    function GetParameterLabel(Index : integer):string; virtual;
    //==========================================================================

    procedure SetBypass(IsBypassActive:boolean); virtual;

    procedure ProcessMidiEvent(Event:TeeMidiEvent); virtual;
    procedure AudioProcess(Sampleframes:integer); virtual; // processes audio.
    procedure FastControlProcess; virtual; abstract;       // processes fast modulation here. (high bandwidth modulation)
    procedure SlowControlProcess; virtual; abstract;       // processes slow modulation here. (low bandwidth modulation

    procedure SetPreset(var ms:TMemoryStream); virtual;
    procedure GetPreset(var ms:TMemoryStream); virtual;

    procedure InitializeState; virtual;

    procedure Suspend; virtual;
    procedure Resume; virtual;

    // Plugins can call ResizeGuiWindow to resize the GUI window, if it returns true, the request is
    // succesful. Not all hosts allow the window to be changed.
    function ResizeGuiWindow(Width, Height:integer):boolean;

    property InputCount  : integer read fInputCount;
    property OutputCount : integer read fOutputCount;

    property PresetName:string read fPresetName write SetPresetName;

    property Globals:TGlobals  read fGlobals write fGlobals;

    property Settings:TeePluginSettings read GetSettings;

    //Plugin Wrapper needs to set these properties so the plugin knows about it's enviroment.
    property IsGuiOpen:boolean read fIsGuiOpen write fIsGuiOpen;
    property HostPlayState:THostPlayState read fHostPlayState write SetHostPlayState;  //Depreciated.

      //These function pointers allow the plugin to access methods in the plugin wrapper.
    property SetParameter:TSetParameterProcedure read fSetParameter write fSetParameter;
    property SetParameterAutomated:TSetParameterProcedure read fSetParameterAutomated write fSetParameterAutomated;

    property ChangeInputCountFunction:TChangePinCountFunction read fChangeInputCountFunction write fChangeInputCountFunction;
    property ChangeOutputCountFunction:TChangePinCountFunction read fChangeOutputCountFunction write fChangeOutputCountFunction;

    property IsSuspended:boolean read fIsSuspended;

    //The plugin wrapper should handle to OnResizeGuiWindow events.
    property OnResizeGuiWindow:TResizeGuiWindowEvent read fOnResizeGuiWindow write fOnResizeGuiWindow;

    property AudioEffect:TVstAudioEffect read fAudioEffect write fAudioEffect;


    property OnPresetNameChanged : TNotifyEvent read fOnPresetNameChanged write fOnPresetNameChanged;
  end;

implementation

uses
  {$IFDEF VER230}
    Vcl.Dialogs,
  {$ELSE}
    Dialogs,
  {$ENDIF}
  Math,
  eeDsp,
  SysUtils, uConstants;




{ TeePluginBase }


constructor TeePluginBase.Create;
begin
  Globals     := TGlobals.Create;

  AudioEffect := TVstAudioEffect.Create;

  fIsSuspended := true;

  IsGuiOpen    := false;

  //Setup input/output pointers.
  SetInitialInputCount(Settings.InitialInputCount);
  SetInitialOutputCount(Settings.InitialOutputCount);

  PresetName := 'Default';
end;

destructor TeePluginBase.Destroy;
begin
  SetLength(Inputs,0);
  SetLength(Outputs,0);

  Globals.Free;
  AudioEffect.Free;
  inherited;
end;

procedure TeePluginBase.InitializeState;
begin

end;

//--------------------------------------------------------------
//   Getter/Setter methods.
//--------------------------------------------------------------
procedure TeePluginBase.SetBypass(IsBypassActive: boolean);
begin

end;

procedure TeePluginBase.SetHostPlayState(const Value: THostPlayState);
begin
  fHostPlayState := Value;
end;

procedure TeePluginBase.SetInitialInputCount(const Value: integer);
begin
  fDefaultInputCount := Value;
  fInputCount := Value;
  SetLength(Inputs,fInputCount);
end;

procedure TeePluginBase.SetInitialOutputCount(const Value: integer);
begin
  fDefaultOutputCount := Value;
  fOutputCount := Value;
  SetLength(Outputs,fOutputCount);
end;

function TeePluginBase.GetParameter(Index: integer): single;
begin
  //result := Globals.VstParameters[Index].ValueVST;
  result := Globals.VstParameters.PublishedParameter(Index).ValueVST;
end;

function TeePluginBase.GetParameterName(Index: integer): string;
begin
  //result := Globals.VstParameters[Index].ShortName;
  result := Globals.VstParameters.PublishedParameter(Index).ShortName;
end;

function TeePluginBase.GetParameterDisplay(Index: integer): string;
begin
  //TODO:
  result := '';
end;

function TeePluginBase.GetParameterLabel(Index: integer): string;
begin
  //result := Globals.VstParameters[Index].Units;
  result := Globals.VstParameters.PublishedParameter(Index).ShortName;
end;

//--------------------------------------------------------------
//   Input output methods.
//--------------------------------------------------------------

procedure TeePluginBase.GetInputPinProperties(Index: integer;
  Pin: PPinProperties);
begin
  Pin^.Name := 'Input ' + IntToStr(Index div 2);
  Pin^.ShortName := 'In ' + IntToStr(Index div 2);
  Pin^.IsStereo := true;
end;

procedure TeePluginBase.GetOutputPinProperties(Index: integer; Pin: PPinProperties);
begin
  Pin^.Name := 'Output ' + IntToStr(Index div 2);
  Pin^.ShortName := 'Out ' + IntToStr(Index div 2);
  Pin^.IsStereo := true;
end;




function TeePluginBase.ChangeInputCount(NewInputCount: integer): integer;
begin
  //TODO: There needs to be a critical section here to ensure the plugin isn't
  //currently processing.

  if assigned(fChangeInputCountFunction) then
  begin
    fInputCount := ChangeInputCountFunction(NewInputCount);
    SetLength(Inputs,fInputCount);
    result := InputCount;
  end else
  begin
    assert(false, 'Input Count function not assigned');
    result := InputCount;
  end;

end;

function TeePluginBase.ChangeOutputCount(NewOutputCount: integer): integer;
begin
  //TODO: There needs to be a critical section here to ensure the plugin isn't
  //currently processing.

  if assigned(fChangeOutputCountFunction) then
  begin
    fOutputCount := ChangeOutputCountFunction(NewOutputCount);
    SetLength(Outputs,fOutputCount);
    result := OutputCount;
  end else
  begin
    assert(false, 'Output Count function not assigned');
    result := OutputCount;
  end;
end;

procedure TeePluginBase.GetPreset(var ms: TMemoryStream);
begin
end;

procedure TeePluginBase.SetPresetName(const Value: string);
begin
  fPresetName := Value;

  if assigned(OnPresetNameChanged) then OnPresetNameChanged(self);
end;

function TeePluginBase.GetSettings: TeePluginSettings;
begin
  //PluginInfo is a global variable that is automatically created.
  result := PluginInfo;
end;

procedure TeePluginBase.SetPreset(var ms: TMemoryStream);
begin

end;


procedure TeePluginBase.Suspend;
begin
  fIsSuspended := true;
end;


function TeePluginBase.ResizeGuiWindow(Width, Height: integer): boolean;
var
  Allowed:boolean;
begin
  Allowed := false;

  if assigned(OnResizeGuiWindow) then OnResizeGuiWindow(Self, Width,  Height, Allowed);

  result := Allowed;
end;

procedure TeePluginBase.Resume;
begin
  //The plugin may check for changed sample rate or block size parameters here.
  fIsSuspended := false;
end;

//--------------------------------------------------------
//   Process methods.
//--------------------------------------------------------
procedure TeePluginBase.ProcessMidiEvent(Event: TeeMidiEvent);
begin

end;

procedure TeePluginBase.ParameterChanged(Index: integer; Value: single);
begin
  assert(Value >= 0);
  assert(Value <= 1);

  assert(Index >=0 );
  assert(Index < Globals.VstParameters.PublishedParameterCount);

  //Globals.VstParameters[Index].ValueVST := Value;
  Globals.VstParameters.PublishedParameter(Index).ValueVST := Value;
end;

procedure TeePluginBase.AudioProcess(Sampleframes: integer);
begin
end;

//--------------------------------------------------------
//   Additional Methods.
//--------------------------------------------------------








end.
