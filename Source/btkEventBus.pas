{ btkEventBus
Author: S.Bugay
Company: Business Technology, Saint Petersburg, Russia. All right reserved.
Date creation: 21.08.2014

Defenition: The implementation of a design pattern EventBus.
  EventBus, implements the functionality that is intended to simplify
  the exchange of data and communication between application components.
}

unit btkEventBus;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.TypInfo,
  System.Rtti;

type

  /// <summary>EventHookAttribute
  /// Attribute for annotating method of listener as event-hook.
  /// </summary>
  EventHookAttribute = class(TCustomAttribute);
  /// <summary>EventHandlerAttribute
  /// Attribute for annotating method of listener as event-handler.
  /// </summary>
  EventHandlerAttribute = class(TCustomAttribute);

  /// <summary>TEventFilterProperties
  /// Properties of eventfilter.
  /// <value><b>efpIsPartOfHashingString</b> - this property is responsible for adding the filter in a hash.
  /// Using filters as a hash to reduce handler-lists. This provides faster calling handlers,
  /// but forbids the use of empty values for hashed filters of listeners.</value>
  /// <value><b>efpCaseSensitive</b> - This property determines how the filter values will be compared.</value>
  /// </summary>
  TEventFilterProperties = set of (efpIsPartOfHashingString, efpCaseSensitive);

  /// <summary>EventFilterAttribute
  /// Attribute for annotating method of event-object as filter.
  /// </summary>
  EventFilterAttribute = class(TCustomAttribute)
  private
    FName: string;
    FProperties: TEventFilterProperties;
  public
    /// <summary>EventFilterAttribute.Name
    /// Used to identify filter. Must be unique for each filter of event.
    /// </summary>
    property Name: string read FName;
    /// <summary>EventFilterAttribute.Properties
    /// Contains the properties of the filter.
    /// See description of TEventFilterProperties for more info about filter properties.
    /// </summary>
    property Properties: TEventFilterProperties read FProperties;
    constructor Create(AName: string; AProperties: TEventFilterProperties = []);
  end;

  TbtkEventObject = class;
  TbtkEventObjectClass = class of TbtkEventObject;

  /// <summary>IbtkEventObject
  /// Need to prevent destruction of event-object while not all handlers of listeners have been handled
  /// </summary>
  IbtkEventObject = interface
  ['{F38E532F-1F8D-4950-AB31-D6B6E75B69A5}']
    /// <summary>IbtkEventObject.Instance
    /// Returns instance of event-object.
    /// This object will be passed as a parameter for event-hooks and event-handlers.
    /// </summary>
    function Instance: TbtkEventObject;
  end;

  /// <summary>TbtkEventObject
  /// Base class of all event-objects.
  /// </summary>
  TbtkEventObject = class(TInterfacedObject, IbtkEventObject)
  private
    FTopic: string;

  public
    const sEventFilterTopicName = 'Topic';

    /// <summary>TbtkEventObject.Instance
    /// Implements IbtkEventObject.Instance.
    /// </summary>
    function Instance: TbtkEventObject;

    /// <summary>TbtkEventObject.Create
    /// Used for initializing read-only properties of event-object.
    /// </summary>
    constructor Create(ATopic: string);

    /// <summary>TbtkEventObject.Topic
    /// Returns the value of the hashed filter "Topic". "Topic" is a basic filter
    /// that allows you to distribute the events in their context.
    /// </summary>
    [EventFilter(sEventFilterTopicName, [efpIsPartOfHashingString])]
    function Topic: string;
  end;

  /// <summary>TbtkEventFilterInfo
  /// Contains information about event-filter, and allows to get filter value of an event-object instance.
  /// </summary>
  TbtkEventFilterInfo = record
  strict private
    FFilterName: string;
    FProperties: TEventFilterProperties;
    FMethod: TRttiMethod;
  public
    /// <summary>TbtkEventFilterInfo.Create
    /// <param name="AFilterName">value of the annotation property "EventFilterAttribute.Name".</param>
    /// <param name="AProperties">value of the annotation property "EventFilterAttribute.Properties".</param>
    /// <param name="AMethod">Link to a describer of the method, that returns value of filter.</param>
    /// </summary>
    constructor Create(AFilterName: string; AProperties: TEventFilterProperties; AMethod: TRttiMethod);
    /// <summary>TbtkEventFilterInfo.FilterName
    /// Contains the value of the annotation property "EventFilterAttribute.Name".
    /// </summary>
    property FilterName: string read FFilterName;
    /// <summary>TbtkEventFilterInfo.Properties
    /// Contains the value of the annotation property "EventFilterAttribute.Properties".
    /// </summary>
    property Properties: TEventFilterProperties read FProperties;
    /// <summary>TbtkEventFilterInfo.GetValueFor
    /// Returns filter value for instance of event-object.
    /// </summary>
    function GetValueFor(AInstance: TbtkEventObject): string;
  end;

  /// <summary>TbtkEventFiltersRTTIInfo
  /// Contains information about filters.
  /// </summary>
  TbtkEventFiltersRTTIInfo = record
  strict private
    type
      TEventObjectClass = TClass;
      TEventFilterName = string;
      TEventFilterInfoList = TList<TbtkEventFilterInfo>;
      TEventsFilterDictionary = TObjectDictionary<TEventObjectClass, TEventFilterInfoList>;
    class var
      FEventsFilterDictionary: TEventsFilterDictionary;
    class constructor Create;
    class destructor Destroy;
  public
    /// <summary>TbtkEventFiltersClassInfo.GetInfoFor
    /// Returns a list, that contains information about filters of event-object.
    /// </summary>
    class function GetInfoFor(AEventObjectClass: TEventObjectClass): TEventFilterInfoList; static;
  end;

  /// <summary>TbtkEventHandlersRTTIInfo
  /// Contains information about handlers and hooks.
  /// </summary>
  TbtkEventHandlersRTTIInfo = record
  strict private
    type
      TListenerClass = TClass;
      TEventObjectClass = TbtkEventObjectClass;
      TEventHandlerMethodDictionary = TDictionary<TEventObjectClass, TRttiMethod>;
      TEventHookMethodDictionary = TDictionary<TEventObjectClass, TRttiMethod>;
      TEventsHandlerDictionary = TObjectDictionary<TListenerClass, TEventHandlerMethodDictionary>;
      TEventsHookDictionary = TObjectDictionary<TListenerClass, TEventHookMethodDictionary>;
    class var FEventsHandlerDictionary: TEventsHandlerDictionary;
    class var FEventsHookDictionary: TEventsHookDictionary;
    class constructor Create;
    class destructor Destroy;
  strict private
    FListenerClass: TListenerClass;
  public
    /// <summary>TbtkEventHandlersClassInfo.GetInfoFor
    /// Returns a structure, that contains information about hooks and handlers of listener.
    /// </summary>
    class function GetInfoFor(AListenerClass: TListenerClass): TbtkEventHandlersRTTIInfo; static;
    /// <summary>TbtkEventHandlersClassInfo.HandlerMethods
    /// Returns a dictionary that associates class of event-object with handler of listener.
    /// </summary>
    function HandlerMethods: TEventHandlerMethodDictionary;
    /// <summary>TbtkEventHandlersClassInfo.HookMethods
    /// Returns a dictionary that associates class of event-object with hook of listener.
    /// </summary>
    function HookMethods: TEventHookMethodDictionary;
  end;

  /// <summary>TbtkEventFilter
  /// Filter of the event-object or of the listener.
  /// </summary>
  TbtkEventFilter = class
  private
    FProperties: TEventFilterProperties;
    FValue: string;
    FNormalizedValue: string;
    FOnValueChanged: TNotifyEvent;
    procedure SetValue(const AValue: string);
  protected
    /// <summary>TbtkEventFilter.OnValueChanged
    /// It's necessary for call hash recalculating, when hashed filter value is changed.
    /// </summary>
    property OnValueChanged: TNotifyEvent read FOnValueChanged write FOnValueChanged;
    property NormalizedValue: string read FNormalizedValue;
  public
    constructor Create(AProperties: TEventFilterProperties; AValue: string);
    /// <summary>TbtkEventFilter.Properties
    /// See description of EventFilterAttribute.Properties for more
    /// info about the filter properties.
    /// </summary>
    property Properties: TEventFilterProperties read FProperties;
    /// <summary>TbtkEventFilter.Value
    /// Value of the filter.
    /// </summary>
    property Value: string read FValue write SetValue;
  end;

  TbtkHashingStringChangeNotifyEvent = procedure(ASender: TObject; AOldValue: string) of object;

  /// <summary>TbtkEventFilters
  /// Filters-dictionary of the event-object or of the listener.
  /// </summary>
  TbtkEventFilters = class(TObjectDictionary<string, TbtkEventFilter>)
  private
    FHashingString: string;
    FHashingStringChanged: TbtkHashingStringChangeNotifyEvent;
    procedure UpdateHashingString;
    procedure FilterValueChanged(ASender: TObject);
    function GetFilters(AName: string): TbtkEventFilter;
  protected
    /// <summary>TbtkEventFilters.ValueNotify
    /// Sets the handler for the event "OnValueChanged" of filters.
    /// </summary>
    procedure ValueNotify(const Value: TbtkEventFilter; Action: TCollectionNotification); override;
    /// <summary>TbtkEventFilters.OnHashingStringChanged
    /// It's necessary for call hash recalculating, when hashed filter value is changed.
    /// </summary>
    property OnHashingStringChanged: TbtkHashingStringChangeNotifyEvent read FHashingStringChanged write FHashingStringChanged;
  public
    constructor Create(AEventObjectClass: TbtkEventObjectClass; AEventObject: TbtkEventObject = nil);
    /// <summary>TbtkEventFilters.HashingString
    /// See description of TEventFilterSetting for more info about the hashed filters.
    /// </summary>
    property HashingString: string read FHashingString;
    property Filters[AName: string]: TbtkEventFilter read GetFilters; default;
  end;

  /// <summary>IbtkCustomEventHandler
  /// Base interface for event-hooks and event-handlers.
  /// </summary>
  IbtkCustomEventHandler = interface
    function GetListener: TObject;
    function GetExtracted: Boolean;
    procedure SetExtracted(AValue: Boolean);
    /// <summary>IbtkCustomEventHandler.Invoke
    /// Calls event-hook or event-handler.
    /// </summary>
    procedure Invoke(AEventObject: IbtkEventObject);
    /// <summary>IbtkCustomEventHandler.Lock
    /// Used to provide thread safety.
    /// </summary>
    function Lock(ATimeout: Cardinal = INFINITE): Boolean;
    /// <summary>IbtkCustomEventHandler.Unlock
    /// Used to provide thread safety.
    /// </summary>
    procedure Unlock;
    /// <summary>IbtkCustomEventHandler.Listener
    /// Listener who owns an event-hook or event-handler.
    /// </summary>
    property Listener: TObject read GetListener;
    /// <summary>IbtkCustomEventHandler.Extracted
    /// Allows to check that the listener was not extracted from the eventbus.
    /// </summary>
    property Extracted: Boolean read GetExtracted write SetExtracted;
  end;

  /// <summary>IbtkEventHandler
  /// Allows to call event-handler and gain access to his filters.
  /// </summary>
  IbtkEventHandler = interface(IbtkCustomEventHandler)
    function GetFilters: TbtkEventFilters;
    /// <summary>TbtkEventHandler.Filters
    /// Reference to filters of event-handler.
    /// </summary>
    property Filters: TbtkEventFilters read GetFilters;
  end;

  /// <summary>IbtkEventHook
  /// Allows to call event-hook, and gain access to his absolute number.
  /// </summary>
  IbtkEventHook = interface(IbtkCustomEventHandler)
    function GetAbsoluteNumber: Integer;
    /// <summary>TbtkEventHook.AbsoluteNumber
    /// Ordinal number of hook.
    /// </summary>
    property AbsoluteNumber: Integer read GetAbsoluteNumber;
  end;

  TbtkCustomHandlerList = TList<IbtkCustomEventHandler>;
  TbtkHookList = TList<IbtkEventHook>;
  TbtkHandlerList = TList<IbtkEventHandler>;

  /// <summary>TbtkCustomEventHandler
  /// Base class for event-hooks and event-handlers.
  /// </summary>
  TbtkCustomEventHandler = class(TInterfacedObject, IbtkCustomEventHandler)
  strict private
    FListener: TObject;
    FMethod: TRttiMethod;
    FExtracted: Boolean;
    function GetListener: TObject;
    function GetExtracted: Boolean;
    procedure SetExtracted(AValue: Boolean);
  public
    constructor Create(AListener: TObject; AMethod: TRttiMethod); virtual;
    /// <summary>TbtkCustomEventHandler.Invoke
    /// Implements IbtkCustomEventHandler.Invoke
    /// </summary>
    procedure Invoke(AEventObject: IbtkEventObject); inline;
    /// <summary>TbtkCustomEventHandler.Lock
    /// Implements IbtkCustomEventHandler.Lock
    /// </summary>
    function Lock(ATimeout: Cardinal = INFINITE): Boolean;
    /// <summary>TbtkCustomEventHandler.Unlock
    /// Implements IbtkCustomEventHandler.Unlock
    /// </summary>
    procedure Unlock;
    /// <summary>TbtkCustomEventHandler.Listener
    /// Implements IbtkCustomEventHandler.Listener
    /// </summary>
    property Listener: TObject read GetListener;
    /// <summary>TbtkCustomEventHandler.Extracted
    /// Implements IbtkCustomEventHandler.Extracted
    /// </summary>
    property Extracted: Boolean read GetExtracted write SetExtracted;
  end;

  /// <summary>TbtkEventHandler
  /// Allows to call event-handler and gain access to his filters.
  /// </summary>
  TbtkEventHandler = class(TbtkCustomEventHandler, IbtkEventHandler)
  private
    FFilters: TbtkEventFilters;
    FHashingStringChanged: TbtkHashingStringChangeNotifyEvent;
    procedure HashingStringChanged(ASender: TObject; AOldValue: string);
    function GetFilters: TbtkEventFilters;
  protected
    /// <summary>TbtkEventHandler.OnHashingStringChanged
    /// It's necessary for call hash recalculating, when hashed filter value is changed.
    /// </summary>
    property OnHashingStringChanged: TbtkHashingStringChangeNotifyEvent read FHashingStringChanged write FHashingStringChanged;
  public
    constructor Create(AListener: TObject; AMethod: TRttiMethod; AFilters: TbtkEventFilters); reintroduce;
    destructor Destroy; override;
    /// <summary>TbtkEventHandler.Filters
    /// Implements IbtkEventHandler.Filters
    /// </summary>
    property Filters: TbtkEventFilters read GetFilters;
  end;

  /// <summary>TbtkEventHook
  /// Allows to call event-hook, and gain access to his absolute number.
  /// </summary>
  TbtkEventHook = class(TbtkCustomEventHandler, IbtkEventHook)
  private
    FAbsoluteNumber: Integer;
    function GetAbsoluteNumber: Integer;
    class var HookCounter: Integer;
  public
    class constructor Create;
    constructor Create(AListener: TObject; AMethod: TRttiMethod); override;
    /// <summary>TbtkEventHook.AbsoluteNumber
    /// Implements IbtkEventHook.AbsoluteNumber
    /// </summary>
    property AbsoluteNumber: Integer read GetAbsoluteNumber;
  end;

  /// <summary>TbtkEventHookComparer
  /// Compares hooks by  their AbsoluteNumber.
  /// </summary>
  TbtkEventHookComparer = class(TComparer<IbtkEventHook>)
  public
    function Compare(const Left, Right: IbtkEventHook): Integer; override;
  end;

  /// <summary>IbtkEventHandlerEnumerator
  /// Implement enumeration list of handlers.
  /// </summary>
  IbtkEventHandlerEnumerator = interface
  ['{9E2E497D-E4F8-48A0-8C47-8A7B337667B5}']
    function GetCurrent: IbtkCustomEventHandler;
    function MoveNext: Boolean;
    property Current: IbtkCustomEventHandler read GetCurrent;
  end;

  /// <summary>TbtkEeventHandlerEnumerator
  /// Implement enumeration list of handlers.
  /// </summary>
  TbtkEeventHandlerEnumerator = class(TInterfacedObject, IbtkEventHandlerEnumerator)
  private
    FHandlerList: TbtkCustomHandlerList;
    FIndex: Integer;
    function GetCurrent: IbtkCustomEventHandler;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    function MoveNext: Boolean;
    procedure AddHandler(AHandler: IbtkCustomEventHandler);
    property Current: IbtkCustomEventHandler read GetCurrent;
  end;

  /// <summary>TbtkListenerInfo
  /// Contains information about listener.
  /// </summary>
  TbtkListenerInfo = class
  strict private
    FListener: TObject;
    FHandlersClassInfo: TbtkEventHandlersRTTIInfo;
    FHandlerFilters: TDictionary<TbtkEventObjectClass, TbtkEventFilters>;
    procedure FillFilters;
  public
    constructor Create(AListener: TObject);
    destructor Destroy; override;
    /// <summary>TbtkListenerInfo.HookMethods
    /// Returns a dictionary that associates class of event-object with hook of listener.
    /// </summary>
    function HookMethods: TDictionary<TbtkEventObjectClass, TRttiMethod>;
    /// <summary>TbtkListenerInfo.HandlerMethods
    /// Returns a dictionary that associates class of event-object with handler of listener.
    /// </summary>
    function HandlerMethods: TDictionary<TbtkEventObjectClass, TRttiMethod>;
    /// <summary>TbtkListenerInfo.HandlerFilters
    /// Returns a dictionary that associates class of event-object with handler-filters of listener.
    /// </summary>
    function HandlerFilters: TDictionary<TbtkEventObjectClass, TbtkEventFilters>;
    /// <summary>TbtkListenerInfo.Listener
    /// Reference to instance of listener.
    /// </summary>
    property Listener: TObject read FListener;
  end;

  /// <summary>TbtkEventHandlers
  /// Contains lists of all hooks and handlers for one event.
  /// </summary>
  TbtkEventHandlers = class
  private
    type
      THashingString = string;
      TbtkHandlerDictionary = TObjectDictionary<THashingString, TbtkHandlerList>;
    var
      FHookList: TbtkHookList;
      FHandlerLists: TbtkHandlerDictionary;

    procedure HashingStringChanged(ASender: TObject; AOldValue: string);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>TbtkEventHandlers.HookList
    /// List of all hooks, that were set for this event.
    /// </summary>
    property HookList: TbtkHookList read FHookList;
    /// <summary>TbtkEventHandlers.HookList
    /// List of all handlers, that were set for this event.
    /// </summary>
    property HandlerLists: TbtkHandlerDictionary read FHandlerLists;
  end;

  TbtkEventExceptionHandler = reference to procedure(AException: Exception);

  /// <summary>IbtkEventBus
  /// Provides basic methods for working with EventBus.
  /// </summary>
  IbtkEventBus = interface
  ['{7736BD48-9E52-4FE5-885B-742AF54BF020}']
    /// <summary>IbtkEventBus.Send
    /// Calls event handling.
    /// If an event handler raises an exception, process of calling other handlers
    /// not will aborted, but will be called ApplicationHandleException.
    /// For exception handling must specify "AExceptionHandler".
    /// </summary>
    procedure Send(AEventObject: IbtkEventObject; AExceptionHandler: TbtkEventExceptionHandler = nil);
    /// <summary>IbtkEventBus.Register
    /// Registers the listener.
    /// </summary>
    function Register(AListener: TObject): TbtkListenerInfo;
    /// <summary>IbtkEventBus.UnRegister
    /// Unregisters the listener.
    /// </summary>
    procedure UnRegister(AListener: TObject);
  end;

  /// <summary>TbtkCustomEventBus
  /// Allows you to create a new EventBus,
  /// or get access to the global named EventBus.
  /// </summary>
  TbtkCustomEventBus = class(TInterfacedObject, IbtkEventBus)
  strict private
    type
      TEventBusName = string;
    class var FEventBusDictionary: TDictionary<TEventBusName, TbtkCustomEventBus>;
  private
    FName: string;
    FListenersInfo: TObjectDictionary<TObject, TbtkListenerInfo>;
    FEventHandlers: TObjectDictionary<TbtkEventObjectClass, TbtkEventHandlers>;
    /// <summary>TbtkEventBus.AddFromListener
    /// Adds hooks and handlers of the listener.
    /// </summary>
    procedure AddFromListener(AEventObjectClass: TbtkEventObjectClass; AListenerInfo: TbtkListenerInfo);
    /// <summary>TbtkEventBus.RemoveFromListener
    /// Removes hooks and handlers of the listener.
    /// </summary>
    procedure RemoveFromListener(AEventObjectClass: TbtkEventObjectClass; AListenerInfo: TbtkListenerInfo);
  protected
    procedure InternalSend(AEventObject: IbtkEventObject; AHandlerEnumerator: IbtkEventHandlerEnumerator; AExceptionHandler: TbtkEventExceptionHandler); virtual; abstract;
  public
    class constructor Create;
    class destructor Destroy;
    /// <summary>TbtkEventBus.GetEventBus
    /// Returns the named global EventBus. If EventBus with that name does not exist, it is created.
    /// </summary>
    class function GetEventBus(AName: TEventBusName = ''): IbtkEventBus;
    constructor Create; virtual;
    destructor Destroy; override;
    /// <summary>TbtkEventBus.Send
    /// Implements TbtkEventBus.Send.
    /// </summary>
    procedure Send(AEventObject: IbtkEventObject; AExceptionHandler: TbtkEventExceptionHandler = nil);
    /// <summary>TbtkEventBus.Register
    /// Implements TbtkEventBus.Register.
    /// </summary>
    function Register(AListener: TObject): TbtkListenerInfo;
    /// <summary>TbtkEventBus.UnRegister
    /// Implements TbtkEventBus.UnRegister.
    /// </summary>
    procedure UnRegister(AListener: TObject);
  end;

  TbtkCustomEventSender = class(TInterfacedObject)
  protected
    procedure DoExecuteHandlers(AEventObject: IbtkEventObject; AHandlerEnumerator: IbtkEventHandlerEnumerator; AExceptionHandler: TbtkEventExceptionHandler);
  public
    procedure Send(AEventObject: IbtkEventObject; AHandlerEnumerator: IbtkEventHandlerEnumerator; AExceptionHandler: TbtkEventExceptionHandler); virtual; abstract;
  end;

  TbtkEventBus<T: TbtkCustomEventSender, constructor> = class(TbtkCustomEventBus)
  private
    FEventSender: T;
  protected
    procedure InternalSend(AEventObject: IbtkEventObject; AHandlerEnumerator: IbtkEventHandlerEnumerator; AExceptionHandler: TbtkEventExceptionHandler); override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

  TbtkSyncEventSender = class(TbtkCustomEventSender)
  public
    procedure Send(AEventObject: IbtkEventObject; AHandlerEnumerator: IbtkEventHandlerEnumerator; AExceptionHandler: TbtkEventExceptionHandler); override;
  end;

  TbtkEventBus = TbtkEventBus<TbtkSyncEventSender>;

