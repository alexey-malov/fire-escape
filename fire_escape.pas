PROGRAM FireEscape;


CONST
  InputFileName = 'c:\teaching\fire-escape\plan.txt';
  MAX_PLAN_WIDTH = 100;
  MAX_PLAN_HEIGHT = 100;
  NO_WAVE = 0;
  FIRE_STEP = 2;

TYPE
  MapFieldType = (
    Empty,  {пустое пространство}
    Wall,   {стена}
    Fire,   {очаг возгорани€}
    Escape, {выход}
    Person, {челове}
    Fire2,  {вторичный очаг возгорани€}
    Trace,  {—лед спасени€ человека}
    BurnedTrace, {объ€тый пламенем след перемещени€ человека}
    FoundEscape {найденный выход}
  );

  BuildingPlanMap = ARRAY[1..MAX_PLAN_HEIGHT, 1..MAX_PLAN_WIDTH] OF MapFieldType;  
 
  MapCoord = RECORD
    Row, Column: Integer;
  END;

  BuildingPlan = RECORD
    Width, Height: Integer;
    Map: BuildingPlanMap;
    PersonPos: MapCoord;
  END;

  WaveMap = ARRAY[1..MAX_PLAN_HEIGHT, 1..MAX_PLAN_WIDTH] OF Integer;


FUNCTION CharToMapField(Ch: CHAR): MapFieldType;
BEGIN
  CASE Ch OF
    ' ': CharToMapField := Empty;
    '#': CharToMapField := Wall;
    'X': CharToMapField := Fire;
    'E': CharToMapField := Escape;
    'O': CharToMapField := Person;
    ELSE CharToMapField := Empty;
  END
END;

FUNCTION MapFieldToChar(Field: MapFieldType): CHAR;
BEGIN
  CASE Field OF
    Empty:        MapFieldToChar := ' ';
    Wall:         MapFieldToChar := '#';
    Fire:         MapFieldToChar := 'X';
    Escape:       MapFieldToChar := 'E';
    Person:       MapFieldToChar := 'O';
    Fire2:        MapFieldToChar := 'x';
    Trace:        MapFieldToChar := '.';
    BurnedTrace:  MapFieldToChar := '*';
    FoundEscape:  MapFieldToChar := '!';
  END
END;

FUNCTION Maximum(X, Y: Integer): Integer;
BEGIN
  IF X > Y THEN
    Maximum := X
  ELSE
    Maximum := Y
END;

FUNCTION ReadBuildingPlanFromFile(FileName: STRING): BuildingPlan;
VAR
  Plan: BuildingPlan;
  InputFile: TEXT;
  Line: String;
  I, Row, Column: Integer;
  Field: MapFieldType;
BEGIN 
  Plan.Width := 0;
  Plan.Height := 0;
  Row := 0;

  Assign(InputFile, FileName);
  Reset(InputFile);
  WHILE NOT EOF(InputFile) DO
  BEGIN
    READLN(InputFile, Line);

    INC(Row);
    Column := 0;
    
    FOR I := 1 TO Length(Line) DO
    BEGIN
      INC(Column);
      Field := CharToMapField(Line[i]);
      Plan.Map[Row, Column] := Field;
      IF Field = Person THEN
      BEGIN
        Plan.PersonPos.Column := Column;
        Plan.PersonPos.Row := Row
      END
    END;
    
    Plan.Width := Maximum(Column, Plan.Width);
  END;
  Plan.Height := Maximum(Row, Plan.Height);

  ReadBuildingPlanFromFile := Plan;
  IF FileName <> '' THEN Close(InputFile)
END;

PROCEDURE WriteBuildingPlanToFile(FileName: STRING; VAR Plan: BuildingPlan);
VAR
  OutputFile: TEXT;
  Row, Column: Integer;
BEGIN
  Assign(OutputFile, FileName);
  Rewrite(OutputFile);

  FOR Row := 1 TO Plan.Height DO
  BEGIN
    FOR Column := 1 TO Plan.Width DO
    BEGIN
      Write(OutputFile, MapFieldToChar(Plan.Map[Row, Column]))
    END;
    WRITELN(OutputFile)
  END;

  Close(OutputFile)
END;

