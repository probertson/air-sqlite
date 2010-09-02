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
	import com.probertson.data.sqlRunnerClasses.PendingStatementUnpooled;
	
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	public class SQLRunnerUnpooled
	{
		
		public function SQLRunnerUnpooled(databaseFile:File, encryptionKey:ByteArray=null) 
		{
			_conn = new SQLConnection();
			_conn.addEventListener(SQLEvent.OPEN, conn_open);
			_conn.openAsync(databaseFile, SQLMode.CREATE, null, false, 1024, encryptionKey);
			_inUse = true;
			
			// create objects ahead of time to avoid the overhead
			// of checking if they're null each time execute() is called.
			// Other cache objects won't be needed nearly as much, so 
			// their instantiation can be deferred.
			_pending = new Vector.<PendingStatementUnpooled>();
			_cache = new Object();
		}
		
		
		// ------- Member vars -------
		
		private var _conn:SQLConnection;
		private var _inUse:Boolean;
		private var _cache:Object;
		private var _current:PendingStatementUnpooled;
		private var _pending:Vector.<PendingStatementUnpooled>;
		private var _closeHandler:Function;
		//private var _batchStmtCache:Object;
		
		
		// ------- Public methods -------
		
		/**
		 * Executes a SQL <code>SELECT</code> query asynchronously. If a SQLConnection is 
		 * available, the query begins executing immediately. Otherwise, it is added to 
		 * a queue of pending queries that are executed in request order.
		 * 
		 * @param	sql	The text of the SQL statement to execute.
		 * @param	parameters	An object whose properties contain the values of the parameters
		 * 						that are used in executing the SQL statement.
		 * @param	responder	The responder containing the callback functions that are called when the statement execution
		 * 						finishes (or fails). Both functions are optional. The responder's result function should define one parameter, a SQLResult 
		 * 						object. When the statement is executed, the SQLResult object containing 
		 * 						the results of the statement execution is passed to this function. The responder's
		 * 						status function should define one parameter, a SQLError object.
		 * @param	itemClass	A class that has properties corresponding to the columns in the 
		 * 						<code>SELECT</code> statement. In the resulting data set, each
		 * 						result row is represented as an instance of this class.
		 */
		public function execute(sql:String, parameters:Object, responder:Responder, itemClass:Class=null):void
		{
			var stmtData:PendingStatementUnpooled = new PendingStatementUnpooled(sql, parameters, responder, itemClass);
			
			_pending[_pending.length] = stmtData;
			
			checkPending();
		}
		
		
		/**
		 * Waits until all pending statements execute, then closes all open connections to 
		 * the database.
		 * 
		 * @param	resultHandler	A function that's called when connections are closed.
		 * 							No argument values are passed to the function.
		 */
		public function close(resultHandler:Function):void
		{
			_closeHandler = resultHandler;
			checkPending();
		}
		
		
		// ------- Pending statements -------
		private function checkPending():void
		{
			// standard (read-only) statements
			if (_pending.length > 0)
			{
				if (!_inUse)
				{
					_current = _pending.shift();
					
					var stmt:SQLStatement = _cache[_current.sql];
					if (stmt == null)
					{
						stmt = new SQLStatement();
						stmt.sqlConnection = _conn;
						stmt.text = _current.sql;
						_cache[_current.sql] = stmt;
					}
					
					stmt.addEventListener(SQLEvent.RESULT, stmt_result);
					stmt.addEventListener(SQLErrorEvent.ERROR, stmt_error);
					
					if (_current.itemClass != null)
					{
						stmt.itemClass = _current.itemClass;
					}
					
					stmt.clearParameters();
					if (_current.parameters != null)
					{
						for (var prop:String in _current.parameters)
						{
							stmt.parameters[":" + prop] = _current.parameters[prop];
						}
					}
					
					stmt.execute();
					
					_inUse = true;
					return;
				}
				else
				{
					// The connection isn't available
					return;
				}
			}
			
			// if there aren't any pending requests and there is a pending close
			// request, close the connections
			if (_closeHandler != null)
			{
				_conn.addEventListener(SQLEvent.CLOSE, conn_close);
				_conn.close();
			}
		}
		
		
		// ------- Event handling -------
		
		private function conn_open(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.OPEN, conn_open);
			returnConnection();
		}
		
		
		private function stmt_result(event:SQLEvent):void
		{
			var stmt:SQLStatement = event.target as SQLStatement;
			stmt.removeEventListener(SQLEvent.RESULT, stmt_result);
			stmt.removeEventListener(SQLErrorEvent.ERROR, stmt_error);
			var result:SQLResult = stmt.getResult();
			if (_current.responder.result != null)
			{
				_current.responder.result(result);
			}
			returnConnection();
		}
		
		
		private function stmt_error(event:SQLErrorEvent):void
		{
			var stmt:SQLStatement = event.target as SQLStatement;
			stmt.removeEventListener(SQLEvent.RESULT, stmt_result);
			stmt.removeEventListener(SQLErrorEvent.ERROR, stmt_error);
			if (_current.responder.error != null)
			{
				_current.responder.error(event.error);
			}
			returnConnection();
		}
		
		
		private function conn_close(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.CLOSE, conn_close);
			
			_closeHandler();
			
			_closeHandler = null;
		}
		
		
		// ------- Private methods -------
		
		private function returnConnection():void
		{
			_inUse = false;
			checkPending();
		}
	}
}