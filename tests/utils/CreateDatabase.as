package utils
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.filesystem.File;
	
	public class CreateDatabase
	{
		
		public function CreateDatabase(dbFile:File=null)
		{
			this.dbFile = dbFile;
		}
		
		
		// ------- Public properties -------
		
		public var dbFile:File;
		
		
		// ------- Public methods -------
		
		public function createDatabase():void
		{
			var conn:SQLConnection = new SQLConnection();
			conn.open(dbFile);
			
			createTable(conn);
			
			conn.close();			
		}
		
		
		public function createPopulatedDatabase():void
		{
			var conn:SQLConnection = new SQLConnection();
			conn.open(dbFile);
			
			createTable(conn);
			populateTable(conn);
			
			conn.close();			
		}
		
		
		// ------- Private methods -------
		
		private function createTable(conn:SQLConnection):void
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = conn;
			stmt.text = CREATE_TABLE_SQL;
			stmt.execute();
		}
		
		
		private function populateTable(conn:SQLConnection):void
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = conn;
			stmt.text = POPULATE_TABLE_SQL;
			stmt.execute();
		}
		
		
		// ------- SQL statements -------
		
		[Embed(source="/sql/create/CreateTable_testTable.sql", mimeType="application/octet-stream")]
		private static const CreateTableStatementText:Class;
		private static const CREATE_TABLE_SQL:String = new CreateTableStatementText();
		
		[Embed(source="/sql/create/PopulateTable_testTable.sql", mimeType="application/octet-stream")]
		private static const PopulateTableStatementText:Class;
		private static const POPULATE_TABLE_SQL:String = new PopulateTableStatementText();
	}
}