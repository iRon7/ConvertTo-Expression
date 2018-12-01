<#PSScriptInfo
.VERSION 3.0.1
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

		Converting back from an expression
		An expression can be restored to an object by preceding it with an
		ampersand (&). An expression that is casted to a string can be
		restored to an object using the native Invoke-Expression cmdlet.
		An expression that is stored in a PowerShell (.ps1) file might also
		be directly invoked by the PowerShell dot-sourcing technique, e.g.:
		. .\Expression.ps1

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
	Begin {
		$Params = $PSBoundParameters; If (!$Iteration) {$ListItem = $True}
		$NumberTypes = @{}; "byte", "int", "int16", "int32", "int64", "sbyte", "uint", "uint16", "uint32", "uint64", "float", "single", "double", "long", "decimal", "IntPtr" | ForEach-Object {$NumberTypes[$_] = $Null}
		$TypeAccelerators = @{}; [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() | ForEach-Object {$TypeAccelerators[$_.Value] = $_.Key}
		$Space = If ($Expand -ge 0) {" "} Else {""}; $Tab = $IndentChar * $Indentation; $LineUp = "$NewLine$($Tab * $Iteration)"
		Function Iterate ($Object, [Switch]$ListItem) {
			If ($Iteration -lt $Depth) {
				$Params = $Params; $Params.Object = $Object; $Params.Iteration = $Iteration + 1; If ($Expand -gt 0) {$Params.Expand = $Expand - 1}
				ConvertTo-Expression @Params
			 } Else {"'...'"}
		}
		Function Stringify ([String[]]$Items, [String[]]$Separator = @(), [String[]]$Open = @(), [String[]]$Close = @()) {
			If (($Expand -le 0) -or (@($Items).Count -le 1)) {$Open[0] + ($Items -Join "$($Separator[0])$Space") + $Close[0]}
			ElseIf ($Open[-1]) {"$($Open[-1])$LineUp$Tab$($Items -Join $($Separator[-1] + $LineUp + $Tab))$LineUp$($Close[-1])"}
			Else {$Items -Join "$($Separator[-1])$LineUp"}
		}
		Function Format-Array ($List) {
			$a = $List | ForEach-Object {Iterate $_ -ListItem}; If ($a -is [String] -and $List[0] -is [Array]) {$a = ",$a"}
			If ($a.Count -le 1) {Stringify $a "," "@(" ")"} ElseIf ($ListItem) {Stringify $a "," "(" ")"} Else {Stringify $a "," "", "(" "", ")"}
		}
		Function Format-HashTable ($Dictionary, $Keys = $Dictionary.Keys) {
			Stringify ($Keys | ForEach-Object {"'$_'$Space=$Space" + (Iterate $Dictionary.$_)}) ";", "" "@{" "}"
		}
		Function Format-Object ($Properties) {
			Format-HashTable $Object (&{ForEach ($Name in ($Properties | Select-Object -Expand "Name")) {$Object.PSObject.Properties |
				Where-Object {$_.Name -eq $Name -and $_.IsGettable} | Select-Object -Expand "Name"}})
		}
		Function Serialize($Object) {
			If ($Null -eq $Object) {"`$Null"} Else {
				$SystemType = $Object.GetType(); $Type = $TypeAccelerators.$SystemType; If (!$Type) {$Type = $SystemType.FullName}; $Parse = $Type; $Cast = $Null;
				$Enumerator = $Object.GetEnumerator.OverloadDefinitions
				$Pson = If ($Object -is [Boolean]) {If ($Object) {'$True'} Else {'$False'}}
				ElseIf ($NumberTypes.ContainsKey($SystemType.Name)) {"$Object"}
				ElseIf ($Object -is [String]) {If ($Object -Match "[`r`n]") {"@'$NewLine$Object$NewLine'@$NewLine"} Else {"'$($Object.Replace('''', ''''''))'"}}
				ElseIf ($Object -is [DateTime]) {$Cast = $Type; "'$($Object.ToString('o'))'"}
				ElseIf ($Object -is [Version]) {$Cast = $Type; "'$Object'"}
				ElseIf ($Object -is [ScriptBlock]) {If ($Object -Match "\#.*?$") {"{$Object$NewLine}"} Else {"{$Object}"}}
				ElseIf ($Object -is [RuntimeTypeHandle]) {$Object.Value}
				ElseIf ($Object -is [Xml]) {$Cast = $Type; $SW = New-Object System.IO.StringWriter; $XW = New-Object System.Xml.XmlTextWriter $SW
					$XW.Formatting = If ($Expand -le 0) {"None"} Else {"Indented"}; $XW.Indentation = $Indentation; $XW.IndentChar = $IndentChar
					$Object.WriteContentTo($XW); If ($Expand -le 0) {"'$SW'"} Else {"@'$NewLine$SW$NewLine'@$NewLine"}}
				ElseIf ($SystemType.Name -eq "DataTable") {$Parse = "Array"; Format-Array $Object}
				ElseIf ($SystemType.Name -eq "DictionaryEntry") {$Cast = "PSCustomObject"; Format-Object ($Object | Get-Member -Type Property)}
				ElseIf ($SystemType.Name -like "KeyValuePair*") {$Cast = "PSCustomObject"; Format-Object ($Object | Get-Member -Type Property)}
				ElseIf ($SystemType.Name -eq "OrderedDictionary") {$Cast = "Ordered"; Format-HashTable $Object}
				ElseIf ($Enumerator -match "[\W]IDictionaryEnumerator[\W]") {$Parse = "Hashtable"; Format-HashTable $Object}
				ElseIf ($Enumerator -match "[\W]IEnumerator[\W]") {$Parse = "Array"; Format-Array $Object}
				ElseIf ($Object -is [ValueType]) {$Cast = $Type; "'$($Object)'"}
				Else {$Properties = $Object | Get-Member -Type Property; If (!$Properties) {$Properties = $Object | Get-Member -Type NoteProperty}
					If ($Properties) {$Cast = "PSCustomObject"; Format-Object $Properties} Else {$Cast = "Void"; "'$Object'"}
				}
				Switch ($TypePrefix) {
					'None'  	{"$Pson"}
					'Native'	{"[$Type]$Pson"}
					'Cast'  	{If ($Cast) {"[$Cast]$Pson"} Else {"$Pson"}}
					'Strict'	{If ($Cast) {"[$Cast]$Pson"} Else {"[$Parse]$Pson"}}
				}
			}
		}
		$Items = @()
	}
	Process {
		If (!$Iteration -and !$PSCmdlet.MyInvocation.ExpectingInput -and $Object -is [Array] -and $Object.Count) {
			$Items = @($Object | ForEach-Object {Serialize $_}); $ContainsArray = $Object[0] -is [Array]
		} Else {$Items += Serialize $Object; $ContainsArray = $Object -is [Array]}
	}
	End {
		If ($Iteration) {$Items} Else {
			If ($Items.Count -le 1 -and $ContainsArray) {$Items = "," + $Items}
			[ScriptBlock]::Create((Stringify $Items ",", ""))
		}
	}
} Set-Alias pson ConvertTo-Expression; Set-Alias ctex ConvertTo-Expression
Set-Alias ConvertTo-Pson ConvertTo-Expression -Description "Serializes an object to a PowerShell expression."
Set-Alias ConvertFrom-Pson  Invoke-Expression -Description "Parses a PowerShell expression to an object."
