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
	import com.probertson.data.Responder;
	
	public class PendingStatementUnpooled
	{
		
		public function PendingStatementUnpooled(sql:String, parameters:Object, responder:Responder, itemClass:Class) 
		{
			_sql = sql;
			_parameters = parameters;
			_responder = responder;
			_itemClass = itemClass;
		}
		
		
		// ------- Public properties -------
		
		private var _sql:String;
		
		public function get sql():String
		{
			return _sql;
		}
		
		
		private var _parameters:Object;
		
		public function get parameters():Object
		{
			return _parameters;
		}
		
		
		private var _responder:Responder;
		
		public function get responder():Responder
		{
			return _responder;
		}
		
		
		private var _itemClass:Class;
		
		public function get itemClass():Class
		{
			return _itemClass;
		}
	}
}