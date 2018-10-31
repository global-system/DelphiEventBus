DelphiEventBus
==============

Implementation of event bus pattern for Delphi XE

EventBus is designed to provide interaction between different components, without increasing connectivity.

###Features

 - **Development**
   - The type of event is determined by the class.
   - Events are inherited.
   - The base class for any event is TbtkEventObject.
 - **Filtering**
   - Events can contain filters.
   - Filter values ​​are case sensitive.
   - To declare filters, annotations of event class methods are used.
   - As a filter, functions without parameters are used that should return the filter value as a string.
   - Filters are identified by name.
   - The filter name is specified in the filter annotation.
   - Filter names are not case sensitive.
   - Filters use two modes:
     - Simple mode.
       - The event filter value corresponds to empty and exactly matching handler filter values.
       - This mode is used by default.
     - Hashable mode.
       - The event filter value only matches exactly the same handler filter value.
       - Hashing accelerates the formation of lists of handlers to be called.
   - Filter mode is specified in the filter annotation.
   - The base class contains one hash filter named "Topic"
 - **Handlers**
   - Adding event handlers is done by registering a listener on the bus.
   - Removal of event handlers is performed by unregistration of the listener in the bus.
   - The filter values ​​of listener event handlers are set after registration.
   - Filter values ​​are bound to the event type, and are equal for different handlers of the same event.
   - To declare handlers, annotations of listener methods are used.
   - Handlers must contain one input parameter with the class type of the event being processed.
   - The type of the handler parameter determines the events that it will process.
   - The handler is invoked for all heirs of the event processed by it.
   - Two types of event handlers are used:
     - Simple handlers.
       - When calling, the filtering conditions are taken into account.
       - The order of the call is not guaranteed.
     - Hooks.
       - Called before calling simple handlers.
       - Ignore filtering conditions.
       - The order of the call corresponds to the reverse order of registration.
   - The type of handler will be determined by annotation.

### Example of use
```delphi
	//event class declaration
	Type
	  TFooEventObject = class(TbtkEventObject)
	  //..........................
	  public
	    const sFooFilterName = 'FooFilter';

	    constructor Create(ATopic: string; AFooFliter: string);

	    [EventFilter(sFooFilterName)] //filter parameter declaration
	    function FooFilter: string;

	  //..........................
	  end;

	//preparation of the listener
	  TFooEventListener = class
	  //..........................
	  public

	    [EventHandler] //handler declaration
	    procedure FooHandler(AFooEvent: TFooEventObject);

	    [EventHook] //hook declaration
	    procedure FooHook(AEventObject: TFooEventObject);

	  //..........................
	  end;

	  EventBus := TbtkEventBus.GetEventBus('FooEventBus');

	  ListenerInfo := EventBus.Register(FooEventListener);

	//setting filter parameters
	  ListenerInfo.HandlerFilters[TFooEventObject][TFooEventObject.sEventFilterTopicName].Value := 'TopicValue';
	  ListenerInfo.HandlerFilters[TFooEventObject][TFooEventObject.sFooFilterName].Value := 'FooFilterValue';

	//creating and sending events
	  EventBus.Send(TFooEventObject.Create('TopicValue', 'FooFilterValue'));

	//listener unregistration
	  EventBus.Unregister(FooListener);
```
### Minimalistic example of use eventhook
```delphi
	program EventHookExample;

        {$APPTYPE CONSOLE}

        uses
          System.SysUtils,
          btkEventBus;

        type
          TFooEventListener = class
          public
            [EventHook] //hook declaration
            procedure FooHook(EventObject: TbtkEventObject);
          end;

        { TFooEventListener }

        //hook implementation
        procedure TFooEventListener.FooHook(EventObject: TbtkEventObject);
        begin
          Writeln(Format('======'#13#10'Event with topic "%s" sended', [EventObject.Topic]));
        end;

        const
          ebFoo = 'FooEventBus';
        var
          FooEventListener: TFooEventListener;
          FooTopicName: string;
        begin
          //register class for eventbus with name 'FooEventBus'
          RegisterEventBusClass(TbtkEventBus, ebFoo);

          FooEventListener := TFooEventListener.Create;
          try
            //register listener
            EventBus(ebFoo).Register(FooEventListener);

            Write('Write topic: ');
            ReadLn(FooTopicName);

            //create and send event
            EventBus(ebFoo).Send(TbtkEventObject.Create(FooTopicName));
          finally
            FooEventListener.Free;
          end;
          Readln;
        end.
```
### Minimalistic example of use eventhandler
```delphi
	program EventHookExample;

        {$APPTYPE CONSOLE}

        uses
          System.SysUtils,
          btkEventBus;

        type
          TFooEventListener = class
          public
            [EventHandler] //handler declaration
            procedure FooHandler(EventObject: TbtkEventObject);
          end;

        { TFooEventListener }

        //handler implementation
        procedure TFooEventListener.FooHandler(EventObject: TbtkEventObject);
        begin
          Writeln(Format('Event with topic "%s" sended', [EventObject.Topic]));
        end;

        const
          FooTopicName = 'FooTopic';
        var
          FooEventListener: TFooEventListener;
          FooListenerInfo: TbtkListenerInfo;

        begin
          //register class for eventbus with empty name
          RegisterEventBusClass(TbtkEventBus);

          FooEventListener := TFooEventListener.Create;
          try
            //register listener and get listner info
            FooListenerInfo := EventBus.Register(FooEventListener);

            //set topicfilter for handler
            FooListenerInfo.HandlerFilters.Items[TbtkEventObject].Filters[TbtkEventObject.sEventFilterTopicName].Value := FooTopicName;

            //create and send event
            EventBus.Send(TbtkEventObject.Create(FooTopicName));
          finally
            FooEventListener.Free;
          end;
          Readln;
        end.
```
