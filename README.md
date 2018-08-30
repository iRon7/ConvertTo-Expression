# ConvertTo-Expression
Serializes an object to a PowerShell expression

The ConvertTo-Expression cmdlet converts (serializes) an object to
a PowerShell expression. The object can be stored in a variable,
file or any other common storage for later use or to be ported to
another system.

#### Converting back *from* an expression  
An expression can be restored to an object by preceding it with an
ampersand (`&`). An expression that is casted to a string can be
restored to an object using the native `Invoke-Expression` cmdlet.
An expression that is stored in a PowerShell (`.ps1`) file might also
be directly invoked by the PowerShell dot-sourcing technique, e.g.:
`. .\Expression.ps1`.


## Examples

Convert a Calendar object to a PowerShell expression:

```powershell
PS C:\> $Calendar = (Get-UICulture).Calendar | ConvertTo-Expression

PS C:\> $Calendar

[PSCustomObject]@{
		'AlgorithmType' = 'SolarCalendar'
		'CalendarType' = 'Localized'
		'Eras' = 1
		'IsReadOnly' = $False
		'MaxSupportedDateTime' = [DateTime]'9999-12-31T23:59:59.9999999'
		'MinSupportedDateTime' = [DateTime]'0001-01-01T00:00:00.0000000'
		'TwoDigitYearMax' = 2029
}

PS C:\> &$Calendar

AlgorithmType        : SolarCalendar
CalendarType         : Localized
Eras                 : 1
IsReadOnly           : False
MaxSupportedDateTime : 9999-12-31 11:59:59 PM
MinSupportedDateTime : 0001-01-01 12:00:00 AM
TwoDigitYearMax      : 2029
```

Save an object in a file and to restore it later:

```powershell
PS C:\>Get-Date | Select-Object -Property * | ConvertTo-Expression | Out-File .\Now.ps1

PS C:\>$Now = .\Now.ps1	# Simular to: $Now = Get-Content .\Now.Ps1 -Raw | Invoke-Expression

PS C:\>$Now

Date        : 1963-10-07 12:00:00 AM
DateTime    : Monday, October 7, 1963 10:47:00 PM
Day         : 7
DayOfWeek   : Monday
DayOfYear   : 280
DisplayHint : DateTime
Hour        : 22
Kind        : Local
Millisecond : 0
Minute      : 22
Month       : 1
Second      : 0
Ticks       : 619388596200000000
TimeOfDay   : 22:47:00
Year        : 1963
```

Compress the PowerShell expression output:

```powershell
PS C:\>@{Account="User01";Domain="Domain01";Admin="True"} | ConvertTo-Expression -Expand -1	

@{'Admin'='True';'Account'='User01';'Domain'='Domain01'}
```

Convert the WinInit Process to a PowerShell expression:

```powershell
PS C:\>WinInitProcess = Get-Process WinInit | ConvertTo-Expression
```
Reveal complex object hierarchies:

```powershell
PS C:\>Get-Host | ConvertTo-Expression -Depth 4
```

## Parameters 

`-InputObject`  
Specifies the objects to convert to a PowerShell expression. Enter
a variable that contains the objects, or type a command or
expression that gets the objects. You can also pipe one or more
objects to `ConvertTo-Expression`.

`-Depth`  
Specifies how many levels of contained objects are included in the 
PowerShell representation. The default value is `9`.

`-Expand`  
Specifies till what level the contained objects are expanded over
separate lines and indented according to the `-Indentation` and 
`-IndentChar` parameters. The default value is `9`.

A negative value will remove redundant spaces and compress the
PowerShell expression to a single line (except for multi-line
strings).

Xml documents and multi-line strings are embedded in a
"here string" and aligned to the left.

`-Indentation`  
Specifies how many IndentChars to write for each level in the hierarchy.

`-IndentChar`  
Specifies which character to use for indenting.

`-TypePrefix`  
Defines how the explicite the object type is being parsed:

`-TypePrefix None`  
No type information will be added to the (embedded) objects and
values in the PowerShell expression. This means that objects
and values will be parsed to one of the following data types
when reading them back with `Invoke-Expression`: a numeric value,
a `[String] ('...')`, an `[Array] (@(...))` or a
`[HashTable] (@{...})`.

`-TypePrefix Native`  
The original type prefix is added to the (embedded) objects and
values in the PowerShell expression. Note that most system
(.Net) objects can’t be read back with `Invoke-Expression`, but
option might help to reveal (embedded) object types and
hierarchies.

`-TypePrefix Cast` (Default)  
The type prefix is only added to (embedded) objects and values
when required and optimized for read back with
Invoke-Expression by e.g. converting system (.Net) objects to
PSCustomObject objects. Numeric values won't have a strict
type and therefor parsed to the default type that fits the
value when restored.

`-TypePrefix Strict`
All (embedded) objects and values will have an explicit type
prefix optimized for read back with `Invoke-Expression` by e.g.
converting system (.Net) objects to PSCustomObject objects.

`-NewLine`  
Specifies which characters to use for a new line. The default is defined by
the operating system.
