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
package com.probertson.data.sqlRunnerClasses
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTransactionLockType;
	import flash.errors.SQLError;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	
	public class PendingBatch
	{
		
		public function PendingBatch(batch:Vector.<SQLStatement>, resultHandler:Function, errorHandler:Function, progressHandler:Function=null)
		{
			_batch = batch;
			_resultHandler = resultHandler;
			_errorHandler = errorHandler;
			_progressHandler = progressHandler;
		}
		
		
		// ------- Member vars -------
		
		private var _batch:Vector.<SQLStatement>;
		private var _results:Vector.<SQLResult>;
		private var _resultHandler:Function;
		private var _errorHandler:Function;
		private var _progressHandler:Function;
		private var _pool:ConnectionPool;
		private var _conn:SQLConnection;
		private var _numStatements:uint;
		private var _statementsCompleted:uint = 0;
		private var _error:SQLError;
		
		
		// ------- Public methods -------
		
		public function executeWithConnection(pool:ConnectionPool, connection:SQLConnection):void
		{
			if (_batch == null || _batch.length == 0)
			{
				return;
			}
			
			_pool = pool;
			_conn = connection;
			_numStatements = _batch.length;
			
//			if (_numStatements > 1)
//			{
				beginTransaction();
//			}
//			else
//			{
//				executeStatements();
//			}
		}
		
		
		// ------- Executing batch -------
		
		private function beginTransaction():void
		{
			_conn.addEventListener(SQLEvent.BEGIN, conn_begin);
			_conn.begin(SQLTransactionLockType.IMMEDIATE);
		}
		
		
		private function conn_begin(event:SQLEvent):void 
		{
			_conn.removeEventListener(SQLEvent.BEGIN, conn_begin);
			executeStatements();
		}
		
		
		private function executeStatements():void
		{
			callProgressHandler();
			
			
			while (_batch.length > 0)
			{
				var stmt:SQLStatement = _batch.shift();
				if (stmt.sqlConnection == null)
				{
					stmt.sqlConnection = _conn;
				}
				stmt.addEventListener(SQLEvent.RESULT, stmt_result);
				stmt.addEventListener(SQLErrorEvent.ERROR, conn_error);
				stmt.execute();
			}
			
			_results = new Vector.<SQLResult>();
		}
		
		
		private function stmt_result(event:SQLEvent):void 
		{
			var stmt:SQLStatement = event.target as SQLStatement;
			stmt.removeEventListener(SQLEvent.RESULT, stmt_result);
			stmt.removeEventListener(SQLErrorEvent.ERROR, conn_error);
			
			_results[_results.length] = stmt.getResult();
			
			_statementsCompleted++;
			callProgressHandler();
			
			if (_statementsCompleted == _numStatements)
			{
//				if (_numStatements > 1)
//				{
					commitTransaction();
//				}
//				else
//				{
//					finish();
//				}
			}
		}
		
		
		private function commitTransaction():void
		{
			_conn.addEventListener(SQLEvent.COMMIT, conn_commit);
			_conn.commit();
		}
		
		
		private function conn_commit(event:SQLEvent):void 
		{
			_conn.removeEventListener(SQLEvent.COMMIT, conn_commit);
			
			finish();
		}
		
		
		private function finish():void
		{
			if (_resultHandler != null)
			{
				_resultHandler(_results);
			}
			
			cleanUp();	
		}
		
		
		// --- Error handling ---
		
		private function conn_error(event:SQLErrorEvent):void
		{
			// once one error is thrown, a bunch more will be thrown from cancelling
			// but they should be ignored
			if (_error == null)
			{
				_error = event.error;
				cancelExecution();
			}
		}
		
		
		private function cancelExecution():void
		{
			_conn.addEventListener(SQLEvent.CANCEL, conn_cancel);
			_conn.cancel();
		}
		
		
		private function conn_cancel(event:SQLEvent):void 
		{
			_conn.removeEventListener(SQLEvent.CANCEL, conn_cancel);
			rollbackTransaction();
		}
		
		
		private function rollbackTransaction():void
		{
			if (_conn.inTransaction)
			{
				_conn.addEventListener(SQLEvent.ROLLBACK, conn_rollback);
				_conn.rollback();
			}
			else
			{
				callErrorHandler();
				cleanUp();
			}
		}
		
		
		private function conn_rollback(event:SQLEvent):void 
		{
			_conn.removeEventListener(SQLEvent.ROLLBACK, conn_rollback);
			callErrorHandler();
			cleanUp();
		}
		
		
		// --- Utility ---
		
		private function callProgressHandler():void
		{
			if (_progressHandler != null)
			{
				_progressHandler(_statementsCompleted + 1, _numStatements + 2);
			}
		}
		
		
		private function callErrorHandler():void
		{
			_errorHandler(_error);
		}
		
		
		private function cleanUp():void
		{
			_pool.returnConnection(_conn);
			
			_conn = null;
			_pool = null;
			_batch = null;
			_results = null;
			_progressHandler = null;
			_resultHandler = null;
			_errorHandler = null;
			_error = null;
		}
	}
}