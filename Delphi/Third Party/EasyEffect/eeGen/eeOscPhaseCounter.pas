unit eeOscPhaseCounter;

{$EXCESSPRECISION OFF}

interface

type
  // TOscPhaseCounter is designed to be used as a phase counter for wavetable
  // oscillators. Normally the phase counter will be a 'float' type variable as
  // you usually need incement the phase by fractional amounts.
  // However wavetables are normally stored in an array which requires an 'integer'
  // index. Converting a 'float' phase to an 'integer' index is a slightly
  // expensive operation because it involves a Round() or Trunc() call.
  // It's possible to use an 'integer' phase counter to avoid the conversion.
  // The downside is 'integer' phase counters require more effort to use.
  // The phase counter now needs to be incremented by a 'integer' amount
  // relative to the size of the wavetable. Converting from the phase counter to
  // a table index and fractional offset requires slightly obsufacting math
  // operations.
  //
  // TOscPhaseCounter wraps an 'integer' phase counter and provides methods to
  // make it as intuitive as use as a float phase counter. The TOscPhaseCounter
  // also has the performance benefits of a 'integer' phase counter.
  //
  // You can eat your cake and hold it too!


  TOscPhaseCounter = record
    // http://docwiki.embarcadero.com/RADStudio/XE3/en/Operator_Overloading_%28Delphi%29
    class operator Explicit(a : TOscPhaseCounter):single;
    class operator Implicit(a : single):TOscPhaseCounter;
    class operator Add(a : TOscPhaseCounter; b : TOscPhaseCounter):TOscPhaseCounter;
    class operator Subtract(a : TOscPhaseCounter; b : TOscPhaseCounter):TOscPhaseCounter;
    class operator Equal(a : TOscPhaseCounter; b : TOscPhaseCounter):boolean;
    class operator NotEqual(a : TOscPhaseCounter; b : TOscPhaseCounter):boolean;
  private
    PhaseInt : cardinal;
  public
    function AsSingle : single;

    procedure IncBy(a : TOscPhaseCounter);
    procedure DecBy(a : TOscPhaseCounter);

    // WARNING: The overflow check only looks for overflows, not underflows.
    function IncByWithOverflowCheck(a : TOscPhaseCounter):boolean;

    procedure GetIndex256(out Index : integer; out Frac : single);
    procedure GetIndex512(out Index : integer; out Frac : single);
    procedure GetIndex1024(out Index : integer; out Frac : single);
    procedure GetIndex2048(out Index : integer; out Frac : single);
  end;

implementation

uses
  SysUtils;

const
  MaxCardinal = High(Cardinal);


// Turn off overflow checking. The phase counter takes advantage of overflow checking
// to allow the phase counter to 'wrap' around.
{$Q-}



{ TOscPhaseCounter }

class operator TOscPhaseCounter.Explicit(a: TOscPhaseCounter): single;
begin
  result := a.PhaseInt / MaxCardinal;
end;

class operator TOscPhaseCounter.Implicit(a: single): TOscPhaseCounter;
begin
  // NOTE: WARNING: The phase counter is always within a 0..1 range.
  // Values outside of this range will wrap around. IE. 2.3 will become 0.3.
  result.PhaseInt := round(a * MaxCardinal);
end;

class operator TOscPhaseCounter.Add(a, b: TOscPhaseCounter): TOscPhaseCounter;
begin
  result.PhaseInt := a.PhaseInt + b.PhaseInt;
end;

class operator TOscPhaseCounter.Subtract(a, b: TOscPhaseCounter): TOscPhaseCounter;
begin
  result.PhaseInt := a.PhaseInt - b.PhaseInt;
end;

class operator TOscPhaseCounter.Equal(a, b: TOscPhaseCounter): boolean;
begin
  result := (a.PhaseInt = b.PhaseInt);
end;

class operator TOscPhaseCounter.NotEqual(a, b: TOscPhaseCounter): boolean;
begin
  result := (a.PhaseInt <> b.PhaseInt);
end;

function TOscPhaseCounter.AsSingle: single;
begin
  result := PhaseInt / MaxCardinal;
end;

procedure TOscPhaseCounter.IncBy(a: TOscPhaseCounter);
begin
  Inc(PhaseInt, a.PhaseInt);
end;

procedure TOscPhaseCounter.DecBy(a: TOscPhaseCounter);
begin
  Dec(PhaseInt, a.PhaseInt);
end;



function TOscPhaseCounter.IncByWithOverflowCheck(a: TOscPhaseCounter): boolean;
var
  LastPhase : cardinal;
begin
  LastPhase := PhaseInt;
  Inc(PhaseInt, a.PhaseInt);

  if PhaseInt >= LastPhase
    then result := false
    else result := true;

end;


procedure TOscPhaseCounter.GetIndex256(out Index: integer; out Frac: single);
const
  ScaleFactor = 1/MaxCardinal*256;
  ShiftAmount = 24;
begin
  Index := PhaseInt shr ShiftAmount;
  Frac := (PhaseInt * ScaleFactor) - (PhaseInt shr ShiftAmount);
end;

procedure TOscPhaseCounter.GetIndex512(out Index: integer; out Frac: single);
const
  ScaleFactor = 1/MaxCardinal*512;
  ShiftAmount = 23;
begin
  Index := PhaseInt shr ShiftAmount;
  Frac := (PhaseInt * ScaleFactor) - (PhaseInt shr ShiftAmount);
end;

procedure TOscPhaseCounter.GetIndex1024(out Index: integer; out Frac: single);
const
  ScaleFactor = 1/MaxCardinal*1024;
  ShiftAmount = 22;
begin
  Index := PhaseInt shr ShiftAmount;
  Frac := (PhaseInt * ScaleFactor) - (PhaseInt shr ShiftAmount);
end;

procedure TOscPhaseCounter.GetIndex2048(out Index: integer; out Frac: single);
const
  ScaleFactor = 1/MaxCardinal*2048;
  ShiftAmount = 21;
begin
  Index := PhaseInt shr ShiftAmount;
  Frac := (PhaseInt * ScaleFactor) - (PhaseInt shr ShiftAmount);
end;


end.
