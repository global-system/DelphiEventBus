unit DUnitX.btkEventBusTest;

interface
uses
  SysUtils,
  Vcl.Forms,
  DUnitX.TestFramework,
  DUnitX.TestFixture,
  Delphi.Mocks,
  btkEventBus;

type

  TbtkCustomTestEventObject = class(TbtkEventObject)
  private
    FHashedTestFilter: string;
    FNotHashedTestFilter: string;
  public
    const sEventHashedTestFilterName = 'HashedTestFilter';
    const sEventNotHashedTestFilterName = 'NotHashedTestFilter';

    constructor Create(ATopic: string; AHashedTestFilter: string;
      ANotHashedTestFilter: string);

    [EventFilter(sEventHashedTestFilterName, [efpIsPartOfHashingString])]
    function HashedTestFilter: string;
    [EventFilter(sEventNotHashedTestFilterName)]
    function NotHashedTestFilter: string;
  end;

  TbtkTestEventObject = class(TbtkCustomTestEventObject)
  private
    FNotHashedTestFilter2: string;

  public
    const sEventNotHashedTestFilter2Name = 'NotHashedTestFilter2';

    constructor Create(ATopic: string; AHashedTestFilter: string;
      ANotHashedTestFilter: string; ANotHashedTestFilter2: string);

    [EventFilter(sEventNotHashedTestFilter2Name)]
    function NotHashedTestFilter2: string;
  end;

  TbtkCaseSensitiveTestEventObject = class(TbtkEventObject)
  private
    FHashedCaseSensitiveTestFilter: string;
    FHashedNotCaseSensitiveTestFilter: string;
    FNotHashedCaseSensitiveTestFilter: string;
    FNotHashedNotCaseSensitiveTestFilter: string;
  public
    const sEventHashedCaseSensitiveTestFilterName = 'HashedCaseSensitiveTestFilter';
    const sEventHashedNotCaseSensitiveTestFilterName = 'HashedNotCaseSensitiveTestFilter';
    const sEventNotHashedCaseSensitiveTestFilterName = 'NotHashedCaseSensitiveTestFilter';
    const sEventNotHashedNotCaseSensitiveTestFilterName = 'NotHashedNotCaseSensitiveTestFilter';

    constructor Create(ATopic: string; AHashedCaseSensitiveTestFilter: string;
      AHashedNotCaseSensitiveTestFilter: string; ANotHashedCaseSensitiveTestFilter: string;
      ANotHashedNotCaseSensitiveTestFilter: string);

    [EventFilter(sEventHashedCaseSensitiveTestFilterName, [efpIsPartOfHashingString, efpCaseSensitive])]
    function HashedCaseSensitiveTestFilter: string;
    [EventFilter(sEventHashedNotCaseSensitiveTestFilterName, [efpIsPartOfHashingString])]
    function HashedNotCaseSensitiveTestFilter: string;
    [EventFilter(sEventNotHashedCaseSensitiveTestFilterName, [efpCaseSensitive])]
    function NotHashedCaseSensitiveTestFilter: string;
    [EventFilter(sEventNotHashedNotCaseSensitiveTestFilterName)]
    function NotHashedNotCaseSensitiveTestFilter: string;
  end;

  TbtkTestEventListener = class
  public
    [EventHandler]
    procedure Handler(AEventObject: TbtkTestEventObject); virtual; abstract;
    [EventHandler]
    procedure HandlerForParentClass(AEventObject: TbtkCustomTestEventObject); virtual; abstract;
    [EventHook]
    procedure Hook(AEventObject: TbtkTestEventObject); virtual; abstract;
    [EventHook]
    procedure HookForParentClass(AEventObject: TbtkCustomTestEventObject); virtual; abstract;
    [EventHandler]
    procedure CaseSensitiveHandler(AEventObject: TbtkCaseSensitiveTestEventObject); virtual; abstract;
  end;

  TbtkTestInvalidEventListener = class
  public
    [EventHandler]
    procedure Handler(AEventObject: TObject); virtual; abstract;
  end;

  TbtkFakeExceptionHandler = class
  public
    procedure HandleException(ASender: TObject; AException: Exception); virtual; abstract;
  end;

  TbtkEventBusTest = class(TObject)
  public

    EventBus: IbtkEventBus;
    Listener: TMock<TbtkTestEventListener>;
    InvalidListener: TMock<TbtkTestInvalidEventListener>;
    ListenerInfo: TbtkListenerInfo;
    Listeners: array[0..2] of TMock<TbtkTestEventListener>;
    ListenersInfo: array[0..2] of TbtkListenerInfo;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    procedure RegisterListener;
    procedure UnRegisterListener;
    procedure RegisterInvalidListener;
    procedure RegisterListeners;
    procedure UnRegisterListeners;

    [Test]
    procedure Register_ListenerIsValid_WillNotRaise;
    [Test]
    procedure Register_ListenerIsNotValid_WillRaise;
    [Test]
    procedure Register_AlreadyRegisteredListener_WillRaise;
    [Test]
    procedure UnRegister_ListenerIsRegistered_WillNotRaise;
    [Test]
    procedure UnRegister_ListenerIsNotRegistered_WillRaise;
    [Test]
    procedure Send_AllFiltersIsEmpty_HandlerNotCalled;
    [Test]
    procedure Send_AllFiltersIsEmpty_HookCalled;
    [Test]
    procedure Send_AllFiltersOfListenerMatchWithParametersOfEvent_HandlerCalled;
    [Test]
    procedure Send_AllFiltersOfListenerMatchWithParametersOfEvent_HookCalled;
    [Test]
    procedure Send_AllFiltersOfListenerDifferentFromParametersOfEvent_HookCalled;
    [Test]
    procedure Send_AllFiltersOfListenerDifferentFromParametersOfEvent_HandlerNotCalled;
    [Test]
    procedure Send_SingleHashedFilterIsEmptyOtherFiltersLikeInEvent_HandlerNotCalled;
    [Test]
    procedure Send_NotHashedFiltersIsEmptyHashedFiltersLikeInEvent_HandlerCalled;
    [Test]
    procedure Send_2HashedFiltersInListenerMatchFiltersInEvent2NotHashedFilterMismatchFiltersInEvent_HandlerNotCalled;
    [Test]
    procedure Send_HandlerContainParentClassOfEvent_HandlerCalled;
    [Test]
    procedure Send_HookContainParentClassOfEvent_HookCalled;
    [Test]
    procedure Send_HandlerContainChildClassOfEvent_HandlerNotCalled;
    [Test]
    procedure Send_HookContainChildClassOfEvent_HookNotCalled;
    [Test]
    procedure Send_ExceptionWasRaisedInHandlerAndExceptionHandlerIsNotExist_WillNotRaiseAny;
    [Test]
    procedure Send_ExceptionRaisedInHandlerAndNotExistExceptionHandler_ApplicationHandleExceptionCalled;
    [Test]
    procedure Send_ExceptionRaisedInHandlerAndExistExceptionHandler_ApplicationHandleExceptionNotCalled;
    [Test]
    procedure Send_ExceptionRaisedInHandlerAndExistExceptionHandler_ExceptionHandlerCalled;
    [Test]
    procedure Send_ExceptionWasRaisedInHandlerAndExceptionHandlerIsExist_ExceptionInExceptionHandlerIsOriginalException;
    [Test]
    procedure Send_ExceptionWasRaisedInHandlerAndExceptionHandlerRaisedNothing_WillNotRaiseAny;
    [Test]
    procedure Send_ExceptionWasRaisedInHandlerAndExceptionHandlerRaisedAcquiredException_FinalExceptionIsOriginalException;
    [Test]
    procedure Send_ExceptionWasRaisedInHandlerAndExceptionHandlerRaisedOuterException_InnerExceptionOfFinalExceptionIsOriginalException;
    [Test]
    procedure Send_ExceptionRaisedInEachHooksAndHandlersRaisedAnException_AllHooksAndHandlersCalled;
    [Test]
    procedure Send_1Event3Listeners_EachHandlerCalledOnce;
    [Test]
    procedure Send_HashedCaseSensitiveFilterOfListenerDifferentCaseWithParametersOfEvent_HandlerNotCalled;
    [Test]
    procedure Send_HashedNotCaseSensitiveFilterOfListenerDifferentCaseWithParametersOfEvent_HandlerCalled;
    [Test]
    procedure Send_NotHashedCaseSensitiveFilterOfListenerDifferentCaseWithParametersOfEvent_HandlerNotCalled;
    [Test]
    procedure Send_NotHashedNotCaseSensitiveFilterOfListenerDifferentCaseWithParametersOfEvent_HandlerCalled;
  end;

  TbtkEventFiltersTest = class(TObject)
  public

    EventBus: IbtkEventBus;
    Listener: TMock<TbtkTestEventListener>;
    EventFilters: TbtkEventFilters;
    TestFilterName: string;
    procedure TryRequestEventFilter;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [test]
    procedure Filters_FilterNameIsExist_WillNotRaise;
    [test]
    procedure Filters_FilterNameIsExistButContainsOtherCharacterCase_WillNotRaise;
    [test]
    procedure Filters_FilterNameIsNotExists_WillRaise;
  end;


