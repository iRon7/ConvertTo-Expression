<#PSScriptInfo
.VERSION 2.2.2
.GUID 5f167621-6abe-4153-a26c-f643e1716720
.AUTHOR Ronald Bode (iRon)
.COMPANYNAME 
.COPYRIGHT 
.TAGS PSON PowerShell Object Notation expression serialize
.LICENSEURI https://github.com/iRon7/ConvertTo-PSON/LICENSE.txt
.PROJECTURI https://github.com/iRon7/ConvertTo-PSON
.ICONURI 
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES
.PRIVATEDATA 
#>

Function ConvertTo-Pson {
	<#
		.SYNOPSIS
			Serializes an object to a PowerShell expression

		.DESCRIPTION
			The ConvertTo-Pson cmdlet converts any object to a string in PowerShell Object
			Notation (PSON) format. The properties are converted to field names, the field
			values are converted to property values, and the methods are removed.
			You can then use the ConvertFrom-Pson (Invoke-Expression) cmdlet to convert a
			PSON-formatted string to a PowerShell object, which is easily managed in
			Windows PowerShell.

		.PARAMETER InputObject
			Specifies the objects to convert to a PSON expression. Enter a variable that
			contains the objects, or type a command or expression that gets the objects.
			You can also pipe an object to ConvertTo-Pson.

		.PARAMETER Depth
			Specifies how many levels of contained objects are included in the PSON
			representation. The default value is 9.

		.PARAMETER Expand
			Specifies till what level the contained objects are expanded over separate lines
			and indented according to the -Indentation and -IndentChar parameters.
			The default value is 9.
			
			A negative value will remove redundant spaces and compress the PSON expression to
			a single line (except for multiline strings).
			
			Xml documents and multiline strings are embedded in a "here string" and aligned
			to the left.
			
		.PARAMETER Indentation
			Specifies how many IndentChars to write for each level in the hierarchy.

		.PARAMETER IndentChar
			Specifies which character to use for indenting.

		.PARAMETER Type
			Defines how the explicite the object type is being parsed:

			-Type None
				No type information will be added to the (embedded) objects and values in
				the PSON string. This means that objects and values will be parsed to one
				of the following data types when reading them back with ConvertFrom-Pson
				(Invoke-Expression): a numeric value, a [String] ('...'), an [Array] 
				(@(...)) or a [HashTable] (@{...}).

			-Type Native
				The original type prefix is added to the (embedded) objects and values in
				the PSON string. Note that most system (.Net) objects can’t be read back
				with ConvertFrom-Pson (Invoke-Expression), but -SetType Name can help to
				reveal (embedded) object types and hierarchies.

			-Type Cast (Default)
				The type prefix is only added to (embedded) objects and values when required
				and optimized for read back with ConvertFrom-Pson (Invoke-Expression) by e.g.
				converting system (.Net) objects to PSCustomObject objects. Numeric values
				won't have a strict type and therefor parsed to the default type that fits
				the value when read back with ConvertFrom-Pson (Invoke-Expression).

			-Type Strict
				All (embedded) objects and values will have an explicit type prefix optimized
				for read back with ConvertFrom-Pson (Invoke-Expression) by e.g. converting
				system (.Net) objects to PSCustomObject objects.

		.PARAMETER NewLine
			Specifies which characters to use for a new line. The default is defined by the
			operating system.

		.EXAMPLE 

			PS C:\>(Get-UICulture).Calendar | ConvertTo-Pson	# Convert a Calendar object to a PowerShell expression

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

			PS C:\>Get-Date | Select-Object -Property * | ConvertTo-Pson	# Convert an object to a PSON expression and to a PowerShell object

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

			PS C:\>WinInitProcess = Get-Process WinInit | ConvertTo-Pson	# Convert the WinInit Process to a PSON expression

		.EXAMPLE 

			PS C:\>Get-Host | ConvertTo-PSON -Depth 4	# Reveal complex object hierarchies

		.LINK
			Invoke-Expression (Alias ConvertFrom-Pson)
	#>
	[CmdletBinding()][OutputType([String])]Param (
		[Parameter(ValueFromPipeLine = $True)][Object[]]$InputObject, [Int]$Depth = 9, [Int]$Expand = 9,
		[Int]$Indentation = 1, [String]$IndentChar = "`t", [ValidateSet("None", "Native", "Cast", "Strict")][String]$TypePrefix = "Cast",
		[String]$NewLine = [System.Environment]::NewLine, [Parameter(DontShow)][Int]$i = 0
	)
	$PipeLine = $Input | ForEach-Object {$_}; If ($PipeLine) {$InputObject = $PipeLine}
	Function Iterate ($Value) {ConvertTo-Pson @(,$Value) $Depth $Expand $Indentation $IndentChar $TypePrefix $NewLine ($i + 1)}
	Function Embed ($List, $Dictionary) {If ($i -ge $Depth) {If ($Null -ne $Dictionary) {Return "@{}"} Else {Return "@()"}}
		$Items = ForEach ($Key in $List) {If ($Null -ne $Dictionary) {"'$Key'$Space=$Space" + (Iterate $Dictionary.$Key)} Else {Iterate $Key}}
		$Open, $Join, $Separator, $Close = If ($Null -ne $Dictionary) {"@{", ";$Space", "$LineUp$Tab", "}"} Else {"@(", ",$Space", ",$LineUp$Tab", ")"}
		$Open + (&{If (($i -ge $Expand) -or (@($Items).Count -le 1)) {$Items -Join $Join} Else {"$LineUp$Tab$($Items -Join $Separator)$LineUp"}}) + $Close
	}
	$Object = If (@($InputObject).Count -eq 1) {@($InputObject)[0]} Else {$InputObject}
	If ($Null -eq $Object) {"`$Null"} Else {$Space = If ($i -gt $Expand) {""} Else {" "}; $Tab = $IndentChar * $Indentation; $LineUp = "$NewLine$($Tab * $i)"
		$Type = $Object.GetType().Name; $Cast = $Null; $Enumerator = $Object.GetEnumerator.OverloadDefinitions
		$PSON = If ($Object -is [Boolean]) {If ($Object) {'$True'} Else {'$False'}}
		ElseIf ($Object -is [Char]) {$Cast = $Type; "'$Object'"}
		ElseIf ($Object -is [String]) {If ($Object -Match "[`r`n]") {"@'$NewLine$Object$NewLine'@$NewLine"} Else {"'$($Object.Replace('''', ''''''))'"}}
		ElseIf ($Object -is [DateTime]) {$Cast = $Type; "'$($Object.ToString('o'))'"}
		ElseIf ($Object -is [TimeSpan] -or $Object -is [Version]) {$Cast = $Type; "'$Object'"}
		ElseIf ($Object -is [Enum]) {$Type = "String"; "'$($Object)'"}
		ElseIf ($Object -is [Xml]) {$Cast = "Xml"; $SW = New-Object System.IO.StringWriter; $XW = New-Object System.Xml.XmlTextWriter $SW
			$XW.Formatting = If ($Level -gt $Expand) {"None"} Else {"Indented"}; $XW.Indentation = $Indentation; $XW.IndentChar = $IndentChar
			$Object.WriteContentTo($XW); If ($Level -gt $Expand) {"'$SW'"} Else {"@'$NewLine$SW$NewLine'@$NewLine"}}
		ElseIf ($Object.GetType().Name -eq "DictionaryEntry" -or $Type -like "KeyValuePair*") {$Type = "Hashtable"; Embed $Object.Key @{$Object.Key = $Object.Value}}
		ElseIf ($Object.GetType().Name -eq "OrderedDictionary") {$Type = "Hashtable"; $Cast = "Ordered"; Embed $Object.Keys $Object}
		ElseIf ($Enumerator -match "[\W]IDictionaryEnumerator[\W]") {$Type = "Hashtable"; Embed $Object.Keys $Object}
		ElseIf ($Enumerator -match "[\W]IEnumerator[\W]" -or $Object.GetType().Name -eq "DataTable") {$Type = "Array"; Embed $Object}
		Else {$Property = $Object | Get-Member -Type Property; If (!$Property) {$Property = $Object | Get-Member -Type NoteProperty}
			$Names = ForEach ($Name in ($Property | Select-Object -Expand "Name")) {$Object.PSObject.Properties |
				Where-Object {$_.Name -eq $Name -and $_.IsGettable} | Select-Object -Expand "Name"}
			If ($Property) {$Type = "PSCustomObject"; $Cast = $Type; Embed $Names $Object} Else {$Object}
		}
		Switch ($TypePrefix) {
			'None'  	{"$PSON"}
			'Native'	{"[$($Object.GetType().Name)]$PSON"}
			'Cast'  	{If ($Cast) {"[$Cast]$PSON"} Else {"$PSON"}}
			'Strict'	{If ($Cast) {"[$Cast]$PSON"} Else {"[$Type]$PSON"}}
		}
	}
} Set-Alias PSON ConvertTo-Pson -Description "Convert variable to PSON"
Set-Alias ConvertFrom-Pson Invoke-Expression -Description "Convert variable from PSON"
