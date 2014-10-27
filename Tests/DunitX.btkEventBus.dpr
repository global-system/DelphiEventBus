program DunitX.btkEventBus;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  DUnitX.TestRunner,
  DUnitX.TestFramework,
  DUnitX.AutoDetect.Console,
  DUnitX.Loggers.Console,
  DUnitX.btkEventBusTest in 'DUnitX.btkEventBusTest.pas';

var
  runner : ITestRunner;
  logger : ITestLogger;

begin
  try
    //Create the runner
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;

    //tell the runner how we will log things
    logger := TDUnitXConsoleLogger.Create(false);
    runner.AddLogger(logger);

    //Run tests
    runner.Execute;

    //We don't want this happening when running under CI.
    System.Write('Done.. press <Enter> key to quit.');
    System.Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
