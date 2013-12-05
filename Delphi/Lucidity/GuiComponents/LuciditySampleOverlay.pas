unit LuciditySampleOverlay;

interface

uses
  Types, Controls, Classes, Graphics,
  RedFox, RedFoxGraphicControl, RedFoxColor,
  VamGraphicControl, VamWinControl,
  uGuiFeedbackData;

type
  TSampleMarker = (smNone, smSampleStartMarker, smSampleEndMarker, smLoopStartMarker, smLoopEndMarker);
  TSampleMarkerChangedEvent = procedure(Sender:TObject; Marker:TSampleMarker; NewPosition : integer) of object;

  TSampleOverlayZoomEvent = procedure(Sender : TObject; Zoom, Offset : single) of object;

  TLuciditySampleOverlay = class(TVamWinControl)
  private
    fSampleStart: integer;
    fSampleEnd: integer;
    fOnSampleMarkerChanged: TSampleMarkerChangedEvent;
    fLoopEnd: integer;
    fLoopStart: integer;
    fShowLoopPoints: boolean;
    fShowMarkerTags: boolean;
    fNoSampleMessage: string;
    fOnZoomChanged: TSampleOverlayZoomEvent;
    fShowReplaceMessage: boolean;
    procedure SetSampleEnd(const Value: integer);
    procedure SetSampleStart(const Value: integer);
    procedure SetLoopEnd(const Value: integer);
    procedure SetLoopStart(const Value: integer);
    procedure SetShowLoopPoints(const Value: boolean);
    procedure SetShowMarkerTags(const Value: boolean);
    procedure SetNoSampleMessage(const Value: string);
    procedure SetShowReplaceMessage(const Value: boolean);
  protected
    FeedbackData : PGuiFeedbackData;
    SampleIsValid : boolean;
    SampleFrames  : integer;
    Zoom, Offset : single;

    IsGrabbed : boolean;
    GrabbedMode : TSampleMarker; //TODO: Rename to GrabbedMarker.
    GrabbedSampleOffset : single;

    MouseOverMarker : TSampleMarker;
    MouseOverMarkerVertOffset : integer;

    IsZooming : boolean;
    ZoomDragx1 : integer;
    ZoomDragx2 : integer;

    MessageFont : TFont;

    procedure SetFont(const Value: TFont); override;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    procedure MouseEnter; override;
    procedure MouseLeave; override;

    procedure Draw_PlayBackPosition(const xPos : single);
    procedure Draw_MarkerTag(const xPos, yPos : single; const aMarker : TSampleMarker);
    procedure Draw_SampleStart(const xPos : single);
    procedure Draw_SampleEnd(const xPos : single);
    procedure Draw_LoopStart(const xPos : single);
    procedure Draw_LoopEnd(const xPos : single);
    procedure Draw_ModLoopPoint(const xPos : single);
    procedure Draw_ZoomSelection(const x1, x2 : integer);
    procedure Draw_ReplaceMessage;

    function IsNearMarker(const PixelPosX, PixelPosY : integer):TSampleMarker;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure LinkToGuiFeedbackData(const aFeedbackData : PGuiFeedbackData);

    procedure Paint; override;

    function SamplePosToPixelPos(x1:integer; SampleFrames:integer):single;
    function PixelPosToSamplePos(x1:single; SampleFrames:integer):integer;

    procedure SetSampleInfo(const aIsValid : boolean; const aSampleFrames : integer);
    procedure SetZoomOffset(const aZoom, aOffset : single);

    property SampleStart : integer read fSampleStart write SetSampleStart;
    property SampleEnd   : integer read fSampleEnd   write SetSampleEnd;
    property LoopStart   : integer read fLoopStart   write SetLoopStart;
    property LoopEnd     : integer read fLoopEnd     write SetLoopEnd;

    property ShowLoopPoints : boolean read fShowLoopPoints write SetShowLoopPoints;
    property ShowReplaceMessage : boolean read fShowReplaceMessage write SetShowReplaceMessage;

    property NoSampleMessage : string read fNoSampleMessage write SetNoSampleMessage;
  published
    property ShowMarkerTags : boolean read fShowMarkerTags write SetShowMarkerTags;

    property OnSampleMarkerChanged : TSampleMarkerChangedEvent read fOnSampleMarkerChanged write fOnSampleMarkerChanged;
    property OnZoomChanged         : TSampleOverlayZoomEvent   read fOnZoomChanged         write fOnZoomChanged;

    property Font;

    {$INCLUDE TControlProperties.inc}
  end;

implementation

uses
  SysUtils,
  UITypes, AggColor, AggRoundedRect, AggPathStorage,
  AggPixelFormat, VamSampleDisplay, VamSampleDisplayBackBuffer,
  uConstants;

