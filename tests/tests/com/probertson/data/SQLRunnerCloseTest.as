package tests.com.probertson.data
{
	import com.probertson.data.SQLRunner;
	
	import events.CloseResultEvent;
	
	import flash.data.SQLResult;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	
	import flexunit.framework.Assert;
	
	import org.flexunit.async.Async;
	
	import utils.CreateDatabase;
	
	public class SQLRunnerCloseTest extends EventDispatcher
	{		
		// Reference declaration for class to test
		private var _sqlRunner:SQLRunner;
		
		
		// ------- Instance vars -------
		
		private var _dbFile:File;
		private var _executionCompleteCount:int = 0;
		
		
		// ------- Setup/cleanup -------
		
		[Before]
		public function setUp():void
		{
			_dbFile = File.createTempDirectory().resolvePath("test.db");
			var createDB:CreateDatabase = new CreateDatabase(_dbFile);
			createDB.createDatabase();
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
			Assert.assertEquals(1, _executionCompleteCount);
		}
		
		
		// ------- SQL statements -------
		
		[Embed(source="sql/LoadRowsLimit.sql", mimeType="application/octet-stream")]
		private static const LoadRowsLimitStatementText:Class;
		private static const LOAD_ROWS_LIMIT_SQL:String = new LoadRowsLimitStatementText();
	}
}