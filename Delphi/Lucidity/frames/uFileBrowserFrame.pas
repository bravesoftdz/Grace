unit uFileBrowserFrame;

interface

uses
  VamLib.ZeroObject,
  Menu.FileTreeMenu,
  eeFileBrowserAddon, uConstants, eePlugin, eeGuiStandard,
  uLucidityEnums, Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RedFoxContainer,
  RedFoxWinControl, VamWinControl, VamPanel, VamCustomTreeView, VamTreeView,
  VamScrollBox, RedFoxGraphicControl, VamGraphicControl, VamLabel, VamDiv,
  VamKnob, VamButton;

type
  TFileBrowserFrame = class(TFrame, IZeroObject)
    Panel: TRedFoxContainer;
    BackgroundPanel: TVamPanel;
    ScrollBox: TVamScrollBox;
    FileTreeView: TVamTreeView;
    LowerPanel: TVamDiv;
    TextInfoContainer: TVamDiv;
    PreviewInfo3: TVamLabel;
    PreviewInfo1: TVamLabel;
    PreviewInfo2: TVamLabel;
    VamDiv1: TVamDiv;
    PreviewVolumeKnob: TVamKnob;
    LfoShapeTextBox1: TVamLabel;
    PreviewOnOffButton: TVamButton;
    InsidePanel: TVamPanel;
    procedure FileTreeViewScrollXChange(Sender: TObject);
    procedure FileTreeViewScrollYChange(Sender: TObject);
    procedure ScrollBoxScroll(Sender: TObject; Kind: TScrollEventKind; ScrollPos: Single);
    procedure FileTreeViewNodeRightClicked(Sender: TObject; Node: TVamTreeViewNode);
    procedure FileTreeViewTreeRightClicked(Sender: TObject);
    procedure PreviewOnOffButtonChanged(Sender: TObject);
  private
    fGuiStandard: TGuiStandard;
    fPlugin: TeePlugin;

    MsgHandle : hwnd;
    procedure MessageHandler(var Message : TMessage);
  private
    FMotherShip : IMothership;
    function GetMotherShipReference:IMotherShip;
    procedure SetMotherShipReference(aMotherShip : IMothership);
    procedure ProcessZeroObjectMessage(MsgID:cardinal; Data:Pointer);
  protected
    IsManualScroll : boolean;
    FileBrowserAddon : TFileBrowserAddon;

    MainContextMenu : TFileTreeViewMainContextMenu;
    NodeContextMenu : TFileTreeViewNodeContextMenu;

    procedure EventHandle_NodeFocusChanged(Sender : TObject);
    procedure EventHandle_FilterNodes(Sender : TObject; const RootDir : string; var FolderNodes, FileNodes : TStringList);
    procedure EventHandle_GetNodeBitmap(Sender : TObject; const NodeFileName : string; var Bitmap : TBitmap);

    property Plugin      : TeePlugin read fPlugin;
    property GuiStandard : TGuiStandard read fGuiStandard;

    procedure Command_ReplaceLoad;
    procedure RefreshFileBrowser;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure InitializeFrame(aPlugin : TeePlugin; aGuiStandard:TGuiStandard);

    procedure KeyCommand(Command:TKeyCommand);

    procedure PreviewInfoChanged;
    procedure SampleDirectoriesChanged;
  end;

implementation

uses
  eeFunctions, uLucidityExtra,
  Lucidity.SampleMap, RedFoxColor;

{$R *.dfm}

constructor TFileBrowserFrame.Create(AOwner: TComponent);
begin
  inherited;

  FileBrowserAddon := TFileBrowserAddon.Create(FileTreeView);
  FileBrowserAddOn.OnNodeFocusChanged := EventHandle_NodeFocusChanged;
  FileBrowserAddOn.OnFilterNodes      := EventHandle_FilterNodes;
  FileBrowserAddOn.OnGetNodeBitmap    := EventHandle_GetNodeBitmap;

  MainContextMenu := TFileTreeViewMainContextMenu.Create;
  NodeContextMenu := TFileTreeViewNodeContextMenu.Create;

  // NOTE: AFAIK TFrame should be receive a windows handle at some stage.
  // for whatever reason this TFrame instance wasn't receiving a handle and
  // i couldn't figure out why. This is a work-around so that the frame
  // can receive messages posted by the EasyEffect Globals class.
  MsgHandle := AllocateHWND(MessageHandler);
end;