const
  //colors
  kBackgroundColor = uConstants.kColor_LcdDark1;
  kMessageColor    = uConstants.kColor_LcdDark5;
  kSampleStart = '$FF0F952A';
  kSampleEnd   = '$FFD11F1F';
  kLoopPoint   = '$FF208ED1';
  kZoomSelectionColor = '$FFFFFF55';
  kMarkerTabHeight = 10;


function IsNear(const ValueA, ValueB : single; const Tolerance:single):boolean;
begin
  if abs(ValueA - ValueB) <= Tolerance
    then result := true
    else result := false;
end;

{ TLuciditySampleOverlay }

constructor TLuciditySampleOverlay.Create(AOwner: TComponent);
begin
  inherited;

  FeedbackData := nil;

  SampleIsValid := false;
  SampleFrames  := 0;
  Zoom := 0;
  Offset := 0;

  fNoSampleMessage := '';

  MessageFont := TFont.Create;
  MessageFont.Height := 16;
  MessageFont.Style  := [TFontStyle.fsBold];

  ShowReplaceMessage := false;
end;

destructor TLuciditySampleOverlay.Destroy;
begin
  MessageFont.Free;
  inherited;
end;

procedure TLuciditySampleOverlay.LinkToGuiFeedbackData(const aFeedbackData: PGuiFeedbackData);
begin
  FeedbackData := aFeedbackData;
end;

function TLuciditySampleOverlay.IsNearMarker(const PixelPosX, PixelPosY: integer): TSampleMarker;
const
  kTolarance = 6;
  kMarkerOffset = 3;
var
  PixSampleStartMarker : single;
  PixSampleEndMarker   : single;
  PixLoopStartMarker : single;
  PixLoopEndMarker   : single;
  CurrentSamplePos : single;
begin
  CurrentSamplePos := VamSampleDisplayBackBuffer.PixelPosToSamplePos(PixelPosX, SampleFrames, Width, Zoom, Offset);

  PixSampleStartMarker := VamSampleDisplayBackBuffer.SamplePosToPixelPos(SampleStart, SampleFrames, Width, Zoom, Offset);
  PixSampleEndMarker   := VamSampleDisplayBackBuffer.SamplePosToPixelPos(SampleEnd, SampleFrames, Width, Zoom, Offset);
  PixLoopStartMarker   := VamSampleDisplayBackBuffer.SamplePosToPixelPos(LoopStart, SampleFrames, Width, Zoom, Offset);
  PixLoopEndMarker     := VamSampleDisplayBackBuffer.SamplePosToPixelPos(LoopEnd, SampleFrames, Width, Zoom, Offset);

  if PixelPosY >= Height - kMarkerTabHeight then
  begin
    // Give preference to selecting the sample start/end area if
    // the mouse is in the lower part of the sample area....
    if IsNear(PixelPosX, PixSampleStartMarker + kMarkerOffset , kTolarance) then exit(smSampleStartMarker);
    if IsNear(PixelPosX, PixSampleEndMarker - kMarkerOffset, kTolarance)    then exit(smSampleEndMarker);
    if (ShowLoopPoints) and (LoopStart <> -1) and (IsNear(PixelPosX, PixLoopStartMarker + kMarkerOffset, kTolarance)) then exit(smLoopStartMarker);
    if (ShowLoopPoints) and (LoopStart <> -1) and (IsNear(PixelPosX, PixLoopEndMarker - kMarkerOffset, kTolarance))   then exit(smLoopEndMarker);
  end else
  begin
    //....else give preference to grabbing the loop start/end markers.
    if (ShowLoopPoints) and (LoopStart <> -1) and (IsNear(PixelPosX, PixLoopStartMarker + kMarkerOffset, kTolarance)) then exit(smLoopStartMarker);
    if (ShowLoopPoints) and (LoopStart <> -1) and (IsNear(PixelPosX, PixLoopEndMarker - kMarkerOffset, kTolarance))   then exit(smLoopEndMarker);
    if IsNear(PixelPosX, PixSampleStartMarker + kMarkerOffset , kTolarance) then exit(smSampleStartMarker);
    if IsNear(PixelPosX, PixSampleEndMarker - kMarkerOffset, kTolarance)    then exit(smSampleEndMarker);
  end;


  // No marker nearby.
  result := smNone;
end;



procedure TLuciditySampleOverlay.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CurrentSamplePos : single;
begin
  inherited;

  IsZooming := false;

  if (Button = mbLeft) and (SampleIsValid) then
  begin
    IsGrabbed := true;
    GrabbedMode := IsNearMarker(X, Y);

    CurrentSamplePos := VamSampleDisplayBackBuffer.PixelPosToSamplePos(X, SampleFrames, Width, Zoom, Offset);

    case GrabbedMode of
      smNone:              GrabbedSampleOffset := 0; // not used
      smSampleStartMarker: GrabbedSampleOffset := CurrentSamplePos - SampleStart;
      smSampleEndMarker:   GrabbedSampleOffset := CurrentSamplePos - SampleEnd;
      smLoopStartMarker:   GrabbedSampleOffset := CurrentSamplePos - LoopStart;
      smLoopEndMarker:     GrabbedSampleOffset := CurrentSamplePos - LoopEnd;
    else
      raise Exception.Create('Unexpected Grabbed mode.');
    end;

    //TODO: Zooming is currently disabled. Leave for now.
    {
    if GrabbedMode = smNone then
    begin
      IsZooming := true;
      ZoomDragX1 := X;
      ZoomDragX2 := X;
    end;
    }

    Invalidate;

  end;
