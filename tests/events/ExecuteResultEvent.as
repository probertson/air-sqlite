package events
{
	import flash.data.SQLResult;
	import flash.events.Event;
	
	public class ExecuteResultEvent extends Event
	{
		// ------- Event type constants -------
		
		public static const RESULT:String = "executeResult";
		
		
		// ------- Constructor -------
		
		public function ExecuteResultEvent(type:String, result:SQLResult, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.result = result;
		}
		
		
		// ------- Public properties -------
		
		public var result:SQLResult;
		
		
		// ------- Event overrides -------
		
		public override function clone():Event
		{
			return new ExecuteResultEvent(type, result, bubbles, cancelable);
		}
		
		
		public override function toString():String
		{
			return formatToString("ExecuteResultEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
	}
}