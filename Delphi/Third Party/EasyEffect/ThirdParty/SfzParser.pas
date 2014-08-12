unit SfzParser;

interface

uses
  Classes, Contnrs;

type
  TSFZTokenType = (ttUnknown, ttComment, ttGroup, ttRegion, ttMultipleOpcodes, ttOpcode);

  // Events
  TOpcodeEvent = procedure(Sender : TObject; OpcodeName, OpcodeValue : string) of object;





  TSfzParser = class
  private
    OpcodeList : TObjectList;
    fOnRegionStart: TNotifyEvent;
    fOnRegionEnd: TNotifyEvent;
    fOnRegionOpcode: TOpcodeEvent;
    fOnGroupEnd: TNotifyEvent;
    fOnGroupStart: TNotifyEvent;
  protected
    IsRegionOpen : boolean;
    IsGroupOpen  : boolean;

    procedure ParseLine(s : string);
    function FindTokenType(s : string):TSfzTokenType;

    procedure ProcessUnknown(s : string);
    procedure ProcessComment(s : string);
    procedure ProcessRegion(s : string);
    procedure ProcessGroup(s : string);
    procedure ProcessMultipleOpcodes(s : string);
    procedure ProcessOpcode(s : string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure ParseFile(Filename : string);
    procedure ParseText(Text : TStringList);

    property OnGroupStart  : TNotifyEvent read fOnGroupStart write fOnGroupStart;
    property OnGroupEnd    : TNotifyEvent read fOnGroupEnd   write fOnGroupEnd;

    property OnRegionStart : TNotifyEvent read fOnRegionStart write fOnRegionStart;
    property OnRegionEnd   : TNotifyEvent read fOnRegionEnd   write fOnRegionEnd;

    property OnRegionOpcode : TOpcodeEvent read fOnRegionOpcode write fOnRegionOpcode;
  end;




implementation

uses
  Types,
  eeFunctions,
  SysUtils,
  StrUtils;

const
  kMaxInt = High(Integer);


function Occurrences(const Substring, Text: string): integer;
var
  offset: integer;
begin
  result := 0;
  offset := PosEx(Substring, Text, 1);
  while offset <> 0 do
  begin
    inc(result);
    offset := PosEx(Substring, Text, offset + length(Substring));
  end;
end;




{ TSfzParser }

constructor TSfzParser.Create;
begin
  OpcodeList := TObjectList.Create;
  OpcodeList.OwnsObjects := true;
end;

destructor TSfzParser.Destroy;
begin
  OpcodeList.Free;
  inherited;
end;


procedure TSfzParser.ParseFile(Filename: string);
var
  Text : TStringList;
begin
  Text := TStringList.Create;
  try
    Text.LoadFromFile(FileName);
    ParseText(Text);
  finally
    Text.Free;
  end;
end;

procedure TSfzParser.ParseText(Text: TStringList);
var
  c1: Integer;
begin
  IsRegionOpen := false;
  IsGroupOpen  := false;

  for c1 := 0 to Text.Count-1 do
  begin
    ParseLine(Text[c1]);
  end;

  if IsRegionOpen then
  begin
    if assigned(OnRegionEnd) then OnRegionEnd(self);
    IsRegionOpen := false;
  end;

  if IsGroupOpen then
  begin
    if assigned(OnGroupEnd) then OnGroupEnd(self);
    IsGroupOpen := false;
  end;
end;

procedure TSfzParser.ParseLine(s: string);
var
  TokenType : TSfzTokenType;
begin
  s := Trim(s);

  if s <> '' then
  begin
    TokenType := FindTokenType(s);

    case TokenType of
      ttUnknown:         ProcessUnknown(s);
      ttComment:         ProcessComment(s);
      ttGroup:           ProcessGroup(s);
      ttRegion:          ProcessRegion(s);
      ttMultipleOpcodes: ProcessMultipleOpcodes(s);
      ttOpcode:          ProcessOpcode(s);
    else
      raise Exception.Create('Unexpected token type.');
    end;
  end;
end;

function TSfzParser.FindTokenType(s: string): TSfzTokenType;
var
  x : integer;
begin
  //== Check for comment ==
  if StartsText('//', s) then exit(ttComment);


  //== Check for group ==
  if SameText('<group>', s) then exit(ttGroup);

  //== Check for region ==
  if SameText('<region>', s) then exit(ttRegion);

  //== Check for opcodes ==
  x := Occurrences('=', s);
  if x = 1 then exit(ttOpcode);
  if x > 1 then exit(ttMultipleOpcodes);

  //== token type is unknown if we've made it this far ==
  result := ttUnknown;
end;


procedure TSfzParser.ProcessComment(s: string);
begin
  //It's a comment. Don't do anything.
end;

procedure TSfzParser.ProcessMultipleOpcodes(s: string);
var
  Lines : TStringDynArray;
  c1: Integer;
begin
  Lines := SplitString(s, ' ');

  for c1 := 0 to Length(Lines)-1 do
  begin
    if FindTokenType(Lines[c1]) = ttMultipleOpcodes then
    begin
      ProcessUnknown('**ERROR**' + Lines[c1] + '**ERROR**');
    end else
    begin
      ParseLine(Lines[c1]);
    end;
  end;

end;

procedure TSfzParser.ProcessOpcode(s: string);
var
  OpcodeName, OpcodeValue : string;
  Lines : TStringDynArray;
begin
  Lines := SplitString(s, '=');

  if Length(Lines) = 2 then
  begin
    OpcodeName  := Lines[0];
    OpcodeValue := Lines[1];
    if assigned(OnRegionOpcode) then OnRegionOpcode(self, OpcodeName, OpcodeValue);
  end;
end;

procedure TSfzParser.ProcessGroup(s: string);
begin
  if IsGroupOpen then
  begin
    if assigned(OnGroupEnd)   then OnGroupEnd(self);
    if assigned(OnGroupStart) then OnGroupStart(self);
  end else
  begin
    if assigned(OnGroupStart) then OnGroupStart(self);
    IsGroupOpen := true;
  end;
end;

procedure TSfzParser.ProcessRegion(s: string);
begin
  if IsRegionOpen then
  begin
    if assigned(OnRegionEnd)   then OnRegionEnd(self);
    if assigned(OnRegionStart) then OnRegionStart(self);
  end else
  begin
    if assigned(OnRegionStart) then OnRegionStart(self);
    IsRegionOpen := true;
  end;
end;

procedure TSfzParser.ProcessUnknown(s: string);
begin

end;






end.