end;

procedure TLuciditySampleOverlay.MouseEnter;
begin
  inherited;

end;

procedure TLuciditySampleOverlay.MouseLeave;
begin
  inherited;
  Cursor := crDefault;

  if MouseOverMarker <> TSampleMarker.smNone then
    begin
      MouseOverMarker := TSampleMarker.smNone;
      Invalidate;
    end;
end;

procedure TLuciditySampleOverlay.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  CurrentSamplePos : single;
  xPos : integer;
  Marker : TSampleMarker;
  PixSampleStartMarker : single;
  PixSampleEndMarker   : single;
  PixLoopStartMarker   : single;
  PixLoopEndMarker     : single;
begin
  inherited;

  if (IsGrabbed = false) and (SampleIsValid) then
  begin
    Marker := IsNearMarker(X, Y);

    case Marker of
      smNone:              Cursor := crDefault;
      smSampleStartMarker: Cursor := crSizeWE;
      smSampleEndMarker:   Cursor := crSizeWE;
      smLoopStartMarker:   Cursor := crSizeWE;
      smLoopEndMarker:     Cursor := crSizeWE;
    else
      raise Exception.Create('Unexpected Marker type.');
    end;


    if (Marker <> MouseOverMarker) then
    begin
      MouseOverMarkerVertOffset := Y;
      MouseOverMarker := Marker;
      Invalidate;
    end else
    if (Marker <> TSampleMarker.smNone) and (MouseOverMarkerVertOffset <> Y) then
    begin
      MouseOverMarkerVertOffset := Y;
      Invalidate;
    end;
  end;


  if (IsGrabbed) then
  begin
    if (IsZooming) then
    begin
      if X <> ZoomDragX2 then
      begin
        ZoomDragX2 := x;
        Invalidate;
      end;
    end;



    if (GrabbedMode = smSampleStartMarker) then
    begin
      CurrentSamplePos := VamSampleDisplayBackBuffer.PixelPosToSamplePos(X, SampleFrames, Width, Zoom, Offset);
      xPos := round(CurrentSamplePos - GrabbedSampleOffset);
      if xPos >= SampleFrames then xPos := SampleFrames-1;
      if xPos < 0 then xPos := 0;
      if xPos <> fSampleStart then
      begin
        fSampleStart := xPos;
        Invalidate;
      end;
    end;


    if (GrabbedMode = smSampleEndMarker) then
    begin
      CurrentSamplePos := VamSampleDisplayBackBuffer.PixelPosToSamplePos(X, SampleFrames, Width, Zoom, Offset);
      xPos := round(CurrentSamplePos - GrabbedSampleOffset);
      if xPos >= SampleFrames then xPos := SampleFrames-1;
      if xPos < 0 then xPos := 0;
      if xPos <> fSampleEnd then
      begin
        fSampleEnd := xPos;
        Invalidate;
      end;
    end;


    if (GrabbedMode = smLoopStartMarker) then
    begin
      CurrentSamplePos := VamSampleDisplayBackBuffer.PixelPosToSamplePos(X, SampleFrames, Width, Zoom, Offset);
      xPos := round(CurrentSamplePos - GrabbedSampleOffset);
      if xPos >= SampleFrames then xPos := SampleFrames-1;
      if xPos < 0 then xPos := 0;
      if xPos <> fLoopStart then
      begin
        fLoopStart := xPos;
        Invalidate;
      end;
    end;


    if (GrabbedMode = smLoopEndMarker) then
    begin
      CurrentSamplePos := VamSampleDisplayBackBuffer.PixelPosToSamplePos(X, SampleFrames, Width, Zoom, Offset);
      xPos := round(CurrentSamplePos - GrabbedSampleOffset);
      if xPos >= SampleFrames then xPos := SampleFrames-1;
      if xPos < 0 then xPos := 0;
      if xPos <> fLoopEnd then
      begin
        fLoopEnd := xPos;
        Invalidate;
      end;
    end;

    //call the event handlers....
    if assigned(OnSampleMarkerChanged) then
    begin
      if (GrabbedMode = smSampleStartMarker) then OnSampleMarkerChanged(Self, smSampleStartMarker, SampleStart);
      if (GrabbedMode = smSampleEndMarker)   then OnSampleMarkerChanged(Self, smSampleEndMarker, SampleEnd);
      if (GrabbedMode = smLoopStartMarker)   then OnSampleMarkerChanged(Self, smLoopStartMarker, LoopStart);
      if (GrabbedMode = smLoopEndMarker)     then OnSampleMarkerChanged(Self, smLoopEndMarker, LoopEnd);
    end;
  end;