implementation

uses
  System.Rtti;

{ TbtkCustomTestEventObject }

constructor TbtkCustomTestEventObject.Create(ATopic, AHashedTestFilter,
  ANotHashedTestFilter: string);
begin
  inherited Create(ATopic);
  FHashedTestFilter := AHashedTestFilter;
  FNotHashedTestFilter := ANotHashedTestFilter;
end;

function TbtkCustomTestEventObject.HashedTestFilter: string;
begin
  Result := FHashedTestFilter;
end;

function TbtkCustomTestEventObject.NotHashedTestFilter: string;
begin
  Result := FNotHashedTestFilter;
end;

{ TbtkTestEventObject }

constructor TbtkTestEventObject.Create(ATopic: string; AHashedTestFilter: string;
  ANotHashedTestFilter: string; ANotHashedTestFilter2: string);
begin
  inherited Create(ATopic, AHashedTestFilter, ANotHashedTestFilter);
  FNotHashedTestFilter2 := ANotHashedTestFilter2;
end;

function TbtkTestEventObject.NotHashedTestFilter2: string;
begin
  Result := FNotHashedTestFilter2;
end;

{ TbtkCaseSensitiveTestEventObject }

constructor TbtkCaseSensitiveTestEventObject.Create(ATopic: string; AHashedCaseSensitiveTestFilter: string;
  AHashedNotCaseSensitiveTestFilter: string; ANotHashedCaseSensitiveTestFilter: string;
  ANotHashedNotCaseSensitiveTestFilter: string);
