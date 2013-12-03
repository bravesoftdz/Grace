{
  A unit to catch assorted GUI related methods that are shared between the Lucidity GUI units.
}

unit uGuiUtils;

interface

uses
  Dialogs, uSampleMap, eePlugin, uLucidityEnums,
  eeGlobals, VamLabel, VamTextBox, eeEnumHelper, VamWinControl, RedFoxContainer, VamPanel,
  Controls;

procedure UpdateTextBoxWithParValue(const TextBox : TVamLabel; const ParIndex:integer; const EnumHelper:TCustomEnumHelperClass; const Globals : TGlobals); overload;
procedure UpdateTextBoxWithParValue(const TextBox : TVamTextBox; const ParIndex:integer; const EnumHelper:TCustomEnumHelperClass; const Globals : TGlobals); overload;

type
  TZoomPos = record
    Zoom : single;    // range 0..1 (min zoom -> max zoom)
    Offset : single;  // range 0..1
    IndexA : single;  // range 0..1
    IndexB : single;  // range 0..1
  end;

procedure CalcZoomOffset(const IndexA, IndexB : single; const SampleFrames, DisplayPixelWidth : integer; out Zoom, Offset : single);
procedure CalcZoomBounds(const Zoom, Offset : single; const SampleFrames, DisplayPixelWidth : integer; out IndexA, IndexB:single);
function CalcZoomPos(const SampleFrames, DisplayPixelWidth, TargetSamplePos : integer):TZoomPos;

procedure ClearPadding(aControl : TVamWinControl); overload;
procedure ClearPadding(aControl : TRedFoxContainer); overload;


type
  TRegionDisplayResult = record
    Region : IRegion;
    Message : string;
  end;

function FindRegionToDisplay(const Plugin : TeePlugin):TRegionDisplayResult;

function ShowLoopMarkers(const aRegion : IRegion):boolean;

procedure SpreadControls_Horz(Controls:TArray<TControl>; const Parent : TWinControl);

procedure UpdateFilterControls(var Knobs : array of TControl; var Labels : array of TControl; const FilterType : TFilterType);



type
  TDialogTarget = (dtLucidityProgram, dtSfzProgram);

procedure SetupFileSaveDialog_Program(var SaveDialog : TFileSaveDialog);
procedure SetupFileOpenDialog_Program(var OpenDialog : TFileOpenDialog);

procedure SetupFileOpenDialog(var OpenDialog : TFileOpenDialog; const Target : TDialogTarget);


implementation

uses
  VamKnob,
  GuidEx,
  LucidityGlobals,
  uLucidityKeyGroup,
  SysUtils;


procedure UpdateTextBoxWithParValue(const TextBox : TVamLabel; const ParIndex:integer; const EnumHelper:TCustomEnumHelperClass; const Globals : TGlobals);
var
  x1 : single;
  s  : string;
begin
  x1 := Globals.VstParameters[ParIndex].ValueVST;
  s  := EnumHelper.ToShortGuiString(x1);
  if TextBox.Text <> s then TextBox.Text := s;
end;

procedure UpdateTextBoxWithParValue(const TextBox : TVamTextBox; const ParIndex:integer; const EnumHelper:TCustomEnumHelperClass; const Globals : TGlobals); overload;
var
  x1 : single;
  s  : string;
begin
  x1 := Globals.VstParameters[ParIndex].ValueVST;
  s  := EnumHelper.ToShortGuiString(x1);
  if TextBox.Text <> s then TextBox.Text := s;
end;

procedure CalcZoomOffset(const IndexA, IndexB : single; const SampleFrames, DisplayPixelWidth : integer; out Zoom, Offset : single);
var
  DivFactor : single;
begin
  //check entry conditions
  assert(IndexB >= IndexA);
  assert(IndexA >= 0);
  assert(IndexA <= 1);
  assert(IndexB >= 0);
  assert(IndexB <= 1);

  Zoom := 1 - (IndexB - IndexA);

  DivFactor := (1 - (IndexB - IndexA));

  if (DivFactor = 0)
    then Offset := 0
    else Offset := IndexA / DivFactor;

  //Check exit conditions
  assert(Zoom >= 0);
  assert(Zoom <= 1);
  assert(Offset >= 0);
  assert(Offset <= 1);