destructor TFileBrowserFrame.Destroy;
begin
  if (MsgHandle <> 0) and (assigned(Plugin)) then
  begin
    Plugin.Globals.RemoveWindowsMessageListener(MsgHandle);
  end;
  DeallocateHWnd(MsgHandle);

  if (assigned(FMotherShip))
    then FMotherShip.DeregisterZeroObject(self);

  FileBrowserAddon.Free;
  MainContextMenu.Free;
  NodeContextMenu.Free;
  inherited;
end;

procedure TFileBrowserFrame.MessageHandler(var Message: TMessage);
begin
end;

procedure TFileBrowserFrame.ProcessZeroObjectMessage(MsgID: cardinal; Data: Pointer);
begin
  if MsgID = TLucidMsgID.SampleDirectoriesChanged then SampleDirectoriesChanged;
  if MsgID = TLucidMsgID.ProgramSavedToDisk       then RefreshFileBrowser;
  if MsgID = TLucidMsgID.PreviewInfoChanged       then PreviewInfoChanged

end;




procedure TFileBrowserFrame.InitializeFrame(aPlugin: TeePlugin; aGuiStandard: TGuiStandard);
begin
  assert(not assigned(fPlugin), 'InitializeFrame() must only be called once.');
  assert(assigned(aPlugin));
  assert(assigned(aGuiStandard));

  fPlugin      := aPlugin;
  fGuiStandard := aGuiStandard;

  if MsgHandle <> 0 then
  begin
    Plugin.Globals.AddWindowsMessageListener(MsgHandle);
  end;


  //==== Some basic GUI setup ====
  ScrollBox.Align := alClient;

  TextInfoContainer.Align := alClient;

  LowerPanel.Height := 60 + LowerPanel.Padding.Top + LowerPanel.Padding.Bottom;
  //LowerPanel.Height := 94 + LowerPanel.Padding.Top + LowerPanel.Padding.Bottom;


  //==== Parameters ====
  GuiStandard.RedFoxKnobHandler.RegisterControl(PreviewVolumeKnob, Plugin.Globals.VstParameters.FindParameter(TParName.PreviewVolume));

  PreviewOnOffButton.IsOn := Plugin.IsPreviewEnabled;

  // TODO: NOTE: Setting the color here doesn't work correctly in Win64.
  //ScrollBox.Color_Border     := GetRedFoxColor(kPanelVeryDark);
  //ScrollBox.Color_Background := GetRedFoxColor(kPanelDark);
  //ScrollBox.Color_Foreground := GetRedFoxColor(kPanelLight);


  MainContextMenu.Initialize(aPlugin);
  NodeContextMenu.Initialize(aPlugin);
  //========================================


  PreviewOnOffButton.Text := '';
  PreviewOnOffButton.Layout.SetSize(18,18);
  PreviewOnOffButton.Color_Border := kColor_ToggleButtonBorder;
  PreviewOnOffButton.ColorOnA     := kColor_ToggleButtonOn;
  PreviewOnOffButton.ColorOnB     := kColor_ToggleButtonOnMouseOver;
  PreviewOnOffButton.ColorOffA    := kColor_ToggleButtonOff;
  PreviewOnOffButton.ColorOffB    := kColor_ToggleButtonOffMouseOver;
  PreviewOnOffButton.ImageOn      := Plugin.Globals.SkinImageLoader.GetImage('Preview_Icon');
  PreviewOnOffButton.ImageOff     := Plugin.Globals.SkinImageLoader.GetImage('Preview_Icon');



  //======================================
  RefreshFileBrowser; //Update some GUI controls...
  PreviewInfoChanged; //Update some GUI controls...


end;

procedure TFileBrowserFrame.SampleDirectoriesChanged;
var
  c1 : integer;
  Name, Path : string;
begin
  if not assigned(Plugin) then exit;

  Plugin.SampleDirectories.RefreshDirectoryList;

  FileBrowserAddon.ClearRootNodes;

  for c1 := 0 to Plugin.SampleDirectories.Count-1 do
  begin
    Name := Plugin.SampleDirectories[c1].Name;
    Path := Plugin.SampleDirectories[c1].Path;

    if (Name <> '') and (DirectoryExists(Path)) then
    begin
      FileBrowserAddon.AddRootNode(Path, Name);
    end;
  end;

  FileBrowserAddon.UpdateRootNodes;
end;




procedure TFileBrowserFrame.FileTreeViewScrollXChange(Sender: TObject);
var
  range : single;
