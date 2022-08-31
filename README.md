# ConvertTo-Expression
Serializes an object to a PowerShell expression.
## [Syntax](#syntax)
```PowerShell
ConvertTo-Expression
    [-Object <Object>]
    [-Depth <Int32>]
    [-Expand <Int32>]
    [-Indentation <Int32>]
    [-IndentChar <String>]
    [-Strong]
    [-Explore]
    [-TypeNaming <String>]
    [-NewLine <String>]
    [<CommonParameters>]
```
## [Description](#description)
 The ConvertTo-Expression cmdlet converts (serializes) an object to a  
PowerShell expression. The object can be stored in a variable,  file or  
any other common storage for later use or to be ported to another  
system.  
  
An expression can be restored to an object using the native  
Invoke-Expression cmdlet:  
  
$Object = Invoke-Expression ($Object | ConverTo-Expression)  
  
Or Converting it to a [ScriptBlock] and invoking it with cmdlets  
along with Invoke-Command or using the call operator (&amp;):  
  
$Object = &amp;([ScriptBlock]::Create($Object | ConverTo-Expression))  
  
An expression that is stored in a PowerShell (.ps1) file might also  
be directly invoked by the PowerShell dot-sourcing technique,  e.g.:  
  
$Object | ConvertTo-Expression | Out-File .\Expression.ps1  
$Object = . .\Expression.ps1  
  
Warning: Invoking partly trusted input with Invoke-Expression or  
[ScriptBlock]::Create() methods could be abused by malicious code  
injections.

