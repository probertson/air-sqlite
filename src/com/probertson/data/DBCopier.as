package com.probertson.data
{
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLIndexSchema;
	import flash.data.SQLMode;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.data.SQLTransactionLockType;
	import flash.data.SQLTriggerSchema;
	import flash.data.SQLViewSchema;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	/**
	 * Dispatched when the encryption operation has begun, the source and destination
	 * databases are known to be valid, and the <code>totalOperations</code> property 
	 * value has been calculated.
	 * 
	 * @eventType flash.events.Event.INIT
	 */
	[Event(name="init", type="flash.events.Event")]
	
	
	/**
	 * Dispatched each time a step of the encryption process completes, starting after 
	 * the <code>init</code> event is dispatched. Each time the <code>progress</code> event 
	 * dispatches, the <code>operationsCompleted</code> property changes. At certain points 
	 * the <code>currentStep</code> property also changes.
	 * 
	 * @eventType flash.events.ProgressEvent.PROGRESS
	 */
	[Event(name="progress", type="flash.events.ProgressEvent")]
	
	
	/**
	 * Dispatched when the encryption process finishes.
	 * 
	 * @eventType flash.events.Event.COMPLETE
	 */
	[Event(name="complete", type="flash.events.Event")]
	
	
	/**
	 * Dispatched when an error occurs during the encryption process.
	 * 
	 * @eventType flash.events.SQLErrorEvent.ERROR
	 */
	[Event(name="error", type="flash.events.SQLErrorEvent")]
	
	
	/**
	 * Used to create a copy of an AIR SQLite database. The DBCopier copies all database objects, 
	 * including tables, views, indexes, triggers, and optionally, table data.
	 * 
	 * <p>You can use the DBCopier to copy an unencrypted database to an encrypted database, 
	 * which is the only way to encrypt a database.</p>
	 * 
	 * <p>To use the DBCopier:</p>
	 * 
	 * <ol>
	 *   <li>Create a DBCopier instance and specify the source database and 
	 * output path where the new database is created. To create an encrypted database, specify 
	 * a value for the <code>destEncryptionKey</code> parameter. If the <code>sourceDB</code> 
	 * database is encrypted, provide that database's encryption key as the 
	 * <code>sourceEncryptionKey</code> parameter.</li>
	 *   <li>If you want the database to be created with a page size or auto-compact value 
	 * that differs from the default values, set the <code>pageSize</code> and/or 
	 * <code>autoCompact</code> properties.</li>
	 *   <li>Call the <code>start()</code> method to begin the database copy operation.</li>
	 * </ol>
	 */
	public class DBCopier extends EventDispatcher
	{
		// ------- Constructor -------
		public function DBCopier(sourceDB:File, outputPath:File, destEncryptionKey:ByteArray=null, sourceEncryptionKey:ByteArray=null)
		{
			// Validate parameters
			if (sourceDB == null)
			{
				throw new ArgumentError("The sourceDB parameter can't be null.");
			}
			if (sourceDB.isDirectory)
			{
				throw new ArgumentError("The sourceDB parameter must specify a database file (not a directory).");
			}
			if (!sourceDB.exists)
			{
				throw new ArgumentError("The sourceDB parameter must specify an existing database file.");
			}
			
			if (outputPath == null)
			{
				throw new ArgumentError("The outputPath parameter can't be null.");
			}
			if (outputPath.isDirectory)
			{
				throw new ArgumentError("The outputPath parameter must specify a file path (not a directory).");
			}
			if (outputPath.exists)
			{
				throw new ArgumentError("The outputPath parameter can't specify an existing database (or other) file.");
			}
			
			if (destEncryptionKey != null && encryptionKey.length != 16)
			{
				throw new ArgumentError("The destEncryptionKey parameter must be null or a ByteArray whose length is exactly 16 bytes.");
			}
			
			if (sourceEncryptionKey != null && sourceEncryptionKey.length != 16)
			{
				throw new ArgumentError("The sourceEncryptionKey parameter must be null or a ByteArray whose length is exactly 16 bytes.");
			}
			
			_srcFile = sourceDB;
			_destFile = outputPath;
			_destEncryptionKey = destEncryptionKey;
			_sourceEncryptionKey = sourceEncryptionKey;
		}
		
		
		// ------- Private vars -------
		private var _srcFile:File;
		private var _destFile:File;
		private var _destEncryptionKey:ByteArray;
		private var _sourceEncryptionKey:ByteArray;
		private var _conn:SQLConnection;
		private var _copyData:Boolean = true;
		
		// --- arrays of sql statements ---
		private var _createTables:Vector.<SQLStatement>;
		private var _copyTableData:Vector.<SQLStatement>;
		private var _createIndices:Vector.<SQLStatement>;
		private var _createViews:Vector.<SQLStatement>;
		private var _createTriggers:Vector.<SQLStatement>;
		
		private var _errorEvent:SQLErrorEvent;
		
		
		// ------- Public properties -------
		private var _autoCompact:Boolean = false;
		
		/**
		 * Specifies whether to create the new database with auto-compact enabled 
		 * (<code>true</code>) or not (<code>false</code>). Set this property before 
		 * calling the <code>start()</code> method.
		 * 
		 * @default false
		 */
		public function get autoCompact():Boolean
		{
			return _autoCompact;
		}
		public function set autoCompact(value:Boolean):void
		{
			_autoCompact = value;
		}
		
		
		private var _currentStep:String = EncrypterProgressPhase.PRE_INIT;
		
		/**
		 * The current step in the database copy process. The possible 
		 * values are defined as constants in the CopyProgressPhase class.
		 * 
		 * <p>This property changes at certain points when the <code>progress</code>
		 * event is dispatched.</p>
		 * 
		 * @see CopyProgressPhase
		 */
		public function get currentStep():String
		{
			return _currentStep;
		}
		private function setProgress(value:String=null):void
		{
			if (value != null)
			{
				_currentStep = value;
			}
			
			if (value != CopyProgressPhase.INIT)
			{
				_operationsCompleted += 1;
			}
			
			if (_currentStep == CopyProgressPhase.PRE_INIT)
			{
				return;
			}
			
			var evt:Event;
			switch (_currentStep)
			{
				case CopyProgressPhase.INIT:
					evt = new Event(Event.INIT);
					break;
				case CopyProgressPhase.COMPLETE:
					evt = new Event(Event.COMPLETE);
					break;
				default:
					evt = new ProgressEvent(ProgressEvent.PROGRESS);
					break;
			}
			
			dispatchEvent(evt);
		}
		
		
		private var _operationsCompleted:uint = 0;
		
		/**
		 * Indicates how many operations have been performed in the copy/encrypt
		 * process. This represents a fraction of the total operations indicated 
		 * by the <code>operationsTotal</code> property.
		 * 
		 * <p>The DBCopier dispatches a <code>progress</code> event when this property changes.</p>
		 * 
		 * @see #operationsTotal
		 * @see #event:progress
		 */
		public function get operationsCompleted():uint
		{
			return _operationsCompleted;
		}
		
		
		private var _operationsTotal:uint = 0;
		
		/**
		 * The total number of operations required for the database copy/encrypt
		 * process. The <code>operationsCompleted</code> property indicates how 
		 * many of the operations have already completed.
		 * 
		 * @see #operationsCompleted
		 */
		public function get operationsTotal():uint
		{
			return _operationsTotal;
		}
		
		
		private var _pageSize:int = 1024;
		
		/**
		 * Specifies the page size to assign to the new database. Set this property before 
		 * calling the <code>start()</code> method.
		 * 
		 * @default 1024
		 */
		public function get pageSize():int
		{
			return _pageSize;
		}
		public function set pageSize(value:int):void
		{
			_pageSize = value;
		}
		
		
		// ------- Public methods -------
		/**
		 * Starts the database copy process.
		 */
		public function start(copyData:Boolean=true):void
		{
			_copyData = copyData;
			openConnection();
		}
		
		
		// ------- Private methods -------
		
		// 1. open connection to dest
		private function openConnection():void
		{
			_conn = new SQLConnection();
			_conn.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			_conn.addEventListener(SQLEvent.OPEN, openHandler);
			_conn.openAsync(_destFile, SQLMode.CREATE, null, _autoCompact, _pageSize, _destEncryptionKey);
		}
		
		private function openHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.OPEN, openHandler);
			
			setProgress();
			
			attachSourceDB();
		}
		
		// 2. attach src
		private function attachSourceDB():void
		{
			_conn.addEventListener(SQLEvent.ATTACH, attachHandler);
			_conn.attach("src", _srcFile, null, _sourceEncryptionKey);
		}
		
		private function attachHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.ATTACH, attachHandler);
			
			setProgress();
			
			loadSourceSchema();
		}
		
		// 3. load src schema
		private function loadSourceSchema():void
		{
			_conn.addEventListener(SQLEvent.SCHEMA, loadSchemaHandler);
			_conn.loadSchema(null, null, "src");
		}
		
		private function loadSchemaHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.SCHEMA, loadSchemaHandler);
			
			setProgress();
			
			constructSQLStatements();
		}
		
		// 4. construct sql statements
		private function constructSQLStatements():void
		{
			var srcSchema:SQLSchemaResult = _conn.getSchemaResult();
			
			_operationsTotal += 1; // create dest
			_operationsTotal += 1; // attach src
			_operationsTotal += 1; // load schema;
			_operationsTotal += 1; // create statements
			_operationsTotal += 1; // begin transaction
			_operationsTotal += srcSchema.tables.length; // create tables
			_operationsTotal += srcSchema.indices.length; // create indices
			_operationsTotal += srcSchema.views.length; // create views
			_operationsTotal += srcSchema.triggers.length; // create triggers
			if (_copyData)
			{
				_operationsTotal += srcSchema.tables.length; // copy table data
			}
			_operationsTotal += 1; // commit transaction
			_operationsTotal += 1; // detach
			_operationsTotal += 1; // close
			
			setProgress(CopyProgressPhase.INIT);
			
			var i:uint = 0;
			var j:uint = 0;
			
			// Statements to create tables and copy data
			_createTables = new Vector.<SQLStatement>();
			if (_copyData)
			{
				_copyTableData = new Vector.<SQLStatement>();
			}
			
			var numTables:uint = srcSchema.tables.length;
			for (i = 0; i < numTables; i++)
			{
				var tbl:SQLTableSchema = srcSchema.tables[i];
				var createTableStmt:SQLStatement = new SQLStatement();
				createTableStmt.sqlConnection = _conn;
				createTableStmt.text = tbl.sql;
				_createTables[_createTables.length] = createTableStmt;
				
				if (_copyData)
				{
					var copyStmt:SQLStatement = new SQLStatement();
					copyStmt.sqlConnection = _conn;
					var copySQL:String = "INSERT INTO main." + tbl.name + " (";
					var col:SQLColumnSchema;
					var numColumns:uint = tbl.columns.length;
					for (j = 0; j < numColumns; j++)
					{
						col = tbl.columns[j];
						if (j > 0)
						{
							copySQL += ", ";
						}
						copySQL += col.name;
					}
					copySQL += ") ";
					copySQL += "SELECT ";
					for (j = 0; j < numColumns; j++)
					{
						col = tbl.columns[j];
						if (j > 0)
						{
							copySQL += ", ";
						}
						copySQL += col.name;
					}
					copySQL += " FROM src." + tbl.name;
					copyStmt.text = copySQL;
					_copyTableData[_copyTableData.length] = copyStmt;
				}
			}
			
			// Statements to create indices
			_createIndices = new Vector.<SQLStatement>();
			
			var numIndices:uint = srcSchema.indices.length;
			for (i = 0; i < numIndices; i++)
			{
				var idx:SQLIndexSchema = srcSchema.indices[i];
				var createIndexStmt:SQLStatement = new SQLStatement();
				createIndexStmt.sqlConnection = _conn;
				createIndexStmt.text = idx.sql;
				_createIndices[_createIndices.length] = createIndexStmt;
			}
			
			// Statements to create views
			_createViews = new Vector.<SQLStatement>();
			
			var numViews:uint = srcSchema.views.length;
			for (i = 0; i < numViews; i++)
			{
				var view:SQLViewSchema = srcSchema.views[i];
				var createViewStmt:SQLStatement = new SQLStatement();
				createViewStmt.sqlConnection = _conn;
				createViewStmt.text = view.sql;
				_createViews[_createViews.length] = createViewStmt;
			}
			
			// Statements to create triggers
			_createTriggers = new Vector.<SQLStatement>();
			
			var numTriggers:uint = srcSchema.triggers.length;
			for (i = 0; i < numTriggers; i++)
			{
				var trigger:SQLTriggerSchema = srcSchema.triggers[i];
				var createTriggerStmt:SQLStatement = new SQLStatement();
				createTriggerStmt.sqlConnection = _conn;
				createTriggerStmt.text = trigger.sql;
				_createTriggers[_createTriggers.length] = createTriggerStmt;
			}
			
			beginTransaction();
		}
		
		// 5. begin transaction
		private function beginTransaction():void
		{
			setProgress(EncrypterProgressPhase.BEGIN);
			
			_conn.addEventListener(SQLEvent.BEGIN, beginHandler);
			_conn.begin(SQLTransactionLockType.EXCLUSIVE);
		}
		
		private function beginHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.BEGIN, beginHandler);
			
			createTables();
		}
		
		// 6. create dest tables
		private function createTables():void
		{
			if (_createTables.length > 0)
			{
				createNextTable();
			}
			else
			{
				// if there aren't any tables there can't be any other objects, so just clean up
				commitTransaction();
			}
		}
		
		private function createNextTable():void
		{
			setProgress(EncrypterProgressPhase.CREATE_TABLES);
			
			var createTableStmt:SQLStatement = _createTables.shift();
			createTableStmt.addEventListener(SQLEvent.RESULT, createTableHandler);
			createTableStmt.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			createTableStmt.execute();
		}
		
		private function createTableHandler(event:SQLEvent):void
		{
			var createTableStmt:SQLStatement = event.target as SQLStatement;
			createTableStmt.removeEventListener(SQLEvent.RESULT, createTableHandler);
			createTableStmt.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			
			if (_createTables.length > 0)
			{
				createNextTable();
			}
			else
			{
				createIndices();
			}
		}
		
		// 7. create dest indices
		private function createIndices():void
		{
			if (_createIndices.length > 0)
			{
				createNextIndex();
			}
			else
			{
				// skip indices and go to the next step (views)
				createViews();
			}
		}
		
		private function createNextIndex():void
		{
			setProgress(EncrypterProgressPhase.CREATE_INDICES);
			
			var createIndexStmt:SQLStatement = _createIndices.shift();
			createIndexStmt.addEventListener(SQLEvent.RESULT, createIndexHandler);
			createIndexStmt.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			createIndexStmt.execute();
		}
		
		private function createIndexHandler(event:SQLEvent):void
		{
			var createIndexStmt:SQLStatement = event.target as SQLStatement;
			createIndexStmt.removeEventListener(SQLEvent.RESULT, createIndexHandler);
			createIndexStmt.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
						
			if (_createIndices.length > 0)
			{
				createNextIndex();
			}
			else
			{
				createViews();
			}
		}
		
		// 8. create dest views
		private function createViews():void
		{
			if (_createViews.length > 0)
			{
				createNextView();
			}
			else
			{
				// skip views and go to the next step (triggers)
				createTriggers();
			}
		}
		
		private function createNextView():void
		{
			setProgress(EncrypterProgressPhase.CREATE_VIEWS);
			
			var createViewStmt:SQLStatement = _createViews.shift();
			createViewStmt.addEventListener(SQLEvent.RESULT, createViewHandler);
			createViewStmt.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			createViewStmt.execute();
		}
		
		private function createViewHandler(event:SQLEvent):void
		{
			var createViewStmt:SQLStatement = event.target as SQLStatement;
			createViewStmt.removeEventListener(SQLEvent.RESULT, createViewHandler);
			createViewStmt.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
						
			if (_createViews.length > 0)
			{
				createNextView();
			}
			else
			{
				createTriggers();
			}
		}
		
		// 9. create dest triggers
		private function createTriggers():void
		{
			if (_createTriggers.length > 0)
			{
				createNextTrigger();
			}
			else
			{
				// skip triggers and go to the next step (copy data)
				copyTableData();
			}
		}
		
		private function createNextTrigger():void
		{
			setProgress(EncrypterProgressPhase.CREATE_TRIGGERS);
			
			var createTriggerStmt:SQLStatement = _createTriggers.shift();
			createTriggerStmt.addEventListener(SQLEvent.RESULT, createTriggerHandler);
			createTriggerStmt.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			createTriggerStmt.execute();
		}
		
		private function createTriggerHandler(event:SQLEvent):void
		{
			var createTriggerStmt:SQLStatement = event.target as SQLStatement;
			createTriggerStmt.removeEventListener(SQLEvent.RESULT, createTriggerHandler);
			createTriggerStmt.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			
			if (_createTriggers.length > 0)
			{
				createNextTrigger();
			}
			else
			{
				copyTableData();
			}
		}
		
		// 10. copy data
		private function copyTableData():void
		{
			if (_copyTableData != null && _copyTableData.length > 0)
			{
				copyNextTable();
			}
			else
			{
				// skip copying table data and go to the next step (clean up)
				commitTransaction();
			}
		}
		
		private function copyNextTable():void
		{
			setProgress(EncrypterProgressPhase.COPY_TABLE_DATA);
			
			var copyTableStmt:SQLStatement = _copyTableData.shift();
			copyTableStmt.addEventListener(SQLEvent.RESULT, copyTableHandler);
			copyTableStmt.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			copyTableStmt.execute();
		}
		
		private function copyTableHandler(event:SQLEvent):void
		{
			var copyTableStmt:SQLStatement = event.target as SQLStatement;
			copyTableStmt.removeEventListener(SQLEvent.RESULT, copyTableHandler);
			copyTableStmt.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
						
			if (_copyTableData.length > 0)
			{
				copyNextTable();
			}
			else
			{
				commitTransaction();
			}
		}
		
		// 11. commit transaction
		private function commitTransaction():void
		{
			setProgress(EncrypterProgressPhase.CLOSE);
			
			_conn.addEventListener(SQLEvent.COMMIT, commitHandler);
			_conn.commit();
		}
		
		private function commitHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.COMMIT, commitHandler);
			
			setProgress();
			
			detachSourceDB();
		}
		
		// 12. detach src
		private function detachSourceDB():void
		{
			_conn.addEventListener(SQLEvent.DETACH, detachHandler);
			_conn.detach("src");
		}
		
		private function detachHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.DETACH, detachHandler);
			
			setProgress();
			
			closeConnection();
		}
		
		// 13. close connection
		private function closeConnection():void
		{
			_conn.addEventListener(SQLEvent.CLOSE, closeHandler);
			_conn.close();
		}
		
		private function closeHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.CLOSE, closeHandler);
			_conn.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			
			setProgress(EncrypterProgressPhase.COMPLETE);
		}
		
		
		// ------- Error handling -------
		private function errorHandler(event:SQLErrorEvent):void
		{
			_errorEvent = event;
			
			// roll back transaction
			if (_conn.inTransaction)
			{
				_conn.addEventListener(SQLEvent.ROLLBACK, rollbackHandler);
				_conn.rollback();
			}
			else
			{
				closeConnectionAfterError();
			}
		}
		
		private function rollbackHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.ROLLBACK, rollbackHandler);
			
			closeConnectionAfterError();
		}
		
		private function closeConnectionAfterError():void
		{
			_conn.addEventListener(SQLEvent.CLOSE, closeConnectionAfterErrorHandler);
			_conn.close();
		}
		
		private function closeConnectionAfterErrorHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.CLOSE, closeConnectionAfterErrorHandler);
			_conn.removeEventListener(SQLErrorEvent.ERROR, errorHandler);
			
			deleteDestinationDB();
		}
		
		// delete dest db (if necessary)
		private function deleteDestinationDB():void
		{
			if (_destFile.exists)
			{
				try
				{
					_destFile.deleteFile();
				}
				catch(error:Error)
				{
					// just ignore, so that error handling can continue
				}
			}
			
			bubbleError();
		}
		
		private function bubbleError():void
		{
			dispatchEvent(_errorEvent.clone());
		}
	}
}