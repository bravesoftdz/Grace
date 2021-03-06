unit soSignalRecorder;

interface

uses
  VamLib.ZeroObject,
  eeGlobals,
  VamLib.MoreTypes,
  LucidityGui.Scope.SignalRecorder;

type
  TSignalRecorder = class(TZeroObject, IScopeSignalRecorder)
  private
    procedure GetReadPointer(out WriteIndex, BufferSize : integer; out Buffer : PArrayOfSingle);
  protected
    Globals : TGlobals;

    Buffer : TArrayOfSingle;
    BufferSize : integer;
    WriteIndex : integer;
    WriteCount : integer;
    procedure SampleRateChanged(Sender : TObject);
  public
    constructor Create(const aGlobals: TGlobals);
    destructor Destroy; override;

    procedure Process(Input1, Input2 : PSingle; SampleFrames : integer);
  end;

implementation

uses
  Math,
  eeCustomGlobals;

{ TSignalRecorder }

constructor TSignalRecorder.Create;
begin
  Globals := aGlobals;
  Globals.AddEventListener(TPluginEvent.SampleRateChanged, SampleRateChanged);


  SampleRateChanged(self);
end;

destructor TSignalRecorder.Destroy;
begin
  BufferSize := 0;
  SetLength(Buffer, 0);
  inherited;
end;

procedure TSignalRecorder.GetReadPointer(out WriteIndex, BufferSize : integer; out Buffer : PArrayOfSingle);
begin
  BufferSize := Self.BufferSize;
  WriteIndex := Self.WriteIndex;
  Buffer     := @Self.Buffer;
end;

procedure TSignalRecorder.SampleRateChanged(Sender: TObject);
begin
  BufferSize := Globals.SampleRate * 4;
  SetLength(Buffer, BufferSize);
  WriteIndex := 0;
end;

procedure TSignalRecorder.Process(Input1, Input2: PSingle; SampleFrames: integer);
var
  c1: Integer;
begin
  for c1 := 0 to SampleFrames-1 do
  begin
    Buffer[WriteIndex] := (Input1^ + Input2^) * 0.5;
    inc(WriteIndex);
    inc(WriteCount);
    if WriteIndex >= BufferSize then WriteIndex := 0;
    inc(Input1);
    inc(Input2);
  end;
end;



end.