FUNCTION StepTo(Row, Column: Integer; StepIndex: Integer; VAR Plan: BuildingPlan; VAR Wave: WaveMap; VAR MadeSteps: Integer): BOOLEAN;
BEGIN
  StepTo := FALSE;
  IF (Row > 0) AND (Column > 0) AND (Row <= Plan.Height) AND (Column <= Plan.Width) THEN
    IF Wave[Row, Column] = NO_WAVE THEN
      CASE Plan.Map[Row, Column] OF
        Empty: 
          BEGIN
            Wave[Row, Column] := StepIndex;
            INC(MadeSteps)
          END;
        Escape:
          BEGIN
            Wave[Row, Column] := StepIndex;
            INC(MadeSteps);
            StepTo := TRUE
          END;
      END;
END;

FUNCTION StepToNeighbors(Row: Integer; Column: Integer; StepIndex: Integer; VAR Plan: BuildingPlan; VAR Wave: WaveMap; VAR MadeSteps: Integer): BOOLEAN;
VAR
  EscapeWasFound: BOOLEAN;
BEGIN
  EscapeWasFound := StepTo(Row, Column + 1, StepIndex, Plan, Wave, MadeSteps);
  EscapeWasFound := StepTo(Row, Column - 1, StepIndex, Plan, Wave, MadeSteps) OR EscapeWasFound;
  EscapeWasFound := StepTo(Row + 1, Column, StepIndex, Plan, Wave, MadeSteps) OR EscapeWasFound;
  EscapeWasFound := StepTo(Row - 1, Column, StepIndex, Plan, Wave, MadeSteps) OR EscapeWasFound;
  StepToNeighbors := EscapeWasFound;
END;

type WavePropagationResult = (NoWay, Stepped, Escaped);

FUNCTION PropagateWave(VAR Plan: BuildingPlan; VAR Wave: WaveMap; StepIndex: Integer): WavePropagationResult;
VAR
  Row, Column: Integer;
  MadeSteps: Integer;
BEGIN
  MadeSteps := 0;
  FOR Row := 1 TO Plan.Height DO
    FOR Column := 1 TO Plan.Width DO
      IF Wave[Row][Column] = StepIndex THEN
        IF StepToNeighbors(Row, Column, StepIndex + 1, Plan, Wave, MadeSteps) THEN
        BEGIN
          PropagateWave := Escaped;
          EXIT;
        END;
  IF MadeSteps > 0 THEN
    PropagateWave := Stepped
  ELSE
    PropagateWave := NoWay
END;

PROCEDURE BurnField(VAR Plan: BuildingPlan; Y, X: Integer);
BEGIN
  IF (X >= 1) AND (X <= Plan.Width) AND (Y >= 1) AND (Y <= Plan.Height) THEN
    IF (Plan.Map[Y, X] = Empty) OR (Plan.Map[Y, X] = Escape) THEN
      Plan.Map[Y, X] := Fire2
END;

PROCEDURE PropagateFire(VAR Plan: BuildingPlan; VAR Wave: WaveMap; StepIndex: Integer);
VAR
  X, Y: Integer;
  OldPlan: BuildingPlan;
BEGIN
  OldPlan := Plan;

  FOR Y := 1 TO Plan.Height DO
    FOR X := 1 TO Plan.Width DO
      IF (OldPlan.Map[Y, X] = Fire) OR (OldPlan.Map[Y, X] = Fire2) THEN
      BEGIN
        BurnField(Plan, Y, X + 1);
        BurnField(Plan, Y, X - 1);
        BurnField(Plan, Y + 1, X);
        BurnField(Plan, Y - 1, X)
      END;

  {«атираем текущий фронт волны в тех местах, где он пересекаетс€ с фронтом огн€}
  FOR Y := 1 TO Plan.Height DO
    FOR X := 1 TO Plan.Width DO
      IF (Wave[Y, X] = StepIndex) AND (Plan.Map[Y, X] = Fire2) THEN
        Wave[Y, X] := 0
END;

FUNCTION FindEscape(VAR Plan: BuildingPlan; VAR Wave: WaveMap; StepIndex: Integer): MapCoord;
VAR
  Y, X: Integer;
  EscapeCoord: MapCoord;
BEGIN
  FOR Y := 1 TO Plan.Height DO
    FOR X := 1 TO Plan.Width DO
      IF (Wave[Y, X] = StepIndex) AND (Plan.Map[Y, X] = Escape) THEN
      BEGIN
        EscapeCoord.Row := Y;
        EscapeCoord.Column := X;
        FindEscape := EscapeCoord;
        EXIT
      END;
  EscapeCoord.Row := 0;
  EscapeCoord.Column := 0;
  FindEscape := EscapeCoord
