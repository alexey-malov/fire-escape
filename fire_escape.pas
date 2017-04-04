PROGRAM FireEscape;

CONST
  MAX_BUILDING_PLAN_WIDTH = 100;  {максимальная ширина плана здания}
  MAX_BUILDING_PLAN_HEIGHT = 100; {максимальная высота плана здания}
  NO_WAVE = 0;
  FIRE_STEP = 2; {Период распространения огня (в шагах человека) }

TYPE
  {Поле плана здания}
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

  {Двумерный массив, предназначенный для карты плана здания}
  BuildingPlanMap = ARRAY[1..MAX_BUILDING_PLAN_HEIGHT, 1..MAX_BUILDING_PLAN_WIDTH] OF MapFieldType;  
 
  MapCoord = RECORD
    Row, Column: Integer;
  END;

  {План здания, содержащий необходимую информацию}
  BuildingPlan = RECORD
    Width, Height: Integer; {Размеры}
    Map: BuildingPlanMap;   {Карта}
    PersonPos: MapCoord;    {Координаты человека на карте}
  END;

  WaveMap = ARRAY[1..MAX_BUILDING_PLAN_HEIGHT, 1..MAX_BUILDING_PLAN_WIDTH] OF Integer;

{Преобразует символ входного файла в поле плана здания}
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

{Преобразует поле плана здания в символ выходного файла}
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

{Формирует символ выходного файла на основе плана здания и фронта волны}
FUNCTION WaveMapFieldToChar(Field: MapFieldType; WaveField: Integer): CHAR;
BEGIN
  CASE Field OF
    Empty:
      BEGIN
        IF WaveField = 0 THEN                              
          WaveMapFieldToChar := ' '
        ELSE
          WaveMapFieldToChar := Chr(WaveField MOD 10 + Ord('0'))
      END;
    Wall:         WaveMapFieldToChar := '#';
    Fire:         WaveMapFieldToChar := 'X';
    Escape:       WaveMapFieldToChar := 'E';
    Person:       WaveMapFieldToChar := 'O';
    Fire2:        WaveMapFieldToChar := 'x';
    Trace:        WaveMapFieldToChar := '.';
    BurnedTrace:  WaveMapFieldToChar := '*';
    FoundEscape:  WaveMapFieldToChar := '!';
  END
END;

FUNCTION Maximum(X, Y: Integer): Integer;
BEGIN
  IF X > Y THEN
    Maximum := X
  ELSE
    Maximum := Y
END;

{Чтение плана здания из файла}
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

{Запись плана здания в файл}
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

{Записывает план здания в файл с фронтом волны (полезно для целей отладки)}
PROCEDURE WriteBuildingPlanWithWaveToFile(FileName: STRING; VAR Plan: BuildingPlan; Wave: WaveMap);
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
      Write(OutputFile, WaveMapFieldToChar(Plan.Map[Row, Column], Wave[Row, Column]))
    END;
    WRITELN(OutputFile)
  END;

  Close(OutputFile)
END;

{Пытается применить шаг StepIndex волнового алгоритма к доступным для перемещения клеткам.
 Ведет учет сделанных шагов. Возвращает True при обнаружении выхода}
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

{Применяет шаг волнового алгоритма к 4 соседям поля с координатами Row, Column}
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

{Результат продвижения фронта волны: хода нет, ход есть, найден выход}
type WavePropagationResult = (NoWay, Stepped, Escaped);

{Применяет шаг распространения  фронта волны. Возвращаемое значение сообщает
  об обнаружении выхода или его недоступности.}
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

{Сжигает доступное поле плана здания в указанных координатах}
PROCEDURE BurnField(VAR Plan: BuildingPlan; Y, X: Integer);
BEGIN
  IF (X >= 1) AND (X <= Plan.Width) AND (Y >= 1) AND (Y <= Plan.Height) THEN
    IF (Plan.Map[Y, X] = Empty) OR (Plan.Map[Y, X] = Escape) THEN
      Plan.Map[Y, X] := Fire2
