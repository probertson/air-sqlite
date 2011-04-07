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
	import flash.errors.SQLError;
	import flash.text.TextField;
	
	/**
	 * A Responder object provides a container to specify a result handler
	 * function and an error handler function in a single object.
	 * 
	 * <p>Use a Responder object to specify the handler methods for the
	 * <code>SQLRunnerUnpooled.execute()</code> method.</p>
	 * 
	 * @see SQLRunnerUnpooled#execute()
	 */
	public class Responder
	{
		/**
		 * Creates a new Responder object.
		 * 
		 * @param result	The function that is called when statement 
		 * 					execution finishes correctly.
		 * @param error		The function that is called when an error
		 * 					happens during statement execution.
		 */
		public function Responder(result:Function, error:Function=null)
		{
			_result = result;
			_error = error;
		}

		// ------- Public properties -------
		
		private var _result:Function;
		
		/**
		 * The function that is called when statement execution finishes correctly.
		 */
		public function get result():Function
		{
			return _result;
		}
		
		
		private var _error:Function;
		
		/**
		 * The function that is called when an error happens during statement 
		 * execution.
		 */
		public function get error():Function
		{
			return _error;
		}
	}
}