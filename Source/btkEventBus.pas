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

const
  bIsPartOfHashingString = True;

type

  /// <summary>EventHookAttribute
  /// Attribute for annotating method of listener as event-hook.
  /// </summary>
  EventHookAttribute = class(TCustomAttribute);
  /// <summary>EventHandlerAttribute
  /// Attribute for annotating method of listener as event-handler.
  /// </summary>
  EventHandlerAttribute = class(TCustomAttribute);

  /// <summary>EventFilterAttribute
  /// Attribute for annotating method of event-object as filter.
  /// </summary>
  EventFilterAttribute = class(TCustomAttribute)
  private
    FName: string;
    FIsPartOfHashingString: Boolean;
  public
    /// <summary>EventFilterAttribute.Name
    /// Used to identify filter. Must be unique for each filter of event.
    /// </summary>
    property Name: string read FName;
    /// <summary>EventFilterAttribute.IsPartOfHashingString
    /// This property is responsible for adding the filter in a hash.
    /// Using filters as a hash to reduce handler-lists. This provides faster calling handlers,
    /// but forbids the use of empty values for hashed filters of listeners.
    /// </summary>
    property IsPartOfHashingString: Boolean read FIsPartOfHashingString;
    constructor Create(AName: string; AIsPartOfHashingString: Boolean = not bIsPartOfHashingString);
  end;

  TbtkEventObject = class;
  TbtkEventObjectClass = class of TbtkEventObject;

  /// <summary>IbtkEventObject
  /// Interface is used to prevent destruction of event-object while not all handlers of listeners have been handled
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
  /// Base class of all event-objects. Implements the interface IbtkEventObject.
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
    [EventFilter(sEventFilterTopicName, bIsPartOfHashingString)]
    function Topic: string;
  end;

  /// <summary>TbtkEventFilterInfo
  /// Contains information about event-filter, and allows to get filter value of an event-object instance.
  /// </summary>
  TbtkEventFilterInfo = record
  strict private
    FFilterName: string;
    FIsPartOfHashingString: Boolean;
    FMethod: TRttiMethod;
  public
    /// <summary>TbtkEventFilterInfo.Create
    /// <param name="AFilterName">value of the annotation property "EventFilterAttribute.Name".</param>
    /// <param name="AIsPartOfHashingString">value of the annotation property "EventFilterAttribute.IsPartOfHashingString".</param>
    /// <param name="AMethod">Link to a describer of the method, that returns value of filter.</param>
    /// </summary>
    constructor Create(AFilterName: string; AIsPartOfHashingString: Boolean; AMethod: TRttiMethod);
    /// <summary>TbtkEventFilterInfo.FilterName
    /// Contains the value of the annotation property "EventFilterAttribute.Name".
    /// </summary>
    property FilterName: string read FFilterName;
    /// <summary>TbtkEventFilterInfo.IsPartOfHashingString
    /// Contains the value of the annotation property "EventFilterAttribute.IsPartOfHashingString".
    /// </summary>
    property IsPartOfHashingString: Boolean read FIsPartOfHashingString;
    /// <summary>TbtkEventFilterInfo.GetValueFor
    /// Returns filter value for instance of event-object.
    /// </summary>
    function GetValueFor(AInstance: TbtkEventObject): string;
  end;

  /// <summary>TbtkEventFiltersRTTIInfo
  /// Is used to store and retrieve information about filters of event-object classes.
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
  /// Is used to store and retrieve information about hooks and handlers of listener classes.
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
    FIsPartOfHashingString: Boolean;
    FValue: string;
    FOnValueChanged: TNotifyEvent;
    procedure SetValue(const AValue: string);
  protected
    /// <summary>TbtkEventFilter.OnValueChanged
    /// Is used to call hash recalculating, when hashed filter value is changed.
    /// </summary>
    property OnValueChanged: TNotifyEvent read FOnValueChanged write FOnValueChanged;
  public
    constructor Create(AIsPartOfHashingString: Boolean; AValue: string);
    /// <summary>TbtkEventFilter.IsPartOfHashingString
    /// See description of EventFilterAttribute.IsPartOfHashingString for more
    /// info about the hashed filters.
    /// </summary>
    property IsPartOfHashingString: Boolean read FIsPartOfHashingString;
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
    /// Is used to set handler for the event "OnValueChanged" of filters.
    /// </summary>
    procedure ValueNotify(const Value: TbtkEventFilter; Action: TCollectionNotification); override;
    /// <summary>TbtkEventFilters.OnHashingStringChanged
    /// Is used to call hash recalculating, when hashed filter value is changed.
    /// </summary>
    property OnHashingStringChanged: TbtkHashingStringChangeNotifyEvent read FHashingStringChanged write FHashingStringChanged;
  public
    constructor Create(AEventObjectClass: TbtkEventObjectClass; AEventObject: TbtkEventObject = nil);
    /// <summary>TbtkEventFilters.HashingString
    /// See description of EventFilterAttribute.IsPartOfHashingString for more
    /// info about the hashed filters.
    /// </summary>
    property HashingString: string read FHashingString;
    property Filters[AName: string]: TbtkEventFilter read GetFilters; default;
  end;

  /// <summary>TbtkCustomEventHandler
  /// Base class for event-hooks and event-handlers.
  /// </summary>
  TbtkCustomEventHandler = class
  strict private
    FListener: TObject;
    FMethod: TRttiMethod;
  public
    constructor Create(AListener: TObject; AMethod: TRttiMethod); virtual;
    /// <summary>TbtkCustomEventHandler.Invoke
    /// Calls event-hook or event-handler.
    /// </summary>
    procedure Invoke(AEventObject: IbtkEventObject); inline;
    /// <summary>TbtkCustomEventHandler.Listener
    /// Listener who owns an event-hook or event-handler.
    /// </summary>
    property Listener: TObject read FListener;
  end;

  /// <summary>TbtkEventHandler
  /// Allows to call event-handler and gain access to his filters.
  /// </summary>
  TbtkEventHandler = class(TbtkCustomEventHandler)
  private
    FFilters: TbtkEventFilters;
    FHashingStringChanged: TbtkHashingStringChangeNotifyEvent;
    procedure HashingStringChanged(ASender: TObject; AOldValue: string);
  protected
    /// <summary>TbtkEventHandler.OnHashingStringChanged
    /// Is used to call hash recalculating, when hashed filter value is changed.
    /// </summary>
    property OnHashingStringChanged: TbtkHashingStringChangeNotifyEvent read FHashingStringChanged write FHashingStringChanged;
  public
    constructor Create(AListener: TObject; AMethod: TRttiMethod; AFilters: TbtkEventFilters); reintroduce;
    destructor Destroy; override;
    /// <summary>TbtkEventHandler.Filters
    /// Reference to filters of event-handler.
    /// </summary>
    property Filters: TbtkEventFilters read FFilters;
  end;

  /// <summary>TbtkEventHook
  /// Allows to call event-hook, and gain access to his absolute number.
  /// </summary>
  TbtkEventHook = class(TbtkCustomEventHandler)
  private
    FAbsoluteNumber: Integer;
    class var HookCounter: Integer;
  public
    class constructor Create;
    constructor Create(AListener: TObject; AMethod: TRttiMethod); override;
    /// <summary>TbtkEventHook.AbsoluteNumber
    /// Ordinal number of hook. Is used to sort hooks in the order of their creation.
    /// </summary>
    property AbsoluteNumber: Integer read FAbsoluteNumber;
  end;

  /// <summary>TbtkEventHookComparer
  /// Is used to sort hooks in the order of their creation.
  /// </summary>
  TbtkEventHookComparer = class(TComparer<TbtkEventHook>)
  public
    function Compare(const Left, Right: TbtkEventHook): Integer; override;
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
      TbtkHookList = TObjectList<TbtkEventHook>;
      TbtkHandlerList = TObjectList<TbtkEventHandler>;
      TbtkHandlerDictionary = TObjectDictionary<THashingString, TbtkHandlerList>;
    var
      FHookList: TbtkHookList;
      FHandlerLists: TbtkHandlerDictionary;

    procedure HashingStringChanged(ASender: TObject; AOldValue: string);
  public
    constructor Create(AEventClassType: TbtkEventObjectClass);
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
    /// For exception handling must specify "AExceptionHandler"..
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

  /// <summary>TbtkEventBus
  /// Implements the interface IbtkEventBus. Allows you to create a new EventBus,
  /// or get access to the global named EventBus.
  /// </summary>
  TbtkEventBus = class(TInterfacedObject, IbtkEventBus)
  strict private
    type
      TEventBusName = string;
    class var FEventBusDictionary: TDictionary<TEventBusName, TbtkEventBus>;
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