begin
  inherited Create(ATopic);
  FHashedCaseSensitiveTestFilter := AHashedCaseSensitiveTestFilter;
  FHashedNotCaseSensitiveTestFilter := AHashedNotCaseSensitiveTestFilter;
  FNotHashedCaseSensitiveTestFilter := ANotHashedCaseSensitiveTestFilter;
  FNotHashedNotCaseSensitiveTestFilter := ANotHashedNotCaseSensitiveTestFilter;
end;

function TbtkCaseSensitiveTestEventObject.HashedCaseSensitiveTestFilter: string;
begin
  Result := FHashedCaseSensitiveTestFilter;
end;

function TbtkCaseSensitiveTestEventObject.HashedNotCaseSensitiveTestFilter: string;
begin
  Result := FHashedNotCaseSensitiveTestFilter;
end;

function TbtkCaseSensitiveTestEventObject.NotHashedCaseSensitiveTestFilter: string;
begin
  Result := FNotHashedCaseSensitiveTestFilter;
end;

function TbtkCaseSensitiveTestEventObject.NotHashedNotCaseSensitiveTestFilter: string;
begin
  Result := FNotHashedNotCaseSensitiveTestFilter;
end;

{ TbtkEventBusTest }

procedure TbtkEventBusTest.Setup;
var
  i: Integer;
begin
  EventBus := TbtkEventBus.Create;
  Listener := TMock<TbtkTestEventListener>.Create;
  InvalidListener := TMock<TbtkTestInvalidEventListener>.Create;
  for i := Low(Listeners) to High(Listeners) do
    Listeners[i] := TMock<TbtkTestEventListener>.Create;
end;

