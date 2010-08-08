package tests.com.probertson.data
{
	import com.probertson.data.SQLRunner;
	
	import events.ExecuteResultEvent;
	
	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	
	import flexunit.framework.Assert;
	
	import org.flexunit.async.Async;
	
	import utils.CreateDatabase;
	
	public class SQLRunnerExecuteTest extends EventDispatcher
	{		
		// Reference declaration for class to test
		private var _sqlRunner:SQLRunner;
		
		
		// ------- Instance vars -------
		
		private var _dbFile:File;
		
		
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
	}
}