END;

{Продвижение фронта огня на соседствующие с огнем поля (если они горят)}
PROCEDURE PropagateFire(VAR Plan: BuildingPlan; VAR Wave: WaveMap; StepIndex: Integer);
VAR
  X, Y: Integer;
  OldPlan: BuildingPlan;
BEGIN
  OldPlan := Plan;
  {Распространяем вторичный фронт огня на соседствующие с огнем клетки}
  FOR Y := 1 TO Plan.Height DO
    FOR X := 1 TO Plan.Width DO
      IF (OldPlan.Map[Y, X] = Fire) OR (OldPlan.Map[Y, X] = Fire2) THEN
      BEGIN
        BurnField(Plan, Y, X + 1);
        BurnField(Plan, Y, X - 1);
        BurnField(Plan, Y + 1, X);
        BurnField(Plan, Y - 1, X)
      END;

  {Затираем текущий фронт волны в тех местах, где он пересекается с фронтом огня}
  FOR Y := 1 TO Plan.Height DO
    FOR X := 1 TO Plan.Width DO
      IF (Wave[Y, X] = StepIndex) AND (Plan.Map[Y, X] = Fire2) THEN
        Wave[Y, X] := 0
END;

{Поиск координат выхода, достигнутого на шаге StepIndex}
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

{Помечаем поле, что по нему прошел человек}
PROCEDURE TraceField(VAR Field: MapFieldType);
BEGIN
  CASE Field OF
    Escape: Field := FoundEscape;
    Empty: Field := Trace;
    Fire: Field := BurnedTrace;
    Fire2: Field := BurnedTrace;
  END;
END;

{Пытается сделать шаг StepIndex в поле с указанными координатами}
FUNCTION TraceStep(VAR Plan: BuildingPlan; VAR Wave: WaveMap; Row, Column, StepIndex: Integer): BOOLEAN;
BEGIN
  IF (Row >= 1) AND (Row <= Plan.Height) AND (Column >= 1) AND (Row <= Plan.Width) THEN
    IF Wave[Row, Column] = StepIndex THEN
    BEGIN
      TraceStep := TRUE;
      TraceField(Plan.Map[Row, Column])
    END
  ELSE
    TraceStep := FALSE
END;

{Прокладывает путь от найденного на шаге StepIndex выхода к начальной точне нахождения человека}
PROCEDURE TracePath(VAR Plan: BuildingPlan; VAR Wave: WaveMap; StepIndex: Integer);
VAR
   Pos: MapCoord;
BEGIN
  Pos := FindEscape(Plan, Wave, StepIndex);
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

{Осуществляет отладочный вывод состояния волны (последний значащий десятичный разряд номера фронта волны)}
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

{Заполняет массив волны нулями (некоторые реализации Pascal не очищают локальные переменные}
PROCEDURE ClearWave(VAR Wave: WaveMap);
VAR
  X, Y: Integer;
BEGIN
  FOR Y := 1 TO MAX_BUILDING_PLAN_HEIGHT DO
    FOR X := 1 TO MAX_BUILDING_PLAN_WIDTH DO
      Wave[Y, X] := 0;      
END;

{Выполняет поиск пути к выходу на указанном плане здания.
 При достижимости выхода возвращает TRUE и прокладывает к нему маршрут}
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
  InputFileName: String;
  Plan: BuildingPlan;
BEGIN
  IF ParamCount >= 1 THEN
    InputFileName := ParamStr(1)
  ELSE
  BEGIN
    Write('Enter buiilding plan file name: ');
    ReadLn(InputFileName)  
  END;
  
  Plan := ReadBuildingPlanFromFile(InputFileName);
  WriteBuildingPlanToFile('', Plan);
  
  WriteLn('---------------');

  IF FindPath(Plan) THEN
    WRITELN('Found an escape')
  ELSE
    WRITELN('It is impossible to escapte from the building');

  WriteBuildingPlanToFile('', Plan); 
  
  IF InputFileName = '' THEN 
    READLN
END.
