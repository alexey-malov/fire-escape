PROGRAM FireEscape;


CONST
  InputFileName = 'c:\teaching\fire-escape\plan.txt';
  MAX_PLAN_WIDTH = 100;
  MAX_PLAN_HEIGHT = 100;
  NO_WAVE = 0;

TYPE
  MapFieldType = (
    Empty,  {пустое пространство}
    Wall,   {стена}
    Fire,   {очаг возгорания}
    Escape, {выход}
    Person, {челове}
    Fire2,  {вторичный очаг возгорания}
    Trace,  {След спасения человека}
    BurnedTrace, {объятый пламенем след перемещения человека}
    FoundEscape {найденный выход}
  );

  StepResult = (Stepped, CantStep, Escaped);

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
    
    Plan.Width := MAX(Column, Plan.Width);
  END;
  Plan.Height := MAX(Row, Plan.Height);

  ReadBuildingPlanFromFile := Plan;  
  Close(InputFile)
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

FUNCTION StepTo(Row: Integer; Column: Integer; StepIndex: Integer; VAR Plan: BuildingPlan; VAR Wave: WaveMap; VAR MadeSteps: Integer): BOOLEAN;
BEGIN
  Result := FALSE;
  IF (Row > 0) AND (Column > 0) AND (Row <= Plan.Height) AND (Column <= Plan.Width) THEN
  BEGIN
    IF Wave[Row, Column] = NO_WAVE THEN
    BEGIN
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
            Result := TRUE
          END;
      END;
    END
  END
END;

FUNCTION StepToNeighbors(Row: Integer; Column: Integer; StepIndex: Integer; VAR Plan: BuildingPlan; VAR Wave: WaveMap; VAR MadeSteps: Integer): BOOLEAN;
BEGIN
  Result := 
    StepTo(Row, Column + 1, StepIndex, Plan, Wave, MadeSteps) OR
    StepTo(Row, Column - 1, StepIndex, Plan, Wave, MadeSteps) OR
    StepTo(Row + 1, Column, StepIndex, Plan, Wave, MadeSteps) OR
    StepTo(Row - 1, Column, StepIndex, Plan, Wave, MadeSteps)
END;

FUNCTION PropagateWave(VAR Plan: BuildingPlan; VAR Wave: WaveMap): BOOLEAN;
VAR
  Row, Column: Integer;
  Res: MapCoord;
  LastStepResult: StepResult;
  MadeSteps: Integer;
  StepIndex: Integer;
BEGIN
  StepIndex := 1;
  Wave[Plan.PersonPos.Row, Plan.PersonPos.Column] := StepIndex;
  REPEAT
    MadeSteps := 0;
    FOR Row := 1 TO Plan.Height DO
    BEGIN
      FOR Column := 1 TO Plan.Width DO
      BEGIN
        IF Wave[Row][Column] = StepIndex THEN
        BEGIN
          IF StepToNeighbors(Row, Column, StepIndex + 1, Plan, Wave, MadeSteps) THEN
          BEGIN
            Result := TRUE;
            EXIT
          END
        END
      END
    END;
    INC(StepIndex)
  UNTIL MadeSteps = 0;
END;

VAR
  Plan: BuildingPlan;
BEGIN
  Plan := ReadBuildingPlanFromFile(InputFileName);
  WriteBuildingPlanToFile('', Plan);
  READLN
END.