procedure TbtkEventBusTest.TearDown;
var
  i: Integer;
begin
  Listener.Free;
  InvalidListener.Free;
  for i := Low(Listeners) to High(Listeners) do
    Listeners[i].Free;
  EventBus := nil;
end;

procedure TbtkEventBusTest.RegisterListener;
begin
  ListenerInfo := EventBus.Register(Listener);
end;

procedure TbtkEventBusTest.UnRegisterListener;
begin
  EventBus.UnRegister(Listener);
end;

procedure TbtkEventBusTest.RegisterInvalidListener;
begin
  EventBus.Register(InvalidListener);
end;

procedure TbtkEventBusTest.RegisterListeners;
var
  i: Integer;
begin
  for i := Low(Listeners) to High(Listeners) do
    ListenersInfo[i] := EventBus.Register(Listeners[i]);
end;

procedure TbtkEventBusTest.UnRegisterListeners;
var
  i: Integer;
begin
  for i := Low(Listeners) to High(Listeners) do
    EventBus.UnRegister(Listeners[i]);
end;

procedure TbtkEventBusTest.Register_ListenerIsValid_WillNotRaise;
begin
  Assert.WillNotRaiseAny(RegisterListener, 'Registration with valid listener generated an exception');
end;

procedure TbtkEventBusTest.Register_ListenerIsNotValid_WillRaise;
begin
  Assert.WillRaiseAny(RegisterInvalidListener, 'Registration with invalid listener not generated an exception');
end;

procedure TbtkEventBusTest.Register_AlreadyRegisteredListener_WillRaise;
begin
  RegisterListener;
  Assert.WillRaiseAny(RegisterListener, 'Re-registration of the listener not generated an exception');
  UnRegisterListener;
end;

procedure TbtkEventBusTest.UnRegister_ListenerIsRegistered_WillNotRaise;
begin
  RegisterListener;
  Assert.WillNotRaiseAny(UnRegisterListener, 'De-registering a registered listener generated an exception');
end;

procedure TbtkEventBusTest.UnRegister_ListenerIsNotRegistered_WillRaise;
begin
  Assert.WillRaiseAny(UnRegisterListener, 'De-registering a unregistered listener not generated an exception');
end;

