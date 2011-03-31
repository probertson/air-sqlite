The air-sqlite project is a set of utility classes to make it easier to work with
SQLite databases using Adobe AIR while following good practices for performance.

Reference documentation is available here: [air-sqlite language reference "asdocs"](http://probertson.com/resources/projects/air-sqlite/asdoc/)

For more information about the design philosophy see the project page here: [air-sqlite project page](http://probertson.com/projects/air-sqlite/)

The primary utility is the SQLRunner class, which provides a way to execute SQL statements.
The statements are executed using a pool of database connections so SELECT statements
are executed at the same time (as long as database connections are available in the 
pool).

SELECT example
--------------

Here is a basic usage example for a SELECT statement, which uses the SQLRunner.execute()
method:

    // setup code:
    // define database file location
    var dbFile:File = File.applicationStorageDirectory.resolvePath("myDatabase.db");
    // create the SQLRunner
    var sqlRunner:SQLRunner = new SQLRunner(dbFile);
    
    // ...
    
    // run the statement, passing in one parameter (":employeeId" in the SQL)
    // the statement returns an Employee object as defined in the 4th parameter
    sqlRunner.execute(LOAD_EMPLOYEE_SQL, {employeeId:102}, resultHandler, Employee);
    
    private function resultHandler(result:SQLResult):void
    {
    	var employee:Employee = result.data[0];
    	// do something with the employee data
    }
    
    // constant for actual SQL statement text
    [Embed(source="sql/LoadEmployee.sql", mimeType="application/octet-stream")]
    private static const LoadEmployeeStatementText:Class;
    private static const LOAD_EMPLOYEE_SQL:String = new LoadEmployeeStatementText();

The SQL statement for this example is as follows:

    SELECT firstName,
        lastName,
        email,
        phone
    FROM main.employees
    WHERE employeeId = :employeeId

INSERT/UPDATE/DELETE example
----------------------------

Here is a basic example for an INSERT/UPDATE/DELETE statement. To execute those statements
use the executeModify() method. The executeModify() method accepts a "batch" of statements
(a Vector of QueuedStatement objects). If you pass more than one statement together in a batch,
the batch executes as a single transaction.

    var insert:QueuedStatement = new QueuedStatement(INSERT_EMPLOYEE_SQL, {firstName:"John", lastName:"Smith"});
    var update:QueuedStatement = new QueuedStatement(UPDATE_EMPLOYEE_SALARY_SQL, {employeeId:100, salary:1000});
    var statementBatch:Vector.<QueuedStatement> = Vector.<QueuedStatement>([insert, update]);
    
    sqlRunner.executeModify(statementBatch, resultHandler, errorHandler, progressHandler);
    
    private function resultHandler(results:Vector.<SQLResult>):void
    {
    	// all operations done
    }
    
    private function errorHandler(error:SQLError):void
    {
    	// something went wrong
    }
    
    private function progressHandler(numStepsComplete:uint, totalSteps:uint):void
    {
    	var progressPercent:int = numStepsComplete / totalSteps;
    }
    
    // constants for actual SQL statement text
    [Embed(source="sql/InsertEmployee.sql", mimeType="application/octet-stream")]
    private static const InsertEmployeeStatementText:Class;
    private static const INSERT_EMPLOYEE_SQL:String = new InsertEmployeeStatementText();
    
    [Embed(source="sql/UpdateEmployeeSalary.sql", mimeType="application/octet-stream")]
    private static const UpdateEmployeeSalaryStatementText:Class;
    private static const UPDATE_EMPLOYEE_SALARY_SQL:String = new UpdateEmployeeSalaryStatementText();