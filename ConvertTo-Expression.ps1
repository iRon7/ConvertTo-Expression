<#PSScriptInfo
.VERSION 2.6.0
.GUID 5f167621-6abe-4153-a26c-f643e1716720
.AUTHOR Ronald Bode (iRon)
.DESCRIPTION Serializes an object to a PowerShell expression (PSON, PowerShell Object Notation).
.COMPANYNAME 
.COPYRIGHT 
.TAGS PSON PowerShell Object Notation expression serialize
.LICENSEURI https://github.com/iRon7/ConvertTo-Expression/LICENSE.txt
.PROJECTURI https://github.com/iRon7/ConvertTo-Expression
.ICONURI https://raw.githubusercontent.com/iRon7/ConvertTo-Expression/master/ConvertTo-Expression.png
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES
.PRIVATEDATA 
#>

Function ConvertTo-Expression {
<#
	.SYNOPSIS
		Serializes an object to a PowerShell expression.

	.DESCRIPTION
		The ConvertTo-Expression cmdlet converts (serializes) an object to
		a PowerShell expression. The object can be stored in a variable,
		file or any other common storage for later use or to be ported to
		another system.

		Convert from expression
		An expression can be restored to an object by preceding it with an
		ampersand (&). An expression that is casted to a string can be
		restored to an object using the native Invoke-Expression cmdlet.
		An expression that is stored in a PowerShell (.ps1) file might also
		be directly invoked by the PowerShell dot-sourcing technique.

	.PARAMETER InputObject
		Specifies the objects to convert to a PowerShell expression. Enter
		a variable that contains the objects, or type a command or
		expression that gets the objects. You can also pipe one or more
		objects to ConvertTo-Expression.

	.PARAMETER Depth
		Specifies how many levels of contained objects are included in the 
		PowerShell representation. The default value is 9.

	.PARAMETER Expand
		Specifies till what level the contained objects are expanded over
		separate lines and indented according to the -Indentation and 
		-IndentChar parameters. The default value is 9.
		
		A negative value will remove redundant spaces and compress the
		PowerShell expression to a single line (except for multi-line
		strings).
		
		Xml documents and multi-line strings are embedded in a
		"here string" and aligned to the left.
		
	.PARAMETER Indentation
		Specifies how many IndentChars to write for each level in the
		hierarchy.

	.PARAMETER IndentChar
		Specifies which character to use for indenting.

	.PARAMETER TypePrefix
		Defines how the explicit the object type is being parsed:

		-TypePrefix None
			No type information will be added to the (embedded) objects and
			values in the PowerShell expression. This means that objects
			and values will be parsed to one of the following data types
			when reading them back with Invoke-Expression: a numeric value,
			a [String] ('...'), an [Array] (@(...)) or a [HashTable]
			(@{...}).

		-TypePrefix Native
			The original type prefix is added to the (embedded) objects and
			values in the PowerShell expression. Note that most system
			(.Net) objects can’t be read back with Invoke-Expression, but
			option might help to reveal (embedded) object types and
			hierarchies.

		-TypePrefix Cast (Default)
			The type prefix is only added to (embedded) objects and values
			when required and optimized for read back with
			Invoke-Expression by e.g. converting system (.Net) objects to
			PSCustomObject objects. Numeric values won't have a strict
			type and therefor parsed to the default type that fits the
			value when restored.

		-TypePrefix Strict
			All (embedded) objects and values will have an explicit type
			prefix optimized for read back with Invoke-Expression by e.g.
			converting system (.Net) objects to PSCustomObject objects.

	.PARAMETER NewLine
		Specifies which characters to use for a new line. The default is
		defined by the operating system.

	.PARAMETER Iteration
		Do not use (for internal use only).

	.EXAMPLE 

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

	.EXAMPLE 

		PS C:\>Get-Date | Select-Object -Property * | ConvertTo-Expression | Out-File .\Now.ps1

		PS C:\>$Now = .\Now.ps1	# $Now = Get-Content .\Now.Ps1 -Raw | Invoke-Expression

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

	.EXAMPLE 

		PS C:\>@{Account="User01";Domain="Domain01";Admin="True"} | ConvertTo-Expression -Expand -1	# Compress the PowerShell output

		@{'Admin'='True';'Account'='User01';'Domain'='Domain01'}

	.EXAMPLE 

		PS C:\>WinInitProcess = Get-Process WinInit | ConvertTo-Expression	# Convert the WinInit Process to a PowerShell expression

	.EXAMPLE 

		PS C:\>Get-Host | ConvertTo-Expression -Depth 4	# Reveal complex object hierarchies

	.LINK
		Invoke-Expression (Alias ConvertFrom-Pson)
#>
	[CmdletBinding()][OutputType([ScriptBlock])]Param (
		[Parameter(ValueFromPipeLine = $True)][Alias('InputObject')]$Object, [Int]$Depth = 9, [Int]$Expand = 9,
		[Int]$Indentation = 1, [String]$IndentChar = "`t", [ValidateSet("None", "Native", "Cast", "Strict")][String]$TypePrefix = "Cast",
		[String]$NewLine = [System.Environment]::NewLine, [Int]$Iteration = 0
	)
	$PipeLine = $Input | ForEach-Object {$_}; If ($PipeLine) {$Object = $PipeLine}
	$NumberTypes = @{}; "byte", "int16", "int32", "int64", "sbyte", "uint16", "uint32", "uint64", "float", "double", "decimal" | ForEach-Object {$NumberTypes[$_] = $Null}
	$TypeAccelerators = @{}; [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() | ForEach-Object {$TypeAccelerators[$_.Value] = $_.Key}
	Function Iterate ($Value) {ConvertTo-Expression $Value $Depth $Expand $Indentation $IndentChar $TypePrefix $NewLine ($Iteration + 1)}
	Function Embed ($List, $Dictionary) {If ($Iteration -ge $Depth) {If ($Null -ne $Dictionary) {Return "@{}"} Else {Return "@()"}}
		$Items = ForEach ($Key in $List) {If ($Null -ne $Dictionary) {"'$Key'$Space=$Space" + (Iterate $Dictionary.$Key)} Else {Iterate $Key}}
		$Open, $Join, $Separator, $Close = If ($Null -ne $Dictionary) {"@{", ";$Space", "$LineUp$Tab", "}"} Else {"@(", ",$Space", ",$LineUp$Tab", ")"}
		$Open + (&{If (($Iteration -ge $Expand) -or (@($Items).Count -le 1)) {$Items -Join $Join} Else {"$LineUp$Tab$($Items -Join $Separator)$LineUp"}}) + $Close
	}
	$Expression = If ($Null -eq $Object) {"`$Null"} Else {
		$Space = If ($Iteration -gt $Expand) {""} Else {" "}; $Tab = $IndentChar * $Indentation; $LineUp = "$NewLine$($Tab * $Iteration)"
		$SystemType = $Object.GetType(); $Type = $TypeAccelerators.$SystemType; If (!$Type) {$Type = $SystemType.FullName}; $Parse = $Type; $Cast = $Null;
		$Enumerator = $Object.GetEnumerator.OverloadDefinitions
		$Pson = If ($Object -is [Boolean]) {If ($Object) {'$True'} Else {'$False'}}
		ElseIf ($NumberTypes.ContainsKey($Type)) {"$Object"}
		ElseIf ($Object -is [String]) {If ($Object -Match "[`r`n]") {"@'$NewLine$Object$NewLine'@$NewLine"} Else {"'$($Object.Replace('''', ''''''))'"}}
		ElseIf ($Object -is [DateTime]) {$Cast = $Type; "'$($Object.ToString('o'))'"}
		ElseIf ($Object -is [Version]) {$Cast = $Type; "'$Object'"}
		ElseIf ($Object -is [ScriptBlock]) {"{$Object$NewLine}"}
		ElseIf ($Object -is [RuntimeTypeHandle]) {$Object.Value}
		ElseIf ($Object -is [IntPtr]) {$Cast = $Type; "$Object"}
		ElseIf ($Object -is [Xml]) {$Cast = $Type; $SW = New-Object System.IO.StringWriter; $XW = New-Object System.Xml.XmlTextWriter $SW
			$XW.Formatting = If ($Level -gt $Expand) {"None"} Else {"Indented"}; $XW.Indentation = $Indentation; $XW.IndentChar = $IndentChar
			$Object.WriteContentTo($XW); If ($Level -gt $Expand) {"'$SW'"} Else {"@'$NewLine$SW$NewLine'@$NewLine"}}
		ElseIf ($SystemType.Name -eq "DictionaryEntry" -or $SystemType.Name -like "KeyValuePair*") {$Parse = "Hashtable"; Embed $Object.Key @{$Object.Key = $Object.Value}}
		ElseIf ($SystemType.Name -eq "OrderedDictionary") {$Cast = "Ordered"; Embed $Object.Keys $Object}
		ElseIf ($Enumerator -match "[\W]IDictionaryEnumerator[\W]") {$Parse = "Hashtable"; Embed $Object.Keys $Object}
		ElseIf ($Enumerator -match "[\W]IEnumerator[\W]" -or $Object.GetType().Name -eq "DataTable") {$Parse = "Array"; Embed $Object}
		ElseIf ($Object -is [ValueType]) {$Cast = $Type; "'$($Object)'"}
		Else {$Property = $Object | Get-Member -Type Property; If (!$Property) {$Property = $Object | Get-Member -Type NoteProperty}
			$Names = ForEach ($Name in ($Property | Select-Object -Expand "Name")) {$Object.PSObject.Properties |
				Where-Object {$_.Name -eq $Name -and $_.IsGettable} | Select-Object -Expand "Name"}
			If ($Property) {$Cast = "PSCustomObject"; Embed $Names $Object} Else {$Cast = "Void"; "'$Object'"}
		}
		Switch ($TypePrefix) {
			'None'  	{"$Pson"}
			'Native'	{"[$Type]$Pson"}
			'Cast'  	{If ($Cast) {"[$Cast]$Pson"} Else {"$Pson"}}
			'Strict'	{If ($Cast) {"[$Cast]$Pson"} Else {"[$Parse]$Pson"}}
		}
	}
	If ($Iteration) {$Expression} Else {[ScriptBlock]::Create($Expression)}
} Set-Alias pson ConvertTo-Expression; Set-Alias ctex ConvertTo-Expression
Set-Alias ConvertTo-Pson ConvertTo-Expression -Description "Serializes an object to a PowerShell expression."
Set-Alias ConvertFrom-Pson  Invoke-Expression -Description "Parses a PowerShell expression to an object."
