# ConvertTo-Expression
Serializes an object to a PowerShell expression

The ConvertTo-Expression cmdlet converts (serializes) an object to
a PowerShell expression. The object can be stored in a variable,
file or any other common storage for later use or to be ported to
another system.

### Installation

The `ConvertTo-Expression` script can be downloaded from the [PowerShell Gallery](https://www.powershellgallery.com/):
```powershell
Install-Script -Name ConvertTo-Expression
```
As it concerns a standalone script, installation isn't really required. If you don't have administrator rights, you might just download the script (or copy it) to the required location. You might than simply invoke the script using PowerShell [`dot sourcing`](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-7#script-scope-and-dot-sourcing):
```powershell
. .\ConvertTo-Expression.ps1
```

#### Converting back *from* an expression  
An expression can be restored to an object using the native
`Invoke-Expression` cmdlet:
```powershell
$Object = Invoke-Expression ($Object | ConverTo-Expression)
```
Or Converting it to a `[ScriptBlock]` and invoking it with cmdlets
along with `Invoke-Command` or using the call operator (`&`):
```powershell
$Object = &([ScriptBlock]::Create($Object | ConverTo-Expression))
```
An expression that is stored in a PowerShell (`.ps1`) file might also
be directly invoked by the PowerShell dot-sourcing technique, e.g.:
```powershell
$Object | ConvertTo-Expression | Out-File .\Expression.ps1
$Object = . .\Expression.ps1
```
***Warning:*** Invoking partly trusted input with Invoke-Expression or
`[ScriptBlock]::Create()` methods could be abused by malicious code
injections.

## Examples

Convert a Calendar object to a PowerShell expression:

```powershell
PS C:\> (Get-UICulture).Calendar | ConvertTo-Expression

[pscustomobject]@{
	'AlgorithmType' = 1
	'CalendarType' = 1
	'Eras' = ,1
	'IsReadOnly' = $False
	'MaxSupportedDateTime' = [datetime]'9999-12-31T23:59:59.9999999'
	'MinSupportedDateTime' = [datetime]'0001-01-01T00:00:00.0000000'
	'TwoDigitYearMax' = 2029
}

PS C:\> (Get-UICulture).Calendar | ConvertTo-Expression -Strong

[pscustomobject]@{
	'AlgorithmType' = [System.Globalization.CalendarAlgorithmType]'SolarCalendar'
	'CalendarType' = [System.Globalization.GregorianCalendarTypes]'Localized'
	'Eras' = [array][int]1
	'IsReadOnly' = [bool]$False
	'MaxSupportedDateTime' = [datetime]'9999-12-31T23:59:59.9999999'
	'MinSupportedDateTime' = [datetime]'0001-01-01T00:00:00.0000000'
	'TwoDigitYearMax' = [int]2029
}
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
## Inputs
`Any`. Each objects provided through the pipeline will converted to an
expression. To concatinate all piped objects in a single expression,
use the unary comma operator, e.g.: `,$Object | ConvertTo-Expression`

## Outputs
`String[]`. ConvertTo-Expression returns a PowerShell expression for
each input object.

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

`-Strong`  
By default, the `ConvertTo-Expression` cmdlet will return a weakly typed
expression which is best for transfing objects between differend
PowerShell systems.
The `-Strong` parameter will strickly define value types and objects
in a way that they can still be read by same PowerShell system and
PowerShell system with the same configuration (installed modules etc.).

`-Explore`  
In explore mode, all type prefixes are omitted in the output expression
(objects will cast to to hash tables). In case the `-Strong` parameter is
also supplied, all *orginal* (.Net) type names are shown.
The `-Explore` switch is usefull for exploring object hyrachies and data
type, not for saving and transfering objects.

`-NewLine`  
Specifies which characters to use for a new line. The default is defined by
the operating system.
