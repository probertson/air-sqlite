INSERT INTO main.testTable
(
	foo, -- doesn't exist, so throws an error
	colInt
)
VALUES
(
	:colString,
	:colInt
)