implementation

function NormalizeFilterName(AFilterName: string): string;
begin
  Result := LowerCase(AFilterName);
end;

{ EventFilterAttribute }

constructor EventFilterAttribute.Create(AName: string; AIsPartOfHashingString: Boolean);
begin
  inherited Create;
  FName := AName;
  FIsPartOfHashingString := AIsPartOfHashingString;
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

constructor TbtkEventFilterInfo.Create(AFilterName: string; AIsPartOfHashingString: Boolean;
  AMethod: TRttiMethod);
begin
  FFilterName := AFilterName;
  FIsPartOfHashingString := AIsPartOfHashingString;
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
                EventFilterAttribute(rMethodAttributes[j]).IsPartOfHashingString,
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
  if Assigned(FOnValueChanged) then
    FOnValueChanged(Self);
end;

constructor TbtkEventFilter.Create(AIsPartOfHashingString: Boolean; AValue: string);
begin
  FIsPartOfHashingString := AIsPartOfHashingString;
  FValue := AValue;
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
    if eventFilter.IsPartOfHashingString then
      FHashingString := Format('%s%s=%s;', [FHashingString, NormalizeFilterName(filterPairs[i].Key), eventFilter.Value]);
  end;
end;

procedure TbtkEventFilters.FilterValueChanged(ASender: TObject);
var
  oldHashingString: string;