end;

procedure TLuciditySampleOverlay.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NewZoom, NewOffset : single;
  sPos1, sPos2 : single;
begin
  inherited;

  if (Button = mbLeft) and (IsGrabbed) then
  begin
    //call the event handlers....
    if assigned(OnSampleMarkerChanged) then
    begin
      if (GrabbedMode = smSampleStartMarker) then OnSampleMarkerChanged(Self, smSampleStartMarker, SampleStart);
      if (GrabbedMode = smSampleEndMarker)   then OnSampleMarkerChanged(Self, smSampleEndMarker, SampleEnd);
      if (GrabbedMode = smLoopStartMarker)   then OnSampleMarkerChanged(Self, smLoopStartMarker, LoopStart);
      if (GrabbedMode = smLoopEndMarker)     then OnSampleMarkerChanged(Self, smLoopEndMarker, LoopEnd);
    end;

    if (IsZooming) and (ZoomDragx1 <> ZoomDragx2) then
    begin
      //TODO: Need to check for max zoom, if so do don't try to zoom in any further.
      if assigned(OnZoomChanged) then
      begin
        //NewZoom   := 0;
        //NewOffset := 0;

        if ZoomDragX1 < ZoomDragX2 then
        begin
          sPos1 := self.PixelPosToSamplePos(ZoomDragX1, SampleFrames);
          sPos2 := self.PixelPosToSamplePos(ZoomDragX2, SampleFrames);
        end else
        begin
          sPos2 := self.PixelPosToSamplePos(ZoomDragX1, SampleFrames);
          sPos1 := self.PixelPosToSamplePos(ZoomDragX2, SampleFrames);
        end;

        if sPos1 < 0             then sPos1 := 0;
        if sPos1 >= SampleFrames then sPos1 := SampleFrames-1;
        if sPos2 < 0             then sPos2 := 0;
        if sPos2 >= SampleFrames then sPos2 := SampleFrames-1;

        NewZoom   := 1 - ((sPos2 - sPos1) / (SampleFrames-1));
        NewOffset := sPos1 / ((SampleFrames-1) - (sPos2 - sPos1));

        OnZoomChanged(Self, NewZoom, NewOffset);
      end;

    end;

    // Important. Do this last.
    IsGrabbed   := false;
    GrabbedMode := smNone;
    IsZooming   := false;
  end;
end;



function TLuciditySampleOverlay.SamplePosToPixelPos(x1, SampleFrames: integer): single;
begin
  result := VamSampleDisplayBackBuffer.SamplePosToPixelPos(x1, SampleFrames, Width, Zoom, Offset)
end;

function TLuciditySampleOverlay.PixelPosToSamplePos(x1: single; SampleFrames: integer): integer;
begin
  result := VamSampleDisplayBackBuffer.PixelPosToSamplePos(x1, SampleFrames, Width, Zoom, Offset);
end;

procedure TLuciditySampleOverlay.SetFont(const Value: TFont);
begin
  inherited;

  // NOTE: This method isn't being called for some reason. Not even sure if it's supposed to
  // be getting called.
  if assigned(Value) then
  begin
    MessageFont.Assign(Value);
    MessageFont.Height := Value.Height * 2;
    MessageFont.Style := Value.Style + [TFontStyle.fsBold];
  end;
end;

procedure TLuciditySampleOverlay.SetLoopEnd(const Value: integer);
begin
  if Value <> fLoopEnd then
  begin
    fLoopEnd := Value;
    Invalidate;
  end;
end;

procedure TLuciditySampleOverlay.SetLoopStart(const Value: integer);
begin
  if Value <> fLoopStart then
  begin
    fLoopStart := Value;
    Invalidate;
  end;
end;

procedure TLuciditySampleOverlay.SetNoSampleMessage(const Value: string);
begin
  if Value <> fNoSampleMessage then
  begin
    fNoSampleMessage := Value;
    Invalidate;
  end;
end;

procedure TLuciditySampleOverlay.SetSampleEnd(const Value: integer);
begin
  if fSampleEnd <> Value then
  begin
    fSampleEnd := Value;
    Invalidate;
  end;
end;

procedure TLuciditySampleOverlay.SetSampleStart(const Value: integer);
begin
  if fSampleStart <> Value then
  begin
    fSampleStart := Value;
    Invalidate;
  end;
end;

procedure TLuciditySampleOverlay.SetShowLoopPoints(const Value: boolean);
begin
  if Value <> fShowLoopPoints then
  begin
    fShowLoopPoints := Value;
    Invalidate;
  end;
end;

procedure TLuciditySampleOverlay.SetShowMarkerTags(const Value: boolean);
begin
  if Value <> fShowMarkerTags then
  begin
    fShowMarkerTags := Value;
    Invalidate;
  end;
end;