procedure TbtkEventBusTest.Send_AllFiltersIsEmpty_HandlerNotCalled;
begin
  RegisterListener;
  try
    Listener.Setup.Expect.Never('Handler');
    EventBus.Send(TbtkTestEventObject.Create('TopicValue', 'HashedTestFilterValue', 'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_AllFiltersIsEmpty_HookCalled;
begin
  RegisterListener;
  try
    Listener.Setup.Expect.Once('Hook');
    EventBus.Send(TbtkTestEventObject.Create('TopicValue', 'HashedTestFilterValue', 'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_AllFiltersOfListenerMatchWithParametersOfEvent_HandlerCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventFilterTopicName].Value := 'TopicValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventHashedTestFilterName].Value := 'HashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilterName].Value := 'NotHashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilter2Name].Value := 'NotHashedTestFilter2Value';

    Listener.Setup.Expect.Once('Handler');
    EventBus.Send(TbtkTestEventObject.Create('TopicValue', 'HashedTestFilterValue', 'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_AllFiltersOfListenerMatchWithParametersOfEvent_HookCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventFilterTopicName].Value := 'TopicValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventHashedTestFilterName].Value := 'HashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilterName].Value := 'NotHashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilter2Name].Value := 'NotHashedTestFilter2Value';

    Listener.Setup.Expect.Once('Hook');
    EventBus.Send(TbtkTestEventObject.Create('TopicValue', 'HashedTestFilterValue', 'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_AllFiltersOfListenerDifferentFromParametersOfEvent_HookCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventFilterTopicName].Value := '-TopicValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventHashedTestFilterName].Value := '-HashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilterName].Value := '-NotHashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilter2Name].Value := '-NotHashedTestFilter2Value';

    Listener.Setup.Expect.Once('Hook');
    EventBus.Send(TbtkTestEventObject.Create('TopicValue', 'HashedTestFilterValue', 'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_AllFiltersOfListenerDifferentFromParametersOfEvent_HandlerNotCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventFilterTopicName].Value := '-TopicValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventHashedTestFilterName].Value := '-HashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilterName].Value := '-NotHashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilter2Name].Value := '-NotHashedTestFilter2Value';

    Listener.Setup.Expect.Never('Handler');
    EventBus.Send(TbtkTestEventObject.Create('TopicValue', 'HashedTestFilterValue',
      'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_SingleHashedFilterIsEmptyOtherFiltersLikeInEvent_HandlerNotCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventFilterTopicName].Value := 'TopicValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventHashedTestFilterName].Value := EmptyStr;
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilterName].Value := 'NotHashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilter2Name].Value := 'NotHashedTestFilter2Value';

    Listener.Setup.Expect.Never('Handler');
    EventBus.Send(TbtkTestEventObject.Create('TopicValue', 'HashedTestFilterValue',
      'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_NotHashedFiltersIsEmptyHashedFiltersLikeInEvent_HandlerCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventFilterTopicName].Value := 'TopicValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventHashedTestFilterName].Value := 'HashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilterName].Value := EmptyStr;
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilter2Name].Value := EmptyStr;

    Listener.Setup.Expect.Once('Handler');
    EventBus.Send(TbtkTestEventObject.Create('TopicValue', 'HashedTestFilterValue',
      'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_2HashedFiltersInListenerMatchFiltersInEvent2NotHashedFilterMismatchFiltersInEvent_HandlerNotCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventFilterTopicName].Value := 'TopicValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventHashedTestFilterName].Value := 'HashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilterName].Value := '-NotHashedTestFilterValue';
    ListenerInfo.HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilter2Name].Value := '-NotHashedTestFilter2Value';

    Listener.Setup.Expect.Never('Handler');
    EventBus.Send(TbtkTestEventObject.Create('TopicValue', 'HashedTestFilterValue',
      'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_HandlerContainParentClassOfEvent_HandlerCalled;
begin
  RegisterListener;
  try
    Listener.Setup.Expect.Once('HandlerForParentClass');
    EventBus.Send(TbtkTestEventObject.Create('', '', 'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_HookContainParentClassOfEvent_HookCalled;
begin
  RegisterListener;
  try
    Listener.Setup.Expect.Once('HookForParentClass');
    EventBus.Send(TbtkTestEventObject.Create('', '', '', ''));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_HandlerContainChildClassOfEvent_HandlerNotCalled;
begin
  RegisterListener;
  try
    Listener.Setup.Expect.Never('Handler');
    EventBus.Send(TbtkCustomTestEventObject.Create('', '', ''));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_HookContainChildClassOfEvent_HookNotCalled;
begin
  RegisterListener;
  try
    Listener.Setup.Expect.Never('Hook');
    EventBus.Send(TbtkCustomTestEventObject.Create('', '', ''));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_ExceptionWasRaisedInHandlerAndExceptionHandlerIsNotExist_WillNotRaiseAny;
var
  fakeExceptionHandler: TMock<TbtkFakeExceptionHandler>;
begin
  fakeExceptionHandler := TMock<TbtkFakeExceptionHandler>.Create;
  Application.OnException := fakeExceptionHandler.Instance.HandleException;
  RegisterListener;
  try
    Listener.Setup.WillRaise('Handler', Exception);

    Assert.WillNotRaiseAny(
      procedure
      begin
        EventBus.Send(TbtkTestEventObject.Create('', '', '', ''))
      end);
  finally
    UnRegisterListener;
    Application.OnException := nil;
    fakeExceptionHandler.Free;
  end;
end;

procedure TbtkEventBusTest.Send_ExceptionRaisedInHandlerAndNotExistExceptionHandler_ApplicationHandleExceptionCalled;
var
  fakeExceptionHandler: TMock<TbtkFakeExceptionHandler>;
begin
  fakeExceptionHandler := TMock<TbtkFakeExceptionHandler>.Create;
  Application.OnException := fakeExceptionHandler.Instance.HandleException;
  RegisterListener;
  try
    Listener.Setup.WillRaise('Handler', Exception);
    fakeExceptionHandler.Setup.Expect.Once('HandleException');

    EventBus.Send(TbtkTestEventObject.Create('', '', '', ''));
    fakeExceptionHandler.Verify;
  finally
    UnRegisterListener;
    Application.OnException := nil;
    fakeExceptionHandler.Free;
  end;
end;

procedure TbtkEventBusTest.Send_ExceptionRaisedInHandlerAndExistExceptionHandler_ApplicationHandleExceptionNotCalled;
var
  fakeExceptionHandler: TMock<TbtkFakeExceptionHandler>;
begin
  fakeExceptionHandler := TMock<TbtkFakeExceptionHandler>.Create;
  Application.OnException := fakeExceptionHandler.Instance.HandleException;
  RegisterListener;
  try
    Listener.Setup.WillRaise('Handler', Exception);
    fakeExceptionHandler.Setup.Expect.Never('HandleException');

    EventBus.Send(TbtkTestEventObject.Create('', '', '', ''),
      procedure(AException: Exception)
      begin

      end);
    fakeExceptionHandler.Verify;
  finally
    UnRegisterListener;
    Application.OnException := nil;
    fakeExceptionHandler.Free;
  end;
end;

procedure TbtkEventBusTest.Send_ExceptionRaisedInHandlerAndExistExceptionHandler_ExceptionHandlerCalled;
var
  fakeExceptionHandler: TMock<TbtkFakeExceptionHandler>;
  calledExceptionHandler: Boolean;
begin
  fakeExceptionHandler := TMock<TbtkFakeExceptionHandler>.Create;
  Application.OnException := fakeExceptionHandler.Instance.HandleException;
  RegisterListener;
  try
    Listener.Setup.WillRaise('Handler', Exception);
    fakeExceptionHandler.Setup.Expect.Never('HandleException');

    calledExceptionHandler := False;
    EventBus.Send(TbtkTestEventObject.Create('', '', '', ''),
      procedure(AException: Exception)
      begin
        calledExceptionHandler := True;
      end);
    Assert.IsTrue(calledExceptionHandler);
  finally
    UnRegisterListener;
    Application.OnException := nil;
    fakeExceptionHandler.Free;
  end;
end;

procedure TbtkEventBusTest.Send_ExceptionWasRaisedInHandlerAndExceptionHandlerIsExist_ExceptionInExceptionHandlerIsOriginalException;
var
  originalException: Exception;
  exceptionInExceptionHandlerIsOriginalException: Boolean;
begin
  RegisterListener;
  try
    originalException := Exception.Create('');
    Listener.Setup.WillExecute('Handler',
      function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
      begin
        raise originalException;
      end);

    exceptionInExceptionHandlerIsOriginalException := False;
    EventBus.Send(TbtkTestEventObject.Create('', '', '', ''),
      procedure(AException: Exception)
      begin
        exceptionInExceptionHandlerIsOriginalException := AException = originalException;
      end);

    Assert.IsTrue(exceptionInExceptionHandlerIsOriginalException);
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_ExceptionWasRaisedInHandlerAndExceptionHandlerRaisedNothing_WillNotRaiseAny;
begin
  RegisterListener;
  try
    Listener.Setup.WillRaise('Handler', Exception, '');

    Assert.WillNotRaiseAny(
      procedure
      begin
        EventBus.Send(TbtkTestEventObject.Create('', '', '', ''),
          procedure(AException: Exception)
          begin
            //nothing
          end)
      end);

  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_ExceptionWasRaisedInHandlerAndExceptionHandlerRaisedAcquiredException_FinalExceptionIsOriginalException;
var
  originalException: Exception;
  finalExceptionIsOriginalException: Boolean;
begin
  RegisterListener;
  try
    originalException := Exception.Create('');
    Listener.Setup.WillExecute('Handler',
      function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
      begin
        raise originalException;
      end);

    finalExceptionIsOriginalException := False;
    try
      EventBus.Send(TbtkTestEventObject.Create('', '', '', ''),
        procedure(AException: Exception)
        begin
          raise Exception(AcquireExceptionObject);
        end);
    except
      on E: Exception do
        finalExceptionIsOriginalException := E = originalException;
    end;

    Assert.IsTrue(finalExceptionIsOriginalException);
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_ExceptionWasRaisedInHandlerAndExceptionHandlerRaisedOuterException_InnerExceptionOfFinalExceptionIsOriginalException;
var
  originalException: Exception;
  innerExceptionOfFinalExceptionIsOriginalException: Boolean;
begin
  RegisterListener;
  try
    originalException := Exception.Create('');
    Listener.Setup.WillExecute('Handler',
      function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
      begin
        raise originalException;
      end);

    innerExceptionOfFinalExceptionIsOriginalException := False;
    try
      EventBus.Send(TbtkTestEventObject.Create('', '', '', ''),
        procedure(AException: Exception)
        begin
          Exception.RaiseOuterException(Exception.Create('OuterException'));
        end);
    except
      on E: Exception do
        innerExceptionOfFinalExceptionIsOriginalException := E.InnerException = originalException;
    end;

    Assert.IsTrue(innerExceptionOfFinalExceptionIsOriginalException);
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_ExceptionRaisedInEachHooksAndHandlersRaisedAnException_AllHooksAndHandlersCalled;
var
  fakeExceptionHandler: TMock<TbtkFakeExceptionHandler>;
begin
  fakeExceptionHandler := TMock<TbtkFakeExceptionHandler>.Create;
  Application.OnException := fakeExceptionHandler.Instance.HandleException;
  RegisterListener;
  try
    Listener.Setup.WillRaise('Handler', Exception);
    Listener.Setup.WillRaise('HandlerForParentClass', Exception);
    Listener.Setup.WillRaise('Hook', Exception);
    Listener.Setup.WillRaise('HookForParentClass', Exception);
    Listener.Setup.Expect.Once('Handler');
    Listener.Setup.Expect.Once('HandlerForParentClass');
    Listener.Setup.Expect.Once('Hook');
    Listener.Setup.Expect.Once('HookForParentClass');
    fakeExceptionHandler.Setup.Expect.AtLeast('HandleException', 4);

    EventBus.Send(TbtkTestEventObject.Create('', '', '', ''));
    fakeExceptionHandler.Verify;
  finally
    UnRegisterListener;
    Application.OnException := nil;
    fakeExceptionHandler.Free;
  end;
end;

procedure TbtkEventBusTest.Send_1Event3Listeners_EachHandlerCalledOnce;
var
  i: Integer;
begin
  RegisterListeners;
  try
    for i := Low(Listeners) to High(Listeners) do
    begin
      ListenersInfo[i].HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventFilterTopicName].Value := 'TopicValue';
      ListenersInfo[i].HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventHashedTestFilterName].Value := 'HashedTestFilterValue';
      ListenersInfo[i].HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilterName].Value := 'NotHashedTestFilterValue';
      ListenersInfo[i].HandlerFilters[TbtkTestEventObject][TbtkTestEventObject.sEventNotHashedTestFilter2Name].Value := 'NotHashedTestFilter2Value';
      Listeners[i].Setup.Expect.Once('Handler');
    end;
    EventBus.Send(TbtkTestEventObject.Create('TopicValue', 'HashedTestFilterValue', 'NotHashedTestFilterValue', 'NotHashedTestFilter2Value'));
    for i := Low(Listeners) to High(Listeners) do
      Listeners[i].Verify;
  finally
    UnRegisterListeners;
  end;
end;

procedure TbtkEventBusTest.Send_HashedCaseSensitiveFilterOfListenerDifferentCaseWithParametersOfEvent_HandlerNotCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkCaseSensitiveTestEventObject][TbtkCaseSensitiveTestEventObject.sEventFilterTopicName].Value := 'TopicValue';
    ListenerInfo.HandlerFilters[TbtkCaseSensitiveTestEventObject][TbtkCaseSensitiveTestEventObject.sEventHashedCaseSensitiveTestFilterName].Value := 'HashedCaseSensitiveTestFilterValue';

    Listener.Setup.Expect.Never('CaseSensitiveHandler');
    EventBus.Send(TbtkCaseSensitiveTestEventObject.Create('TopicValue', 'hasheDcasEsensitivEtesTfilteRvaluE', '', '', ''));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_HashedNotCaseSensitiveFilterOfListenerDifferentCaseWithParametersOfEvent_HandlerCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkCaseSensitiveTestEventObject][TbtkCaseSensitiveTestEventObject.sEventFilterTopicName].Value := 'TopicValue';
    ListenerInfo.HandlerFilters[TbtkCaseSensitiveTestEventObject][TbtkCaseSensitiveTestEventObject.sEventHashedNotCaseSensitiveTestFilterName].Value := 'HashedNotCaseSensitiveTestFilterValue';

    Listener.Setup.Expect.Once('CaseSensitiveHandler');
    EventBus.Send(TbtkCaseSensitiveTestEventObject.Create('TopicValue', '', 'hasheDnoTcasEsensitivEtesTfilteRvaluE', '', ''));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_NotHashedCaseSensitiveFilterOfListenerDifferentCaseWithParametersOfEvent_HandlerNotCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkCaseSensitiveTestEventObject][TbtkCaseSensitiveTestEventObject.sEventFilterTopicName].Value := 'TopicValue';
    ListenerInfo.HandlerFilters[TbtkCaseSensitiveTestEventObject][TbtkCaseSensitiveTestEventObject.sEventNotHashedCaseSensitiveTestFilterName].Value := 'NotHashedCaseSensitiveTestFilterValue';

    Listener.Setup.Expect.Never('CaseSensitiveHandler');
    EventBus.Send(TbtkCaseSensitiveTestEventObject.Create('TopicValue', '', '', 'noThasheDcasEsensitivEtesTfilteRvaluE', ''));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

