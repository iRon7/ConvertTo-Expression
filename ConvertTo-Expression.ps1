<#PSScriptInfo
.VERSION 3.1.1
.GUID 5f167621-6abe-4153-a26c-f643e1716720
.AUTHOR Ronald Bode (iRon)
.DESCRIPTION Stringifys an object to a PowerShell expression (PSON, PowerShell Object Notation).
.COMPANYNAME
.COPYRIGHT
.TAGS PSON PowerShell Object Notation expression Stringify
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
		The ConvertTo-Expression cmdlet converts (serialize) an object to a
		PowerShell expression. The object can be stored in a variable, file or
		any other common storage for later use or to be ported to another
		system.

		Converting back from an expression
		An expression can be restored to an object by preceding it with an
		ampersand (&):

			$Object = &($Object | ConverTo-Expression)

		An expression that is casted to a string can be restored to an
		object using the native Invoke-Expression cmdlet:

			$Object = Invoke-Expression [String]($Object | ConverTo-Expression)

		An expression that is stored in a PowerShell (.ps1) file might also
		be directly invoked by the PowerShell dot-sourcing technique, e.g.:

			$Object | ConvertTo-Expression | Out-File .\Expression.ps1
			$Object = . .\Expression.ps1

	.PARAMETER InputObject
		Specifies the objects to convert to a PowerShell expression. Enter a
		variable that contains the objects, or type a command or expression
		that gets the objects. You can also pipe one or more objects to
		ConvertTo-Expression.

	.PARAMETER Depth
		Specifies how many levels of contained objects are included in the
		PowerShell representation. The default value is 9.

	.PARAMETER Expand
		Specifies till what level the contained objects are expanded over
		separate lines and indented according to the -Indentation and
		-IndentChar parameters. The default value is equal to the -Depth value.

		A negative value will remove redundant spaces and compress the
		PowerShell expression to a single line (except for multi-line strings).

		Xml documents and multi-line strings are embedded in a "here string"
		and aligned to the left.

	.PARAMETER Indentation
		Specifies how many IndentChars to write for each level in the
		hierarchy.

	.PARAMETER IndentChar
		Specifies which character to use for indenting.

	.PARAMETER Strong
		By default, the ConvertTo-Expression cmdlet will return a weakly typed
		expression which is best for transfing objects between differend
		PowerShell systems.
		The -Strong parameter will strickly define value types and objects
		in a way that they can still be read by same PowerShell system and
		PowerShell system with the same configuration (installed modules etc.).

	.PARAMETER Explore
		In explore mode, all type prefixes are omitted in the output expression
		(objects will cast to to hash tables). In case the -Strong parameter is
		also supplied, all orginal (.Net) type names are shown.
		The -Explore switch is usefull for exploring object hyrachies and data
		type, not for saving and transfering objects.

	.EXAMPLE

		PS C:\> $Calendar = (Get-UICulture).Calendar | ConvertTo-Expression

		PS C:\> $Calendar

		[PSCustomObject]@{
				'AlgorithmType' = 'SolarCalendar'
				'CalendarType' = 'Localized'
				'Eras' = @(1)
				'IsReadOnly' = $False
				'MaxSupportedDateTime' = [DateTime]'9999-12-31T23:59:59.9999999'
				'MinSupportedDateTime' = [DateTime]'0001-01-01T00:00:00.0000000'
				'TwoDigitYearMax' = 2029
		}

		PS C:\> &$Calendar

		AlgorithmType        : SolarCalendar
		CalendarType         : Localized
		Eras                 : {1}
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
		[Parameter(ValueFromPipeLine = $True)][Alias('InputObject')]$Object, [Int]$Depth = 9, [Int]$Expand = $Depth,
		[Int]$Indentation = 1, [String]$IndentChar = "`t", [Switch]$Strong, [Switch]$Explore,
		[String]$NewLine = [System.Environment]::NewLine
	)
	Begin {
		$NumberTypes = @{}; "byte", "int", "int16", "int32", "int64", "sbyte", "uint", "uint16", "uint32", "uint64", "float", "single", "double", "long", "decimal", "IntPtr" | ForEach-Object {$NumberTypes[$_] = $Null}
		$CastAccelerators = @{}; [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get.GetEnumerator() | ForEach-Object {$CastAccelerators[$_.Value] = $_.Key}
		Function ReferenceName ($Object, $Path) {
			$Name = ForEach ($e in $References.GetEnumerator()) {If ([object]::ReferenceEquals($e.Value, $Object)) {$e.Name; Break}}
			If ($Null -eq $Name) {$References[($Path | ForEach-Object {If ($_ -is [Int]) {"[$_]"} Else {".$_"}}) -Join ''] = $Object} Else {$Name}
		}
		Function List([String[]]$Items, [String[]]$Separator = @(), [String[]]$Open = @(), [String[]]$Close = @(), [Int]$Indent) {
			If (($Expand -le 0) -or (@($Items).Count -le 1)) {$Open[0] + ($Items -Join "$($Separator[0])$Space") + $Close[0]}
			Else {
				$Lead = "$NewLine$($Tab * $Indent)"
				If ($Open[-1]) {"$($Open[-1])$Lead$Tab$($Items -Join $($Separator[-1] + $Lead + $Tab))$Lead$($Close[-1])"}
				Else {$Items -Join "$($Separator[-1])$Lead"}
			}
		}
		Function Stringify($Object, [Int]$Expand, [Array]$Path = @()) {
			Function Serialize ($Keys) {
				Function Iterate($Object, $Name) {
					If ($Path.Count -lt $Depth) {Stringify $Object -Expand ($Expand - ($Expand -gt 0)) -Path ($Path + $Name)} Else {"'...'"}
				}
				If ($Null -ne $Keys) {
					$Names = If ($Keys -eq $True) {$Object.Keys} Else {
						(&{ForEach ($Name in ($Keys | Select-Object -Expand "Name")) {$Object.PSObject.Properties |
						Where-Object {$_.Name -eq $Name -and $_.IsGettable} | Select-Object -Expand "Name"}})
					}
					List ($Names | ForEach-Object {"'$_'$Space=$Space" + (Iterate $Object.$_ "$_")}) ";", "" "@{" "}" $Path.Count
				} Else {
					$i = 0; $Array = $Object | ForEach-Object {Iterate $_ $i; $i++}
					If ($Array -is [String] -and $Object[0] -is [Array]) {$Array = ",$Array"}
					If ($Array.Count -le 1) {List $Array "," "@(" ")" $Path.Count}
					ElseIf (!$Path.Count -or $Path[-1] -is [Int]) {List $Array "," "(" ")" $Path.Count}
					Else {List $Array "," "", "(" "", ")" $Path.Count}
				}
			}
			If ($Null -eq $Object) {"`$Null"} Else {
				$Type = $Object.GetType(); $Cast = $CastAccelerators.$Type; If (!$Cast) {$Cast = $Type.FullName}; $Convert = $Cast; $Parse = $Null;
				$Enumerator = $Object.GetEnumerator.OverloadDefinitions
				$DTO = If ($Object -is [Boolean]) {If ($Object) {'$True'} Else {'$False'}}
				ElseIf ($NumberTypes.ContainsKey($Type.Name)) {"$Object"}
				ElseIf ($Object -is [String]) {If ($Object -Match "[`r`n]") {"@'$NewLine$Object$NewLine'@$NewLine"} Else {"'$($Object.Replace('''', ''''''))'"}}
				ElseIf ($Object -is [DateTime]) {$Parse = $Cast; "'$($Object.ToString('o'))'"}
				ElseIf ($Object -is [Version]) {$Parse = $Cast; "'$Object'"}
				ElseIf ($Object -is [Enum]) {If ($Strong) {$Parse = $Cast; "'$Object'"} Else {"$(0 + $Object)"}}
				ElseIf ($Object -is [ScriptBlock]) {If ($Object -Match "\#.*?$") {"{$Object$NewLine}"} Else {"{$Object}"}}
				ElseIf ($Object -is [RuntimeTypeHandle]) {$Object.Value}
				ElseIf ($Object -is [Xml]) {$Parse = $Cast; $SW = New-Object System.IO.StringWriter; $XW = New-Object System.Xml.XmlTextWriter $SW
					$XW.Formatting = If ($Expand -le 0) {"None"} Else {"Indented"}; $XW.Indentation = $Indentation; $XW.IndentChar = $IndentChar
					$Object.WriteContentTo($XW); If ($Expand -le 0) {"'$SW'"} Else {"@'$NewLine$SW$NewLine'@$NewLine"}}
				Else {$ReferenceName = ReferenceName $Object $Path; If ($ReferenceName) {'$_' + $ReferenceName}
					ElseIf ($Type.Name -eq "DataTable") {$Convert = "Array"; Serialize}
					ElseIf ($Type.Name -eq "DictionaryEntry") {$Parse = "PSCustomObject"; Serialize ($Object | Get-Member -Type Property)}
					ElseIf ($Type.Name -like "KeyValuePair*") {$Parse = "PSCustomObject"; Serialize ($Object | Get-Member -Type Property)}
					ElseIf ($Type.Name -eq "OrderedDictionary") {$Parse = "Ordered"; Serialize $True}
					ElseIf ($Enumerator -match "[\W]IDictionaryEnumerator[\W]") {$Convert = "Hashtable"; Serialize $True}
					ElseIf ($Enumerator -match "[\W]IEnumerator[\W]") {$Convert = "Array"; Serialize}
					ElseIf ($Object -is [ValueType]) {$Parse = $Cast; "'$($Object)'"}
					Else {$Properties = $Object | Get-Member -Type Property; If (!$Properties) {$Properties = $Object | Get-Member -Type NoteProperty}
						If ($Properties) {$Parse = "PSCustomObject"; Serialize $Properties} Else {"'$Object'"}
					}
				}
				If ($Strong) {If ($Explore) {"[$Cast]$DTO"} Else {If ($Parse) {"[$Parse]$DTO"} Else {"[$Convert]$DTO"}}}
				Else {If ($Explore) {"$DTO"} Else {If ($Parse) {"[$Parse]$DTO"} Else {"$DTO"}}}
			}
		}
		$Space = If ($Expand -ge 0) {" "} Else {""}; $Tab = $IndentChar * $Indentation
		$Items = @(); $References = @{}
	}
	Process {
		If (!$PSCmdlet.MyInvocation.ExpectingInput -and $Object -is [Array] -and $Object.Count) {
			$i = 0; $Items = @($Object | ForEach-Object {Stringify $_ -Expand $Expand}); $ContainsArray = $Object[0] -is [Array]
		} Else {$Items += Stringify $Object -Expand $Expand; $ContainsArray = $Object -is [Array]}
	}
	End {
		If ($Items.Count -le 1 -and $ContainsArray) {$Items = "," + $Items}
		$Expression = List $Items ",", ""
		Try {[ScriptBlock]::Create($Expression)} Catch {$PSCmdlet.WriteError($_); $Expression}
	}
}; Set-Alias ctex ConvertTo-Expression
