package tests.com.probertson.data
{
	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;
	import events.ExecuteModifyErrorEvent;
	import events.ExecuteModifyResultEvent;
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flexunit.framework.Assert;
	import org.flexunit.async.Async;
	import utils.CreateDatabase;
	
	public class SQLRunnerExecuteModifyTest extends EventDispatcher
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
		
		
		// ------- Tests -------
		
		[Test(async, timeout="500")]
		public function testOneStatement():void
		{
			addEventListener(ExecuteModifyResultEvent.RESULT, Async.asyncHandler(this, testOneStatement_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt]), testOneStatement_result, testOneStatement_error);
		}
		
		// --- handlers ---
		
		private function testOneStatement_result(results:Vector.<SQLResult>):void
		{
			dispatchEvent(new ExecuteModifyResultEvent(ExecuteModifyResultEvent.RESULT, results));
		}
		
		private function testOneStatement_result2(event:ExecuteModifyResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(1, event.results.length);
			Assert.assertEquals(1, event.results[0].rowsAffected);
		}
		
		private function testOneStatement_error(error:SQLError):void
		{
			Assert.fail(error.message);
		}
		
		
		[Test(async, timeout="500")]
		public function testTwoStatements():void
		{
			addEventListener(ExecuteModifyResultEvent.RESULT, Async.asyncHandler(this, testTwoStatements_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"World", colInt:9});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1, stmt2]), testTwoStatements_result, testTwoStatements_error);
		}
		
		// --- handlers ---
		
		private function testTwoStatements_result(results:Vector.<SQLResult>):void
		{
			dispatchEvent(new ExecuteModifyResultEvent(ExecuteModifyResultEvent.RESULT, results));
		}
		
		private function testTwoStatements_result2(event:ExecuteModifyResultEvent, passThroughData:Object):void
		{
			Assert.assertEquals(2, event.results.length);
			Assert.assertEquals(1, event.results[0].rowsAffected);
			Assert.assertEquals(1, event.results[1].rowsAffected);
		}
		
		private function testTwoStatements_error(error:SQLError):void
		{
			Assert.fail(error.message);
		}
		
		
		[Test(async, timeout="500")]
		public function testReuseStatement():void
		{
			addEventListener(ExecuteModifyResultEvent.RESULT, Async.asyncHandler(this, testReuseStatement_result2, 500));
			
			_sqlRunner = new SQLRunner(_dbFile);
			var stmt1:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"Hello", colInt:7});
			var stmt2:QueuedStatement = new QueuedStatement(ADD_ROW_SQL, {colString:"World", colInt:17});
			_sqlRunner.executeModify(Vector.<QueuedStatement>([stmt1, stmt2]), testReuseStatement_result, testReuseStatement_error);
		}
		
		// --- handlers ---
		
		private function testReuseStatement_result(results:Vector.<SQLResult>):void
		{
			dispatchEvent(new ExecuteModifyResultEvent(ExecuteModifyResultEvent.RESULT, results));
		}
		
		private function testReuseStatement_result2(event:ExecuteModifyResultEvent, passThroughData:Object):void
		{
			// verify that the inserts happened
			Assert.assertEquals(2, event.results.length);
			Assert.assertEquals(1, event.results[0].rowsAffected);
			Assert.assertEquals(1, event.results[1].rowsAffected);
			
			// verify that the inserted data matches
			var id1:int = event.results[0].lastInsertRowID;
			var id2:int = event.results[1].lastInsertRowID;
			
			var conn:SQLConnection = new SQLConnection();
			conn.open(_dbFile);
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = conn;
			stmt.text = "SELECT colString, colInt FROM main.testTable WHERE colIntPK = :colIntPK";
			var result:SQLResult;
			
			stmt.parameters[":colIntPK"] = id1;
			stmt.execute();
			result = stmt.getResult();
			Assert.assertEquals("Hello", result.data[0].colString);
			Assert.assertEquals(7, result.data[0].colInt);
			
			stmt.parameters[":colIntPK"] = id2;
			stmt.execute();
			result = stmt.getResult();
			Assert.assertEquals("World", result.data[0].colString);
			Assert.assertEquals(17, result.data[0].colInt);
			
			conn.close();			
		}
		
		private function testReuseStatement_error(error:SQLError):void
		{
			Assert.fail(error.message);
		}
		
		
		// ------- SQL statements -------
		
		[Embed(source="sql/AddRow.sql", mimeType="application/octet-stream")]
		private static const AddRowStatementText:Class;
		private static const ADD_ROW_SQL:String = new AddRowStatementText();
	}
}