begin
  if IsManualScroll then exit;

  ScrollBox.ScrollXPos := FileTreeView.ScrollPosX;
  ScrollBox.ScrollYPos := (1 - FileTreeView.ScrollPosY);

  ScrollBox.ScrollXIndexSize := FileTreeView.ScrollRangeX;

  range := FileTreeView.ScrollRangeY;
  if Range < 0.1 then Range := 0.1;
  ScrollBox.ScrollYIndexSize := range;
end;

procedure TFileBrowserFrame.FileTreeViewScrollYChange(Sender: TObject);
var
  range : single;
begin
  if IsManualScroll then exit;

  ScrollBox.ScrollXPos := FileTreeView.ScrollPosX;
  ScrollBox.ScrollYPos := (1 - FileTreeView.ScrollPosY);

  ScrollBox.ScrollXIndexSize := FileTreeView.ScrollRangeX;

  range := FileTreeView.ScrollRangeY;
  if range < 0.1 then range := 0.1;
  ScrollBox.ScrollYIndexSize := range;
end;

procedure TFileBrowserFrame.ScrollBoxScroll(Sender: TObject; Kind: TScrollEventKind; ScrollPos: Single);
begin
  IsManualScroll := true;

  try
    FileTreeView.ScrollPosX := ScrollBox.ScrollXPos;
    FileTreeView.ScrollPosY := (1-ScrollBox.ScrollYPos);
    FileTreeView.Invalidate;
  finally
    IsManualScroll := false;
  end;
end;

procedure TFileBrowserFrame.SetMotherShipReference(aMotherShip: IMothership);
begin
  FMotherShip := aMothership;
end;

procedure TFileBrowserFrame.KeyCommand(Command: TKeyCommand);
begin
  if not assigned(Plugin) then exit;

  case Command of
    TKeyCommand.ContextUp:    FileBrowserAddOn.Command_BrowserUp;
    TKeyCommand.ContextDown:  FileBrowserAddOn.Command_BrowserDown;
    TKeyCommand.ContextLeft:  FileBrowserAddOn.Command_BrowserLeft;
    TKeyCommand.ContextRight: FileBrowserAddOn.Command_BrowserRight;
    TKeyCommand.PageUp:       FileBrowserAddOn.Command_PageUp;
    TKeyCommand.PageDown:     FileBrowserAddOn.Command_PageDown;
    TKeyCommand.SelectUp:     FileBrowserAddOn.Command_SelectUp;
    TKeyCommand.SelectDown:   FileBrowserAddOn.Command_SelectDown;
    TKeyCommand.ReplaceLoad:  Command_ReplaceLoad;
  else
    raise Exception.Create('Unexpected Command Value');
  end;
end;




procedure TFileBrowserFrame.PreviewInfoChanged;
begin
  if not assigned(Plugin) then exit;

  if (Plugin.PreviewInfo^.IsSupported) and (Plugin.PreviewInfo^.IsValid) then
  begin
    PreviewInfo1.Text := Plugin.PreviewInfo^.FileName;

    if Plugin.PreviewInfo^.ChannelCount = '1'
      then PreviewInfo2.Text := Plugin.PreviewInfo^.SampleTime + '  MONO'
      else PreviewInfo2.Text := Plugin.PreviewInfo^.SampleTime + '  STEREO';

    PreviewInfo3.Text := Plugin.PreviewInfo^.SampleRate + ' hz' + '  ' + Plugin.PreviewInfo^.BitDepth + ' bit';
  end else
  if (Plugin.PreviewInfo^.IsSupported) and (Plugin.PreviewInfo^.IsValid = false) then
  begin
    PreviewInfo1.Text := Plugin.PreviewInfo^.FileName;
    PreviewInfo2.Text := 'Invalid Sample';
    PreviewInfo3.Text := '';
  end else
  begin
    PreviewInfo1.Text := '';
    PreviewInfo2.Text := '';
    PreviewInfo3.Text := '';
  end;

end;



procedure TFileBrowserFrame.EventHandle_NodeFocusChanged(Sender: TObject);
var
  NodeData : PNodeData;
begin
  if not assigned(Plugin) then exit;

  Plugin.StopPreview;

  NodeData := FileBrowserAddOn.GetFocusedNodeData;
  if assigned(NodeData) then
  begin
    if FileExists(NodeData.FileName)
      then Plugin.TriggerPreview(NodeData.FileName)
      else Plugin.ClearPreviewInfo;
  end;

end;

procedure TFileBrowserFrame.EventHandle_FilterNodes(Sender: TObject; const RootDir: string; var FolderNodes, FileNodes: TStringList);
var
  c1 : integer;
  ext : string;
  DataFolderName : string;
  Index : integer;
  fn : string;
