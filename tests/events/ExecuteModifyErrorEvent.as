package events
{
	import flash.errors.SQLError;
	import flash.events.Event;
	
	public class ExecuteModifyErrorEvent extends Event
	{
		// ------- Event type constants -------
		
		public static const ERROR:String = "executeModifyError";
		
		
		// ------- Constructor -------
		
		public function ExecuteModifyErrorEvent(type:String, error:SQLError, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.error = error;
		}
		
		
		// ------- Public properties -------
		
		public var error:SQLError;
		
		
		// ------- Event overrides -------
		
		public override function clone():Event
		{
			return new ExecuteModifyErrorEvent(type, error, bubbles, cancelable);
		}
		
		
		public override function toString():String
		{
			return formatToString("ExecuteModifyErrorEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
	}
}