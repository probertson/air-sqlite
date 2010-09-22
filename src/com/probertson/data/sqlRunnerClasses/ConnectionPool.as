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

Acknowledgement:
Some of the implementation techniques used here were inspired by the ConnectionPool
example accompanying Daniel Rinehart's article "User experience considerations
with SQLite operations" (http://www.adobe.com/devnet/air/flex/articles/air_sql_operations.html).
*/
package com.probertson.data.sqlRunnerClasses
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.errors.SQLErrorOperation;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	public class ConnectionPool 
	{
		
		// ------- Constructor -------
		
		public function ConnectionPool(dbFile:File, maxSize:int=5) 
		{
			_dbFile = dbFile;
			_maxSize = maxSize;
			_available = new Vector.<SQLConnection>();
			_inUse = new Dictionary();
			_pending = new Vector.<PendingStatement>();
		}
		
		
		// ------- Member vars -------
		
		private var _dbFile:File;
		// Standard (pooled) connections
		private var _maxSize:int = 5;
		private var _available:Vector.<SQLConnection>;
		private var _inUse:Dictionary;
		private var _totalConnections:int = 0;
		private var _numConnectionsBeingOpened:int = 0;
		private var _pending:Vector.<PendingStatement>;
		// Batch/blocking (write/modify) connection
		private var _blocked:Boolean = false;
		private var _blockingPending:Vector.<PendingBatch>;
		private var _blockedPending:Vector.<PendingStatement>;
		private var _blockingConnection:SQLConnection;
		// Closing
		private var _pendingClose:Boolean = false;
		private var _pendingCloseHandler:Function;
		private var _pendingCloseErrorHandler:Function;
		private var _pendingCloseCount:int = 0;
		
		
		// ------- Public properties -------
		
		public function get numConnections():int
		{
			return _totalConnections;
		}
		
		
		private var _connectionErrorHandler:Function;
		public function get connectionErrorHandler():Function { return _connectionErrorHandler; }
		public function set connectionErrorHandler(value:Function):void
		{
			if (_connectionErrorHandler == value)
				return;
			_connectionErrorHandler = value;
		}
		
		
		// ------- Public methods -------
		
		/**
		 * Adds a pending statement to the execution queue. If a connection is available
		 * it is executed immediately. Otherwise statements are executed in the 
		 * order they're requested, as database connections become available.
		 */
		public function addPendingStatement(pendingStatement:PendingStatement):void
		{
			// TODO: throw an error or dispatch an event if there is a pending close
			if (!_blocked)
			{
				_pending.push(pendingStatement);
				checkPending();
			}
			else
			{
				if (_blockedPending == null)
				{
					_blockedPending = new Vector.<PendingStatement>();
				}
				_blockedPending.push(pendingStatement);
			}
		}
		
		
		/**
		 * Requests a blocking connection -- a connection that's guaranteed to be 
		 * the only one in use at one time. This connection is appropriate to 
		 * use for executing statements that change data or the database structure,
		 * such as <code>INSERT</code>, <code>UPDATE</code>, <code>DELETE</code>,
		 * <code>CREATE ...</code>, <code>ALTER ...</code>, <code>DROP ...</code>, etc.
		 */
		public function addBlockingBatch(batch:PendingBatch):void
		{
			// TODO: throw an error or dispatch an event if there is a pending close
			if (_blockingPending == null)
			{
				_blockingPending = new Vector.<PendingBatch>();
			}
			
			_blockingPending.push(batch);
			
			if (_blockingConnection == null)
			{
				_blocked = true;
				_blockingConnection = new SQLConnection();
				_blockingConnection.addEventListener(SQLEvent.OPEN, conn_open);
				_blockingConnection.addEventListener(SQLErrorEvent.ERROR, conn_openError);
				_blockingConnection.openAsync(_dbFile);
			}
			else
			{
				checkPending();
			}
		}
		
		
		public function close(handler:Function, errorHandler:Function):void
		{
			_pendingClose = true;
			_pendingCloseHandler = handler;
			_pendingCloseErrorHandler = errorHandler;
			
			checkPending();
		}
		
		
		/**
		 * Returns a SQLConnection to the pool, indicating that it is no longer
		 * being used and can be made available to pending or incoming connection
		 * requests.
		 * 
		 * @param	connection	The SQLConnection that is no longer in use.
		 */
		internal function returnConnection(connection:SQLConnection):void
		{
			if (connection != _blockingConnection)
			{
				_inUse[connection] = false;
				_available.push(connection);
			}
			else
			{
				_blocked = false;
				if (_blockedPending != null && _blockedPending.length > 0)
				{
					_pending = _blockedPending.splice(0, _blockedPending.length);
				}
			}
			
			checkPending();
		}
		
		
		// ------- Pending statements -------
		
		private function checkPending():void
		{
			// standard (read-only) statements
			while (_pending.length > 0)
			{
				var conn:SQLConnection;
				
				if (_available.length > 0)
				{
					var stmt:PendingStatement = _pending.shift();
					
					if (stmt.statementCache.preferredConnections != null)
					{
						for (var i:int = 0, len:int = stmt.statementCache.preferredConnections.length; i < len; i++)
						{
							conn = stmt.statementCache.preferredConnections[i];
							if (!_inUse[conn])
							{
								var index:int = _available.indexOf(conn);
								_available.splice(index, 1);
								break;
							}
							else
							{
								conn = null;
							}
						}
					}
					
					if (conn == null)
					{
						conn = _available.shift();
					}
					
					_inUse[conn] = true;
					stmt.executeWithConnection(this, conn);
				}
				else if (_totalConnections < _maxSize && _pending.length > _numConnectionsBeingOpened)
				{
					// increment the total here, so that while the connection
					// is being opened further requests don't cause additional
					// connections to be created
					_numConnectionsBeingOpened++;
					_totalConnections++;
					conn = new SQLConnection();
					conn.addEventListener(SQLEvent.OPEN, conn_open);
					conn.addEventListener(SQLErrorEvent.ERROR, conn_openError);
					conn.openAsync(_dbFile, SQLMode.READ);
					return;
				}
				else
				{
					// No connections are available, and we've reached the 
					// maximum allotment
					return;
				}
			}
			
			// once there are no more pending read requests, execute a blocking
			// batch if there is one
			if (!_blocked && _blockingPending != null && _blockingPending.length > 0 && _blockingConnection.connected)
			{
				_blocked = true;
				var pendingBatch:PendingBatch = _blockingPending.shift();
				pendingBatch.executeWithConnection(this, _blockingConnection);
				return;
			}
			
			// if there aren't any pending requests or currently executing statements 
			// and there is a pending close request, close the connections
			if (_pendingClose &&
				_pending.length == 0 &&
				(_available.length == _totalConnections) && 
				!_blocked &&
				(_blockingPending == null || _blockingPending.length == 0))
			{
				closeAll();
			}
		}
		
		
		private function conn_open(event:SQLEvent):void
		{
			var conn:SQLConnection = event.target as SQLConnection;
			conn.removeEventListener(SQLEvent.OPEN, conn_open);
			conn.removeEventListener(SQLErrorEvent.ERROR, conn_openError);
			
			if (conn != _blockingConnection)
			{
				_numConnectionsBeingOpened--;
				returnConnection(conn);
			}
			else
			{
				_blocked = false;
				checkPending();
			}
		}
		
		
		private function conn_openError(event:SQLErrorEvent):void
		{
			// only handle open errors. Close errors are handled by the close 
			// error handler. Errors that happen during
			// statement operations (such as begin, commit, rollback, execute) 
			// are handled by the statement error handlers.
			if (event.error.operation != SQLErrorOperation.OPEN)
				return;
			
			var conn:SQLConnection = SQLConnection(event.target);
			conn.removeEventListener(SQLErrorEvent.ERROR, conn_openError);
			conn.removeEventListener(SQLEvent.OPEN, conn_open);
			
			if (_connectionErrorHandler != null)
			{
				_connectionErrorHandler(event.error);
			}
			else
			{
				throw(event.error);
			}
		}
		
		
		private function closeAll():void
		{
			_pendingCloseCount = 0;
			
			for each (var conn:SQLConnection in _available)
			{
				conn.addEventListener(SQLEvent.CLOSE, conn_close);
				conn.addEventListener(SQLErrorEvent.ERROR, conn_closeError);
				conn.close();
				_pendingCloseCount++;
			}
			
			if (_blockingConnection != null && _blockingConnection.connected)
			{
				_blockingConnection.addEventListener(SQLEvent.CLOSE, conn_close);
				_blockingConnection.close();
				_pendingCloseCount++;
			}
			
			if (_pendingCloseCount == 0)
			{
				_finishClosing();
			}
		}
		
		
		private function conn_close(event:SQLEvent):void
		{
			var conn:SQLConnection = event.target as SQLConnection;
			conn.removeEventListener(SQLEvent.CLOSE, conn_close);
			conn.removeEventListener(SQLErrorEvent.ERROR, conn_closeError);
			
			_pendingCloseCount--;
			
			if (_pendingCloseCount == 0)
			{
				_finishClosing();
			}
		}
		
		
		private function conn_closeError(event:SQLErrorEvent):void
		{
			if (event.error.operation != SQLErrorOperation.CLOSE)
				return;
			
			var conn:SQLConnection = event.target as SQLConnection;
			conn.removeEventListener(SQLEvent.CLOSE, conn_close);
			conn.removeEventListener(SQLErrorEvent.ERROR, conn_closeError);
			
			_pendingCloseErrorHandler(event.error);
		}
		
		
		private function _finishClosing():void
		{
			while (_pending.length > 0)
				_pending.shift();
			while (_available.length > 0)
				_available.shift();
			while (_blockedPending != null && _blockedPending.length > 0)
				_blockedPending.shift();
			while (_blockingPending != null && _blockingPending.length > 0)
				_blockingPending.shift();
			
			_blockingConnection = null;
			
			_pendingCloseHandler();
		}
	}
}