procedure TLuciditySampleOverlay.SetShowReplaceMessage(const Value: boolean);
begin
  if Value <> fShowReplaceMessage then
  begin
    fShowReplaceMessage := Value;
    Invalidate;
  end;
end;

procedure TLuciditySampleOverlay.SetSampleInfo(const aIsValid: boolean; const aSampleFrames: integer);
begin
  if (aIsValid <> SampleIsValid) or (aSampleFrames <> SampleFrames) then
  begin
    SampleIsValid := aIsValid;
    SampleFrames  := aSampleFrames;
    Invalidate;
  end;
end;

procedure TLuciditySampleOverlay.SetZoomOffset(const aZoom, aOffset: single);
begin
  if (Zoom <> aZoom) or (Offset <> aOffset) then
  begin
    Zoom   := aZoom;
    Offset := aOffset;
    Invalidate;
  end;
end;


procedure TLuciditySampleOverlay.Paint;
var
  x1, y1, x2, y2 : single;
  TextBounds : TRect;
begin
  inherited;

  BackBuffer.BufferInterface.ClearAll(255,255,255,0);
  BackBuffer.BufferInterface.BlendMode := TAggBlendMode.bmSourceOver;

  if (SampleIsValid = false) and (fNoSampleMessage <> '') then
  begin
    TextBounds := Rect(0,0, Width, Height);
    BackBuffer.DrawText(fNoSampleMessage, Font, TRedFoxAlign.AlignCenter, TRedFoxAlign.AlignCenter, TextBounds);
  end;

  if SampleIsValid then
  begin
    if assigned(FeedbackData) then
    begin
      //== Draw the buffered loop boundary points...
      if (FeedbackData^.IsVoiceActive) then
      begin
        BackBuffer.BufferInterface.LineWidth := 1;


        if (FeedBackData^.SampleBounds.ShowPlaybackBounds) then
        begin
          BackBuffer.BufferInterface.FillColor := GetRedFoxColor('$22FFFFFF').AsAggRgba8;
          BackBuffer.BufferInterface.NoLine;

          x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(FeedbackData^.SampleBounds.PlaybackStart, SampleFrames, Width, Zoom, Offset);
          x2 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(FeedbackData^.SampleBounds.PlaybackEnd,   SampleFrames, Width, Zoom, Offset);

          y1 := 0;
          y2 := self.Height;

          BackBuffer.BufferInterface.Rectangle(x1, y1, x2, y2);
        end;


        if (FeedBackData^.SampleBounds.ShowHighlightBounds) then
        begin
          BackBuffer.BufferInterface.FillColor := GetRedFoxColor('$22FFFFFF').AsAggRgba8;
          BackBuffer.BufferInterface.NoLine;

          x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(FeedbackData^.SampleBounds.HighlightStart, SampleFrames, Width, Zoom, Offset);
          x2 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(FeedbackData^.SampleBounds.HighlightEnd,   SampleFrames, Width, Zoom, Offset);

          y1 := 0;
          y2 := self.Height;

          BackBuffer.BufferInterface.Rectangle(x1, y1, x2, y2);
        end;


        if (FeedbackData^.SampleBounds.ShowRealTimeMarkers) then
        begin
          //== Draw the current playback postion...
          x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(FeedbackData^.SampleBounds.PlaybackPos, SampleFrames, Width, Zoom, Offset);
          self.Draw_PlayBackPosition(x1);

          //== draw the modulated loop points ==
          //x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(FeedbackData^.SampleBounds.ModLoopStart, SampleFrames, Width, Zoom, Offset);
          //self.Draw_ModLoopPoint(x1); // TODO: currently disable. Think about re-enabling.

          //x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(FeedbackData^.SampleBounds.ModLoopEnd, SampleFrames, Width, Zoom, Offset);
          //self.Draw_ModLoopPoint(x1); // TODO: currently disable. Think about re-enabling.
        end;
      end;
    end;


    //== some setup ==
    BackBuffer.BufferInterface.BlendMode := TAggBlendMode.bmAlpha;

    BackBuffer.BufferInterface.LineColor := GetRedFoxColor('$FF1944C3').AsAggRgba8;
    BackBuffer.BufferInterface.NoFill;

    //========= Draw sample start/end markers =======
    x1 := SampleStart;
    x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(x1, SampleFrames, Width, Zoom, Offset);
    Draw_SampleStart(x1);

    x1 := SampleEnd;
    x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(x1, SampleFrames, Width, Zoom, Offset);
    Draw_SampleEnd(x1);


    //========= Draw Loop start/end markers =======
    BackBuffer.BufferInterface.LineWidth := 1;
    BackBuffer.BufferInterface.LineColor := GetRedFoxColor(kLoopPoint).AsAggRgba8;
    BackBuffer.BufferInterface.FillColor := GetRedFoxColor(kLoopPoint).AsAggRgba8;

    if (ShowLoopPoints) and (LoopStart <> -1) then
    begin
      x1 := LoopStart;
      x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(x1, SampleFrames, Width, Zoom, Offset);
      Draw_LoopStart(x1);
    end;

    if (ShowLoopPoints) and (LoopEnd <> -1) then
    begin
      x1 := LoopEnd;
      x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(x1, SampleFrames, Width, Zoom, Offset);
      Draw_LoopEnd(x1);
    end;


    if (IsGrabbed = false) then
    begin
      case MouseOverMarker of
        smSampleStartMarker:
        begin
          x1 := SampleStart;
          x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(x1, SampleFrames, Width, Zoom, Offset);
          Draw_SampleStart(x1);
          Draw_MarkerTag(x1, MouseOverMarkerVertOffset, TSampleMarker.smSampleStartMarker);
        end;

        smSampleEndMarker:
        begin
          x1 := SampleEnd;
          x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(x1, SampleFrames, Width, Zoom, Offset);
          Draw_SampleEnd(x1);
          Draw_MarkerTag(x1, MouseOverMarkerVertOffset, TSampleMarker.smSampleEndMarker);
        end;

        smLoopStartMarker:
        begin
          if (ShowLoopPoints) and (LoopStart <> -1) then
          begin
            x1 := LoopStart;
            x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(x1, SampleFrames, Width, Zoom, Offset);
            Draw_LoopStart(x1);
            Draw_MarkerTag(x1, MouseOverMarkerVertOffset, TSampleMarker.smLoopStartMarker);
          end;

        end;

        smLoopEndMarker:
        begin
          if (ShowLoopPoints) and (LoopEnd <> -1) then
          begin
            x1 := LoopEnd;
            x1 := VamSampleDisplayBackBuffer.SamplePosToPixelPos(x1, SampleFrames, Width, Zoom, Offset);
            Draw_LoopEnd(x1);
            Draw_MarkerTag(x1, MouseOverMarkerVertOffset, TSampleMarker.smLoopEndMarker);
          end;
        end;
      end;
    end;



    if (IsZooming) and (ZoomDragx1 <> ZoomDragx2) then
    begin
      Draw_ZoomSelection(ZoomDragx1, ZoomDragx2);
    end;

    if (ShowReplaceMessage) then
    begin
      Draw_ReplaceMessage;
    end;

  end;

