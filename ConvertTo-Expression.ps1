<#PSScriptInfo
.VERSION 3.2.19
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

	.INPUTS
		Any. Each objects provided through the pipeline will converted to an
		expression. To concatinate all piped objects in a single expression,
		use the unary comma operator, e.g.: ,$Object | ConvertTo-Expression

	.OUTPUTS
		System.Management.Automation.ScriptBlock[]. ConvertTo-Expression
		returns a PowerShell expression (ScriptBlock) for each input object.
		A PowerShell expression default display output is a Sytem.String.

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
		https://www.powershellgallery.com/packages/ConvertFrom-Expression
#>
	[CmdletBinding()][OutputType([ScriptBlock])]Param (
		[Parameter(ValueFromPipeLine = $True)][Alias('InputObject')]$Object, [Int]$Depth = 9, [Int]$Expand = $Depth,
		[Int]$Indentation = 1, [String]$IndentChar = "`t", [Switch]$Strong, [Switch]$Explore, [Switch]$Concatenate,
		[String]$NewLine = [System.Environment]::NewLine
	)
	Begin {
		If (!$PSCmdlet.MyInvocation.ExpectingInput) {If ($Concatenate) {Write-Warning 'The concatenate switch only applies to pipeline input'} Else {$Concatenate = $True}}
		$ListItem = $Null
		$Tab = $IndentChar * $Indentation
		Function Serialize($Object, $Iteration, $Indent) {
			Function Quote ([String]$Item) {"'$($Item.Replace('''', ''''''))'"}
			Function Here ([String]$Item) {If ($Item -Match '[\r\n]') {"@'$NewLine$Item$NewLine'@$NewLine"} Else {Quote $Item}}
			Function Stringify ($Object, $Cast = $Type, $Convert) {
				$Casted = $PSBoundParameters.ContainsKey('Cast')
				Function Prefix($Object, [Switch]$Parenthesis) {
					If ($Convert) {If ($ListItem) {$Object = "($Convert $Object)"} Else {$Object = "$Convert $Object"}}
					If ($Parenthesis) {$Object = "($Object)"}
					If ($Explore) {If ($Strong) {"[$Type]$Object"} Else {$Object}}
					ElseIf ($Strong -or $Casted) {If ($Cast) {"[$Cast]$Object"}}
					Else {$Object}
				}
				Function Iterate($Object, [Switch]$Strong = $Strong, [Switch]$ListItem, [Switch]$Level) {
					If ($Iteration -lt $Depth) {Serialize $Object -Iteration ($Iteration + 1) -Indent ($Indent + 1 - [Int][Bool]$Level)} Else {"'...'"}
				}
				If ($Object -is [String]) {Prefix $Object} Else {
					$List, $Properties = $Null; $Methods = $Object.PSObject.Methods.Name
					If ($Methods -Contains 'GetEnumerator') {
						If ($Methods -Contains 'get_Keys' -and $Methods -Contains 'get_Values') {
							$List = [Ordered]@{}; ForEach ($Key in $Object.get_Keys()) {$List[(Quote $Key)] = Iterate $Object[$Key]}
						} Else {
							$Level = @($Object).Count -eq 1 -or ($Null -eq $Indent -and !$Explore -and !$Strong)
							$StrongItem = $Strong -and $Type.Name -eq 'Object[]'
							$List = @(ForEach ($Item in $Object) {
								Iterate $Item -ListItem -Level:$Level -Strong:$StrongItem
							})
						}
					} Else {
						$Properties = $Object.PSObject.Properties | Where-Object {$_.MemberType -eq 'Property'}
						If (!$Properties) {$Properties = $Object.PSObject.Properties | Where-Object {$_.MemberType-eq 'NoteProperty'}}
						If ($Properties) {$List = [Ordered]@{}; ForEach ($Property in $Properties) {$List[(Quote $Property.Name)] = Iterate $Property.Value}}
					}
					If ($List -is [Array]) {
						If (!$Casted -and ($Type.Name -eq 'Object[]' -or "$Type".Contains('.'))) {$Cast = 'array'}
						If (!$List.Count) {Prefix '@()'}
						ElseIf ($List.Count -eq 1) {
							If ($Strong) {Prefix "$List"}
							ElseIf ($ListItem) {"(,$List)"}
							Else {",$List"}
						}
						ElseIf ($Indent -ge $Expand - 1 -or $Type.GetElementType().IsPrimitive) {
							$Content = If ($Expand -ge 0) {$List -Join ', '} Else {$List -Join ','}
							Prefix -Parenthesis:($ListItem -or $Strong) $Content
						}
						ElseIf ($Null -eq $Indent -and !$Strong -and !$Convert) {Prefix ($List -Join ",$NewLine")}
						Else {
							$LineFeed = $NewLine + ($Tab * $Indent)
							$Content = "$LineFeed$Tab" + ($List -Join ",$LineFeed$Tab")
							If ($Convert) {$Content = "($Content)"}
							If ($ListItem -or $Strong) {Prefix -Parenthesis "$Content$LineFeed"} Else {Prefix $Content}
						}
					} ElseIf ($List -is [System.Collections.Specialized.OrderedDictionary]) {
						If (!$Casted) {If ($Properties) {$Casted = $True; $Cast = 'pscustomobject'} Else {$Cast = 'hashtable'}}
						If (!$List.Count) {Prefix '@{}'}
						ElseIf ($Expand -lt 0) {Prefix ('@{' + (@(ForEach ($Key in $List.get_Keys()) {"$Key=$($List.$Key)"}) -Join ';') + '}')}
						ElseIf ($List.Count -eq 1 -or $Indent -ge $Expand - 1) {
							Prefix ('@{' + (@(ForEach ($Key in $List.get_Keys()) {"$Key = $($List.$Key)"}) -Join '; ') + '}')
						} Else {
							$LineFeed = $NewLine + ($Tab * $Indent)
							Prefix ("@{$LineFeed$Tab" + (@(ForEach ($Key in $List.get_Keys()) {
								If (($List.$Key)[0] -NotMatch '[\S]') {"$Key =$($List.$Key)".TrimEnd()} Else {"$Key = $($List.$Key)".TrimEnd()}
							}) -Join "$LineFeed$Tab") + "$LineFeed}")
						}
					}
					Else {Prefix ",$List"}
				}
			}
			If ($Null -eq $Object) {"`$Null"} Else {
				$Type = $Object.GetType()
				If ($Object -is [Boolean]) {If ($Object) {Stringify '$True'} Else {Stringify '$False'}}
				ElseIf ($Object -is [Adsi]) {Stringify "'$($Object.ADsPath)'" $Type}
				ElseIf ('Char', 'mailaddress', 'Regex', 'Semver', 'Type', 'Version', 'Uri' -Contains $Type.Name) {Stringify "'$($Object)'" $Type}
				ElseIf ($Type.IsPrimitive) {Stringify "$Object"}
				ElseIf ($Object -is [String]) {Stringify (Here $Object)}
				ElseIf ($Object -is [SecureString]) {Stringify "'$($Object | ConvertFrom-SecureString)'" -Convert 'ConvertTo-SecureString'}
				ElseIf ($Object -is [PSCredential]) {Stringify $Object.Username, $Object.Password -Convert 'New-Object PSCredential'}
				ElseIf ($Object -is [DateTime]) {Stringify "'$($Object.ToString('o'))'" $Type}
				ElseIf ($Object -is [Enum]) {If ("$Type".Contains('.')) {Stringify "$(0 + $Object)"} Else {Stringify "'$Object'" $Type}}
				ElseIf ($Object -is [ScriptBlock]) {If ($Object -Match "\#.*?$") {Stringify "{$Object$NewLine}"} Else {Stringify "{$Object}"}}
				ElseIf ($Object -is [RuntimeTypeHandle]) {Stringify "$($Object.Value)"}
				ElseIf ($Object -is [Xml]) {
					$SW = New-Object System.IO.StringWriter; $XW = New-Object System.Xml.XmlTextWriter $SW
					$XW.Formatting = If ($Indent -lt $Expand - 1) {'Indented'} Else {'None'}
					$XW.Indentation = $Indentation; $XW.IndentChar = $IndentChar; $Object.WriteContentTo($XW); Stringify (Here $SW) $Type}
				ElseIf ($Object -is [System.Data.DataTable]) {Stringify $Object.Rows}
				ElseIf ($Type.Name -eq "OrderedDictionary") {Stringify $Object 'ordered'}
				ElseIf ($Object -is [ValueType]) {Stringify "'$($Object)'" $Type}
				Else {Stringify $Object}
			}
		}
	}
	Process {
		$Expression = (Serialize $Object).TrimEnd()
		Try {[ScriptBlock]::Create($Expression)} Catch {$PSCmdlet.WriteError($_); $Expression}
	}
}; Set-Alias ctex ConvertTo-Expression