begin
  if TbtkEventFilter(ASender).IsPartOfHashingString then
  begin
    oldHashingString := HashingString;
    UpdateHashingString;
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
      TbtkEventFilter.Create(filtersInfo[i].IsPartOfHashingString, filterValue));
  end;
  UpdateHashingString;
end;

{ TbtkCustomEventHandler }

constructor TbtkCustomEventHandler.Create(AListener: TObject; AMethod: TRttiMethod);
begin
  FListener := AListener;
  FMethod := AMethod;
end;

procedure TbtkCustomEventHandler.Invoke(AEventObject: IbtkEventObject);
begin
  FMethod.Invoke(Listener, [AEventObject.Instance]);
end;

{ TbtkEventHandler }

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

function TbtkEventHookComparer.Compare(const Left, Right: TbtkEventHook): Integer;
begin
  Result := TComparer<Integer>.Default.Compare(Left.AbsoluteNumber, Right.AbsoluteNumber);
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

constructor TbtkEventHandlers.Create(AEventClassType: TbtkEventObjectClass);
begin
  inherited Create;
//  FEventObjectClass := AEventClassType;
  FHookList := TbtkHookList.Create(True);
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
  eventHandler: TbtkEventHandler;
begin
  eventHandler := HandlerLists[AOldValue].Extract(TbtkEventHandler(ASender));
  if HandlerLists[AOldValue].Count = 0 then
    HandlerLists.Remove(AOldValue);
  if not HandlerLists.ContainsKey(eventHandler.Filters.HashingString) then
    HandlerLists.Add(eventHandler.Filters.HashingString, TObjectList<TbtkEventHandler>.Create(True));
  HandlerLists[eventHandler.Filters.HashingString].Add(eventHandler);
end;

{ TbtkEventBus }

procedure TbtkEventBus.AddFromListener(AEventObjectClass: TbtkEventObjectClass; AListenerInfo: TbtkListenerInfo);
var
  eventHashingString: string;
  eventHandler: TbtkEventHandler;
  eventHook: TbtkEventHook;
  handlerList: TObjectList<TbtkEventHandler>;
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
      handlerList := TObjectList<TbtkEventHandler>.Create(True);
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