end;

procedure TLuciditySampleOverlay.Draw_MarkerTag(const xPos, yPos: single; const aMarker: TSampleMarker);
const
  kSpacer = 4;
  kInternalSpacer = 2;
var
  Text : string;
  tw, th : integer;
  tx, ty : single;
  RectWidth  : single;
  RectHeight : single;
  x1, y1, x2, y2 : single;
  TextColor : TRedFoxColor;
  TextBounds : TRect;
begin
  BackBuffer.BufferInterface.BlendMode := TAggBlendMode.bmSourceOver;

  case aMarker of
    smSampleStartMarker:
    begin
      TextColor := GetRedFoxColor(kSampleStart);
      Text := 'Sample Start';
    end;

    smSampleEndMarker:
    begin
      TextColor := GetRedFoxColor(kSampleEnd);
      Text := 'Sample End';
    end;

    smLoopStartMarker:
    begin
      TextColor := GetRedFoxColor(kLoopPoint);
      Text := 'Loop Start';
    end;

    smLoopEndMarker:
    begin
      TextColor := GetRedFoxColor(kLoopPoint);
      Text := 'Loop End';
    end;
  else
    raise Exception.Create('Type not handled.');
  end;

  BackBuffer.UpdateFont(Font);

  tw := round(BackBuffer.TextWidth(Text));
  th := round(BackBuffer.TextHeight);

  RectHeight := th + kInternalSpacer * 2;
  RectWidth  := tw + kInternalSpacer * 4;

  if xPos <= (Width div 3 * 2)
    then tx := round(xPos) + kSpacer
    else tx := round(xPos) - kSpacer - RectWidth;

  if yPos < (Height div 3)
    then ty := round(yPos) + (kSpacer * 2)
    else ty := round(yPos) - (kSpacer * 2) - RectHeight;

  x1 := round(tx) + 0.5;
  y1 := round(ty) - 0.5;
  x2 := round(tx + RectWidth) + 0.5;
  y2 := round(ty + RectHeight) - 0.5 + 1;


  TextBounds.Left  := round(tx) + 2;
  TextBounds.Top   := round(ty);
  TextBounds.Right  := round(tx + RectWidth);
  TextBounds.Bottom := round(ty + RectHeight);

  BackBuffer.BufferInterface.LineWidth := 1;
  BackBuffer.BufferInterface.LineColor := TextColor;
  BackBuffer.BufferInterface.FillColor := GetRedFoxColor(clBlack);


  BackBuffer.BufferInterface.Rectangle(x1, y1, x2, y2);

  BackBuffer.DrawText(Text, Font, TRedFoxAlign.AlignCenter, TRedFoxAlign.AlignCenter, TextBounds, TextColor);




