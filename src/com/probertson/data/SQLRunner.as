/*
For the latest version of this code, visit:
http://probertson.com/projects/air-sqlite/

Copyright (c) 2009 H. Paul Robertson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
package com.probertson.data
{
	import com.probertson.data.sqlRunnerClasses.ConnectionPool;
	import com.probertson.data.sqlRunnerClasses.PendingBatch;
	import com.probertson.data.sqlRunnerClasses.PendingStatement;
	import com.probertson.data.sqlRunnerClasses.StatementCache;
	
	import flash.data.SQLStatement;
	import flash.events.FullScreenEvent;
	import flash.filesystem.File;
	
	public class SQLRunner 
	{
		// ------- Constructor -------
		
		public function SQLRunner(databaseFile:File, maxPoolSize:int=5) 
		{
			_connectionPool = new ConnectionPool(databaseFile, maxPoolSize);
			// create this cache object ahead of time to avoid the overhead
			// of checking if it's null each time execute() is called.
			// Other cache objects won't be needed nearly as much, so 
			// their instantiation can be deferred.
			_stmtCache = new Object();
		}
		
		
		// ------- Member vars -------
		
		private var _connectionPool:ConnectionPool;
		private var _stmtCache:Object;
		private var _batchStmtCache:Object;
		
		
		// ------- Public properties -------
		
		/**
		 * The total number of database connections either in the pool
		 * or in use.
		 */
		public function get numConnections():int
		{
			return _connectionPool.numConnections;
		}
		
		
		/**
		 * Set this property to a function that is called when an error happens 
		 * while attempting to open a database connection.
		 * 
		 * <p>When an error occurs while trying to connect to a database, the specified function is
		 * called with one argument, the SQLError object for the error. If no function
		 * is specified for this property, the error is thrown, resulting in an 
		 * unhandled error in a debugger environment.</p>
		 */
		public function get connectionErrorHandler():Function
		{
			return _connectionPool.connectionErrorHandler;
		}
		public function set connectionErrorHandler(value:Function):void
		{
			_connectionPool.connectionErrorHandler = value;
		}
		
		
		// ------- Public methods -------
		
		/**
		 * Executes a SQL <code>SELECT</code> query asynchronously. If a SQLConnection is 
		 * available, the query begins executing immediately. Otherwise, it is added to 
		 * a queue of pending queries that are executed in request order.
		 * 
		 * @param	sql	The text of the SQL statement to execute.
		 * @param	parameters	An object whose properties contain the values of the parameters
		 * 						that are used in executing the SQL statement.
		 * @param	handler	The callback function that's called when the statement execution
		 * 					finishes. This function should define one parameter, a SQLResult 
		 * 					object. When the statement is executed, the SQLResult object containing 
		 * 					the results of the statement execution is passed to this function.
		 * @param	itemClass	A class that has properties corresponding to the columns in the 
		 * 						<code>SELECT</code> statement. In the resulting data set, each
		 * 						result row is represented as an instance of this class.
		 * @param	errorHandler	The callback function that's called when an error occurs
		 * 							during the statement's execution. A single argument is passed
		 * 							to the errorHandler function: a SQLError object containing 
		 * 							information about the error that happened.
		 */
		public function execute(sql:String, parameters:Object, handler:Function, itemClass:Class=null, errorHandler:Function=null):void
		{
			var stmt:StatementCache = _stmtCache[sql];
			if (stmt == null)
			{
				stmt = new StatementCache(sql);
				_stmtCache[sql] = stmt;
			}
			var pending:PendingStatement = new PendingStatement(stmt, parameters, handler, itemClass, errorHandler);
			_connectionPool.addPendingStatement(pending);
		}
		
		
		/**
		 * Executes the set of SQL statements defined in the batch Vector. The statements
		 * are executed within a transaction.
		 * 
		 * @param	batch	The set of SQL statements to execute, defined as QueuedStatement
		 * 					objects.
		 * @param	resultHandler	The function that's called when the batch processing finishes.
		 * 							This function is called with one argument, a Vector of 
		 * 							SQLResult objects returned by the batch operations.
		 * @param	errorHandler	The function that's called when an error occurs in the batch.
		 * 							The function is called with one argument, a SQLError object.
		 * @param	progressHandler	A function that's called each time progress is made in executing
		 * 							the batch (including after opening the transaction and after
		 * 							each statement execution). This function is called with two 
		 * 							uint arguments: The number of steps completed, 
		 * 							and the total number of execution steps. (Each "step" is either
		 * 							a statement to be executed, or the opening or closing of the 
		 * 							transaction.)
		 */
		public function executeModify(statementBatch:Vector.<QueuedStatement>, resultHandler:Function, errorHandler:Function, progressHandler:Function=null):void
		{
			var len:int = statementBatch.length;
			var statements:Vector.<SQLStatement> = new Vector.<SQLStatement>(len);
			var parameters:Vector.<Object> = new Vector.<Object>(len);
			
			if (_batchStmtCache == null)
			{
				_batchStmtCache = new Object();
			}
			
			for (var i:int = 0; i < len; i++)
			{
				var sql:String = statementBatch[i].statementText;
				var stmt:SQLStatement = _batchStmtCache[sql];
				if (stmt == null)
				{
					stmt = new SQLStatement();
					stmt.text = sql;
					_batchStmtCache[sql] = stmt;
				}
				
				statements[i] = stmt;
				parameters[i] = statementBatch[i].parameters;
			}
			
			var pendingBatch:PendingBatch = new PendingBatch(statements, parameters, resultHandler, errorHandler, progressHandler);
			_connectionPool.addBlockingBatch(pendingBatch);
		}
		
		
		/**
		 * Waits until all pending statements execute, then closes all open connections to 
		 * the database.
		 * 
		 * <p>Once you've called <code>close()</code>, you shouldn't use the SQLRunner 
		 * instance anymore. Instead, create a new SQLRunner object if you need to 
		 * access the same database again.</p>
		 * 
		 * @param	resultHandler	A function that's called when connections are closed.
		 * 							No argument values are passed to the function.
		 * 
		 * @param	errorHandler	A function that's called when an error occurs during
		 * 							the close operation. A SQLError object is passed as
		 * 							an argument to the function.
		 */
		public function close(resultHandler:Function, errorHandler:Function=null):void
		{
			_connectionPool.close(resultHandler, errorHandler);
		}
	}
}