## [Examples](exampls)
### Example 1
```PowerShell
(Get-UICulture).Calendar | ConvertTo-Expression
[pscustomobject]@{
    'AlgorithmType' = 1
    'CalendarType' = 1
    'Eras' = , 1
    'IsReadOnly' = $False
    'MaxSupportedDateTime' = [datetime]'9999-12-31T23:59:59.9999999'
    'MinSupportedDateTime' = [datetime]'0001-01-01T00:00:00.0000000'
    'TwoDigitYearMax' = 2029
}
```
### Example 2
```PowerShell
(Get-UICulture).Calendar | ConvertTo-Expression -Strong
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
### Example 3
```PowerShell
Get-Date | Select-Object -Property * | ConvertTo-Expression | Out-File .\Now.ps1
PS> $Now = .\Now.ps1	# $Now = Get-Content .\Now.Ps1 -Raw | Invoke-Expression
PS> $Now
Date        : 1963-10-07 12:00:00 AM
DateTime    : Monday,  October 7,  1963 10:47:00 PM
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
### Example 4
```PowerShell
@{Account="User01";Domain="Domain01";Admin="True"} | ConvertTo-Expression -Expand -1	# Compress the PowerShell output
@{'Admin'='True';'Account'='User01';'Domain'='Domain01'}
```
### Example 5
```PowerShell
WinInitProcess = Get-Process WinInit | ConvertTo-Expression	# Convert the WinInit Process to a PowerShell expression
```
### Example 6
```PowerShell
Get-Host | ConvertTo-Expression -Depth 4	# Reveal complex object hierarchies
```
## [Parameters](#parameters)
### `-Object`
| <!--                    --> | <!-- --> |
| --------------------------- | -------- |
| Type:                       | [Object](https://docs.microsoft.com/en-us/dotnet/api/System.Object) |
| Position:                   | 1 |
| Default value:              |  |
| Accept pipeline input:      | true (ByValue) |
| Accept wildcard characters: | false |
### `-Depth`
 Specifies how many levels of contained objects are included in the  
PowerShell representation. The default value is 9.

| <!--                    --> | <!-- --> |
| --------------------------- | -------- |
| Type:                       | [Int32](https://docs.microsoft.com/en-us/dotnet/api/System.Int32) |
| Position:                   | 2 |
| Default value:              | 9 |
| Accept pipeline input:      | false |
| Accept wildcard characters: | false |
### `-Expand`
 Specifies till what level the contained objects are expanded over  
separate lines and indented according to the -Indentation and  
-IndentChar parameters. The default value is equal to the -Depth value.  
  
A negative value will remove redundant spaces and compress the  
PowerShell expression to a single line (except for multi-line strings).  
  
Xml documents and multi-line strings are embedded in a &quot;here string&quot;  
and aligned to the left.

| <!--                    --> | <!-- --> |
| --------------------------- | -------- |
| Type:                       | [Int32](https://docs.microsoft.com/en-us/dotnet/api/System.Int32) |
| Position:                   | 3 |
| Default value:              | $Depth |
| Accept pipeline input:      | false |
| Accept wildcard characters: | false |
### `-Indentation`
 Specifies how many IndentChars to write for each level in the  
hierarchy.

| <!--                    --> | <!-- --> |
| --------------------------- | -------- |
| Type:                       | [Int32](https://docs.microsoft.com/en-us/dotnet/api/System.Int32) |
| Position:                   | 4 |
| Default value:              | 4 |
| Accept pipeline input:      | false |
| Accept wildcard characters: | false |
### `-IndentChar`
 Specifies which character to use for indenting.

| <!--                    --> | <!-- --> |
| --------------------------- | -------- |
| Type:                       | [String](https://docs.microsoft.com/en-us/dotnet/api/System.String) |
| Position:                   | 5 |
| Default value:              |  |
| Accept pipeline input:      | false |
| Accept wildcard characters: | false |
### `-Strong`
 By default,  the ConvertTo-Expression cmdlet will return a weakly typed  
expression which is best for transfing objects between differend  
PowerShell systems.  
The -Strong parameter will strickly define value types and objects  
in a way that they can still be read by same PowerShell system and  
PowerShell system with the same configuration (installed modules etc.).

| <!--                    --> | <!-- --> |
| --------------------------- | -------- |
| Type:                       | [SwitchParameter](https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter) |
| Position:                   | named |
| Default value:              | False |
| Accept pipeline input:      | false |
| Accept wildcard characters: | false |
### `-Explore`
 In explore mode,  all type prefixes are omitted in the output expression  
(objects will cast to to hash tables). In case the -Strong parameter is  
also supplied,  all orginal (.Net) type names are shown.  
The -Explore switch is usefull for exploring object hyrachies and data  
type,  not for saving and transfering objects.

| <!--                    --> | <!-- --> |
| --------------------------- | -------- |
| Type:                       | [SwitchParameter](https://docs.microsoft.com/en-us/dotnet/api/System.Management.Automation.SwitchParameter) |
| Position:                   | named |
| Default value:              | False |
| Accept pipeline input:      | false |
| Accept wildcard characters: | false |
### `-TypeNaming`
| <!--                    --> | <!-- --> |
| --------------------------- | -------- |
| Accepted values:            | Name, Fullname, Auto |
| Type:                       | [String](https://docs.microsoft.com/en-us/dotnet/api/System.String) |
| Position:                   | 6 |
| Default value:              | Auto |
| Accept pipeline input:      | false |
| Accept wildcard characters: | false |
### `-NewLine`
| <!--                    --> | <!-- --> |
| --------------------------- | -------- |
| Type:                       | [String](https://docs.microsoft.com/en-us/dotnet/api/System.String) |
| Position:                   | 7 |
| Default value:              | [System.Environment]::NewLine |
| Accept pipeline input:      | false |
| Accept wildcard characters: | false |
## [Inputs](#inputs)
### Any. Each objects provided through the pipeline will converted to an
expression. To concatinate all piped objects in a single expression,
use the unary comma operator,  e.g.: ,$Object | ConvertTo-Expression
## [Outputs](#outputs)
### [String[]](https://docs.microsoft.com/en-us/dotnet/api/System.String[])
## [Related Links](#related-links)
* [https://www.powershellgallery.com/packages/ConvertFrom-Expression](https://www.powershellgallery.com/packages/ConvertFrom-Expression)