begin
  // Remove any program sample data folders from the folder listing.
  for c1 := 0 to FileNodes.Count-1 do
  begin
    ext := ExtractFileExt(FileNodes[c1]);
    if SameText(ext, '.lpg') then
    begin
      DataFolderName := RemoveFileExt(FileNodes[c1]) + ' Samples';
      Index := FolderNodes.IndexOf(DataFoldername);
      if Index <> -1 then FolderNodes.Delete(Index);
    end;
  end;


  // remove un-supported audio format files.
  for c1 := FileNodes.Count-1  downto 0 do
  begin
    fn := IncludeTrailingPathDelimiter(RootDir) + FileNodes[c1];
    if (IsSupportedAudioFormat(fn) = false) and (IsSupportedProgramFormat(fn) = false) then
    begin
      FileNodes.Delete(c1);
    end;
  end;

end;



procedure TFileBrowserFrame.Command_ReplaceLoad;
var
  NodeData : PNodeData;
  CurRegion : IRegion;
  NewRegion : IRegion;
begin
  if not assigned(Plugin) then exit;

  Plugin.StopPreview;

  NodeData := FileBrowserAddOn.GetFocusedNodeData;
  if (assigned(NodeData)) and (FileExists(NodeData.FileName)) then
  begin
    if IsSupportedAudioFormat(NodeData.FileName) then
    begin
      CurRegion := Plugin.FocusedRegion;

      if not assigned(CurRegion) then
      begin
        NewRegion := Plugin.SampleMap.LoadSample(NodeData.FileName, Plugin.FocusedKeyGroup);
      end else
      begin
        NewRegion := Plugin.SampleMap.ReplaceSample(NodeData.FileName, CurRegion);
      end;

      if assigned(NewRegion) then
      begin
        Plugin.FocusRegion(NewRegion.GetProperties^.UniqueID);
      end;
    end;


    if IsSupportedProgramFormat(NodeData.FileName) then
    begin
      Plugin.LoadProgramFromFile(NodeData.FileName);
    end;


  end;
end;

procedure TFileBrowserFrame.FileTreeViewNodeRightClicked(Sender: TObject; Node: TVamTreeViewNode);
var
  NodeData : PNodeData;
begin
  //called when a node is right clicked.
  NodeContextMenu.FocusedNode := Node;

  NodeData := FileBrowserAddOn.GetFocusedNodeData;
  if assigned(NodeData)
    then NodeContextMenu.NodeFileName := NodeData^.FileName
    else NodeContextMenu.NodeFileName := '';

  NodeContextMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TFileBrowserFrame.FileTreeViewTreeRightClicked(Sender: TObject);
begin
  //called when the treeview is right clicked with no node under the cursor.
  MainContextMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

function TFileBrowserFrame.GetMotherShipReference: IMotherShip;
begin
  result := FMotherShip;
end;

procedure TFileBrowserFrame.EventHandle_GetNodeBitmap(Sender: TObject; const NodeFileName: string; var Bitmap: TBitmap);
var
  ext : string;
begin
  if not assigned(Plugin) then exit;

  ext := ExtractFileExt(NodeFileName);
  if SameText(ext, '') then
  begin
    Bitmap := Plugin.Globals.SkinImageLoader.GetImage('Browser_FolderIcon');
    exit; //=====================================================================>>exit>>========>>
  end;



  if IsSupportedAudioFormat(NodeFileName) then
  begin
    Bitmap := Plugin.Globals.SkinImageLoader.GetImage('Browser_AudioIcon');
    exit; //=====================================================================>>exit>>========>>
  end;


  if IsSupportedProgramFormat(NodeFileName) then
  begin
    Bitmap := Plugin.Globals.SkinImageLoader.GetImage('Browser_ProgramIcon');
    exit; //=====================================================================>>exit>>========>>
  end;








  //Plugin.Globals.
end;

procedure TFileBrowserFrame.PreviewOnOffButtonChanged(Sender: TObject);
begin
  if not assigned(Plugin) then exit;

  Plugin.IsPreviewEnabled := (Sender as TVamButton).IsOn;
end;

procedure TFileBrowserFrame.RefreshFileBrowser;
begin
  //TODO:
  // Here we need to refresh the file browser.
  // this is desired because it would be good if the browser refreshed after saving
  // a new program to disk. Currently it doesn't show up until the patch browser node
  // is closed and re-opended.

  SampleDirectoriesChanged;
end;

end.
