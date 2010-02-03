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
	import flash.events.SQLEvent;
	
	public class PendingStatement 
	{
		
		public function PendingStatement(cache:StatementCache, parameters:Object, handler:Function, itemClass:Class) 
		{
			_cache = cache;
			_parameters = parameters;
			_handler = handler;
			_itemClass = itemClass;
		}
		
		
		// ------- Member vars -------
		private var _cache:StatementCache;
		private var _parameters:Object;
		private var _handler:Function;
		private var _itemClass:Class;
		private var _pool:ConnectionPool;
		
		
		// ------- Public properties -------
		public function get statementCache():StatementCache { return _cache; }
		
		
		// ------- Public methods -------
		public function executeWithConnection(pool:ConnectionPool, conn:SQLConnection):void
		{
			_pool = pool;
			
			var stmt:SQLStatement = _cache.getStatementForConnection(conn);
			stmt.addEventListener(SQLEvent.RESULT, stmt_result);
			if (_itemClass != null)
			{
				stmt.itemClass = _itemClass;
			}
			
			stmt.clearParameters();
			if (_parameters != null)
			{
				for (var prop:String in _parameters)
				{
					stmt.parameters[":" + prop] = _parameters[prop];
				}
			}
			
			stmt.execute();
		}
		
		
		// ------- Event handling -------
		private function stmt_result(event:SQLEvent):void
		{
			var stmt:SQLStatement = event.target as SQLStatement;
			stmt.removeEventListener(SQLEvent.RESULT, stmt_result);
			var result:SQLResult = stmt.getResult();
			_pool.returnConnection(stmt.sqlConnection);
			_handler(result);
		}
	}
}