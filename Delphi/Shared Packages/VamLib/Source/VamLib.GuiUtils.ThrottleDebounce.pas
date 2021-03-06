unit VamLib.GuiUtils.ThrottleDebounce;

interface

uses
  SysUtils,
  VamLib.OneShotTimer;

///  Throttle - Debounce
///
///  TODO:MED
///
///  It would be possible to create a dynamic throttle-debounce system where all
///  the client code wouldn't need to maintain individual instances of Throttle
///  and Debounce tokens. Instead, the using code could be passing in
///  unassigned object tokens as VAR method variables.
///  The throttle-debounce code would check if the token was assigned, if not
///  it would assign an unused token to the variable.
///  Once debouncing was finished the original VAR token would be cleared,
///  releasing the token instance back into the unused token group.
///
///  This dynamic system would allow throttle-debouncing to be used liberally
///  without too many concerns about creating too many objects that would
///  only be infrequently used.

type
  TThrottleToken = class
  private
    TimerID : cardinal;
    CallRef : TProc;
    LastCallTime : TDateTime;
    IsTrailingCallRequired : Boolean;
    IsActive : boolean;
    ThrottleTime : integer;
    procedure Run;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Throttle(const Milliseconds : integer; Task : TProc);
    procedure Cancel;
  end;


  TDebounceEdge = (deLeading, deTrailing, deBoth);

  TDebounceToken = class
  private
    TimerID : cardinal;
    CallRef : TProc;
    LastCallTime : TDateTime;
    IsTrailingCallRequired : Boolean;
    IsActive : boolean;
    DebounceTime : integer;
    DebounceEdge : TDebounceEdge;
    procedure Run;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Debounce(const Milliseconds : integer; const Edge : TDebounceEdge; Task : TProc);
    procedure Cancel;
  end;

implementation

uses
  DateUtils;

{ TThrottleToken }

constructor TThrottleToken.Create;
begin

end;

destructor TThrottleToken.Destroy;
begin
  Cancel;
  inherited;
end;


procedure TThrottleToken.Throttle(const Milliseconds: integer; Task: TProc);
begin
  if not IsActive then
  begin
    IsActive := true;
    IsTrailingCallRequired := false;
    CallRef := Task;
    ThrottleTime := Milliseconds;
    CallRef();
    LastCallTime := now;
    TimerID := SetTimeOut(Run, Milliseconds);
  end else
  begin
    CallRef := Task;
    IsTrailingCallRequired := true;;
    ThrottleTime := Milliseconds;
  end;
end;

procedure TThrottleToken.Cancel;
begin
  ClearTimeout(TimerID);
  IsActive := false;
  CallRef := nil;
end;

procedure TThrottleToken.Run;
begin
  if IsTrailingCallRequired then
  begin
    if not WithinPastMilliSeconds(Now, LastCallTime, ThrottleTime-1) then
    begin
      CallRef();
      LastCallTime := now;
      IsTrailingCallRequired := false;
      SetTimeOut(run, TimerID, ThrottleTime);
    end else
    begin
      SetTimeOut(run, TimerID, ThrottleTime div 2);
    end;
  end else
  begin
    IsActive := false;
  end;
end;





{ TDebounceToken }

constructor TDebounceToken.Create;
begin

end;

destructor TDebounceToken.Destroy;
begin
  Cancel;
  inherited;
end;

procedure TDebounceToken.Cancel;
begin
  ClearTimeout(TimerID);
  IsActive := false;
  CallRef := nil;
end;

procedure TDebounceToken.Run;
begin
  if IsTrailingCallRequired then
  begin
    if not WithinPastMilliSeconds(Now, LastCallTime, DebounceTime-1) then
    begin
      if (DebounceEdge = deTrailing) or (DebounceEdge = deBoth)
        then CallRef();
      LastCallTime := now;
      IsTrailingCallRequired := false;
      SetTimeOut(run, TimerID, DebounceTime);
    end else
    begin
      SetTimeOut(run, TimerID, DebounceTime div 2);
    end;
  end else
  begin
    IsActive := false;
  end;
end;

procedure TDebounceToken.Debounce(const Milliseconds: integer; const Edge : TDebounceEdge; Task: TProc);
begin
  if not IsActive then
  begin
    IsActive := true;
    IsTrailingCallRequired := true;
    CallRef := Task;
    DebounceTime := Milliseconds;
    DebounceEdge := Edge;
    if (Edge = deLeading) or (Edge = deBoth)
      then CallRef();
    LastCallTime := now;
    TimerID := SetTimeOut(Run, Milliseconds);
  end else
  begin
    CallRef := Task;
    IsTrailingCallRequired := true;;
    LastCallTime := now;
    DebounceTime := Milliseconds;
    DebounceEdge := Edge;
  end;
end;




end.