end;

procedure CalcZoomBounds(const Zoom, Offset : single; const SampleFrames, DisplayPixelWidth : integer; out IndexA, IndexB:single);
var
  DivFactor : single;
  Dist : single;
begin
  //check entry conditions
  assert(Zoom >= 0);
  assert(Zoom <= 1);
  assert(Offset >= 0);
  assert(Offset <= 1);

  Dist := 1 - Zoom;
  // (IndexB - IndexA) := Dist;

  DivFactor := (1 - Dist);

  IndexA := Offset * DivFactor;
  IndexB := IndexA + Dist;

  //Check exit conditions
  assert(IndexA >= 0);
  assert(IndexA <= 1);
  assert(IndexB >= 0);
  assert(IndexB <= 1);
end;

function CalcZoomPos(const SampleFrames, DisplayPixelWidth, TargetSamplePos : integer):TZoomPos;
var
  SampleIndexA, SampleIndexB : integer;
begin
  if TargetSamplePos >= SampleFrames then raise Exception.Create('TargetSamplePos is larger than SampleFrames.');

  if DisplayPixelWidth >= SampleFrames then
  begin
    SampleIndexA := 0;
    SampleIndexB := SampleFrames-1;
    result.Zoom := 0;
    result.Offset := 0;
    result.IndexA := 0;
    result.IndexB := 1;
    exit; //=============================>>
  end;


  if DisplayPixelWidth < SampleFrames then
  begin
    SampleIndexA := TargetSamplePos - (DisplayPixelWidth div 2);
    SampleIndexB := TargetSamplePos + (DisplayPixelWidth div 2);

    if SampleIndexA < 0 then
    begin
      SampleIndexA := 0;
      SampleIndexB := SampleIndexA + DisplayPixelWidth;
    end;

    if SampleIndexB >= SampleFrames then
    begin
      SampleIndexA := SampleFrames - 1 - DisplayPixelWidth;
      SampleIndexB := SampleFrames - 1;
    end;

    // double check everything has been computed correctly.
    assert(SampleIndexA >= 0);
    assert(SampleIndexB < SampleFrames);


    result.IndexA := SampleIndexA / (SampleFrames-1);
    result.IndexB := SampleIndexB / (SampleFrames-1);

    //finally, calc the zoom and offset values...
    CalcZoomOffset(result.IndexA, result.IndexB, SampleFrames, DisplayPixelWidth, result.Zoom, result.Offset);
  end;
end;


procedure ClearPadding(aControl : TVamWinControl); overload;
begin
  aControl.Padding.SetBounds(0,0,0,0);
  aControl.Margins.SetBounds(0,0,0,0);
  aControl.AlignWithMargins := true;

  if (aControl is TVamPanel) then
  begin
    (aControl as TVamPanel).CornerRadius1 := 3;
    (aControl as TVamPanel).CornerRadius2 := 3;
    (aControl as TVamPanel).CornerRadius3 := 3;
    (aControl as TVamPanel).CornerRadius4 := 3;
  end;

end;

procedure ClearPadding(aControl : TRedFoxContainer); overload;
begin
  aControl.Padding.SetBounds(0,0,0,0);
  aControl.Margins.SetBounds(0,0,0,0);
  aControl.AlignWithMargins := true;
end;


procedure SetupFileSaveDialog_Program(var SaveDialog : TFileSaveDialog);
var
  ft : TFileTypeItem;
begin
  if (LucidityGlobals.LastProgramLoadDir <> '') and (DirectoryExists(LucidityGlobals.LastProgramSaveDir)) then
  begin
    SaveDialog.DefaultFolder := LucidityGlobals.LastProgramSaveDir;
  end;

  ft := SaveDialog.FileTypes.Add;
  ft.DisplayName := 'Lucidity Program';
  ft.FileMask    := '*.lpg';

  SaveDialog.DefaultExtension := 'lpg';
end;

procedure SetupFileOpenDialog_Program(var OpenDialog : TFileOpenDialog);
var
  ft : TFileTypeItem;
