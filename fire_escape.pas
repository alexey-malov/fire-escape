PROGRAM FireEscape;


CONST
  InputFileName = 'c:\teaching\fire-escape\plan.txt';
  MAX_PLAN_WIDTH = 100;
  MAX_PLAN_HEIGHT = 100;

TYPE
  MapFieldType = (Empty, Wall, Fire, Escape, Person);

  BuildingPlanMap = ARRAY[1..MAX_PLAN_HEIGHT, 1..MAX_PLAN_WIDTH] OF MapFieldType;  

  BuildingPlan = RECORD
    Width: Integer;
    Height: Integer;
    Map: BuildingPlanMap;     
  END;

FUNCTION CharToMapField(Ch: CHAR): MapFieldType;
BEGIN
  CASE Ch OF
    ' ': CharToMapField := Empty;
    '#': CharToMapField := Wall;
    '*': CharToMapField := Fire;
    'E': CharToMapField := Escape;
    'O': CharToMapField := Person;
    ELSE CharToMapField := Empty;
  END
END;

FUNCTION ReadBuildingPlan(FileName: STRING): BuildingPlan;
VAR
  Plan: BuildingPlan;
  InputFile: TEXT;
  Line: String;
  currentField: MapFieldType;
  I, Row, Column: Integer;
BEGIN
  Assign(InputFile, FileName);
  Reset(InputFile);
  
  Plan.Width := 0;
  Plan.Height := 0;
  Row := 0;

  WHILE NOT EOF(InputFile) DO
  BEGIN
    READLN(InputFile, Line);

    INC(Row);
    Column := 0;
    
    FOR I := 1 TO Length(Line) DO
    BEGIN
      INC(Column);
      Plan.Map[Row, Column] := CharToMapField(Line[i])
    END;
    
    Plan.Width := MAX(Column, Plan.Width);
    Plan.Height := MAX(Row, Plan.Height)
  END;

  ReadBuildingPlan := Plan
END;



VAR
  Plan: BuildingPlan;
BEGIN
  Plan := ReadBuildingPlan(InputFileName);
  WriteLn('Plan Size is: ', Plan.Width, 'x', Plan.Height);
  ReadLn
END.