var
  ThreadLockWaitingTimeout: Cardinal = 30000;

implementation

function NormalizeFilterName(AFilterName: string): string;
begin
  Result := LowerCase(AFilterName);
end;

function NormalizeFilterValue(AFilterValue: string; ACaseSensitive: Boolean): string;
begin
  if ACaseSensitive then
    Result := AFilterValue
  else
    Result := LowerCase(AFilterValue);
end;

{ EventFilterAttribute }

constructor EventFilterAttribute.Create(AName: string; AProperties: TEventFilterProperties);
begin
  inherited Create;
  FName := AName;
  FProperties := AProperties;
end;

{ TbtkEventObject }

constructor TbtkEventObject.Create(ATopic: string);
begin
  inherited Create;
  FTopic := ATopic;
end;

function TbtkEventObject.Instance: TbtkEventObject;
begin
  Result := Self;
end;

function TbtkEventObject.Topic: string;
begin
  Result := FTopic;
end;

{ TbtkEventFilterInfo }

constructor TbtkEventFilterInfo.Create(AFilterName: string; AProperties: TEventFilterProperties;
  AMethod: TRttiMethod);
begin
  FFilterName := AFilterName;
  FProperties := AProperties;
  FMethod := AMethod;
end;

function TbtkEventFilterInfo.GetValueFor(AInstance: TbtkEventObject): string;
begin
  Result := FMethod.Invoke(AInstance, []).AsString;
