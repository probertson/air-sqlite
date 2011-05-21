package tests.com.probertson.data
{
	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;
	
	import events.ExecuteModifyResultEvent;
	
	import flash.data.SQLResult;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	
	import flexunit.framework.Assert;
	
	import org.flexunit.async.Async;
	
	import utils.CreateDatabase;
	
	public class SQLRunnerExecuteModifyProgressHandlerTest extends EventDispatcher
	{
		// ------- Instance to test -------
		
		private var _sqlRunner:SQLRunner;
		
		
		// ------- Instance vars -------
		
		private var _dbFile:File;
		private var _callCount:int = 0;
		private var _numComplete:int = 0;
		
		
		// ------- Setup/Teardown -------
		
		[Before]
		public function setUp():void
		{
			_callCount = 0;
			_dbFile = File.createTempDirectory().resolvePath("test.db");
			var createDB:CreateDatabase = new CreateDatabase(_dbFile);
			createDB.createDatabase();
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
		
		
		// ------- Test methods -------
		
		[Test(async, timeout="500")]
		public function test_withOneStatement_executeModify_callsProgressHandler_once():void
		{
			addEventListener(ExecuteModifyResultEvent.RESULT, Async.asyncHandler(this, test_withOneStatement_executeModify_callsProgressHandler_once_result2, 500));
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt]),
				test_withOneStatement_executeModify_callsProgressHandler_once_result,
				null,
				test_withOneStatement_executeModify_callsProgressHandler_once_progress);
		}
		
		private function test_withOneStatement_executeModify_callsProgressHandler_once_progress(numComplete:int, total:int):void
		{
			_callCount++;
		}
		
		private function test_withOneStatement_executeModify_callsProgressHandler_once_result(results:Vector.<SQLResult>):void
		{
			dispatchEvent(new ExecuteModifyResultEvent(ExecuteModifyResultEvent.RESULT, results));
		}
		
		private function test_withOneStatement_executeModify_callsProgressHandler_once_result2(event:ExecuteModifyResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(1, _callCount);
		}
		
		
		[Test(async, timeout="500")]
		public function test_withTwoStatements_executeModify_callsProgressHandler_fourTimes():void
		{
			addEventListener(ExecuteModifyResultEvent.RESULT, Async.asyncHandler(this, test_withTwoStatements_executeModify_callsProgressHandler_fourTimes_result2, 500));
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1, stmt2]),
				test_withTwoStatements_executeModify_callsProgressHandler_fourTimes_result,
				null,
				test_withTwoStatements_executeModify_callsProgressHandler_fourTimes_progress);
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandler_fourTimes_progress(numComplete:int, total:int):void
		{
			_callCount++;
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandler_fourTimes_result(results:Vector.<SQLResult>):void
		{
			dispatchEvent(new ExecuteModifyResultEvent(ExecuteModifyResultEvent.RESULT, results));
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandler_fourTimes_result2(event:ExecuteModifyResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(4, _callCount);
		}
		
		
		[Test(async, timeout="500")]
		public function test_withOneStatement_executeModify_callsProgressHandler_withCompleteArgumentEqualToOne():void
		{
			addEventListener(ExecuteModifyResultEvent.RESULT, Async.asyncHandler(this, test_withOneStatement_executeModify_callsProgressHandler_withCompleteArgumentEqualToOne_result2, 500));
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1]),
				test_withOneStatement_executeModify_callsProgressHandler_withCompleteArgumentEqualToOne_result,
				null,
				test_withOneStatement_executeModify_callsProgressHandler_withCompleteArgumentEqualToOne_progress);
		}
		
		private function test_withOneStatement_executeModify_callsProgressHandler_withCompleteArgumentEqualToOne_progress(numComplete:int, total:int):void
		{
			if (_callCount == 0)
			{
				_numComplete = numComplete;
			}
			_callCount++;
		}
		
		private function test_withOneStatement_executeModify_callsProgressHandler_withCompleteArgumentEqualToOne_result(results:Vector.<SQLResult>):void
		{
			dispatchEvent(new ExecuteModifyResultEvent(ExecuteModifyResultEvent.RESULT, results));
		}
		
		private function test_withOneStatement_executeModify_callsProgressHandler_withCompleteArgumentEqualToOne_result2(event:ExecuteModifyResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(1, _numComplete);
		}
		
		
		[Test(async, timeout="500")]
		public function test_withTwoStatements_executeModify_callsProgressHandlerTheFirstTime_withCompleteArgumentEqualToOne():void
		{
			addEventListener(ExecuteModifyResultEvent.RESULT, Async.asyncHandler(this, test_withTwoStatements_executeModify_callsProgressHandlerTheFirstTime_withCompleteArgumentEqualToOne_result2, 500));
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1, stmt2]),
				test_withTwoStatements_executeModify_callsProgressHandlerTheFirstTime_withCompleteArgumentEqualToOne_result,
				null,
				test_withTwoStatements_executeModify_callsProgressHandlerTheFirstTime_withCompleteArgumentEqualToOne_progress);
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandlerTheFirstTime_withCompleteArgumentEqualToOne_progress(numComplete:int, total:int):void
		{
			_callCount++;
			if (_callCount == 1)
			{
				_numComplete = numComplete;
			}
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandlerTheFirstTime_withCompleteArgumentEqualToOne_result(results:Vector.<SQLResult>):void
		{
			dispatchEvent(new ExecuteModifyResultEvent(ExecuteModifyResultEvent.RESULT, results));
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandlerTheFirstTime_withCompleteArgumentEqualToOne_result2(event:ExecuteModifyResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(1, _numComplete);
		}
		
		
		[Test(async, timeout="500")]
		public function test_withTwoStatements_executeModify_callsProgressHandlerTheSecondTime_withCompleteArgumentEqualToTwo():void
		{
			addEventListener(ExecuteModifyResultEvent.RESULT, Async.asyncHandler(this, test_withTwoStatements_executeModify_callsProgressHandlerTheSecondTime_withCompleteArgumentEqualToTwo_result2, 500));
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1, stmt2]),
				test_withTwoStatements_executeModify_callsProgressHandlerTheSecondTime_withCompleteArgumentEqualToTwo_result,
				null,
				test_withTwoStatements_executeModify_callsProgressHandlerTheSecondTime_withCompleteArgumentEqualToTwo_progress);
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandlerTheSecondTime_withCompleteArgumentEqualToTwo_progress(numComplete:int, total:int):void
		{
			_callCount++;
			if (_callCount == 2)
			{
				_numComplete = numComplete;
			}
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandlerTheSecondTime_withCompleteArgumentEqualToTwo_result(results:Vector.<SQLResult>):void
		{
			dispatchEvent(new ExecuteModifyResultEvent(ExecuteModifyResultEvent.RESULT, results));
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandlerTheSecondTime_withCompleteArgumentEqualToTwo_result2(event:ExecuteModifyResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(2, _numComplete);
		}
		
		
		[Test(async, timeout="500")]
		public function test_withTwoStatements_executeModify_callsProgressHandlerTheThirdTime_withCompleteArgumentEqualToThree():void
		{
			addEventListener(ExecuteModifyResultEvent.RESULT, Async.asyncHandler(this, test_withTwoStatements_executeModify_callsProgressHandlerTheThirdTime_withCompleteArgumentEqualToThree_result2, 500));
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1, stmt2]),
				test_withTwoStatements_executeModify_callsProgressHandlerTheThirdTime_withCompleteArgumentEqualToThree_result,
				null,
				test_withTwoStatements_executeModify_callsProgressHandlerTheThirdTime_withCompleteArgumentEqualToThree_progress);
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandlerTheThirdTime_withCompleteArgumentEqualToThree_progress(numComplete:int, total:int):void
		{
			_callCount++;
			if (_callCount == 3)
			{
				_numComplete = numComplete;
			}
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandlerTheThirdTime_withCompleteArgumentEqualToThree_result(results:Vector.<SQLResult>):void
		{
			dispatchEvent(new ExecuteModifyResultEvent(ExecuteModifyResultEvent.RESULT, results));
		}
		
		private function test_withTwoStatements_executeModify_callsProgressHandlerTheThirdTime_withCompleteArgumentEqualToThree_result2(event:ExecuteModifyResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(3, _numComplete);
		}
		
		
		// ------- SQL statements -------
		
		[Embed(source="/sql/AddRow.sql", mimeType="application/octet-stream")]
		private static const AddRowStatementText:Class;
		private static const ADD_ROW_SQL:String = new AddRowStatementText();
	}
}