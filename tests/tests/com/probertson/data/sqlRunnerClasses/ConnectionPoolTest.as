package tests.com.probertson.data.sqlRunnerClasses
{
	import com.probertson.data.sqlRunnerClasses.ConnectionPool;
	import com.probertson.data.sqlRunnerClasses.PendingBatch;
	import com.probertson.data.sqlRunnerClasses.PendingStatement;
	import com.probertson.data.sqlRunnerClasses.StatementCache;
	
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.Timer;
	
	import flexunit.framework.Assert;
	
	import org.flexunit.async.Async;
	
	import utils.CreateDatabase;
	
	public class ConnectionPoolTest extends EventDispatcher
	{		
		// Reference declaration for class to test
		private var _connectionPool:ConnectionPool;
		
		
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
			_connectionPool.close(_connectionPool_close, null);
		}
		
		
		private function _connectionPool_close():void
		{
			_connectionPool = null;
			var tempDir:File = _dbFile.parent;
			tempDir.deleteDirectory(true);
		}
				
		
		// ------- Tests -------
		
		[Test(async, timeout="3000")]
		public function testAddBlockingBatchThenPendingStatement():void
		{
			addEventListener(Event.COMPLETE, Async.asyncHandler(this, testAddBlockingBatchThenPendingStatement_complete, 3000));
			
			_connectionPool = new ConnectionPool(_dbFile);
			
			_testCompleteTimer = new Timer(2000);
			_testCompleteTimer.addEventListener(TimerEvent.TIMER, testAddBlockingBatchThenPendingStatement_timer);
			_testCompleteTimer.start();
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.text = ADD_ROW_SQL;
			var stmts:Vector.<SQLStatement> = Vector.<SQLStatement>([stmt, stmt, stmt]);
			var params:Vector.<Object> = Vector.<Object>([{colString:"Hello", colInt:7}, {colString:"World", colInt:17}, {colString:"Hello", colInt:7}]);
			var pendingBatch:PendingBatch = new PendingBatch(stmts, params, testAddBlockingBatchThenPendingStatement_batchResult, testAddBlockingBatchThenPendingStatement_batchError, null);
			_connectionPool.addBlockingBatch(pendingBatch);
			var pendingStatement:PendingStatement = new PendingStatement(new StatementCache(LOAD_ROWS_LIMIT_SQL), null, testAddBlockingBatchThenPendingStatement_executeResult, null, testAddBlockingBatchThenPendingStatement_executeError);
			_connectionPool.addPendingStatement(pendingStatement);
		}
		
		
		// handlers
		
		private var _executeModifyComplete:Boolean = false;
		private function testAddBlockingBatchThenPendingStatement_batchResult(results:Vector.<SQLResult>):void
		{
			_executeModifyComplete = true;
			Assert.assertFalse(_executeComplete);
		}
		
		
		private function testAddBlockingBatchThenPendingStatement_batchError(error:SQLError):void
		{
			Assert.fail("Error during batch statement");
		}
		
		private var _executeComplete:Boolean = false;
		private function testAddBlockingBatchThenPendingStatement_executeResult(result:SQLResult):void
		{
			_executeComplete = true;
			Assert.assertTrue(_executeModifyComplete);
		}
		
		private function testAddBlockingBatchThenPendingStatement_executeError(error:SQLError):void
		{
			Assert.fail("Error during pending statement call");
		}
		
		private function testAddBlockingBatchThenPendingStatement_timer(event:TimerEvent):void
		{
			_testCompleteTimer.removeEventListener(TimerEvent.TIMER, testAddBlockingBatchThenPendingStatement_timer);
			_testCompleteTimer.stop();
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function testAddBlockingBatchThenPendingStatement_complete(event:Event, passThroughData:Object):void
		{
			Assert.assertTrue(_executeModifyComplete && _executeComplete);
		}
		
		
		// ------- SQL statements -------
		
		[Embed(source="sql/LoadRowsLimit.sql", mimeType="application/octet-stream")]
		private static const LoadRowsLimitStatementText:Class;
		private static const LOAD_ROWS_LIMIT_SQL:String = new LoadRowsLimitStatementText();
		
		[Embed(source="sql/AddRow.sql", mimeType="application/octet-stream")]
		private static const AddRowStatementText:Class;
		private static const ADD_ROW_SQL:String = new AddRowStatementText();
	}
}