end;

{ TbtkEventFiltersClassInfo }

class constructor TbtkEventFiltersRTTIInfo.Create;
begin
  FEventsFilterDictionary := TEventsFilterDictionary.Create([doOwnsValues]);
end;

class destructor TbtkEventFiltersRTTIInfo.Destroy;
begin
  FEventsFilterDictionary.Free;
end;

class function TbtkEventFiltersRTTIInfo.GetInfoFor(AEventObjectClass: TEventObjectClass): TEventFilterInfoList;
var
  i, j: Integer;
  rContext: TRttiContext;
  rMethods: TArray<TRttiMethod>;
  rMethodAttributes: TArray<TCustomAttribute>;
  eventFilterInfoList: TEventFilterInfoList;

begin
  if not FEventsFilterDictionary.TryGetValue(AEventObjectClass, eventFilterInfoList) then
  begin
    FEventsFilterDictionary.Add(AEventObjectClass, TEventFilterInfoList.Create);
    eventFilterInfoList := FEventsFilterDictionary[AEventObjectClass];

    rContext := TRttiContext.Create;
    try
      rMethods := rContext.GetType(AEventObjectClass).GetMethods;
      for i := 0 to Length(rMethods) - 1 do
      begin
        rMethodAttributes := rMethods[i].GetAttributes;
        for j := 0 to Length(rMethodAttributes) - 1 do
          if rMethodAttributes[j] is EventFilterAttribute then
            eventFilterInfoList.Add(
              TbtkEventFilterInfo.Create(
                EventFilterAttribute(rMethodAttributes[j]).Name,
                EventFilterAttribute(rMethodAttributes[j]).Properties,
                rMethods[i]));
      end;

    finally
      rContext.Free;
    end;
  end;
  Result := eventFilterInfoList;
