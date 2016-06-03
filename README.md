DelphiEventBus
==============

Implementation of event bus pattern for Delphi XE

EventBus предназначен для обеспечения взаимодействия между различными компонентами, без повышения связанности.

###Особенности

 - **События**
   - Тип события определяется классом.
   - События наследуются.
   - Базовым классом для любого события является TbtkEventObject.
 - **Фильтрация**
   - События могут содержать фильтры.
   - Значения фильтров регистрочувствительны.
   - Для объявления фильтров используются аннотации методов класса события.
   - В качестве фильтра используются функции без параметров, которые должны возвращать значение фильтра ввиде строки.
   - Фильтры идентифицируются по имени.
   - Имя фильтра указывается в аннотации фильтра.
   - Имена фильтров не регистрочувствительны.
   - В фильтрах используется два режима:
     - Простой режим.
       - Значению фильтра события соответствуют пустые и точно совпадающие значения фильтра обработчика.
       - Этот режим используется поумолчанию.
     - Хэшируемый режим.
       - Значению фильтра события соответствуют только точно совпадающие значения фильтра обработчика.
       - Хэширование ускоряет формирование списков обработчиков, которые будут вызваны.
   - Режим фильтра указывается в аннотации фильтра.
   - Базовый класс содержит один хэшируемый фильтр с именем "Topic"
 - **Обработчики**
   - Добавление обработчиков событий производится путём регистрации слушателя в шине.
   - Удаление обработчиков событий производится путём дерегистрации слушателя в шине.
   - Значения фильтров обработчиков событий слушателя устанавливаются после регистрации.
   - Значения фильтров привязываются к типу события, и равны для разных обработчиков одного события.
   - Для объявления обработчиков используются аннотации методов слушателя.
   - Обработчики должны содержать один входной параметр с типом класса обрабатываемого события.
   - По типу параметра обработчика определяются события которые он будет обрабатывать.
   - Обработчик вызывается и для всех наследников обрабатываемого им события.
   - Используется два типа обработчиков событий:
     - Простые обработчики.
       - При вызове учитывается соответствие условий фильтрации. 
       - Порядок вызова не гарантируется.
     - Хуки.
       - Вызываются перед вызовом простых обработчиков.
       - Игнорируют условия фильтрации.
       - Порядок вызова соответствует обратному порядку регистрации.
   - Тип обработчика определятся аннотацией.

###Example of use
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
###Minimalistic example of use eventhook
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
###Minimalistic example of use eventhandler
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