end;



procedure TLuciditySampleOverlay.Draw_SampleStart(const xPos: single);
const
  kTagWidth  = 7;
  kTagHeight = 8;
  kCornerRadius = 3;
var
  x1,y1, x2, y2 : single;
  Rc: TAggRoundedRect;
  Path: TAggPathStorage;
begin
  BackBuffer.BufferInterface.LineWidth := 1;
  BackBuffer.BufferInterface.LineColor := GetRedFoxColor(kSampleStart).AsAggRgba8;
  BackBuffer.BufferInterface.FillColor := GetRedFoxColor(kSampleStart).AsAggRgba8;

  //== vertical marker line ==
  x1 := round(xPos) + 0.5;
  if (x1 > -1) and (x1 < 0) then x1 := x1 + 1;
  if (x1 > Width) and (x1 < Width + 1) then x1 := x1 - 1;
  BackBuffer.BufferInterface.Line(x1, 0, x1, Height);

  if ShowMarkerTags then
  begin
    //== the tag ==
    rc := TAggRoundedRect.Create;
    Path := TAggPathStorage.Create;
    try
      x2 := x1 + kTagWidth;
      y1 := Height - kTagHeight;
      y2 := Height;

      rc.Rect(x1,y1,x2,y2);
      rc.Radius(0, 0, kCornerRadius, kCornerRadius, kCornerRadius, kCornerRadius, 0, 0);
      Path.AddPath(rc);

      BackBuffer.BufferInterface.ResetPath;
      BackBuffer.BufferInterface.AddPath(Path);
      BackBuffer.BufferInterface.DrawPath;
    finally
      rc.Free;
      Path.Free;
    end;
  end;

end;

procedure TLuciditySampleOverlay.Draw_SampleEnd(const xPos: single);
const
  kTagWidth  = 7;
  kTagHeight = 8;
  kCornerRadius = 3;
var
  x1,y1, x2, y2 : single;
  Rc: TAggRoundedRect;
  Path: TAggPathStorage;
begin
  BackBuffer.BufferInterface.LineWidth := 1;
  BackBuffer.BufferInterface.LineColor := GetRedFoxColor(kSampleEnd).AsAggRgba8;
  BackBuffer.BufferInterface.FillColor := GetRedFoxColor(kSampleEnd).AsAggRgba8;

  //== vertical marker line ==
  x1 := round(xPos) - 0.5;
  if (x1 > -1) and (x1 < 0) then x1 := x1 + 1;
  if (x1 > Width) and (x1 < Width + 1) then x1 := x1 - 1;
  BackBuffer.BufferInterface.Line(x1, 0, x1, Height);

  if ShowMarkerTags then
  begin
    //== the tag ==
    rc := TAggRoundedRect.Create;
    Path := TAggPathStorage.Create;
    try
      x2 := x1;
      x1 := x1 - kTagWidth;
      y1 := Height - kTagHeight;
      y2 := Height;

      rc.Rect(x1,y1,x2,y2);
      rc.Radius(kCornerRadius, kCornerRadius, 0, 0, 0, 0, kCornerRadius, kCornerRadius);
      Path.AddPath(rc);

      BackBuffer.BufferInterface.ResetPath;
      BackBuffer.BufferInterface.AddPath(Path);
      BackBuffer.BufferInterface.DrawPath;
    finally
      rc.Free;
      Path.Free;
    end;
  end;

end;

procedure TLuciditySampleOverlay.Draw_LoopStart(const xPos: single);
const
  kTagWidth  = 7;
  kTagHeight = 8;
var
  Path: TAggPathStorage;
  x1 : single;
begin
  BackBuffer.BufferInterface.LineWidth := 1;
  BackBuffer.BufferInterface.LineColor := GetRedFoxColor(kLoopPoint).AsAggRgba8;
  BackBuffer.BufferInterface.FillColor := GetRedFoxColor(kLoopPoint).AsAggRgba8;

  //== vertical marker line ==
  x1 := round(xPos) + 0.5;
  if (x1 > -1) and (x1 < 0) then x1 := x1 + 1;
  if (x1 > Width) and (x1 < Width + 1) then x1 := x1 - 1;
  BackBuffer.BufferInterface.Line(x1, 0, x1, Height);

  if ShowMarkerTags then
  begin
    //== the tag ==
    Path := TAggPathStorage.Create;
    try
      Path.MoveTo(x1, 0);
      Path.LineTo(x1 + kTagWidth, 0);
      Path.LineTo(x1, kTagHeight);
      Path.ClosePolygon;

      BackBuffer.BufferInterface.ResetPath;
      BackBuffer.BufferInterface.AddPath(Path);
      BackBuffer.BufferInterface.DrawPath;
    finally
      Path.Free;
    end;
  end;

end;

procedure TLuciditySampleOverlay.Draw_LoopEnd(const xPos: single);
const
  kTagWidth  = 7;
  kTagHeight = 8;