end;

function GetEventHandlerParameterType(AMethod: TRttiMethod): TbtkEventObjectClass;
var
  rParameters: TArray<TRttiParameter>;
  parameterType: TClass;
begin
  rParameters := AMethod.GetParameters;

  if (AMethod.MethodKind = mkProcedure) and
    (Length(rParameters) = 1) and (rParameters[0].ParamType.IsInstance) then
  begin
    parameterType := rParameters[0].ParamType.AsInstance.MetaclassType;
    if parameterType.InheritsFrom(TbtkEventObject) then
      Exit(TbtkEventObjectClass(parameterType));
  end;
  raise Exception.Create('Handler must be a procedure of object and contain the a single parameter of type ' + TbtkEventObject.ClassName);
end;

{ TbtkEventHandlersClassInfo }

class constructor TbtkEventHandlersRTTIInfo.Create;
begin
  FEventsHandlerDictionary := TEventsHandlerDictionary.Create([doOwnsValues]);
  FEventsHookDictionary := TEventsHookDictionary.Create([doOwnsValues]);
end;

class destructor TbtkEventHandlersRTTIInfo.Destroy;
begin
  FEventsHandlerDictionary.Free;
  FEventsHookDictionary.Free;
end;

class function TbtkEventHandlersRTTIInfo.GetInfoFor(AListenerClass: TListenerClass): TbtkEventHandlersRTTIInfo;
var
  i, j: Integer;
  rContext: TRttiContext;
  rMethods: TArray<TRttiMethod>;
  rMethodAttributes: TArray<TCustomAttribute>;
  handlerMethods: TEventHandlerMethodDictionary;
  hookMethods: TEventHookMethodDictionary;
