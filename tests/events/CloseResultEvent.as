package events
{
	import flash.events.Event;
	
	public class CloseResultEvent extends Event
	{
		// ------- Event type constants -------
		
		public static const CLOSE:String = "close";
		
		
		// ------- Constructor -------
		
		public function CloseResultEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		
		// ------- Event overrides -------
		
		override public function clone():Event
		{
			return new CloseResultEvent(type, bubbles, cancelable);
		}
		
		
		override public function toString():String
		{
			return formatToString("CloseResultEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
	}
}