var
  Path: TAggPathStorage;
  x1 : single;
begin
  BackBuffer.BufferInterface.LineWidth := 1;
  BackBuffer.BufferInterface.LineColor := GetRedFoxColor(kLoopPoint).AsAggRgba8;
  BackBuffer.BufferInterface.FillColor := GetRedFoxColor(kLoopPoint).AsAggRgba8;

  //== vertical marker line ==
  x1 := round(xPos) - 0.5;
  if (x1 > -1) and (x1 < 0) then x1 := x1 + 1;
  if (x1 > Width) and (x1 < Width + 1) then x1 := x1 - 1;
  BackBuffer.BufferInterface.Line(x1, 0, x1, Height);

  if ShowMarkerTags then
  begin
    //== the tag ==
    Path := TAggPathStorage.Create;
    try
      Path.MoveTo(x1, 0);
      Path.LineTo(x1 - kTagWidth, 0);
      Path.LineTo(x1, kTagHeight);
      Path.ClosePolygon;

      BackBuffer.BufferInterface.ResetPath;
      BackBuffer.BufferInterface.AddPath(Path);
      BackBuffer.BufferInterface.DrawPath;
    finally
      Path.Free;
    end;
  end;

end;

procedure TLuciditySampleOverlay.Draw_PlayBackPosition(const xPos: single);
var
  x1, y1, y2 : single;
begin
  BackBuffer.BufferInterface.LineColor := GetRedFoxColor('$FFFFFFFF').AsAggRgba8;
  BackBuffer.BufferInterface.NoFill;
  x1 := round(xPos) + 0.5;
  y1 := 0;
  y2 := self.Height;

  BackBuffer.BufferInterface.Line(X1, Y1, x1, Y2);
end;

procedure TLuciditySampleOverlay.Draw_ModLoopPoint(const xPos: single);
var
  x1, y1, y2 : single;
begin
  BackBuffer.BufferInterface.LineColor := GetRedFoxColor(kLoopPoint).AsAggRgba8;
  BackBuffer.BufferInterface.NoFill;
  x1 := round(xPos) + 0.5;
  y1 := 0;
  y2 := self.Height;

  BackBuffer.BufferInterface.Line(X1, Y1, x1, Y2);
end;

procedure TLuciditySampleOverlay.Draw_ZoomSelection(const x1, x2: integer);
begin

  BackBuffer.BufferInterface.NoLine;
  BackBuffer.BufferInterface.FillColor := GetRedFoxColor(kZoomSelectionColor, 40);

  if x1 <> x2 then
  begin
    backBuffer.BufferInterface.Rectangle(x1, 0, x2, Height);
  end;

  BackBuffer.BufferInterface.LineColor := GetRedFoxColor(kZoomSelectionColor);
  BackBuffer.BufferInterface.NoFill;



  BackBuffer.BufferInterface.Line(X1+0.5, 0, x1+0.5, Height);
  BackBuffer.BufferInterface.Line(X2+0.5, 0, x2+0.5, Height);
end;

procedure TLuciditySampleOverlay.Draw_ReplaceMessage;
var
  tw, th : single;
  Text : string;
  RectWidth  : single;
  RectHeight : single;
  tx, ty : single;
  x1,y1, x2, y2 : single;
  TextBounds : TRect;
  TextColor : TRedFoxColor;
begin
  BackBuffer.BufferInterface.BlendMode := TAggBlendMode.bmSourceOver;
  BackBuffer.UpdateFont(MessageFont);

  Text := 'Replace Sample';

  tw := round(BackBuffer.TextWidth(Text));
  th := round(BackBuffer.TextHeight);

  RectHeight := th + 20;
  RectWidth  := tw + 60;

  tx := (Width  - RectWidth)  * 0.5;
  ty := (Height - RectHeight) * 0.5;

  //x1 := round(tx) + 0.5;
  //y1 := round(ty) - 0.5;
  //x2 := round(tx + RectWidth) + 0.5;
  //y2 := round(ty + RectHeight) - 0.5 + 1;

  x1 := round(tx);
  y1 := round(ty);
  x2 := round(tx + RectWidth);
  y2 := round(ty + RectHeight);

  BackBuffer.BufferInterface.FillColor := GetRedFoxColor(kBackgroundColor);
  BackBuffer.BufferInterface.LineColor := GetRedFoxColor(kMessageColor);
  BackBuffer.BufferInterface.LineWidth := 2;
  BackBuffer.BufferInterface.RoundedRect(x1, y1, x2, y2, 3);

  TextBounds.Left   := round(x1);
  TextBounds.Top    := round(y1);
  TextBounds.Right  := round(x2);
  TextBounds.Bottom := round(y2);

  TextColor := GetRedFoxColor(kMessageColor);

  BackBuffer.DrawText(Text, MessageFont, TRedFoxAlign.AlignCenter, TRedFoxAlign.AlignCenter, TextBounds, TextColor);


end;














end.
