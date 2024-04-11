<#PSScriptInfo
.VERSION 3.4.0
.GUID 5f167621-6abe-4153-a26c-f643e1716720
.AUTHOR Ronald Bode (iRon)
.DESCRIPTION This cmdlet is deprecated, a replacement might be found in the ObjectGraphTools module.
.COMPANYNAME
.COPYRIGHT
.TAGS PSON PowerShell Object Notation Expression Serialize Stringify
.LICENSE https://github.com/iRon7/ConvertTo-Expression/LICENSE.txt
.PROJECTURI https://github.com/iRon7/ObjectGraphTools
.ICON https://raw.githubusercontent.com/iRon7/ConvertTo-Expression/master/ConvertTo-Expression.png
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
#>

<#
.SYNOPSIS
    Serializes an object to a PowerShell expression.

.DESCRIPTION
    The ConvertTo-Expression cmdlet converts (serializes) an object to a
    PowerShell expression. The object can be stored in a variable,  file or
    any other common storage for later use or to be ported to another
    system.

    An expression can be restored to an object using the native
    Invoke-Expression cmdlet:

        $Object = Invoke-Expression ($Object | ConverTo-Expression)

    Or Converting it to a [ScriptBlock] and invoking it with cmdlets
    along with Invoke-Command or using the call operator (&):

        $Object = &([ScriptBlock]::Create($Object | ConverTo-Expression))

    An expression that is stored in a PowerShell (.ps1) file might also
    be directly invoked by the PowerShell dot-sourcing technique,  e.g.:

        $Object | ConvertTo-Expression | Out-File .\Expression.ps1
        $Object = . .\Expression.ps1

    Warning: Invoking partly trusted input with Invoke-Expression or
    [ScriptBlock]::Create() methods could be abused by malicious code
    injections.

.INPUTS
    Any. Each objects provided through the pipeline will converted to an
    expression. To concatinate all piped objects in a single expression,
    use the unary comma operator,  e.g.: ,$Object | ConvertTo-Expression

.OUTPUTS
    String[]. ConvertTo-Expression returns a PowerShell [String] expression
    for each input object.

.PARAMETER InputObject
    Specifies the objects to convert to a PowerShell expression. Enter a
    variable that contains the objects,  or type a command or expression
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
    By default,  the ConvertTo-Expression cmdlet will return a weakly typed
    expression which is best for transfing objects between differend
    PowerShell systems.
    The -Strong parameter will strickly define value types and objects
    in a way that they can still be read by same PowerShell system and
    PowerShell system with the same configuration (installed modules etc.).

.PARAMETER Explore
    In explore mode,  all type prefixes are omitted in the output expression
    (objects will cast to to hash tables). In case the -Strong parameter is
    also supplied,  all orginal (.Net) type names are shown.
    The -Explore switch is usefull for exploring object hyrachies and data
    type,  not for saving and transfering objects.

.EXAMPLE

    PS> (Get-UICulture).Calendar | ConvertTo-Expression
    [pscustomobject]@{
        'AlgorithmType' = 1
        'CalendarType' = 1
        'Eras' = , 1
        'IsReadOnly' = $False
        'MaxSupportedDateTime' = [datetime]'9999-12-31T23:59:59.9999999'
        'MinSupportedDateTime' = [datetime]'0001-01-01T00:00:00.0000000'
        'TwoDigitYearMax' = 2029
    }

.EXAMPLE
    PS> (Get-UICulture).Calendar | ConvertTo-Expression -Strong
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

    PS> Get-Date | Select-Object -Property * | ConvertTo-Expression | Out-File .\Now.ps1
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

.EXAMPLE

    PS> @{Account="User01";Domain="Domain01";Admin="True"} | ConvertTo-Expression -Expand -1	# Compress the PowerShell output
    @{'Admin'='True';'Account'='User01';'Domain'='Domain01'}

.EXAMPLE

    PS> WinInitProcess = Get-Process WinInit | ConvertTo-Expression	# Convert the WinInit Process to a PowerShell expression

.EXAMPLE

    PS> Get-Host | ConvertTo-Expression -Depth 4	# Reveal complex object hierarchies

.LINK
    https://www.powershellgallery.com/packages/ConvertFrom-Expression
#>

using namespace System.Management.Automation