begin
  Result.FListenerClass := AListenerClass;
  if not FEventsHandlerDictionary.ContainsKey(AListenerClass) then
  begin
    handlerMethods := TEventHandlerMethodDictionary.Create;
    hookMethods := TEventHandlerMethodDictionary.Create;
    rContext := TRttiContext.Create;
    try
      rMethods := rContext.GetType(AListenerClass).GetMethods;
      for i := 0 to Length(rMethods) - 1 do
      begin
        rMethodAttributes := rMethods[i].GetAttributes;
        for j := 0 to Length(rMethodAttributes) - 1 do
        try
          if rMethodAttributes[j] is EventHandlerAttribute then
            handlerMethods.Add(GetEventHandlerParameterType(rMethods[i]), rMethods[i])
          else
            if rMethodAttributes[j] is EventHookAttribute then
              hookMethods.Add(GetEventHandlerParameterType(rMethods[i]), rMethods[i]);
        except
          handlerMethods.Free;
          hookMethods.Free;
          raise;
        end;
      end;
      FEventsHandlerDictionary.Add(AListenerClass, handlerMethods);
      FEventsHookDictionary.Add(AListenerClass, hookMethods);
    finally
      rContext.Free;
    end;
  end;
end;

function TbtkEventHandlersRTTIInfo.HandlerMethods: TEventHandlerMethodDictionary;
begin
  Result := FEventsHandlerDictionary[FListenerClass];
end;

function TbtkEventHandlersRTTIInfo.HookMethods: TEventHookMethodDictionary;
begin
  Result := FEventsHookDictionary[FListenerClass];
end;

{ TbtkEventFilter }

procedure TbtkEventFilter.SetValue(const AValue: string);
begin
  FValue := AValue;
  FNormalizedValue := NormalizeFilterValue(FValue, efpCaseSensitive in Properties);
  if Assigned(FOnValueChanged) then
    FOnValueChanged(Self);
end;

constructor TbtkEventFilter.Create(AProperties: TEventFilterProperties; AValue: string);
begin
  //Properties must be set befor Value
  FProperties := AProperties;
  SetValue(AValue);
end;

{ TEventFilters }

procedure TbtkEventFilters.UpdateHashingString;
var
  i: Integer;
  filterPairs: TArray<TPair<string, TbtkEventFilter>>;
  eventFilter: TbtkEventFilter;
begin
  FHashingString := EmptyStr;
  filterPairs := ToArray;
  for i := 0 to Length(filterPairs) - 1 do
  begin
    eventFilter := filterPairs[i].Value;
    if efpIsPartOfHashingString in eventFilter.Properties then
      FHashingString := Format('%s%s=%s;', [FHashingString, NormalizeFilterName(filterPairs[i].Key),
        eventFilter.NormalizedValue]);
  end;
end;

procedure TbtkEventFilters.FilterValueChanged(ASender: TObject);
var
  oldHashingString: string;
begin
  if efpIsPartOfHashingString in TbtkEventFilter(ASender).Properties then
  begin
    oldHashingString := HashingString;
    UpdateHashingString;
    if oldHashingString <> HashingString then
      if Assigned(FHashingStringChanged) then
        FHashingStringChanged(Self, oldHashingString);
  end;
end;

function TbtkEventFilters.GetFilters(AName: string): TbtkEventFilter;
begin
  Result := Items[NormalizeFilterName(AName)];
end;

procedure TbtkEventFilters.ValueNotify(const Value: TbtkEventFilter; Action: TCollectionNotification);
begin
  inherited;
  case Action of
    cnAdded: Value.OnValueChanged := FilterValueChanged;
    cnRemoved..cnExtracted: Value.OnValueChanged := nil;
  end;
end;

constructor TbtkEventFilters.Create(AEventObjectClass: TbtkEventObjectClass; AEventObject: TbtkEventObject);
var
  i: Integer;
  filtersInfo: TList<TbtkEventFilterInfo>;
  filterValue: string;
