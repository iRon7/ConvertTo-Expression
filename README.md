# ConvertTo-PSON
Serializes an object to a PowerShell expression

The ConvertTo-Pson cmdlet converts any object to a string in PowerShell Object
Notation (PSON) format. The properties are converted to field names, the field
values are converted to property values, and the methods are removed.
You can then use the ConvertFrom-Pson (Invoke-Expression) cmdlet to convert a
PSON-formatted string to a PowerShell object, which is easily managed in
Windows PowerShell.

## Examples

###Convert a Calendar object to a PowerShell expression

PS C:\>(Get-UICulture).Calendar | ConvertTo-Pson

[PSCustomObject]@{
	'AlgorithmType' = 'SolarCalendar'
	'CalendarType' = 'Localized'
	'Eras' = 1
	'IsReadOnly' = $False
	'MaxSupportedDateTime' = [DateTime]'9999-12-31T23:59:59.9999999'
	'MinSupportedDateTime' = [DateTime]'0001-01-01T00:00:00.0000000'
	'TwoDigitYearMax' = 2029
}

.EXAMPLE 

PS C:\>@{Account="User01";Domain="Domain01";Admin="True"} | ConvertTo-Pson -Expand -1	# Compress the PSON output

@{'Admin'='True';'Account'='User01';'Domain'='Domain01'}


.EXAMPLE 

PS C:\>Get-Date | Select-Object -Property * | ConvertTo-Pson	# Convert an object to a PSON string and PSON object

[PSCustomObject]@{
	'Date' = [DateTime]'2018-01-09T00:00:00.0000000+01:00'
	'DateTime' = 'Tuesday, January 9, 2018 7:22:57 PM'
	'Day' = 9
	'DayOfWeek' = 'Tuesday'
	'DayOfYear' = 9
	'DisplayHint' = 'DateTime'
	'Hour' = 19
	'Kind' = 'Local'
	'Millisecond' = 671
	'Minute' = 22
	'Month' = 1
	'Second' = 57
	'Ticks' = 636511225776716485
	'TimeOfDay' = [TimeSpan]'19:22:57.6716485'
	'Year' = 2018
}

PS C:\>Get-Date | Select-Object -Property * | ConvertTo-Pson | ConvertFrom-Pson

Date        : 2018-01-09 12:00:00 AM
DateTime    : Tuesday, January 9, 2018 7:27:43 PM
Day         : 9
DayOfWeek   : Tuesday
DayOfYear   : 9
DisplayHint : DateTime
Hour        : 19
Kind        : Local
Millisecond : 76
Minute      : 27
Month       : 1
Second      : 43
Ticks       : 636511228630764893
TimeOfDay   : 19:27:43.0764893
Year        : 2018

.EXAMPLE 

PS C:\>WinInitProcess = Get-Process WinInit | ConvertTo-Pson	# Convert the WinInit Process to PSON format

## Parameters 

`InputObject`  
Specifies the objects to convert to JSON format. Enter a variable that contains
the objects, or type a command or expression that gets the objects. You can also
pipe an object to ConvertTo-Json.

`Depth`  
Specifies how many levels of contained objects are included in the JSON
representation. The default value is 9.

`Expand`  
Specifies till what level the contained objects are expanded over separate lines
and indented according to the -Indentation and -IndentChar parameters.
The default value is 9.

A negative value will remove redundant spaces and compress the PSON expression to
a single line (except for multiline strings).

Xml documents and multiline strings are embedded in a "here string" and aligned
to the left.

`Indentation`  
Specifies how many IndentChars to write for each level in the hierarchy.

`IndentChar`  
Specifies which character to use for indenting.

`Type`  
Defines how the explicite the object type is being parsed:

	`-Type None`  
	No type information will be added to the (embedded) objects and values in
	the PSON string. This means that objects and values will be parsed to any
	of these data types when reading them back with ConvertFrom-Pson
	(Invoke-Expression): a numeric value, a [String] ('...'), an [Array] 
	(@(...)) or a [HashTable] (@{...}).

	`-Type Native`  
	The original type prefix is added to the (embedded) objects and values in
	the PSON string. Note that most system (.Net) objects can’t be read back
	with ConvertFrom-Pson (Invoke-Expression), but -SetType Name can help to
	reveal (embedded) object types and hierarchies.

	`-Type Cast` (Default)  
	The type prefix is only added to (embedded) objects and values when required
	and optimized for read back with ConvertFrom-Pson (Invoke-Expression) by e.g.
	converting system (.Net) objects to PSCustomObject objects. Numeric values
	won't have a strict type and therefor parsed to the default type that fits
	the value when read back with ConvertFrom-Pson (Invoke-Expression).

	`-Type Strict`
	All (embedded) objects and values will have an explicit type prefix optimized
	for read back with ConvertFrom-Pson (Invoke-Expression) by e.g. converting
	system (.Net) objects to PSCustomObject objects.

`NewLine`  
	Specifies which characters to use for a new line. The default is defined by
	the operating system.

