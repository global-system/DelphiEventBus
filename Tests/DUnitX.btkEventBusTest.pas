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

    [EventFilter(sEventHashedTestFilterName, bIsPartOfHashingString)]
    function HashedTestFilter: string;
    [EventFilter(sEventNotHashedTestFilterName, not bIsPartOfHashingString)]
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
    procedure Send_ExceptionRaisedInHandlerAndNotExistExceptionHandler_ApplicationHandleExceptionCalled;
    [Test]
    procedure Send_ExceptionRaisedInHandlerAndExistExceptionHandler_ApplicationHandleExceptionNotCalled;
    [Test]
    procedure Send_ExceptionRaisedInHandlerAndExistExceptionHandler_ExceptionHandlerCalled;
    [Test]
    procedure Send_ExceptionRaisedInEachHooksAndHandlersRaisedAnException_AllHooksAndHandlersCalled;
    [Test]
    procedure Send_1Event3Listeners_EachHandlerCalledOnce;
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

{ TbtkEventBusTest }

procedure TbtkEventBusTest.Setup;
var
  i: Integer;
begin
  EventBus := TbtkEventBus.GetEventBus;
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

{ TbtkEventFiltersTest }

procedure TbtkEventFiltersTest.TryRequestEventFilter;
begin
  EventFilters[TestFilterName];
end;

procedure TbtkEventFiltersTest.Setup;
var
  listenerInfo: TbtkListenerInfo;
begin
  EventBus := TbtkEventBus.GetEventBus;
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