procedure TbtkEventBus.RemoveFromListener(AEventObjectClass: TbtkEventObjectClass; AListenerInfo: TbtkListenerInfo);
var
  i: Integer;
  eventHashingString: string;
  handlerList: TObjectList<TbtkEventHandler>;
begin
  if AListenerInfo.HandlerMethods.ContainsKey(AEventObjectClass) then
  begin
    eventHashingString := AListenerInfo.HandlerFilters[AEventObjectClass].HashingString;
    handlerList := FEventHandlers[AEventObjectClass].HandlerLists[eventHashingString];
    for i := 0 to handlerList.Count - 1 do
    begin
      if handlerList[i].Listener = AListenerInfo.Listener then
      begin
        handlerList.Delete(i);
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
        FEventHandlers[AEventObjectClass].HookList.Delete(i);
        Break;
      end;
end;

class constructor TbtkEventBus.Create;
begin
  FEventBusDictionary := TDictionary<TEventBusName, TbtkEventBus>.Create;
end;

class destructor TbtkEventBus.Destroy;
begin
  FEventBusDictionary.Free;
end;

class function TbtkEventBus.GetEventBus(AName: TEventBusName): IbtkEventBus;
var
  eventBus: TbtkEventBus;
begin
  if not FEventBusDictionary.TryGetValue(AName, eventBus) then
  begin
    eventBus := TbtkEventBus.Create;
    eventBus.FName := AName;
    FEventBusDictionary.Add(AName, eventBus);
  end;
  Result := eventBus;
end;

constructor TbtkEventBus.Create;
begin
  inherited Create;
  FListenersInfo := TObjectDictionary<TObject, TbtkListenerInfo>.Create([doOwnsValues]);
  FEventHandlers := TObjectDictionary<TbtkEventObjectClass, TbtkEventHandlers>.Create([doOwnsValues]);
end;

destructor TbtkEventBus.Destroy;
begin
  if TbtkEventBus.FEventBusDictionary.ContainsKey(FName) then
    TbtkEventBus.FEventBusDictionary.Remove(FName);
  FListenersInfo.Free;
  FEventHandlers.Free;
  inherited Destroy;
end;

procedure TbtkEventBus.Send(AEventObject: IbtkEventObject; AExceptionHandler: TbtkEventExceptionHandler);
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
      if (not eventFilter.IsPartOfHashingString) and
        (handlerFilter.Value <> EmptyStr) and
        (handlerFilter.Value <> eventFilter.Value) then
        Exit(False);
    end;
  end;

  procedure SafeInvoke(AEventObject: IbtkEventObject;
    AEventHandler: TbtkCustomEventHandler; AExceptionHandler: TbtkEventExceptionHandler);
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
  eventHandlerList: TObjectList<TbtkEventHandler>;

  hooks: TList<TbtkEventHook>;
  handlers: TList<TbtkEventHandler>;

begin
  if not(AEventObject.Instance is TbtkEventObject) then
    raise Exception.Create('Event object must be inherits from TbtkEventObject class');

  hooks := TList<TbtkEventHook>.Create;
  handlers := TList<TbtkEventHandler>.Create;
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
                handlers.AddRange(eventHandlerList.ToArray);
        end;
      finally
        eventFilters.Free;
      end;
      eventClass := TbtkEventObjectClass(eventClass.ClassParent)
    end;

    hooks.Sort(TbtkEventHookComparer.Create);
    for i := hooks.Count - 1 downto 0 do
      SafeInvoke(AEventObject, hooks[i], AExceptionHandler);

    for i := handlers.Count - 1 downto 0 do
      SafeInvoke(AEventObject, handlers[i], AExceptionHandler);

  finally
    hooks.Free;
    handlers.Free;
  end;

end;

function TbtkEventBus.Register(AListener: TObject): TbtkListenerInfo;
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
        FEventHandlers.Add(eventObjectClassList[i], TbtkEventHandlers.Create(eventObjectClassList[i]));
      AddFromListener(eventObjectClassList[i], FListenersInfo[AListener]);
    end;
  finally
    eventObjectClassList.Free;
  end;
  Result := FListenersInfo[AListener];
end;

procedure TbtkEventBus.UnRegister(AListener: TObject);
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

end.