begin
  if (LucidityGlobals.LastProgramLoadDir <> '') and (DirectoryExists(LucidityGlobals.LastProgramSaveDir)) then
  begin
    OpenDialog.DefaultFolder := LucidityGlobals.LastProgramLoadDir;
  end;

  ft := OpenDialog.FileTypes.Add;
  ft.DisplayName := 'Lucidity Program';
  ft.FileMask    := '*.lpg';

  ft := OpenDialog.FileTypes.Add;
  ft.DisplayName := 'All Files';
  ft.FileMask    := '*.*';

  OpenDialog.DefaultExtension := 'lpg';
end;


function FindRegionToDisplay(const Plugin : TeePlugin):TRegionDisplayResult; overload;
var
  rx : IRegion;
  rs : string;
  kg : IKeyGroup;
  SelectedRegionCount : integer;
begin
  rx := nil;
  rs := '';


  kg := Plugin.FocusedKeyGroup;
  if not assigned(kg) then
  begin
    rx := nil;
    rs := '(No Key Group Selected)';
    result.Region  := rx;
    result.Message := rs;
    exit; //================exit>>==================>>
  end;


  if (Plugin.GuiState.IsSampleMapVisible = false) then
  begin
    rx := Plugin.FocusedRegion;
    rs := '';

    if (assigned(rx)) and (rx.GetKeyGroup.GetName <> kg.GetName) then
    begin
      rx := Plugin.SampleMap.FindRegionByKeyGroup(kg.GetName);
      rs := '';
    end;

    if (not assigned(rx)) then
    begin
      rx := Plugin.SampleMap.FindRegionByKeyGroup(kg.GetName);
      rs := '';
    end;

    if (not assigned(rx)) and (Plugin.SampleMap.RegionCount = 0) then
    begin
      rs := '(No Samples Loaded)';
    end;

    if (not assigned(rx)) and (Plugin.SampleMap.RegionCount > 0) then
    begin
      rs := '(No Regions Selected)';
    end;
  end else
  begin
    if (Plugin.GuiState.MouseOverRegionID <> TGuidEx.EmptyGuid) then
    begin
      rx := Plugin.SampleMap.FindRegionByUniqueID(Plugin.GuiState.MouseOverRegionID);
      if not assigned(rx) then rs := 'ERROR';
    end else
    begin
      SelectedRegionCount := Plugin.SampleMap.SelectedRegionCount;

      if Plugin.SampleMap.RegionCount = 0 then
      begin
        rx := nil;
        rs := '(No Samples Loaded)';
      end else
      if SelectedRegionCount = 0 then
      begin
        rx := nil;
        rs := '(No Regions Selected)';
      end else
      if SelectedRegionCount > 1 then
      begin
        rx := nil;
        rs := '(' + IntToStr(SelectedRegionCount) + ' Regions Selected)';
      end else
      begin
        rx := Plugin.FocusedRegion;
        rs := '';
      end;
    end;
  end;

  result.Region  := rx;
  result.Message := rs;
end;

function ShowLoopMarkers(const aRegion : IRegion):boolean;
var
  kg : TKeyGroup;
begin
  kg := (aRegion.GetKeyGroup.GetObject as TKeyGroup);
  case kg.VoiceParameters.SamplePlaybackType of
    TSamplePlaybackType.NoteSampler,
    TSamplePlaybackType.LoopSampler,
    TSamplePlaybackType.OneShotSampler:
    begin
      case kg.VoiceParameters.SamplerLoopBounds of
        //TSamplerLoopBounds.LoopOff:    result := false;
        TSamplerLoopBounds.LoopSample: result := false;
        TSamplerLoopBounds.LoopPoints: result := true;
      else
        raise Exception.Create('Unexpected type.');
      end;
    end;

    TSamplePlaybackType.GrainStretch: result := true;
    TSamplePlaybackType.WaveOsc:      result := true;
  else
    raise Exception.Create('Unexpected Sample playback type.');
  end;

end;

procedure SpreadControls_Horz(Controls:TArray<TControl>; const Parent : TWinControl);
var
  ControlCount : integer;
  c1: Integer;
  TotalControlWidth : integer;
  TotalSpace : integer;
  OffsetA, OffsetB : single;
