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
package com.probertson.data
{
	/**
	 * A QueuedStatement object bundles together the values representing a single
	 * SQL statement that's executed as part of a batch of SQL statements.
	 * 
	 * @see SQLRunner#executeModify()
	 */
	public class QueuedStatement
	{
		/**
		 * Creates a new QueuedStatement object.
		 * @param sql	The SQL text of the statement to execute
		 * @param parameters	An object (associative array) containing the names
		 * 						and values of the parameters used in the statement.
		 * 						The parameter names are the property names of the 
		 * 						object, and the parameter values are the property 
		 * 						values. The parameter names in the <code>sql</code>
		 * 						parameter should use a colon (":") prefix.
		 */
		public function QueuedStatement(sql:String, parameters:Object=null)
		{
			_statementText = sql;
			_parameters = parameters;
		}
		
		// ------- Public properties -------
		
		private var _statementText:String;
		/**
		 * The SQL text of the statement to execute
		 */
		public function get statementText():String { return _statementText; }
		
		
		
		private var _parameters:Object;
		/**
		 * An object (associative array) containing the names and values of the 
		 * parameters used in the statement.
		 */
		public function get parameters():Object { return _parameters; }
	}
}