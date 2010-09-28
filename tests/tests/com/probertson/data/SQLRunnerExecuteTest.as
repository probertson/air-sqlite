package tests.com.probertson.data
{
	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;
	
	import events.ExecuteResultEvent;
	
	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.Timer;
	
	import flexunit.framework.Assert;
	
	import org.flexunit.async.Async;
	
	import utils.CreateDatabase;
	
	public class SQLRunnerExecuteTest extends EventDispatcher
	{		
		// Reference declaration for class to test
		private var _sqlRunner:SQLRunner;
		
		
		// ------- Instance vars -------
		
		private var _dbFile:File;
		private var _testCompleteTimer:Timer;
		
		
		// ------- Setup/cleanup -------
		
		[Before]
		public function setUp():void
		{
			_dbFile = File.createTempDirectory().resolvePath("test.db");
			var createDB:CreateDatabase = new CreateDatabase(_dbFile);
			createDB.createPopulatedDatabase();
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
		
		
		// ------- Tests -------
		
		// ----- Multiple simultaneous SQL statements -----
		
		[Test(async, timeout="500")]
		public function testConnectionCreation():void
		{
			addEventListener(ExecuteResultEvent.RESULT, Async.asyncHandler(this, testConnectionCreation_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile, 5);
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testConnectionCreation_result);
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testConnectionCreation_result);
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testConnectionCreation_result);
			_pendingCount = 3;
		}
		
		// --- handlers ---
		
		private var _pendingCount:int = 0;
		
		private function testConnectionCreation_result(result:SQLResult):void
		{
			dispatchEvent(new ExecuteResultEvent(ExecuteResultEvent.RESULT, result));
		}
		
		private function testConnectionCreation_result2(event:ExecuteResultEvent, passThroughData:Object):void
		{
			Assert.assertTrue(_sqlRunner.numConnections == _pendingCount);
		}
		
		
		
		[Test(async, timeout="500")]
		public function testConnectionCreationLimit():void
		{
			addEventListener(ExecuteResultEvent.RESULT, Async.asyncHandler(this, testConnectionCreationLimit_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile, 2);
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testConnectionCreationLimit_result);
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testConnectionCreationLimit_result);
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testConnectionCreationLimit_result);
		}
		
		// --- handlers ---
		
		private function testConnectionCreationLimit_result(result:SQLResult):void
		{
			dispatchEvent(new ExecuteResultEvent(ExecuteResultEvent.RESULT, result));
		}
		
		private function testConnectionCreationLimit_result2(event:ExecuteResultEvent, passThroughData:Object):void
		{
			Assert.assertTrue(_sqlRunner.numConnections == 2);
		}
		
		
		// ----- SELECT added while INSERT/UPDATE/DELETE is running -----
		
		[Ignore("This test isn't working. It should probably be rewritten as a test of the ConnectionPool class")]
		[Test(async, timeout="3000")]
		public function testExecuteDuringExecuteModify():void
		{
			addEventListener(Event.COMPLETE, Async.asyncHandler(this, testExecuteDuringExecuteModify_complete, 3000));
			
			_sqlRunner = new SQLRunner(_dbFile);
			
			_testCompleteTimer = new Timer(2000);
			_testCompleteTimer.addEventListener(TimerEvent.TIMER, testExecuteDuringExecuteModify_timer);
			_testCompleteTimer.start();
			
			// pre-create the SQLConnections
			var stmt:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt]), testExecuteDuringExecuteModify_preCreate1Result, testExecuteDuringExecuteModify_preCreate1Error);
		}
		
		
		// --- handlers ---
		
		private function testExecuteDuringExecuteModify_preCreate1Result(results:Vector.<SQLResult>):void
		{
			// pre-create the execute() connection
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testExecuteDuringExecuteModify_preCreate2Result, null, testExecuteDuringExecuteModify_preCreate2Error);
		}
		
		private function testExecuteDuringExecuteModify_preCreate1Error(error:SQLError):void
		{
			Assert.fail("An error occurred while pre-creating the executeModify connection");
		}
		
		private function testExecuteDuringExecuteModify_preCreate2Result(result:SQLResult):void
		{
			// execute the modify statement that's actually part of the test
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"World", colInt:17});
			var stmt3:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt4:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"World", colInt:17});
			var stmt5:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt6:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"World", colInt:17});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1, stmt2, stmt3, stmt4, stmt5, stmt6]), testExecuteDuringExecuteModify_executeModifyResult, testExecuteDuringExecuteModify_executeModifyError, testExecuteDuringExecuteModify_executeModifyProgress);
		}
		
		private function testExecuteDuringExecuteModify_preCreate2Error(error:SQLError):void
		{
			Assert.fail("An error occurred while pre-creating the executeModify connection");
		}
		
		private var _executeModifyComplete:Boolean = false;
		private function testExecuteDuringExecuteModify_executeModifyResult(results:Vector.<SQLResult>):void
		{
			_executeModifyComplete = true;
		}
		
		private var _executeCalled:Boolean = false;
		private function testExecuteDuringExecuteModify_executeModifyProgress(complete:uint, total:uint):void
		{
			// call execute() here, so we know we're in the middle of the transaction
			if (!_executeCalled && complete > 2)
			{
				_executeCalled = true;
				_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testExecuteDuringExecuteModify_executeResult, null, testExecuteDuringExecuteModify_executeError);
			}
		}
		
		private function testExecuteDuringExecuteModify_executeModifyError(error:SQLError):void
		{
			Assert.fail("Error during executeModify() statement");
		}
		
		private var _executeComplete:Boolean = false;
		private function testExecuteDuringExecuteModify_executeResult(result:SQLResult):void
		{
			_executeComplete = true;
		}
		
		private function testExecuteDuringExecuteModify_executeError(error:SQLError):void
		{
			Assert.fail("Error during execute() call");
		}
		
		private function testExecuteDuringExecuteModify_timer(event:TimerEvent):void
		{
			_testCompleteTimer.removeEventListener(TimerEvent.TIMER, testExecuteDuringExecuteModify_timer);
			_testCompleteTimer.stop();
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function testExecuteDuringExecuteModify_complete(event:Event, passThroughData:Object):void
		{
			Assert.assertTrue(_executeModifyComplete && _executeComplete);
		}
		
		

		// ----- LIMIT statement -----
		
		[Test(async, timeout="500")]
		public function testLimit():void
		{
			addEventListener(ExecuteResultEvent.RESULT, Async.asyncHandler(this, testLimit_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testLimit_result);
		}
		
		// --- handlers ---
		
		private function testLimit_result(result:SQLResult):void
		{
			dispatchEvent(new ExecuteResultEvent(ExecuteResultEvent.RESULT, result));
		}
		
		private function testLimit_result2(event:ExecuteResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(3, event.result.data.length);
			Assert.assertEquals("a", event.result.data[0].colString);
			Assert.assertEquals(0, event.result.data[0].colInt);
			Assert.assertEquals("b", event.result.data[1].colString);
			Assert.assertEquals(1, event.result.data[1].colInt);
			Assert.assertEquals("c", event.result.data[2].colString);
			Assert.assertEquals(2, event.result.data[2].colInt);
		}
		
		
		// ----- LIMIT..OFFSET statement -----
		
		[Test(async, timeout="500")]
		public function testLimitOffset():void
		{
			addEventListener(ExecuteResultEvent.RESULT, Async.asyncHandler(this, testLimitOffset_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testLimitOffset_result);
		}
		
		// --- handlers ---
		
		private function testLimitOffset_result(result:SQLResult):void
		{
			dispatchEvent(new ExecuteResultEvent(ExecuteResultEvent.RESULT, result));
		}
		
		private function testLimitOffset_result2(event:ExecuteResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(4, event.result.data.length);
			Assert.assertEquals("d", event.result.data[0].colString);
			Assert.assertEquals(3, event.result.data[0].colInt);
			Assert.assertEquals("e", event.result.data[1].colString);
			Assert.assertEquals(4, event.result.data[1].colInt);
			Assert.assertEquals("f", event.result.data[2].colString);
			Assert.assertEquals(5, event.result.data[2].colInt);
			Assert.assertEquals("g", event.result.data[3].colString);
			Assert.assertEquals(6, event.result.data[3].colInt);
		}
		
		
		// ----- Parameterized LIMIT..OFFSET statement -----
		
		[Test(async, timeout="500")]
		public function testParameterizedLimitOffset():void
		{
			addEventListener(ExecuteResultEvent.RESULT, Async.asyncHandler(this, testParameterizedLimitOffset_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			_sqlRunner.execute(LOAD_ROWS_PARAMETERIZED_LIMIT_OFFSET_SQL, {limit:7, offset:2}, testParameterizedLimitOffset_result);
		}
		
		// --- handlers ---
		
		private function testParameterizedLimitOffset_result(result:SQLResult):void
		{
			dispatchEvent(new ExecuteResultEvent(ExecuteResultEvent.RESULT, result));
		}
		
		private function testParameterizedLimitOffset_result2(event:ExecuteResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(7, event.result.data.length);
			Assert.assertEquals("c", event.result.data[0].colString);
			Assert.assertEquals(2, event.result.data[0].colInt);
			Assert.assertEquals("d", event.result.data[1].colString);
			Assert.assertEquals(3, event.result.data[1].colInt);
			Assert.assertEquals("e", event.result.data[2].colString);
			Assert.assertEquals(4, event.result.data[2].colInt);
			Assert.assertEquals("f", event.result.data[3].colString);
			Assert.assertEquals(5, event.result.data[3].colInt);
			Assert.assertEquals("g", event.result.data[4].colString);
			Assert.assertEquals(6, event.result.data[4].colInt);
			Assert.assertEquals("h", event.result.data[5].colString);
			Assert.assertEquals(7, event.result.data[5].colInt);
			Assert.assertEquals("i", event.result.data[6].colString);
			Assert.assertEquals(8, event.result.data[6].colInt);
		}
		
		
		// ------- SQL statements -------
		
		[Embed(source="sql/LoadRowsLimit.sql", mimeType="application/octet-stream")]
		private static const LoadRowsLimitStatementText:Class;
		private static const LOAD_ROWS_LIMIT_SQL:String = new LoadRowsLimitStatementText();
		
		[Embed(source="sql/LoadRowsLimitOffset.sql", mimeType="application/octet-stream")]
		private static const LoadRowsLimitOffsetStatementText:Class;
		private static const LOAD_ROWS_LIMIT_OFFSET_SQL:String = new LoadRowsLimitOffsetStatementText();
		
		[Embed(source="sql/LoadRowsParameterizedLimitOffset.sql", mimeType="application/octet-stream")]
		private static const LoadRowsParameterizedLimitOffsetStatementText:Class;
		private static const LOAD_ROWS_PARAMETERIZED_LIMIT_OFFSET_SQL:String = new LoadRowsParameterizedLimitOffsetStatementText();
		
		[Embed(source="sql/AddRow.sql", mimeType="application/octet-stream")]
		private static const AddRowStatementText:Class;
		private static const ADD_ROW_SQL:String = new AddRowStatementText();
	}
}