begin
  ControlCount := Length(Controls);

  TotalControlWidth := 0;
  for c1 := 0 to ControlCount-1 do
  begin
    inc(TotalControlWidth, Controls[c1].Width);
  end;

  TotalSpace := Parent.Width - TotalControlWidth;

  for c1 := 0 to ControlCount-1 do
  begin
    offsetA := (TotalControlWidth / ControlCount * c1);
    offsetB := TotalSpace / (ControlCount-1) * c1;
    Controls[c1].Left := round(OffsetA + OffsetB);
  end;
end;





procedure UpdateFilterControls(var Knobs : array of TControl; var Labels : array of TControl; const FilterType : TFilterType);
  procedure FastUpdateControl(aControl, aLabel : Tcontrol; const Caption : string = '');
  begin
    if Caption <> '' then
    begin
      aControl.Visible := true;
      (aLabel as TVamLabel).Text := Caption;
      aLabel.Visible := true;
    end else
    begin
      aControl.Visible := false;
      (aLabel as TVamLabel).Text := '';
      aLabel.Visible := false;
    end;
  end;
begin
  case FilterType of
    ftNone:
    begin
      FastUpdateControl(Knobs[0], Labels[0], '');
      FastUpdateControl(Knobs[1], Labels[1], '');
      FastUpdateControl(Knobs[2], Labels[2], '');
      FastUpdateControl(Knobs[3], Labels[3], '');
    end;

    ftLowPassA, ftBandPassA, ftHighPassA:
    begin
      FastUpdateControl(Knobs[0], Labels[0], 'FREQ');
      FastUpdateControl(Knobs[1], Labels[1], 'RES');
      FastUpdateControl(Knobs[2], Labels[2], '');
      FastUpdateControl(Knobs[3], Labels[3], '');
    end;

    ftLofiA:
    begin
      FastUpdateControl(Knobs[0], Labels[0], 'SR');
      FastUpdateControl(Knobs[1], Labels[1], 'BITS');
      FastUpdateControl(Knobs[2], Labels[2], '');
      FastUpdateControl(Knobs[3], Labels[3], '');
    end;

    ftRingModA:
    begin
      FastUpdateControl(Knobs[0], Labels[0], 'FREQ');
      FastUpdateControl(Knobs[1], Labels[1], 'AMT');
      FastUpdateControl(Knobs[2], Labels[2], '');
      FastUpdateControl(Knobs[3], Labels[3], '');
    end;

    //ftDistA:
    //begin
    //end;

    ftCombA:
    begin
      FastUpdateControl(Knobs[0], Labels[0], 'FREQ');
      FastUpdateControl(Knobs[1], Labels[1], 'AMT');
      FastUpdateControl(Knobs[2], Labels[2], '');
      FastUpdateControl(Knobs[3], Labels[3], '');
    end;
  else
    raise Exception.Create('Type not handled.');
  end;

end;


procedure SetupFileOpenDialog(var OpenDialog : TFileOpenDialog; const Target : TDialogTarget);
var
  ft : TFileTypeItem;
begin
  case Target of
    dtLucidityProgram:
    begin
      if (LucidityGlobals.LastProgramLoadDir <> '') and (DirectoryExists(LucidityGlobals.LastProgramSaveDir)) then
      begin
        OpenDialog.DefaultFolder := LucidityGlobals.LastProgramLoadDir;
      end;

      ft := OpenDialog.FileTypes.Add;
      ft.DisplayName := 'Lucidity Program';
      ft.FileMask    := '*.lpg';

      ft := OpenDialog.FileTypes.Add;
      ft.DisplayName := 'All Files';
      ft.FileMask    := '*.*';

      OpenDialog.DefaultExtension := 'lpg';
    end;


    dtSfzProgram:
    begin
      // TODO: set default folder location.

      ft := OpenDialog.FileTypes.Add;
      ft.DisplayName := 'SFZ Program';
      ft.FileMask    := '*.sfz';

      ft := OpenDialog.FileTypes.Add;
      ft.DisplayName := 'All Files';
      ft.FileMask    := '*.*';

      OpenDialog.DefaultExtension := 'sfz';
    end;
  else
    raise Exception.Create('Target type not handled.');
  end;
end;



end.