[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')] # https://github.com/PowerShell/PSScriptAnalyzer/issues/1472
[CmdletBinding()][OutputType([scriptblock])] param(
    [Parameter(ValueFromPipeLine = $True)][Alias('InputObject')] $Object,
    [int]$Depth = 9,
    [int]$Expand = $Depth,
    [int]$Indentation = 4,
    [string]$IndentChar = ' ',
    [switch]$Strong,
    [switch]$Explore,
    [ValidateSet("Name", "Fullname", "Auto")][string]$TypeNaming = 'Auto',
    [string]$NewLine = [System.Environment]::NewLine
)
begin {
    $ValidUnqoutedKey = '^[\p{L}\p{Lt}\p{Lm}\p{Lo}_][\p{L}\p{Lt}\p{Lm}\p{Lo}\p{Nd}_]*$'
    $ListItem = $Null
    $Tab = $IndentChar * $Indentation
    function Serialize ($Object, $Iteration, $Indent) {
        function Quote ([string]$Item) { "'$($Item.Replace('''',  ''''''))'" }
        function QuoteKey ([string]$Key) { if ($Key -cmatch $ValidUnqoutedKey) { $Key } else { Quote $Key } }
        function Here ([string]$Item) { if ($Item -match '[\r\n]') { "@'$NewLine$Item$NewLine'@$NewLine" } else { Quote $Item } }
        function Stringify ($Object, $Cast = $Type, $Convert) {
            $Casted = $PSBoundParameters.ContainsKey('Cast')
            function GetTypeName($Type) {
                if ($Type -is [Type]) {
                    if ($TypeNaming -eq 'Fullname') { $Typename = $Type.Fullname }
                    elseif ($TypeNaming -eq 'Name') { $Typename = $Type.Name }
                    else {
                        $Typename = "$Type"
                         if ($Type.Namespace -eq 'System' -or $Type.Namespace -eq 'System.Management.Automation') {
                            if ($Typename.Contains('.')) { $Typename = $Type.Name }
                        }
                    }
                    if ($Type.GetType().GenericTypeArguments) {
                        $TypeArgument = ForEach ($TypeArgument in $Type.GetType().GenericTypeArguments) { GetTypeName $TypeArgument }
                        $Arguments = if ($Expand -ge 0) { $TypeArgument -join ', ' } else { $TypeArgument -join ',' }
                        $Typename = $Typename.GetType().Split(0x60)[0] + '[' + $Arguments + ']'
                    }
                    $Typename
                } else { $Type }
            }
            function Prefix ($Object, [switch]$Parenthesis) {
                if ($Convert) { if ($ListItem) { $Object = "($Convert $Object)" } else { $Object = "$Convert $Object" } }
                if ($Parenthesis) { $Object = "($Object)" }
                if ($Explore) { if ($Strong) { "[$(GetTypeName $Type)]$Object" } else { $Object } }
                elseif ($Strong -or $Casted) { if ($Cast) { "[$(GetTypeName $Cast)]$Object" } }
                else { $Object }
            }
            function Iterate ($Object, [switch]$Strong = $Strong, [switch]$ListItem, [switch]$Level) {
                if ($Iteration -lt $Depth) { Serialize $Object -Iteration ($Iteration + 1) -Indent ($Indent + 1 - [int][bool]$Level) } else { "'...'" }
            }
            if ($Object -is [string]) { Prefix $Object } else {
                $List, $Properties = $Null; $Methods = $Object.PSObject.Methods
                if ($Methods['GetEnumerator'] -is [PSMethod]) {
                    if ($Methods['get_Keys'] -is [PSMethod] -and $Methods['get_Values'] -is [PSMethod]) {
                        $List = [Ordered]@{}; foreach ($Key in $Object.get_Keys()) { $List[(QuoteKey $Key)] = Iterate $Object[$Key] }
                    } else {
                        $Level = @($Object).Count -eq 1 -or ($Null -eq $Indent -and !$Explore -and !$Strong)
                        $StrongItem = $Strong -and $Type.Name -eq 'Object[]'
                        $List = @(foreach ($Item in $Object) {
                                Iterate $Item -ListItem -Level:$Level -Strong:$StrongItem
                            })
                    }
                } else {
                    $Properties = $Object.PSObject.Properties | Where-Object { $_.MemberType -eq 'Property' }
                    if (!$Properties) { $Properties = $Object.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' } }
                    if ($Properties) { $List = [Ordered]@{}; foreach ($Property in $Properties) { $List[(QuoteKey $Property.Name)] = Iterate $Property.Value } }
                }
                if ($List -is [array]) {
                    #if (!$Casted -and ($Type.Name -eq 'Object[]' -or "$Type".Contains('.'))) { $Cast = 'array' }
                    if (!$List.Count) { Prefix '@()' }
                    elseif ($List.Count -eq 1) {
                        if ($Strong) { Prefix "$List" }
                        elseif ($ListItem) { "(,$List)" }
                        else { ",$List" }
                    }
                    elseif ($Indent -ge $Expand - 1 -or $Type.GetElementType().IsPrimitive) {
                        $Content = if ($Expand -ge 0) { $List -join ', ' } else { $List -join ',' }
                        Prefix -Parenthesis:($ListItem -or $Strong) $Content
                    }
                    elseif ($Null -eq $Indent -and !$Strong -and !$Convert) { Prefix ($List -join ",$NewLine") }
                    else {
                        $LineFeed = $NewLine + ($Tab * $Indent)
                        $Content = "$LineFeed$Tab" + ($List -join ",$LineFeed$Tab")
                        if ($Convert) { $Content = "($Content)" }
                        if ($ListItem -or $Strong) { Prefix -Parenthesis "$Content$LineFeed" } else { Prefix $Content }
                    }
                } elseif ($List -is [System.Collections.Specialized.OrderedDictionary]) {
                    if (!$Casted) { if ($Properties) { $Casted = $True; $Cast = 'pscustomobject' } else { $Cast = 'hashtable' } }
                    if (!$List.Count) { Prefix '@{}' }
                    elseif ($Expand -lt 0) { Prefix ('@{' + (@(foreach ($Key in $List.get_Keys()) { "$Key=" + $List[$Key] }) -join ';') + '}') }
                    elseif ($List.Count -eq 1 -or $Indent -ge $Expand - 1) {
                        Prefix ('@{' + (@(foreach ($Key in $List.get_Keys()) { "$Key = " + $List[$Key] }) -join '; ') + '}')
                    } else {
                        $LineFeed = $NewLine + ($Tab * $Indent)
                        Prefix ("@{$LineFeed$Tab" + (@(foreach ($Key in $List.get_Keys()) {
                                        if (($List[$Key])[0] -notmatch '[\S]') { "$Key =" + $List[$Key].TrimEnd() } else { "$Key = " + $List[$Key].TrimEnd() }
                                    }) -join "$LineFeed$Tab") + "$LineFeed}")
                    }
                }
                else { Prefix ",$List" }
            }
        }
        if ($Null -eq $Object) { "`$Null" } else {
            $Type = $Object.GetType()
            if ($Object -is [Boolean]) { if ($Object) { Stringify '$True' } else { Stringify '$False' } }
            elseif ('adsi' -as [type] -and $Object -is [adsi]) { Stringify "'$($Object.ADsPath)'" $Type }
            elseif ('Char', 'mailaddress', 'Regex', 'Semver', 'Type', 'Version', 'Uri' -contains $Type.Name) { Stringify "'$($Object)'" $Type }
            elseif ($Type.IsPrimitive) { Stringify "$Object" }
            elseif ($Object -is [string]) { Stringify (Here $Object) }
            elseif ($Object -is [securestring]) { Stringify "'$($Object | ConvertFrom-SecureString)'" -Convert 'ConvertTo-SecureString' }
            elseif ($Object -is [pscredential]) { Stringify $Object.Username, $Object.Password -Convert 'New-Object PSCredential' }
            elseif ($Object -is [datetime]) { Stringify "'$($Object.ToString('o'))'" $Type }
            elseif ($Object -is [Enum]) { if ("$Type".Contains('.')) { Stringify "$(0 + $Object)" } else { Stringify "'$Object'" $Type } }
            elseif ($Object -is [scriptblock]) { if ($Object -match "\#.*?$") { Stringify "{$Object$NewLine}" } else { Stringify "{$Object}" } }
            elseif ($Object -is [RuntimeTypeHandle]) { Stringify "$($Object.Value)" }
            elseif ($Object -is [xml]) {
                $SW = New-Object System.IO.StringWriter; $XW = New-Object System.Xml.XmlTextWriter $SW
                $XW.Formatting = if ($Indent -lt $Expand - 1) { 'Indented' } else { 'None' }
                $XW.Indentation = $Indentation; $XW.IndentChar = $IndentChar; $Object.WriteContentTo($XW); Stringify (Here $SW) $Type }
            elseif ($Object -is [System.Data.DataTable]) { Stringify $Object.Rows }
            elseif ($Type.Name -eq "OrderedDictionary") { Stringify $Object 'ordered' }
            elseif ($Object -is [ValueType]) { try { Stringify "'$($Object)'" $Type } catch [NullReferenceException]{ Stringify '$Null' $Type } }
            else { Stringify $Object }
        }
    }
}
process {
    (Serialize $Object).TrimEnd()
}
