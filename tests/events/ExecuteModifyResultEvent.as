package events
{
	import flash.data.SQLResult;
	import flash.events.Event;
	
	public class ExecuteModifyResultEvent extends Event
	{
		// ------- Event type constants -------
		
		public static const RESULT:String = "executeModifyResult";
		
		
		// ------- Constructor -------
		
		public function ExecuteModifyResultEvent(type:String, results:Vector.<SQLResult>, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.results = results;
		}
		
		
		// ------- Public properties -------
		
		public var results:Vector.<SQLResult>;
		
		
		// ------- Event overrides -------
		
		public override function clone():Event
		{
			return new ExecuteModifyResultEvent(type, results, bubbles, cancelable);
		}
		
		
		public override function toString():String
		{
			return formatToString("ExecuteModifyResultEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
	}
}