begin
  inherited Create([doOwnsValues]);
  filtersInfo := TbtkEventFiltersRTTIInfo.GetInfoFor(AEventObjectClass);
  for i := 0 to filtersInfo.Count - 1 do
  begin
    if Assigned(AEventObject) then
      filterValue := filtersInfo[i].GetValueFor(AEventObject)
    else
      filterValue := EmptyStr;
    Add(NormalizeFilterName(filtersInfo[i].FilterName),
      TbtkEventFilter.Create(filtersInfo[i].Properties, filterValue));
  end;
  UpdateHashingString;
end;

{ TbtkCustomEventHandler }

function TbtkCustomEventHandler.GetListener: TObject;
begin
  Result := FListener;
end;

function TbtkCustomEventHandler.GetExtracted: Boolean;
begin
  Result := FExtracted;
end;

procedure TbtkCustomEventHandler.SetExtracted(AValue: Boolean);
begin
  FExtracted := AValue;
end;

constructor TbtkCustomEventHandler.Create(AListener: TObject; AMethod: TRttiMethod);
begin
  FListener := AListener;
  FMethod := AMethod;
  FExtracted := False;
end;

procedure TbtkCustomEventHandler.Invoke(AEventObject: IbtkEventObject);
begin
  FMethod.Invoke(Listener, [AEventObject.Instance]);
end;

function TbtkCustomEventHandler.Lock(ATimeout: Cardinal): Boolean;
begin
  Result := MonitorEnter(Self, ATimeout);
end;

procedure TbtkCustomEventHandler.Unlock;
begin
  MonitorExit(Self);
end;

{ TbtkEventHandler }

function TbtkEventHandler.GetFilters: TbtkEventFilters;
begin
  Result := FFilters;
end;

constructor TbtkEventHandler.Create(AListener: TObject; AMethod: TRttiMethod; AFilters: TbtkEventFilters);
begin
  inherited Create(AListener, AMethod);
  FFilters := AFilters;
  FFilters.OnHashingStringChanged := HashingStringChanged;
end;

destructor TbtkEventHandler.Destroy;
begin
  FFilters.OnHashingStringChanged := nil;
  inherited;
end;

procedure TbtkEventHandler.HashingStringChanged(ASender: TObject; AOldValue: string);
begin
  if Assigned(FHashingStringChanged) then
    FHashingStringChanged(Self, AOldValue);
end;

{ TbtkEventHook }

function TbtkEventHook.GetAbsoluteNumber: Integer;
begin
  Result := FAbsoluteNumber;
end;

class constructor TbtkEventHook.Create;
begin
  HookCounter := 0;
end;

constructor TbtkEventHook.Create(AListener: TObject; AMethod: TRttiMethod);
begin
  inherited;
  FAbsoluteNumber := HookCounter;
  Inc(HookCounter);
end;

{ TbtkEventHookComparer }

function TbtkEventHookComparer.Compare(const Left, Right: IbtkEventHook): Integer;
begin
  Result := TComparer<Integer>.Default.Compare(Left.AbsoluteNumber, Right.AbsoluteNumber);
end;

{ TbtkEeventHandlerEnumerator }

function TbtkEeventHandlerEnumerator.GetCurrent: IbtkCustomEventHandler;
begin
  Result := FHandlerList[FIndex];
end;

constructor TbtkEeventHandlerEnumerator.Create;
begin
  inherited Create;
  FIndex := -1;
  FHandlerList := TbtkCustomHandlerList.Create;
end;

destructor TbtkEeventHandlerEnumerator.Destroy;
begin
  FHandlerList.Free;
  inherited;
end;

function TbtkEeventHandlerEnumerator.MoveNext: Boolean;
begin
  if FIndex >= FHandlerList.Count then
    Exit(False);
  Inc(FIndex);
  Result := FIndex < FHandlerList.Count;
end;

procedure TbtkEeventHandlerEnumerator.AddHandler(AHandler: IbtkCustomEventHandler);
begin
  FHandlerList.Add(AHandler);
end;

{ TbtkListenerInfo }

procedure TbtkListenerInfo.FillFilters;
var
  i: Integer;
  eventObjectClasses: TArray<TbtkEventObjectClass>;
begin
  eventObjectClasses := HandlerMethods.Keys.ToArray;
  for i := 0 to Length(eventObjectClasses) - 1 do
    HandlerFilters.Add(eventObjectClasses[i], TbtkEventFilters.Create(eventObjectClasses[i]));
end;

constructor TbtkListenerInfo.Create(AListener: TObject);
begin
  inherited Create;
  FListener := AListener;
  FHandlersClassInfo := TbtkEventHandlersRTTIInfo.GetInfoFor(AListener.ClassType);
  FHandlerFilters := TDictionary<TbtkEventObjectClass, TbtkEventFilters>.Create;
  FillFilters;
end;

destructor TbtkListenerInfo.Destroy;
begin
  FHandlerFilters.Free;
  inherited Destroy;
end;

function TbtkListenerInfo.HookMethods: TDictionary<TbtkEventObjectClass, TRttiMethod>;
begin
  Result := FHandlersClassInfo.HookMethods;
end;

function TbtkListenerInfo.HandlerMethods: TDictionary<TbtkEventObjectClass, TRttiMethod>;
begin
  Result := FHandlersClassInfo.HandlerMethods;
end;

function TbtkListenerInfo.HandlerFilters: TDictionary<TbtkEventObjectClass, TbtkEventFilters>;
begin
  Result := FHandlerFilters;
end;

{ TbtkEventHandlers }

constructor TbtkEventHandlers.Create;
begin
  inherited Create;
  FHookList := TbtkHookList.Create;
  FHandlerLists := TbtkHandlerDictionary.Create([doOwnsValues]);
end;

destructor TbtkEventHandlers.Destroy;
begin
  FHookList.Free;
  FHandlerLists.Free;
  inherited;
end;

procedure TbtkEventHandlers.HashingStringChanged(ASender: TObject; AOldValue: string);
var
  eventHandler: IbtkEventHandler;
begin
  eventHandler := HandlerLists[AOldValue].Extract(TbtkEventHandler(ASender));
  if HandlerLists[AOldValue].Count = 0 then
    HandlerLists.Remove(AOldValue);
  if not HandlerLists.ContainsKey(eventHandler.Filters.HashingString) then
    HandlerLists.Add(eventHandler.Filters.HashingString, TbtkHandlerList.Create);
  HandlerLists[eventHandler.Filters.HashingString].Add(eventHandler);