END;

FUNCTION TraceField(Field: MapFieldType): MapFieldType;
BEGIN
  CASE Field OF
    Escape: TraceField := FoundEscape;
    Empty: TraceField := Trace;
    Fire: TraceField := BurnedTrace;
    Fire2: TraceField := BurnedTrace;
    ELSE TraceField := Field;
  END;
END;

FUNCTION TraceStep(VAR Plan: BuildingPlan; VAR Wave: WaveMap; Row, Column, StepIndex: Integer): BOOLEAN;
BEGIN
  IF (Row >= 1) AND (Row <= Plan.Height) AND (Column >= 1) AND (Row <= Plan.Width) THEN
    IF Wave[Row, Column] = StepIndex THEN
    BEGIN
      TraceStep := TRUE;
      Plan.Map[Row, Column] := TraceField(Plan.Map[Row, Column])
    END
  ELSE
    TraceStep := FALSE
END;

PROCEDURE TracePath(VAR Plan: BuildingPlan; VAR Wave: WaveMap; StepIndex: Integer);
VAR
   Pos: MapCoord;
BEGIN
  Pos := FindEscape(Plan, Wave, StepIndex);
  WRITELN(StepIndex);
  Plan.Map[Pos.Row, Pos.Column] := FoundEscape;
  REPEAT
    DEC(StepIndex);
    IF TraceStep(Plan, Wave, Pos.Row + 1, Pos.Column, StepIndex) THEN
      INC(Pos.Row)
    ELSE IF TraceStep(Plan, Wave, Pos.Row - 1, Pos.Column, StepIndex) THEN
      DEC(Pos.Row)
    ELSE IF TraceStep(Plan, Wave, Pos.Row, Pos.Column + 1, StepIndex) THEN
      INC(Pos.Column)
    ELSE IF TraceStep(Plan, Wave, Pos.Row, Pos.Column - 1, StepIndex) THEN
      DEC(Pos.Column)
    ELSE
      BEGIN
        WriteLn('Halted');
        HALT
      END
  UNTIL StepIndex = 1
END;

PROCEDURE DebugWave(VAR Plan: BuildingPlan; VAR Wave: WaveMap);
VAR
  X, Y: Integer;
BEGIN
  FOR Y := 1 TO Plan.Height DO
  BEGIN
    FOR X := 1 TO Plan.Width DO
      Write(Wave[Y, X] MOD 10);
    WRITELN
  END;
  WRITELN
    
END;

PROCEDURE ClearWave(VAR Wave: WaveMap);
VAR
  X, Y: Integer;
BEGIN
  FOR Y := 1 TO MAX_PLAN_HEIGHT DO
    FOR X := 1 TO MAX_PLAN_WIDTH DO
      Wave[Y, X] := 0;      
END;

FUNCTION FindPath(VAR Plan: BuildingPlan): BOOLEAN;
VAR
  Wave: WaveMap;
  StepIndex: Integer;
  FireStep: Integer;
BEGIN
  StepIndex := 1;
  ClearWave(Wave);
  Wave[Plan.PersonPos.Row, Plan.PersonPos.Column] := StepIndex;
  FindPath := FALSE;
  FireStep := 0;
  WHILE TRUE DO
  BEGIN
    CASE PropagateWave(Plan, Wave, StepIndex) OF
      Escaped: BREAK;
      Stepped: INC(StepIndex);
      NoWay: EXIT;
    END;

    INC(FireStep);
    IF FireStep = FIRE_STEP THEN
    BEGIN
      PropagateFire(Plan, Wave, StepIndex);
      FireStep := 0
    END
  END;
  TracePath(Plan, Wave, StepIndex + 1);
  FindPath := TRUE
END;

VAR
  Plan: BuildingPlan;
BEGIN
  Plan := ReadBuildingPlanFromFile(InputFileName);
  WriteBuildingPlanToFile('', Plan);
  
  WriteLn('---------------');

  IF FindPath(Plan) THEN
    WRITELN('Found an escape')
  ELSE
    WRITELN('Found no way');

  WriteBuildingPlanToFile('', Plan); 
  

  READLN
END.
