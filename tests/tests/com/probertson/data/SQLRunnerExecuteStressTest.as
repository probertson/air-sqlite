package tests.com.probertson.data
{
	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;
	
	import events.ExecuteModifyResultEvent;
	
	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import flexunit.framework.Assert;
	
	import org.flexunit.async.Async;
	
	import utils.CreateDatabase;
	
	public class SQLRunnerExecuteStressTest extends EventDispatcher
	{		
		// Reference declaration for class to test
		private var _sqlRunner:SQLRunner;
		
		
		// ------- Instance vars -------
		
		private var _dbFile:File;
		private var _totalExecutions:int = 0;
		private var _totalComplete:int = 0;
		
		
		// ------- Setup/cleanup -------
		
		[Before]
		public function setUp():void
		{
			_dbFile = File.createTempDirectory().resolvePath("test.db");
			var createDB:CreateDatabase = new CreateDatabase(_dbFile);
			createDB.createDatabase();
			
			_totalExecutions = 0;
			_totalComplete = 0;
		}
		
		
		[After(async, timeout="250")]
		public function tearDown():void
		{
			_sqlRunner.close(sqlRunner_close);
		}
		
		private function sqlRunner_close():void
		{
			_sqlRunner = null;
			var tempDir:File = _dbFile.parent;
			tempDir.deleteDirectory(true);
		}
		
		
		[BeforeClass]
		public static function setUpBeforeClass():void
		{
		}
		
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}
		
		
		// ------- Tests -------
		
		[Test(async, timeout="800000")]
		public function testLongRunning():void
		{
			addEventListener(Event.COMPLETE, Async.asyncHandler(this, testLongRunning_result2, 800000));
			
			_sqlRunner = new SQLRunner(_dbFile);
			
			_numTimersComplete = 0;
			_latestRowId = -1;
			
			var addTimer:Timer = new Timer(600, 500);
			addTimer.addEventListener(TimerEvent.TIMER, _addTimer_timer);
			addTimer.addEventListener(TimerEvent.TIMER_COMPLETE, _timer_timerComplete);
			addTimer.start();
			
			var updateTimer:Timer = new Timer(10, 30000);
			updateTimer.addEventListener(TimerEvent.TIMER, _updateTimer_timer);
			updateTimer.addEventListener(TimerEvent.TIMER_COMPLETE, _timer_timerComplete);
			updateTimer.start();
			
			var selectTimer:Timer = new Timer(10000, 20);
			selectTimer.addEventListener(TimerEvent.TIMER, _selectTimer_timer);
			selectTimer.addEventListener(TimerEvent.TIMER_COMPLETE, _timer_timerComplete);
			selectTimer.start();
			
			_progressTimer = new Timer(1000);
			_progressTimer.addEventListener(TimerEvent.TIMER, _progressTimer_timer);
			_progressTimer.start();
		}
		
		private var _progressTimer:Timer;
		
		// --- handlers ---
		
		private var _latestRowId:int = -1;
		private var _totalAdd:int = 0;
		private var _totalUpdate:int = 0;
		private var _totalSelect:int = 0;
		
		private function _addTimer_timer(event:TimerEvent):void
		{
			var stmt:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:getRandomString(), colInt:getRandomInt()});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt]), testLongRunning_result, testLongRunning_error);
			_totalExecutions++;
			_totalAdd++;
		}
		
		private function _updateTimer_timer(event:TimerEvent):void
		{
			var timer:Timer = event.target as Timer;
			if (_latestRowId > -1)
			{
				var stmt:QueuedStatement = new QueuedStatement(UPDATE_ROW_SQL, {colIntPK:_latestRowId, colString:getRandomString(), colInt:getRandomInt()});
				_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt]), testLongRunning_result, testLongRunning_error);
				_totalExecutions++;
				_totalUpdate++;
//				stmt = new QueuedStatement(UPDATE_ROW_SQL, {colIntPK:_latestRowId, colString:getRandomString(), colInt:getRandomInt()});
//				_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt]), testLongRunning_result, testLongRunning_error);
//				_totalExecutions++;
//				_totalUpdate++;
			}
		}
		
		private function _selectTimer_timer(event:TimerEvent):void
		{
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testLongRunning_result);
			_totalExecutions++;
			_totalSelect++;
		}
		
		private var _lastComplete:int = 0;
		private function _progressTimer_timer(event:TimerEvent):void
		{
			var time:Number = Math.round(getTimer() / 100) / 10;
			trace(time, "s,", _totalAdd, "add;", _totalUpdate, "update;", _totalSelect, "select;", _totalComplete, "/", _totalExecutions, (_totalComplete - _lastComplete), "since last");
			_lastComplete = _totalComplete;
		}
		
		private var _numTimersComplete:int = 0;
		
		private function _timer_timerComplete(event:TimerEvent):void
		{
			_numTimersComplete++;
			
			var timer:Timer = event.target as Timer;
			timer.removeEventListener(TimerEvent.TIMER, _addTimer_timer);
			timer.removeEventListener(TimerEvent.TIMER, _updateTimer_timer);
			timer.removeEventListener(TimerEvent.TIMER, _selectTimer_timer);
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, _timer_timerComplete);
		}
		
		private function testLongRunning_result(results:Object):void
		{
			_totalComplete++;
			if (results is Vector.<SQLResult>)
				_latestRowId = (results as Vector.<SQLResult>)[0].lastInsertRowID;
			
			if (_numTimersComplete == 3)
			{
				_progressTimer.stop();
				_progressTimer.removeEventListener(TimerEvent.TIMER, _progressTimer_timer);
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		private function testLongRunning_result2(event:Event, passThroughData:Object):void
		{
			Assert.assertEquals(_totalExecutions, _totalComplete);
		}
		
		private function testLongRunning_error(error:SQLError):void
		{
			Assert.fail(error.message);
		}
		
		
		// ------- Utility -------
		
		private static const ALPHABET:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		
		private function getRandomString():String
		{
			var len:int = Math.round(Math.random() * 8) + 5;
			
			var result:String = "";
			
			for (var i:int = 0; i < len; i++)
			{
				result += ALPHABET.charAt(Math.round(Math.random() * 25));
			}
			
			return result;
		}
		
		
		private function getRandomInt():int
		{
			return Math.round(Math.random() * 100);
		}
		
		
		// ------- SQL statements -------
		
		[Embed(source="sql/AddRow.sql", mimeType="application/octet-stream")]
		private static const AddRowStatementText:Class;
		private static const ADD_ROW_SQL:String = new AddRowStatementText();
		
		[Embed(source="sql/UpdateRow.sql", mimeType="application/octet-stream")]
		private static const UpdateRowStatementText:Class;
		private static const UPDATE_ROW_SQL:String = new UpdateRowStatementText();
		
		[Embed(source="sql/LoadRowsLimit.sql", mimeType="application/octet-stream")]
		private static const LoadRowsLimitStatementText:Class;
		private static const LOAD_ROWS_LIMIT_SQL:String = new LoadRowsLimitStatementText();
	}
}