end;

{ TbtkEventBus }

procedure TbtkCustomEventBus.AddFromListener(AEventObjectClass: TbtkEventObjectClass; AListenerInfo: TbtkListenerInfo);
var
  eventHashingString: string;
  eventHandler: TbtkEventHandler;
  eventHook: TbtkEventHook;
  handlerList: TbtkHandlerList;
begin
  if AListenerInfo.HandlerMethods.ContainsKey(AEventObjectClass) then
  begin
    eventHandler := TbtkEventHandler.Create(AListenerInfo.Listener,
      AListenerInfo.HandlerMethods[AEventObjectClass],
      AListenerInfo.HandlerFilters[AEventObjectClass]);
    eventHandler.OnHashingStringChanged := FEventHandlers[AEventObjectClass].HashingStringChanged;

    eventHashingString := AListenerInfo.HandlerFilters[AEventObjectClass].HashingString;
    if not FEventHandlers[AEventObjectClass].HandlerLists.TryGetValue(eventHashingString, handlerList) then
    begin
      handlerList := TbtkHandlerList.Create;
      FEventHandlers[AEventObjectClass].HandlerLists.Add(eventHashingString, handlerList);
    end;
    handlerList.Add(eventHandler);
  end;

  if AListenerInfo.HookMethods.ContainsKey(AEventObjectClass) then
  begin
    eventHook := TbtkEventHook.Create(AListenerInfo.Listener, AListenerInfo.HookMethods[AEventObjectClass]);
    FEventHandlers[AEventObjectClass].HookList.Add(eventHook);
  end;
end;

procedure TbtkCustomEventBus.RemoveFromListener(AEventObjectClass: TbtkEventObjectClass; AListenerInfo: TbtkListenerInfo);
var
  i: Integer;
  eventHashingString: string;
  handlerList: TbtkHandlerList;
  handler: IbtkCustomEventHandler;
begin
  if AListenerInfo.HandlerMethods.ContainsKey(AEventObjectClass) then
  begin
    eventHashingString := AListenerInfo.HandlerFilters[AEventObjectClass].HashingString;
    handlerList := FEventHandlers[AEventObjectClass].HandlerLists[eventHashingString];
    for i := 0 to handlerList.Count - 1 do
    begin
      if handlerList[i].Listener = AListenerInfo.Listener then
      begin
        handler := handlerList[i];
        if handler.Lock(ThreadLockWaitingTimeout) then
        try
          handler.Extracted := True;
          handlerList.Delete(i);
        finally
          handler.Unlock;
        end
        else
          raise Exception.Create('Could not lock handler');
        if handlerList.Count = 0 then
          FEventHandlers[AEventObjectClass].HandlerLists.Remove(eventHashingString);
        Break;
      end;
    end;
  end;

  if AListenerInfo.HookMethods.ContainsKey(AEventObjectClass) then
    for i := FEventHandlers[AEventObjectClass].HookList.Count - 1 downto 0 do
      if FEventHandlers[AEventObjectClass].HookList[i].Listener = AListenerInfo.Listener then
      begin
        handler := FEventHandlers[AEventObjectClass].HookList[i];
        if handler.Lock(ThreadLockWaitingTimeout) then
        try
          handler.Extracted := True;
          FEventHandlers[AEventObjectClass].HookList.Delete(i);
        finally
          handler.Unlock;
        end
        else
          raise Exception.Create('Could not lock handler');
        Break;
      end;
end;

class constructor TbtkCustomEventBus.Create;
begin
  FEventBusDictionary := TDictionary<TEventBusName, TbtkCustomEventBus>.Create;
end;

class destructor TbtkCustomEventBus.Destroy;
begin
  FEventBusDictionary.Free;
end;

class function TbtkCustomEventBus.GetEventBus(AName: TEventBusName): IbtkEventBus;
var
  eventBus: TbtkCustomEventBus;
begin
  if not FEventBusDictionary.TryGetValue(AName, eventBus) then
  begin
    eventBus := Self.Create;
    eventBus.FName := AName;
    FEventBusDictionary.Add(AName, eventBus);
  end;
  if not(eventBus is Self) then
    raise Exception.Create('Incorrectly specified class of eventbus');
  Result := eventBus;
end;

constructor TbtkCustomEventBus.Create;
begin
  inherited Create;
  FListenersInfo := TObjectDictionary<TObject, TbtkListenerInfo>.Create([doOwnsValues]);
  FEventHandlers := TObjectDictionary<TbtkEventObjectClass, TbtkEventHandlers>.Create([doOwnsValues]);
end;

destructor TbtkCustomEventBus.Destroy;
begin
  if TbtkCustomEventBus.FEventBusDictionary.ContainsKey(FName) then
    TbtkCustomEventBus.FEventBusDictionary.Remove(FName);
  FListenersInfo.Free;
  FEventHandlers.Free;
  inherited Destroy;
end;

procedure TbtkCustomEventBus.Send(AEventObject: IbtkEventObject; AExceptionHandler: TbtkEventExceptionHandler);
  function FiltersMatch(AEventFilters: TbtkEventFilters; AHandlerFilters: TbtkEventFilters): Boolean;
  var
    i: Integer;
    filterNames: TArray<string>;
    eventFilter, handlerFilter: TbtkEventFilter;
  begin
    Result := True;
    filterNames := AEventFilters.Keys.ToArray;
    for i := 0 to Length(filterNames) - 1 do
    begin
      eventFilter := AEventFilters[filterNames[i]];
      handlerFilter := AHandlerFilters[filterNames[i]];
      if not(efpIsPartOfHashingString in eventFilter.Properties) and
        (handlerFilter.Value <> EmptyStr) and
        (handlerFilter.NormalizedValue <> eventFilter.NormalizedValue) then
        Exit(False);
    end;
  end;

  procedure SafeInvoke(AEventObject: IbtkEventObject;
    AEventHandler: IbtkCustomEventHandler; AExceptionHandler: TbtkEventExceptionHandler);
  begin
    try
      AEventHandler.Invoke(AEventObject);
    except
      on E: Exception do
      begin
        if Assigned(AExceptionHandler) then
          AExceptionHandler(E)
        else
          ApplicationHandleException(Self);
      end;
    end;
  end;

var
  i: Integer;

  eventClass: TbtkEventObjectClass;
  eventFilters: TbtkEventFilters;
  eventHandlers: TbtkEventHandlers;
  eventHandlerList: TbtkHandlerList;

  hooks: TbtkHookList;
  handlers: TbtkHandlerList;

  handlerEnumerator: TbtkEeventHandlerEnumerator;

