/*
For the latest version of this code, visit:
http://probertson.com/projects/air-sqlite/

Copyright (c) 2009-2011 H. Paul Robertson

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
	import flash.data.SQLStatement;
	import flash.utils.Dictionary;
	
	public class StatementCache
	{
		
		public function StatementCache(sql:String)
		{
			_sql = sql;
		}
		
		
		// ------- Member vars -------
		private var _sql:String;
		private var _preferredConnections:Vector.<SQLConnection>;
		private var _cache:Dictionary;
		
		
		// ------- Public properties -------
		public function get preferredConnections():Vector.<SQLConnection>
		{
			if (_preferredConnections == null || _preferredConnections.length == 0)
			{
				return null;
			}
			return _preferredConnections;
		}
		
		
		// ------- Public methods -------
		public function getStatementForConnection(conn:SQLConnection):SQLStatement
		{
			var result:SQLStatement = null;
			if (_cache == null)
			{
				_cache = new Dictionary();
				_preferredConnections = new Vector.<SQLConnection>();
			}
			else
			{
				result = _cache[conn]; 
			}
			
			if (result == null)
			{
				result = new SQLStatement();
				result.sqlConnection = conn;
				result.text = _sql;
				_cache[conn] = result;
				_preferredConnections.push(conn);
			}
			
			return result;
		}
	}
}