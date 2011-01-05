package com.probertson.data
{
	/**
	 * The CopyProgressPhase defines constants representing the steps in
	 * the process of copying (and optionally encrypting) a database. These 
	 * values are the possible values for the <code>DBCopier.currentStep</code> 
	 * property.
	 * 
	 * <p>The DBCopier instance dispatches a <code>progress</code> event as it 
	 * makes progress on the copy/encrypt operation. At certain points it also 
	 * updates the <code>currentStep</code> property to indicate the part of
	 * the process that it's currently working on.</p>
	 * 
	 * @see DBCopier#currentStep
	 * @see DBCopier#event:progress
	 */
	public class CopyProgressPhase
	{
		/**
		 * Indicates that the DBCopier has been created but the copy/encryption process
		 * has not yet started.
		 */
		public static const PRE_INIT:String = "preInit";
		
		/**
		 * 
		 */
		public static const INIT:String = "init";
		public static const BEGIN:String = "begin";
		public static const CREATE_TABLES:String = "createTables";
		public static const CREATE_INDICES:String = "createIndices";
		public static const CREATE_VIEWS:String = "createViews";
		public static const CREATE_TRIGGERS:String = "createTriggers";
		public static const COPY_TABLE_DATA:String = "copyTableData";
		public static const CLOSE:String = "close";
		public static const COMPLETE:String = "complete";
	}
}