begin
  if not(AEventObject.Instance is TbtkEventObject) then
    raise Exception.Create('Event object must be inherits from TbtkEventObject class');

  hooks := TbtkHookList.Create;
  handlers := TbtkHandlerList.Create;
  try

    eventClass := TbtkEventObjectClass(AEventObject.Instance.ClassType);
    while eventClass <> TbtkEventObject.ClassParent do
    begin
      eventFilters := TbtkEventFilters.Create(eventClass, AEventObject.Instance);
      try
        if FEventHandlers.TryGetValue(eventClass, eventHandlers) then
        begin
          hooks.AddRange(eventHandlers.HookList.ToArray);

          if eventHandlers.HandlerLists.TryGetValue(eventFilters.HashingString, eventHandlerList) then
            for i := 0 to eventHandlerList.Count - 1 do
              if FiltersMatch(eventFilters, eventHandlerList[i].Filters) then
                handlers.Add(eventHandlerList[i]);
        end;
      finally
        eventFilters.Free;
      end;
      eventClass := TbtkEventObjectClass(eventClass.ClassParent)
    end;

    hooks.Sort(TbtkEventHookComparer.Create);
    handlerEnumerator := TbtkEeventHandlerEnumerator.Create;
    try
      for i := hooks.Count -1 downto 0 do
        handlerEnumerator.AddHandler(hooks[i]);

      for i := handlers.Count - 1 downto 0 do
        handlerEnumerator.AddHandler(handlers[i]);

      InternalSend(AEventObject, handlerEnumerator, AExceptionHandler);
    except
      handlerEnumerator.Free;
      raise;
    end;

  finally
    hooks.Free;
    handlers.Free;
  end;
end;

function TbtkCustomEventBus.Register(AListener: TObject): TbtkListenerInfo;
var
  i: Integer;
  handlerClasses: TArray<TbtkEventObjectClass>;
  hookClasses: TArray<TbtkEventObjectClass>;
  eventObjectClassList: TList<TbtkEventObjectClass>;
begin
  Assert(not FListenersInfo.ContainsKey(AListener), 'Listener already exists');
  FListenersInfo.Add(AListener, TbtkListenerInfo.Create(AListener));
  eventObjectClassList := TList<TbtkEventObjectClass>.Create;
  try
    handlerClasses := FListenersInfo[AListener].HandlerMethods.Keys.ToArray;
    hookClasses := FListenersInfo[AListener].HookMethods.Keys.ToArray;
    eventObjectClassList.AddRange(handlerClasses);
    for i := 0 to Length(hookClasses) - 1 do
      if not eventObjectClassList.Contains(hookClasses[i]) then
        eventObjectClassList.Add(hookClasses[i]);

    for i := 0 to eventObjectClassList.Count - 1 do
    begin
      if not FEventHandlers.ContainsKey(eventObjectClassList[i]) then
        FEventHandlers.Add(eventObjectClassList[i], TbtkEventHandlers.Create);
      AddFromListener(eventObjectClassList[i], FListenersInfo[AListener]);
    end;
  finally
    eventObjectClassList.Free;
  end;
  Result := FListenersInfo[AListener];
end;

procedure TbtkCustomEventBus.UnRegister(AListener: TObject);
var
  i: Integer;
  handlerClasses: TArray<TbtkEventObjectClass>;
  hookClasses: TArray<TbtkEventObjectClass>;
  eventObjectClassList: TList<TbtkEventObjectClass>;
begin
  Assert(FListenersInfo.ContainsKey(AListener), 'Listener is not exists');
  eventObjectClassList := TList<TbtkEventObjectClass>.Create;
  try
    handlerClasses := FListenersInfo[AListener].HandlerMethods.Keys.ToArray;
    hookClasses := FListenersInfo[AListener].HookMethods.Keys.ToArray;
    eventObjectClassList.AddRange(handlerClasses);
    for i := 0 to Length(hookClasses) - 1 do
      if not eventObjectClassList.Contains(hookClasses[i]) then
        eventObjectClassList.Add(hookClasses[i]);

    for i := 0 to eventObjectClassList.Count - 1 do
    begin
      RemoveFromListener(eventObjectClassList[i], FListenersInfo[AListener]);
      if (FEventHandlers[eventObjectClassList[i]].HandlerLists.Count = 0)
        and (FEventHandlers[eventObjectClassList[i]].HookList.Count = 0) then
        FEventHandlers.Remove(eventObjectClassList[i]);
    end;
  finally
    eventObjectClassList.Free;
  end;
  FListenersInfo.Remove(AListener);
end;

{ TbtkCustomEventSender }

procedure TbtkCustomEventSender.DoExecuteHandlers(AEventObject: IbtkEventObject; AHandlerEnumerator: IbtkEventHandlerEnumerator;
  AExceptionHandler: TbtkEventExceptionHandler);
var
  handler: IbtkCustomEventHandler;
begin
  while AHandlerEnumerator.MoveNext do
  try
    handler := AHandlerEnumerator.Current;
    handler.Lock(ThreadLockWaitingTimeout);
    try
      if not handler.Extracted then
        handler.Invoke(AEventObject);
    finally
      handler.Unlock;
    end;
  except
    on E: Exception do
    begin
      if Assigned(AExceptionHandler) then
        AExceptionHandler(E)
      else
        ApplicationHandleException(Self);
    end;
  end;
end;

{ TbtkEventBus<T> }

constructor TbtkEventBus<T>.Create;
begin
  inherited;
  FEventSender := T.Create;
end;

destructor TbtkEventBus<T>.Destroy;
begin
  FEventSender := nil;
  inherited;
end;

procedure TbtkEventBus<T>.InternalSend(AEventObject: IbtkEventObject; AHandlerEnumerator: IbtkEventHandlerEnumerator; AExceptionHandler: TbtkEventExceptionHandler);
begin
  FEventSender.Send(AEventObject, AHandlerEnumerator, AExceptionHandler);
end;

{ TbtkSyncEventSender }

procedure TbtkSyncEventSender.Send(AEventObject: IbtkEventObject; AHandlerEnumerator: IbtkEventHandlerEnumerator;
  AExceptionHandler: TbtkEventExceptionHandler);
begin
  DoExecuteHandlers(AEventObject, AHandlerEnumerator, AExceptionHandler);
end;

end.
