package tests.com.probertson.data
{
	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;
	
	import events.CloseResultEvent;
	
	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	
	import flexunit.framework.Assert;
	
	import org.flexunit.async.Async;
	import org.hamcrest.mxml.collection.InArray;
	
	import utils.CreateDatabase;
	
	public class SQLRunnerCloseTest extends EventDispatcher
	{		
		// Reference declaration for class to test
		private var _sqlRunner:SQLRunner;
		
		
		// ------- Instance vars -------
		
		private var _dbFile:File;
		private var _numExecutions:int = 0;
		private var _numExecutionsHalfway:int = 0;
		private var _executionCompleteCount:int = 0;
		
		
		// ------- Setup/cleanup -------
		
		[Before]
		public function setUp():void
		{
			_dbFile = File.createTempDirectory().resolvePath("test.db");
			var createDB:CreateDatabase = new CreateDatabase(_dbFile);
			createDB.createDatabase();
			_numExecutions = 0;
			_numExecutionsHalfway = 0;
			_executionCompleteCount = 0;
		}
		
		[After]
		public function tearDown():void
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
		
		// ----- Test basic closing -----
		
		[Test(async, timeout="500")]
		public function testClose():void
		{
			addEventListener(CloseResultEvent.CLOSE, Async.asyncHandler(this, testClose_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			_sqlRunner.close(testClose_result);
		}
	
		// --- handlers ---
		
		private function testClose_result():void
		{
			dispatchEvent(new CloseResultEvent(CloseResultEvent.CLOSE));
		}
		
		private function testClose_result2(event:CloseResultEvent, passThroughData:Object):void
		{
			Assert.assertTrue(true);
		}
		
		
		// ----- Test that statements execute before closing -----
		
		[Test(async, timeout="500")]
		public function testCloseAfterExecute():void
		{
			addEventListener(CloseResultEvent.CLOSE, Async.asyncHandler(this, testCloseAfterExecute_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseAfterExecute_execute_result);
			_numExecutions++;
			_sqlRunner.close(testCloseAfterExecute_result);
		}
		
		// --- handlers ---
		
		private function testCloseAfterExecute_execute_result(result:SQLResult):void
		{
			_executionCompleteCount++;
		}
		
		private function testCloseAfterExecute_result():void
		{
			dispatchEvent(new CloseResultEvent(CloseResultEvent.CLOSE));
		}
		
		private function testCloseAfterExecute_result2(event:CloseResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(_numExecutions, _executionCompleteCount);
		}
		
		
		[Test(async, timeout="500")]
		public function testCloseAfterMultipleExecute():void
		{
			addEventListener(CloseResultEvent.CLOSE, Async.asyncHandler(this, testCloseAfterMultipleExecute_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseAfterMultipleExecute_execute_result);
			_numExecutions++;
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseAfterMultipleExecute_execute_result);
			_numExecutions++;
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseAfterMultipleExecute_execute_result);
			_numExecutions++;
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseAfterMultipleExecute_execute_result);
			_numExecutions++;
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseAfterMultipleExecute_execute_result);
			_numExecutions++;
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseAfterMultipleExecute_execute_result);
			_numExecutions++;
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseAfterMultipleExecute_execute_result);
			_numExecutions++;
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseAfterMultipleExecute_execute_result);
			_numExecutions++;
			_sqlRunner.close(testCloseAfterMultipleExecute_result);
		}
		
		// --- handlers ---
		
		private function testCloseAfterMultipleExecute_execute_result(result:SQLResult):void
		{
			_executionCompleteCount++;
		}
		
		private function testCloseAfterMultipleExecute_result():void
		{
			dispatchEvent(new CloseResultEvent(CloseResultEvent.CLOSE));
		}
		
		private function testCloseAfterMultipleExecute_result2(event:CloseResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(_numExecutions, _executionCompleteCount);
		}
		
		
		// ----- Test that executeModify() statements execute before closing -----
		
		[Test(async, timeout="500")]
		public function testCloseAfterExecuteModify():void
		{
			addEventListener(CloseResultEvent.CLOSE, Async.asyncHandler(this, testCloseAfterExecuteModify_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"World", colInt:17});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1, stmt2]), testCloseAfterExecuteModify_executeModify_result, testCloseAfterExecuteModify_executeModify_error);
			_numExecutions++;
			
			var stmt3:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hola", colInt:15});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt3]), testCloseAfterExecuteModify_executeModify_result, testCloseAfterExecuteModify_executeModify_error);
			_numExecutions++;
			
			var stmt4:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Mundo", colInt:99});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt4]), testCloseAfterExecuteModify_executeModify_result, testCloseAfterExecuteModify_executeModify_error);
			_numExecutions++;
			
			_sqlRunner.close(testCloseAfterExecuteModify_result);
		}
		
		// --- handlers ---
		
		private function testCloseAfterExecuteModify_executeModify_result(results:Vector.<SQLResult>):void
		{
			_executionCompleteCount++;
		}
		
		private function testCloseAfterExecuteModify_executeModify_error(error:SQLError):void
		{
			Assert.fail(error.message);
		}
		
		private function testCloseAfterExecuteModify_result():void
		{
			dispatchEvent(new CloseResultEvent(CloseResultEvent.CLOSE));
		}
		
		private function testCloseAfterExecuteModify_result2(event:CloseResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(_numExecutions, _executionCompleteCount);
		}
		
		
		[Test(async, timeout="500")]
		public function testCloseAfterMixedExecute():void
		{
			addEventListener(CloseResultEvent.CLOSE, Async.asyncHandler(this, testCloseAfterMixedExecute_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"World", colInt:17});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1, stmt2]), testCloseAfterMixedExecute_executeModify_result, testCloseAfterMixedExecute_executeModify_error);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseAfterMixedExecute_execute_result);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseAfterMixedExecute_execute_result);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseAfterMixedExecute_execute_result);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseAfterMixedExecute_execute_result);
			_numExecutions++;
			
			var stmt3:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hola", colInt:15});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt3]), testCloseAfterMixedExecute_executeModify_result, testCloseAfterMixedExecute_executeModify_error);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseAfterMixedExecute_execute_result);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseAfterMixedExecute_execute_result);
			_numExecutions++;
			
			var stmt4:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Mundo", colInt:99});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt4]), testCloseAfterMixedExecute_executeModify_result, testCloseAfterMixedExecute_executeModify_error);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseAfterMixedExecute_execute_result);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseAfterMixedExecute_execute_result);
			_numExecutions++;
			
			_sqlRunner.close(testCloseAfterMixedExecute_result);
		}
		
		// --- handlers ---
		
		private function testCloseAfterMixedExecute_execute_result(result:SQLResult):void
		{
			_executionCompleteCount++;
		}
		
		private function testCloseAfterMixedExecute_executeModify_result(results:Vector.<SQLResult>):void
		{
			_executionCompleteCount++;
		}
		
		private function testCloseAfterMixedExecute_executeModify_error(error:SQLError):void
		{
			Assert.fail(error.message);
		}
		
		private function testCloseAfterMixedExecute_result():void
		{
			dispatchEvent(new CloseResultEvent(CloseResultEvent.CLOSE));
		}
		
		private function testCloseAfterMixedExecute_result2(event:CloseResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(_numExecutions, _executionCompleteCount);
		}
		
		
		// ----- Test executing, closing, then re-opening and closing again -----
		
		[Test(async, timeout="5000")]
		public function testCloseOpenClose():void
		{
			addEventListener(CloseResultEvent.CLOSE, Async.asyncHandler(this, testCloseOpenClose_result2, 5000));
			
			_sqlRunner = new SQLRunner(_dbFile);
			
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"World", colInt:17});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1, stmt2]), testCloseOpenClose_stmt1_result, testCloseOpenClose_executeModify_error);
			_numExecutions++;
			_numExecutionsHalfway++;
		}
		
		private function testCloseOpenClose_stmt1_result(results:Vector.<SQLResult>):void
		{
			_executionCompleteCount++;
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseOpenClose_execute1_result);
			_numExecutions++;
			_numExecutionsHalfway++;
		}
		
		private function testCloseOpenClose_execute1_result(result:SQLResult):void
		{
			_executionCompleteCount++;
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseOpenClose_execute2_result);
			_numExecutions++;
			_numExecutionsHalfway++;
		}
		
		private function testCloseOpenClose_execute2_result(result:SQLResult):void
		{
			_executionCompleteCount++;
			var stmt3:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hola", colInt:15});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt3]), testCloseOpenClose_stmt3_result, testCloseOpenClose_executeModify_error);
			_numExecutions++;
			_numExecutionsHalfway++;
		}
		
		private function testCloseOpenClose_stmt3_result(results:Vector.<SQLResult>):void
		{
			_executionCompleteCount++;
			_sqlRunner.close(testCloseOpenClose_close1_result);
		}
		
		private function testCloseOpenClose_close1_result():void
		{
			Assert.assertEquals(_numExecutionsHalfway, _executionCompleteCount);
			_sqlRunner = new SQLRunner(_dbFile);
			
			_execution3Complete = 0;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseOpenClose_execute3_result);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseOpenClose_execute3_result);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_SQL, null, testCloseOpenClose_execute3_result);
			_numExecutions++;
			
			_sqlRunner.execute(LOAD_ROWS_LIMIT_OFFSET_SQL, null, testCloseOpenClose_execute3_result);
			_numExecutions++;
			
			_stmt4Complete = false;
			var stmt4:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Mundo", colInt:99});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt4]), testCloseOpenClose_stmt4_result, testCloseOpenClose_executeModify_error);
			_numExecutions++;
		}
		
		private var _execution3Complete:int = 0;
		
		private function testCloseOpenClose_execute3_result(result:SQLResult):void
		{
			_executionCompleteCount++;
			_execution3Complete++;
			
			if (_execution3Complete == 4)
				_checkReadyToClose();
		}
		
		
		private var _stmt4Complete:Boolean = false;
		
		private function testCloseOpenClose_stmt4_result(results:Vector.<SQLResult>):void
		{
			_executionCompleteCount++;
			_stmt4Complete = true;
			_checkReadyToClose();
		}
		
		private function _checkReadyToClose():void
		{
			if (_execution3Complete == 4 && _stmt4Complete)
				_sqlRunner.close(testCloseOpenClose_result);
		}
		
		// --- handlers ---
		
		private function testCloseOpenClose_executeModify_error(error:SQLError):void
		{
			Assert.fail(error.message);
		}
		
		private function testCloseOpenClose_result():void
		{
			dispatchEvent(new CloseResultEvent(CloseResultEvent.CLOSE));
		}
		
		private function testCloseOpenClose_result2(event:CloseResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(_numExecutions, _executionCompleteCount);
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