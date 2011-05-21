package tests.com.probertson.data
{
	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;
	
	import events.ExecuteModifyErrorEvent;
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
	
	public class SQLRunnerExecuteModifyErrors extends EventDispatcher
	{		
		// Reference declaration for class to test
		private var _sqlRunner:SQLRunner;
		
		
		// ------- Instance vars -------
		
		private var _dbFile:File;
		private var _errorCount:int = 0;
		private var _expectedErrors:int = 0;
		private var _delayBeforeAssert:Timer;
		
		
		// ------- Setup/cleanup -------
		
		[Before]
		public function setUp():void
		{
			_dbFile = File.createTempDirectory().resolvePath("test.db");
			var createDB:CreateDatabase = new CreateDatabase(_dbFile);
			createDB.createDatabase();
			
			_errorCount = 0;
			_expectedErrors = 0;
			_delayBeforeAssert = new Timer(2000);
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
		
		// ----- One statment in a batch -----
		
		[Ignore("This test doesn't really work, since it will automatically succeed when the first error hits so it doesn't really test if multiple errors are thrown.")]
		[Test(async, timeout="500")]
		public function testOneStatementErrorThrowing():void
		{
			addEventListener(ExecuteModifyErrorEvent.ERROR, Async.asyncHandler(this, testOneStatementErrorThrowing_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt:QueuedStatement = new QueuedStatement(INSERT_ERROR_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt]), testOneStatementErrorThrowing_result, testOneStatementErrorThrowing_error);
		}
		
		// --- handlers ---
		
		private function testOneStatementErrorThrowing_error(error:SQLError):void
		{
			dispatchEvent(new ExecuteModifyErrorEvent(ExecuteModifyErrorEvent.ERROR, error));
		}
		
		private function testOneStatementErrorThrowing_result(results:Vector.<SQLResult>):void
		{
			Assert.fail("Expected an error but none occurred");
		}
		
		private function testOneStatementErrorThrowing_result2(event:ExecuteModifyErrorEvent, passThroughData:Object):void
		{
			Assert.assertTrue(true);
		}
		
		
		// ----- Multiple statements in a batch -----
		
		[Ignore("This test doesn't really work, since it will automatically succeed when the first error hits so it doesn't really test if multiple errors are thrown.")]
		[Test(async, timeout="500")]
		public function testMultipleStatementsErrorThrowing():void
		{
			addEventListener(ExecuteModifyErrorEvent.ERROR, Async.asyncHandler(this, testMultipleStatementsErrorThrowing_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt:QueuedStatement = new QueuedStatement(INSERT_ERROR_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(INSERT_ERROR_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt, stmt2]), testMultipleStatementsErrorThrowing_result, testMultipleStatementsErrorThrowing_error);
			_expectedErrors = 1;
		}
		
		// --- handlers ---
		
		private function testMultipleStatementsErrorThrowing_error(error:SQLError):void
		{
			_errorCount++;
			
			if (_errorCount == _expectedErrors)
				dispatchEvent(new ExecuteModifyErrorEvent(ExecuteModifyErrorEvent.ERROR, error));
		}
		
		private function testMultipleStatementsErrorThrowing_result(results:Vector.<SQLResult>):void
		{
			Assert.fail("Expected an error but none occurred");
		}
		
		private function testMultipleStatementsErrorThrowing_result2(event:ExecuteModifyErrorEvent, passThroughData:Object):void
		{
			Assert.assertTrue(true);
		}
		
		
		// ----- Multiple statements in a batch, followed by a SELECT -----
		
		[Test(async, timeout="5000")]
		public function testMultipleStatementsPlusSelectErrorHandling():void
		{
			addEventListener(Event.COMPLETE, Async.asyncHandler(this, testMultipleStatementsPlusSelectErrorHandling_result2, 5000));
			
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt:QueuedStatement = new QueuedStatement(INSERT_ERROR_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(INSERT_ERROR_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt, stmt2]), testMultipleStatementsPlusSelectErrorHandling_executeModifyResult, testMultipleStatementsPlusSelectErrorHandling_error);
			_expectedErrors = 1;
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testMultipleStatementsPlusSelectErrorHandling_executeResult);
			
			_delayBeforeAssert.delay = 2000;
			_delayBeforeAssert.addEventListener(TimerEvent.TIMER, testMultipleStatementsPlusSelectErrorHandling_timer);
			_delayBeforeAssert.start();
		}
		
		
		// --- handlers ---
		
		private function testMultipleStatementsPlusSelectErrorHandling_error(error:SQLError):void
		{
			_errorCount++;
		}
		
		private function testMultipleStatementsPlusSelectErrorHandling_executeModifyResult(results:Vector.<SQLResult>):void
		{
			Assert.fail("Expected an error but none occurred");
		}
		
		private var _executeComplete:Boolean = false;
		
		private function testMultipleStatementsPlusSelectErrorHandling_executeResult(result:SQLResult):void
		{
			_executeComplete = true;
		}
		
		private function testMultipleStatementsPlusSelectErrorHandling_timer(event:TimerEvent):void
		{
			_delayBeforeAssert.removeEventListener(TimerEvent.TIMER, testMultipleStatementsPlusSelectErrorHandling_timer);
			_delayBeforeAssert.stop();
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function testMultipleStatementsPlusSelectErrorHandling_result2(event:Event, passThroughData:Object):void
		{
			Assert.assertEquals(_expectedErrors, _errorCount);
			Assert.assertTrue(_executeComplete);
		}
		
		
		// ------- SQL statements -------
		
		[Embed(source="/sql/InsertError.sql", mimeType="application/octet-stream")]
		private static const InsertErrorStatementText:Class;
		private static const INSERT_ERROR_SQL:String = new InsertErrorStatementText();
		
		[Embed(source="/sql/LoadRowsLimit.sql", mimeType="application/octet-stream")]
		private static const LoadRowsLimitStatementText:Class;
		private static const LOAD_ROWS_LIMIT_SQL:String = new LoadRowsLimitStatementText();
		
	}
}