procedure TbtkEventBusTest.Send_NotHashedNotCaseSensitiveFilterOfListenerDifferentCaseWithParametersOfEvent_HandlerCalled;
begin
  RegisterListener;
  try
    ListenerInfo.HandlerFilters[TbtkCaseSensitiveTestEventObject][TbtkCaseSensitiveTestEventObject.sEventFilterTopicName].Value := 'TopicValue';
    ListenerInfo.HandlerFilters[TbtkCaseSensitiveTestEventObject][TbtkCaseSensitiveTestEventObject.sEventNotHashedNotCaseSensitiveTestFilterName].Value := 'NotHashedNotCaseSensitiveTestFilterValue';

    Listener.Setup.Expect.Once('CaseSensitiveHandler');
    EventBus.Send(TbtkCaseSensitiveTestEventObject.Create('TopicValue', '', '', '', 'noThasheDnoTcasEsensitivEtesTfilteRvaluE'));
    Listener.Verify;
  finally
    UnRegisterListener;
  end;
end;

{ TbtkEventFiltersTest }

procedure TbtkEventFiltersTest.TryRequestEventFilter;
begin
  EventFilters[TestFilterName];
end;

procedure TbtkEventFiltersTest.Setup;
var
  listenerInfo: TbtkListenerInfo;
begin
  EventBus := TbtkEventBus.Create;
  Listener := TMock<TbtkTestEventListener>.Create;
  listenerInfo := EventBus.Register(Listener);
  EventFilters := listenerInfo.HandlerFilters[TbtkTestEventObject];
end;

procedure TbtkEventFiltersTest.TearDown;
begin
  EventBus.UnRegister(Listener);
  Listener.Free;
  EventBus := nil;
end;

procedure TbtkEventFiltersTest.Filters_FilterNameIsExist_WillNotRaise;
begin
  TestFilterName := 'Topic';
  Assert.WillNotRaise(TryRequestEventFilter);
end;

procedure TbtkEventFiltersTest.Filters_FilterNameIsExistButContainsOtherCharacterCase_WillNotRaise;
begin
  TestFilterName := 'tOPiC';
  Assert.WillNotRaise(TryRequestEventFilter);
end;

procedure TbtkEventFiltersTest.Filters_FilterNameIsNotExists_WillRaise;
begin
  TestFilterName := '-Topic';
  Assert.WillRaise(TryRequestEventFilter);
end;

initialization
  TDUnitX.RegisterTestFixture(TbtkEventBusTest);
  TDUnitX.RegisterTestFixture(TbtkEventFiltersTest);

finalization

end.
