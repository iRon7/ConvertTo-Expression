#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

$MyPath = [System.IO.FileInfo]$MyInvocation.MyCommand.Path
$AliasName = [System.IO.Path]::GetFileNameWithoutExtension($MyPath.Name) -Replace '\.Tests$'
$ScriptName = [System.IO.Path]::ChangeExtension($AliasName, 'ps1')
$ScriptPath = Join-Path $MyPath.DirectoryName $ScriptName

Set-Alias -Name $AliasName -Value $ScriptPath

Function Should-BeEqualTo ($Value2, [Parameter(ValueFromPipeLine = $True)]$Value1) {
    $Value1 | Should -Be $Value2
    $Value1 | Should -BeOfType $Value2.GetType().Name
}

Describe 'ConvertTo-Expression' {

    BeforeAll {
        $Version  = [Version]'1.2.3.4'
        $Guid = [GUID]'5f167621-6abe-4153-a26c-f643e1716720'
        $TimeSpan = New-TimeSpan -Hour 1 -Minute 25
        $DateTime = Get-Date
        Mock Get-Date -ParameterFilter {$null -eq $Date} {$DateTime}
        
        $DataTable = New-Object Data.DataTable
        $Null = $DataTable.Columns.Add((New-Object Data.DataColumn 'Column1'), [String])
        $Null = $DataTable.Columns.Add((New-Object Data.DataColumn 'Column2'), [Int])
        $DataRow = $DataTable.NewRow()
        $DataRow.Item('Column1') = "A"
        $DataRow.Item('Column2') = 1
        $DataTable.Rows.Add($DataRow)
        $DataRow = $DataTable.NewRow()
        $DataRow.Item('Column1') = "B"
        $DataRow.Item('Column2') = 2
        $DataTable.Rows.Add($DataRow)

        $Object = @{
            String     = [String]"String"
            Text       = [String]"Hello`r`nWorld"
            Char       = [Char]65
            Byte       = [Byte]66
            Int        = [Int]67
            Long       = [Long]68
            Null       = $Null
            Booleans   = $False, $True
            Decimal    = [Decimal]69
            Single     = [Single]70
            Double     = [Double]71
            DateTime   = $DateTime
            TimeSpan   = $TimeSpan
            Version    = $Version
            Guid       = $Guid
            Script     = {2 * 3}
            Array      = @("One", "Two", @("Three", "Four"), "Five")
            EmptyArray = @()
            HashTable  = @{city="New York"; currency="Dollar	(`$)"; postalCode=10021; Etc = @("Three", "Four", "Five")}
            Ordered    = [Ordered]@{One = 1; Two = 2; Three = 3; Four = 4}
            Object     = New-Object PSObject -Property @{Name = "One"; Value = 1; Group = @("First", "Last")}
            # DataTable  = $DataTable
            Xml        = [Xml]@"
                <items>
                    <item id="0001" type="donut">
                        <name>Cake</name>
                        <ppu>0.55</ppu>
                        <batters>
                            <batter id="1001">Regular</batter>
                            <batter id="1002">Chocolate</batter>
                            <batter id="1003">Blueberry</batter>
                        </batters>
                        <topping id="5001">None</topping>
                        <topping id="5002">Glazed</topping>
                        <topping id="5005">Sugar</topping>
                        <topping id="5006">Sprinkles</topping>
                        <topping id="5003">Chocolate</topping>
                        <topping id="5004">Maple</topping>
                    </item>

                </items>
"@
        }
    }
    
    Context 'custom object' {

        It "default conversion" {
            
            $Expression = $Object | ConvertTo-Expression
            
            $Actual = &([ScriptBlock]::Create($Expression))
            
            $Actual.String      | Should -Be $Object.String
            $Actual.Text        | Should -Be $Object.Text
            $Actual.Char        | Should -Be $Object.Char
            $Actual.Byte        | Should -Be $Object.Byte
            $Actual.Int         | Should -Be $Object.Int
            $Actual.Long        | Should -Be $Object.Long
            $Actual.Null        | Should -Be $Object.Null
            $Actual.Booleans[0] | Should -Be $Object.Booleans[0]
            $Actual.Booleans[1] | Should -Be $Object.Booleans[1]
            $Actual.Decimal     | Should -Be $Object.Decimal
            $Actual.Single      | Should -Be $Object.Single
            $Actual.Double      | Should -Be $Object.Double
            $Actual.Long        | Should -Be $Object.Long
            $Actual.DateTime    | Should -Be $DateTime
            $Actual.TimeSpan    | Should -Be $TimeSpan
            $Actual.Version     | Should -Be $Version
            $Actual.Guid        | Should -Be $Guid
            &$Actual.Script     | Should -Be (&$Object.Script)
            $Actual.Array       | Should -Be $Object.Array
            ,$Actual.EmptyArray | Should -BeOfType [Array]
            $Actual.HashTable.City       | Should -Be $Object.HashTable.City
            $Actual.HashTable.Currency   | Should -Be $Object.HashTable.Currency
            $Actual.HashTable.PostalCode | Should -Be $Object.HashTable.PostalCode
            $Actual.HashTable.Etc        | Should -Be $Object.HashTable.Etc
            $Actual.Ordered.One          | Should -Be $Object.Ordered.One
            $Actual.Ordered.Two          | Should -Be $Object.Ordered.Two
            $Actual.Ordered.Three        | Should -Be $Object.Ordered.Three
            $Actual.Ordered.Four         | Should -Be $Object.Ordered.Four
            $Actual.Object.Name          | Should -Be $Object.Object.Name
            $Actual.Object.Value         | Should -Be $Object.Object.Value
            $Actual.Object.Group         | Should -Be $Object.Object.Group
            # $Actual.DataTable.Column1[0] | Should -Be $Object.DataTable.Column1[0]
            # $Actual.DataTable.Column1[1] | Should -Be $Object.DataTable.Column1[1]
            # $Actual.DataTable.Column2[0] | Should -Be $Object.DataTable.Column2[0]
            # $Actual.DataTable.Column2[1] | Should -Be $Object.DataTable.Column2[1]
        }

        It "compress" {
            
            $Expression = $Object | ConvertTo-Expression -Expand -1
            
            $Actual = &([ScriptBlock]::Create($Expression))
            
            $Actual.String      | Should -Be $Object.String
            $Actual.Text        | Should -Be $Object.Text
            $Actual.Char        | Should -Be $Object.Char
            $Actual.Byte        | Should -Be $Object.Byte
            $Actual.Int         | Should -Be $Object.Int
            $Actual.Long        | Should -Be $Object.Long
            $Actual.Null        | Should -Be $Object.Null
            $Actual.Booleans[0] | Should -Be $Object.Booleans[0]
            $Actual.Booleans[1] | Should -Be $Object.Booleans[1]
            $Actual.Decimal     | Should -Be $Object.Decimal
            $Actual.Single      | Should -Be $Object.Single
            $Actual.Double      | Should -Be $Object.Double
            $Actual.Long        | Should -Be $Object.Long
            $Actual.DateTime    | Should -Be $DateTime
            $Actual.TimeSpan    | Should -Be $TimeSpan
            $Actual.Guid        | Should -Be $Guid
            $Actual.Version     | Should -Be $Version
            &$Actual.Script     | Should -Be (&$Object.Script)
            $Actual.Array       | Should -Be $Object.Array
            ,$Actual.EmptyArray | Should -BeOfType [Array]
            $Actual.HashTable.City       | Should -Be $Object.HashTable.City
            $Actual.HashTable.Currency   | Should -Be $Object.HashTable.Currency
            $Actual.HashTable.PostalCode | Should -Be $Object.HashTable.PostalCode
            $Actual.HashTable.Etc        | Should -Be $Object.HashTable.Etc
            $Actual.Ordered.One          | Should -Be $Object.Ordered.One
            $Actual.Ordered.Two          | Should -Be $Object.Ordered.Two
            $Actual.Ordered.Three        | Should -Be $Object.Ordered.Three
            $Actual.Ordered.Four         | Should -Be $Object.Ordered.Four
            $Actual.Object.Name          | Should -Be $Object.Object.Name
            $Actual.Object.Value         | Should -Be $Object.Object.Value
            $Actual.Object.Group         | Should -Be $Object.Object.Group
            # $Actual.DataTable.Column1[0] | Should -Be $Object.DataTable.Column1[0]
            # $Actual.DataTable.Column1[1] | Should -Be $Object.DataTable.Column1[1]
            # $Actual.DataTable.Column2[0] | Should -Be $Object.DataTable.Column2[0]
            # $Actual.DataTable.Column2[1] | Should -Be $Object.DataTable.Column2[1]
        }
        
        It "converts strong type" {
            
            $Expression = $Object | ConvertTo-Expression -Strong
            
            $Actual = &([ScriptBlock]::Create($Expression))
            
            $Actual.String      | Should-BeEqualTo $Object.String
            $Actual.Text        | Should-BeEqualTo $Object.Text
            $Actual.Char        | Should-BeEqualTo $Object.Char
            $Actual.Byte        | Should-BeEqualTo $Object.Byte
            $Actual.Int         | Should-BeEqualTo $Object.Int
            $Actual.Long        | Should-BeEqualTo $Object.Long
            $Actual.Null        | Should -Be $Object.Null
            $Actual.Booleans[0] | Should-BeEqualTo $Object.Booleans[0]
            $Actual.Booleans[1] | Should-BeEqualTo $Object.Booleans[1]
            $Actual.Decimal     | Should-BeEqualTo $Object.Decimal
            $Actual.Single      | Should-BeEqualTo $Object.Single
            $Actual.Double      | Should-BeEqualTo $Object.Double
            $Actual.Long        | Should-BeEqualTo $Object.Long
            $Actual.DateTime    | Should-BeEqualTo $DateTime
            $Actual.TimeSpan    | Should-BeEqualTo $TimeSpan
            $Actual.Version     | Should-BeEqualTo $Version
            $Actual.Guid        | Should-BeEqualTo $Guid
            &$Actual.Script     | Should-BeEqualTo (&$Object.Script)
            $Actual.Array       | Should -Be $Object.Array
            ,$Actual.EmptyArray | Should -BeOfType [Array]
            $Actual.HashTable.City       | Should -Be $Object.HashTable.City
            $Actual.HashTable.Currency   | Should -Be $Object.HashTable.Currency
            $Actual.HashTable.PostalCode | Should -Be $Object.HashTable.PostalCode
            $Actual.HashTable.Etc        | Should -Be $Object.HashTable.Etc
            $Actual.Ordered.One          | Should -Be $Object.Ordered.One
            $Actual.Ordered.Two          | Should -Be $Object.Ordered.Two
            $Actual.Ordered.Three        | Should -Be $Object.Ordered.Three
            $Actual.Ordered.Four         | Should -Be $Object.Ordered.Four
            $Actual.Object.Name          | Should -Be $Object.Object.Name
            $Actual.Object.Value         | Should -Be $Object.Object.Value
            $Actual.Object.Group         | Should -Be $Object.Object.Group
            # $Actual.DataTable.Column1[0] | Should -Be $Object.DataTable.Column1[0]
            # $Actual.DataTable.Column1[1] | Should -Be $Object.DataTable.Column1[1]
            # $Actual.DataTable.Column2[0] | Should -Be $Object.DataTable.Column2[0]
            # $Actual.DataTable.Column2[1] | Should -Be $Object.DataTable.Column2[1]
            $Actual.XML                  | Should -BeOfType [System.Xml.XmlDocument]
        }
        
        It "convert calendar to expression" {
        
            $Calendar = (Get-UICulture).Calendar
            
            $Expression = $Calendar | ConvertTo-Expression
            
            $Actual = &([ScriptBlock]::Create($Expression))
        
            $Actual.AlgorithmType        | Should -Be $Calendar.AlgorithmType
            $Actual.CalendarType         | Should -Be $Calendar.CalendarType
            $Actual.Eras                 | Should -Be $Calendar.Eras
            $Actual.IsReadOnly           | Should -Be $Calendar.IsReadOnly
            $Actual.MaxSupportedDateTime | Should -Be $Calendar.MaxSupportedDateTime
            $Actual.MinSupportedDateTime | Should -Be $Calendar.MinSupportedDateTime
            $Actual.TwoDigitYearMax      | Should -Be $Calendar.TwoDigitYearMax
            
        }

        It "compress ConvertTo-Expression" {
        
            $User = @{Account="User01";Domain="Domain01";Admin=$True}
            
            $Expression = $User | ConvertTo-Expression -Expand -1
            
            "$Expression".Contains(" ") | Should -Be $False
            
            $Actual = &([ScriptBlock]::Create($Expression))
        
            $Actual.Account | Should-BeEqualTo $User.Account
            $Actual.Domain  | Should-BeEqualTo $User.Domain
            $Actual.Admin   | Should-BeEqualTo $User.Admin
            
        }

        It "convert Date" {
        
            $Date = Get-Date | Select-Object -Property *
            
            $Expression = $Date | ConvertTo-Expression 
            
            $Actual = &([ScriptBlock]::Create($Expression))

            $Actual.Date        | Should -Be $Date.Date
            $Actual.DateTime    | Should -Be $Date.DateTime
            $Actual.Day         | Should -Be $Date.Day
            $Actual.DayOfWeek   | Should -Be $Date.DayOfWeek
            $Actual.DayOfYear   | Should -Be $Date.DayOfYear
            $Actual.DisplayHint | Should -Be $Date.DisplayHint
            $Actual.Hour        | Should -Be $Date.Hour
            $Actual.Kind        | Should -Be $Date.Kind
            $Actual.Millisecond | Should -Be $Date.Millisecond
            $Actual.Minute      | Should -Be $Date.Minute
            $Actual.Month       | Should -Be $Date.Month
            $Actual.Second      | Should -Be $Date.Second
            $Actual.Ticks       | Should -Be $Date.Ticks
            $Actual.TimeOfDay   | Should -Be $Date.TimeOfDay
            $Actual.Year        | Should -Be $Date.Year

        }
    }
    
    Context 'system objects' {

        # $WinInitProcess = Get-Process WinInit

        # It "convert (wininit) process" {

            # $Expression = $WinInitProcess | ConvertTo-Expression 
            
            # $Actual = &([ScriptBlock]::Create($Expression))
            
            # $Actual.ProcessName | Should-BeEqualTo $WinInitProcess.ProcessName
            # $Actual.StartInfo.Environment['TEMP'] | Should -Be $WinInitProcess.StartInfo.Environment['TEMP']
            # $Actual.StartInfo.EnvironmentVariables['TEMP'] | Should -Be $WinInitProcess.StartInfo.EnvironmentVariables['TEMP']
            
        # }

        # It "convert (wininit) process (Strong)" {

            # $Expression = $WinInitProcess | ConvertTo-Expression -Strong
            
            # $Actual = &([ScriptBlock]::Create($Expression))
            
            # $Actual.ProcessName | Should-BeEqualTo $WinInitProcess.ProcessName
            # $Actual.StartInfo.Environment['TEMP'] | Should -Be $WinInitProcess.StartInfo.Environment['TEMP']
            # $Actual.StartInfo.EnvironmentVariables['TEMP'] | Should -Be $WinInitProcess.StartInfo.EnvironmentVariables['TEMP']
            
        # }

        It "convert MyInvocation" {
        

            $Expression = $MyInvocation | ConvertTo-Expression 
            
            $Actual = &([ScriptBlock]::Create($Expression))
            
            $Actual.MyCommand.Name | Should -Be $MyInvocation.MyCommand.Name
            
        }

        # It "convert MyInvocation (Strong)" {
        

            # $Expression = $MyInvocation | ConvertTo-Expression -Strong
            
            # $Actual = &([ScriptBlock]::Create($Expression))
            
            # $Actual.MyCommand.Name | Should -Be $MyInvocation.MyCommand.Name
            
        # }
    }
    
    Describe 'DataTable' {

        It "default" {

            $DataTable = New-Object Data.DataTable
            $Null = $DataTable.Columns.Add((New-Object Data.DataColumn 'Column1'), [String])
            $Null = $DataTable.Columns.Add((New-Object Data.DataColumn 'Column2'), [Int])
            $DataRow = $DataTable.NewRow()
            $DataRow.Item('Column1') = "A"
            $DataRow.Item('Column2') = 1
            $DataTable.Rows.Add($DataRow)
            $DataRow = $DataTable.NewRow()
            $DataRow.Item('Column1') = "B"
            $DataRow.Item('Column2') = 2
            $DataTable.Rows.Add($DataRow)

            $Expression = ConvertTo-Expression $DataTable

            $Actual = &([ScriptBlock]::Create($Expression))
            
            $Actual.Column1[0] | Should -Be $DataTable.Column1[0]
            $Actual.Column1[1] | Should -Be $DataTable.Column1[1]
            $Actual.Column2[0] | Should -Be $DataTable.Column2[0]
            $Actual.Column2[1] | Should -Be $DataTable.Column2[1]

            $Expression = ,$DataTable | ConvertTo-Expression

            $Actual = &([ScriptBlock]::Create($Expression))
            
            $Actual.Column1[0] | Should -Be $DataTable.Column1[0]
            $Actual.Column1[1] | Should -Be $DataTable.Column1[1]
            $Actual.Column2[0] | Should -Be $DataTable.Column2[0]
            $Actual.Column2[1] | Should -Be $DataTable.Column2[1]
        }
    }
    
    Context 'cast types' {
        BeforeAll {
            $Ordered = [Ordered]@{a = 1; b = 2}
        }
        
        It "default" {
            $Expression = $Ordered | ConvertTo-Expression -Expand 0
            "$Expression" | Should -Be "[ordered]@{a = 1; b = 2}"
        }
        
        It "strong" {
            $Expression = $Ordered | ConvertTo-Expression -Expand 0 -Strong
            "$Expression" | Should -Be "[ordered]@{a = [int]1; b = [int]2}"
        }
    
        It "explore" {
            $Expression = $Ordered | ConvertTo-Expression -Expand 0 -Explore
            "$Expression" | Should -Be "@{a = 1; b = 2}"
        }
        
        It "explore strong" {
            $Expression = $Ordered | ConvertTo-Expression -Expand 0 -Explore -Strong
            "$Expression" | Should -Be "[System.Collections.Specialized.OrderedDictionary]@{a = [int]1; b = [int]2}"
        }
    }

    Context 'Formatting' {

        BeforeEach {
            Function Test-Format ([String]$Expression, [Switch]$Strong, [Int]$Expand = 9) {
                if ([System.Environment]::NewLine -ne "`r`n") { $Expression = $Expression.Replace("`r`n", [System.Environment]::NewLine) }
                $Object = &([ScriptBlock]::Create("$Expression"))
                $Actual = ConvertTo-Expression $Object -Strong:$Strong -Expand $Expand
                $IsEqual = $Actual -eq $Expression
                if (!$IsEqual) {
                    Write-Host 'Expected:'
                    Write-Host "$Expression"
                    Write-Host 'Actual:'
                    Write-Host "$Actual"
                }
                $IsEqual
            }
        }

        It 'default formatting' {

            Test-Format "1" | Should -BeTrue

            Test-Format "'One'" | Should -BeTrue

#           Test-Format ",'One'" | Should -BeTrue

            Test-Format @"
1,
2,
3
"@ | Should -BeTrue

            Test-Format @"
'One',
'Two',
'Three'
"@ | Should -BeTrue

            Test-Format @"
'One',
'Two',
'Three',
'Four'
"@ | Should -BeTrue

            Test-Format @"
'One',
(,'Two'),
'Three',
'Four'
"@ | Should -BeTrue

            Test-Format @"
'One',
(
    'Two',
    'Three'
),
'Four'
"@ | Should -BeTrue

            Test-Format @"
'One',
@{Two = 2},
'Three',
'Four'
"@ | Should -BeTrue

            Test-Format @"
[pscustomobject]@{value = 1},
[pscustomobject]@{value = 2},
[pscustomobject]@{value = 3}
"@ | Should -BeTrue

            Test-Format @"
[pscustomobject]@{
    One = 1
    Two = 2
    Three = 3
    Four = 4
}
"@ | Should -BeTrue

            Test-Format @"
'One',
[ordered]@{
    Two = 2
    Three = 3
},
'Four'
"@ | Should -BeTrue

            Test-Format "@{One = 1}" | Should -BeTrue

            Test-Format @"
[ordered]@{
    One = 1
    Two = 2
    Three = 3
    Four = 4
}
"@ | Should -BeTrue

            Test-Format @"
[ordered]@{
    One = 1
    Two = 2
    'Three.1' = ,3.1
    Four = 4
}
"@ | Should -BeTrue

            Test-Format @"
[ordered]@{
    One = 1
    Two = 2
    'Three.12' =
        3.1,
        3.2
    Four = 4
}
"@ | Should -BeTrue

            Test-Format @"
[ordered]@{
    One = 1
    Two = 2
    Three = @{One = 3.1}
    Four = 4
}
"@ | Should -BeTrue

            Test-Format @"
[ordered]@{
    One = 1
    Two = 2
    Three = [ordered]@{
        One = 3.1
        Two = 3.2
    }
    Four = 4
}
"@ | Should -BeTrue

            Test-Format @"
[ordered]@{
    String = 'String'
    HereString = @'
Hello
World
'@
    Int = 67
    Double = 1.2
    Long = 1234567890123456
    DateTime = [datetime]'1963-10-07T17:56:53.8139055'
    Version = [version]'1.2.34567.890'
    Guid = [guid]'5f167621-6abe-4153-a26c-f643e1716720'
    Script = {2 * 3}
    Array =
        'One',
        'Two',
        'Three',
        'Four'
    ByteArray =
        1,
        2,
        3
    StringArray =
        'One',
        'Two',
        'Three'
    EmptyArray = @()
    SingleValueArray = ,'one'
    SubArray =
        'One',
        (
            'Two',
            'Three'
        ),
        'Four'
    HashTable = @{Name = 'Value'}
    Ordered = [ordered]@{
        One = 1
        Two = 2
        Three = 3
        Four = 4
    }
    Object = [pscustomobject]@{Name = 'Value'}
}
"@ | Should -BeTrue
    }

        It 'strong formatting' {

            Test-Format -Strong "[int]1"

            Test-Format -Strong "[string]'One'"

        # Test-Format -Strong "[byte[]](1, 2, 3)"

        # Test-Format -Strong @"
# [string[]](
    # 'One',
    # 'Two',
    # 'Three'
# )
# "@ | Should -BeTrue

            Test-Format -Strong @"
[Object[]](
    [string]'One',
    [string]'Two',
    [string]'Three',
    [string]'Four'
)
"@ | Should -BeTrue

            Test-Format -Strong @"
[Object[]](
    [string]'One',
    [Object[]][string]'Two',
    [string]'Three',
    [string]'Four'
)
"@ | Should -BeTrue

            Test-Format -Strong @"
[Object[]](
    [string]'One',
    [Object[]](
        [string]'Two',
        [string]'Three'
    ),
    [string]'Four'
)
"@ | Should -BeTrue

            Test-Format -Strong @"
[Object[]](
    [string]'One',
    [hashtable]@{Two = [int]2},
    [string]'Three',
    [string]'Four'
)
"@ | Should -BeTrue

            Test-Format -Strong @"
[Object[]](
    [pscustomobject]@{value = [int]1},
    [pscustomobject]@{value = [int]2},
    [pscustomobject]@{value = [int]3}
)
"@ | Should -BeTrue

            Test-Format -Strong @"
[pscustomobject]@{
    One = [int]1
    Two = [int]2
    Three = [int]3
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong @"
[Object[]](
    [string]'One',
    [ordered]@{
        Two = [int]2
        Three = [int]3
    },
    [string]'Four'
)
"@ | Should -BeTrue

            Test-Format -Strong "[hashtable]@{One = [int]1}"

            Test-Format -Strong @"
[ordered]@{
    One = [int]1
    Two = [int]2
    Three = [int]3
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong @"
[ordered]@{
    One = [int]1
    Two = [int]2
    'Three.1' = [Object[]][double]3.1
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong @"
[ordered]@{
    One = [int]1
    Two = [int]2
    'Three.12' = [Object[]](
        [double]3.1,
        [double]3.2
    )
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong @"
[ordered]@{
    One = [int]1
    Two = [int]2
    Three = [hashtable]@{One = [double]3.1}
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong @"
[ordered]@{
    One = [int]1
    Two = [int]2
    Three = [ordered]@{
        One = [double]3.1
        Two = [double]3.2
    }
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong @"
[ordered]@{
    String = [string]'String'
    HereString = [string]@'
Hello
World
'@
    Int = [int]67
    Double = [double]1.2
    Long = [long]1234567890123456
    DateTime = [datetime]'1963-10-07T17:56:53.8139055'
    Version = [version]'1.2.34567.890'
    Guid = [guid]'5f167621-6abe-4153-a26c-f643e1716720'
    Script = [scriptblock]{2 * 3}
    Array = [Object[]](
        [string]'One',
        [string]'Two',
        [string]'Three',
        [string]'Four'
    )
    ByteArray = [byte[]](1, 2, 3)
    StringArray = [string[]](
        'One',
        'Two',
        'Three'
    )
    EmptyArray = [Object[]]@()
    SingleValueArray = [Object[]][string]'one'
    SubArray = [Object[]](
        [string]'One',
        [Object[]](
            [string]'Two',
            [string]'Three'
        ),
        [string]'Four'
    )
    HashTable = [hashtable]@{Name = [string]'Value'}
    Ordered = [ordered]@{
        One = [int]1
        Two = [int]2
        Three = [int]3
        Four = [int]4
    }
    Object = [pscustomobject]@{Name = [string]'Value'}
}
"@ | Should -BeTrue
    }

        It 'formatting -expand 1' {

            Test-Format -Expand 1 "1"

            Test-Format -Expand 1 "'One'"

            Test-Format -Expand 1 @"
1,
2,
3
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
'One',
'Two',
'Three'
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
'One',
'Two',
'Three',
'Four'
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
'One',
(,'Two'),
'Three',
'Four'
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
'One',
('Two', 'Three'),
'Four'
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
'One',
@{Two = 2},
'Three',
'Four'
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
[pscustomobject]@{value = 1},
[pscustomobject]@{value = 2},
[pscustomobject]@{value = 3}
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
[pscustomobject]@{
    One = 1
    Two = 2
    Three = 3
    Four = 4
}
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
'One',
[ordered]@{Two = 2; Three = 3},
'Four'
"@ | Should -BeTrue

            Test-Format -Expand 1 "@{One = 1}"

            Test-Format -Expand 1 @"
[ordered]@{
    One = 1
    Two = 2
    Three = 3
    Four = 4
}
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
[ordered]@{
    One = 1
    Two = 2
    'Three.1' = ,3.1
    Four = 4
}
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
[ordered]@{
    One = 1
    Two = 2
    'Three.12' = 3.1, 3.2
    Four = 4
}
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
[ordered]@{
    One = 1
    Two = 2
    Three = @{One = 3.1}
    Four = 4
}
"@ | Should -BeTrue

            Test-Format -Expand 1 @"
[ordered]@{
    One = 1
    Two = 2
    Three = [ordered]@{One = 3.1; Two = 3.2}
    Four = 4
}
"@ | Should -BeTrue
            Test-Format -Expand 1 @"
[ordered]@{
    String = 'String'
    HereString = @'
Hello
World
'@
    Int = 67
    Double = 1.2
    Long = 1234567890123456
    DateTime = [datetime]'1963-10-07T17:56:53.8139055'
    Version = [version]'1.2.34567.890'
    Guid = [guid]'5f167621-6abe-4153-a26c-f643e1716720'
    Script = {2 * 3}
    Array = 'One', 'Two', 'Three', 'Four'
    ByteArray = 1, 2, 3
    StringArray = 'One', 'Two', 'Three'
    EmptyArray = @()
    SingleValueArray = ,'one'
    SubArray = 'One', ('Two', 'Three'), 'Four'
    HashTable = @{Name = 'Value'}
    Ordered = [ordered]@{One = 1; Two = 2; Three = 3; Four = 4}
    Object = [pscustomobject]@{Name = 'Value'}
}
"@ | Should -BeTrue
    }

        It 'strong formatting -expand 1' {

            Test-Format -Strong -Expand 1 "[int]1"

            Test-Format -Strong -Expand 1 "[string]'One'"

        # Test-Format -Strong -Expand 1 "[byte[]](1, 2, 3)"

        # Test-Format -Strong -Expand 1 @"
# [string[]](
    # 'One',
    # 'Two',
    # 'Three'
# )
# "@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[Object[]](
    [string]'One',
    [string]'Two',
    [string]'Three',
    [string]'Four'
)
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[Object[]](
    [string]'One',
    [Object[]][string]'Two',
    [string]'Three',
    [string]'Four'
)
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[Object[]](
    [string]'One',
    [Object[]]([string]'Two', [string]'Three'),
    [string]'Four'
)
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[Object[]](
    [string]'One',
    [hashtable]@{Two = [int]2},
    [string]'Three',
    [string]'Four'
)
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[Object[]](
    [pscustomobject]@{value = [int]1},
    [pscustomobject]@{value = [int]2},
    [pscustomobject]@{value = [int]3}
)
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[pscustomobject]@{
    One = [int]1
    Two = [int]2
    Three = [int]3
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[Object[]](
    [string]'One',
    [ordered]@{Two = [int]2; Three = [int]3},
    [string]'Four'
)
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 "[hashtable]@{One = [int]1}"

            Test-Format -Strong -Expand 1 @"
[ordered]@{
    One = [int]1
    Two = [int]2
    Three = [int]3
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[ordered]@{
    One = [int]1
    Two = [int]2
    'Three.1' = [Object[]][double]3.1
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[ordered]@{
    One = [int]1
    Two = [int]2
    'Three.12' = [Object[]]([double]3.1, [double]3.2)
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[ordered]@{
    One = [int]1
    Two = [int]2
    Three = [hashtable]@{One = [double]3.1}
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[ordered]@{
    One = [int]1
    Two = [int]2
    Three = [ordered]@{One = [double]3.1; Two = [double]3.2}
    Four = [int]4
}
"@ | Should -BeTrue

            Test-Format -Strong -Expand 1 @"
[ordered]@{
    String = [string]'String'
    HereString = [string]@'
Hello
World
'@
    Int = [int]67
    Double = [double]1.2
    Long = [long]1234567890123456
    DateTime = [datetime]'1963-10-07T17:56:53.8139055'
    Version = [version]'1.2.34567.890'
    Guid = [guid]'5f167621-6abe-4153-a26c-f643e1716720'
    Script = [scriptblock]{2 * 3}
    Array = [Object[]]([string]'One', [string]'Two', [string]'Three', [string]'Four')
    ByteArray = [Object[]]([int]1, [int]2, [int]3)
    StringArray = [Object[]]([string]'One', [string]'Two', [string]'Three')
    EmptyArray = [Object[]]@()
    SingleValueArray = [Object[]][string]'one'
    SubArray = [Object[]]([string]'One', [Object[]]([string]'Two', [string]'Three'), [string]'Four')
    HashTable = [hashtable]@{Name = [string]'Value'}
    Ordered = [ordered]@{One = [int]1; Two = [int]2; Three = [int]3; Four = [int]4}
    Object = [pscustomobject]@{Name = [string]'Value'}
}
"@ | Should -BeTrue
    }

        It 'formatting -expand 0' {
    
            Test-Format -Expand 0 "1"

            Test-Format -Expand 0 "'One'"

            Test-Format -Expand 0 "1, 2, 3"

            Test-Format -Expand 0 "'One', 'Two', 'Three'"

            Test-Format -Expand 0 "'One', 'Two', 'Three', 'Four'"

            Test-Format -Expand 0 "'One', (,'Two'), 'Three', 'Four'"

            Test-Format -Expand 0 "'One', ('Two', 'Three'), 'Four'"

            Test-Format -Expand 0 "'One', @{Two = 2}, 'Three', 'Four'"

            Test-Format -Expand 0 "[pscustomobject]@{value = 1}, [pscustomobject]@{value = 2}, [pscustomobject]@{value = 3}"

            Test-Format -Expand 0 "[pscustomobject]@{One = 1; Two = 2; Three = 3; Four = 4}"

            Test-Format -Expand 0 "'One', [ordered]@{Two = 2; Three = 3}, 'Four'"

            Test-Format -Expand 0 "@{One = 1}"

            Test-Format -Expand 0 "[ordered]@{One = 1; Two = 2; Three = 3; Four = 4}"

            Test-Format -Expand 0 "[ordered]@{One = 1; Two = 2; 'Three.1' = ,3.1; Four = 4}"

            Test-Format -Expand 0 "[ordered]@{One = 1; Two = 2; 'Three.12' = 3.1, 3.2; Four = 4}"

            Test-Format -Expand 0 "[ordered]@{One = 1; Two = 2; Three = @{One = 3.1}; Four = 4}"

            Test-Format -Expand 0 "[ordered]@{One = 1; Two = 2; Three = [ordered]@{One = 3.1; Two = 3.2}; Four = 4}"

            Test-Format -Expand 0 @"
[ordered]@{String = 'String'; HereString = @'
Hello
World
'@
; Int = 67; Double = 1.2; Long = 1234567890123456; DateTime = [datetime]'1963-10-07T17:56:53.8139055'; Version = [version]'1.2.34567.890'; Guid = [guid]'5f167621-6abe-4153-a26c-f643e1716720'; Script = {2 * 3}; Array = 'One', 'Two', 'Three', 'Four'; ByteArray = 1, 2, 3; StringArray = 'One', 'Two', 'Three'; EmptyArray = @(); SingleValueArray = ,'one'; SubArray = 'One', ('Two', 'Three'), 'Four'; HashTable = @{Name = 'Value'}; Ordered = [ordered]@{One = 1; Two = 2; Three = 3; Four = 4}; Object = [pscustomobject]@{Name = 'Value'}}
"@ | Should -BeTrue

    }

        It 'strong formatting -expand 0' {
    
            Test-Format -Strong -Expand 0 "[int]1"

            Test-Format -Strong -Expand 0 "[string]'One'"

        # Test-Format -Strong -Expand 0 "[byte[]](1, 2, 3)"

        # Test-Format -Strong -Expand 0 "[string[]]('One', 'Two', 'Three')"

            Test-Format -Strong -Expand 0 "[Object[]]([string]'One', [string]'Two', [string]'Three', [string]'Four')"

            Test-Format -Strong -Expand 0 "[Object[]]([string]'One', [Object[]][string]'Two', [string]'Three', [string]'Four')"

            Test-Format -Strong -Expand 0 "[Object[]]([string]'One', [Object[]]([string]'Two', [string]'Three'), [string]'Four')"

            Test-Format -Strong -Expand 0 "[Object[]]([string]'One', [hashtable]@{Two = [int]2}, [string]'Three', [string]'Four')"

            Test-Format -Strong -Expand 0 "[Object[]]([pscustomobject]@{value = [int]1}, [pscustomobject]@{value = [int]2}, [pscustomobject]@{value = [int]3})"

            Test-Format -Strong -Expand 0 "[pscustomobject]@{One = [int]1; Two = [int]2; Three = [int]3; Four = [int]4}"

            Test-Format -Strong -Expand 0 "[Object[]]([string]'One', [ordered]@{Two = [int]2; Three = [int]3}, [string]'Four')"

            Test-Format -Strong -Expand 0 "[hashtable]@{One = [int]1}"

            Test-Format -Strong -Expand 0 "[ordered]@{One = [int]1; Two = [int]2; Three = [int]3; Four = [int]4}"

            Test-Format -Strong -Expand 0 "[ordered]@{One = [int]1; Two = [int]2; 'Three.1' = [Object[]][double]3.1; Four = [int]4}"

            Test-Format -Strong -Expand 0 "[ordered]@{One = [int]1; Two = [int]2; 'Three.12' = [Object[]]([double]3.1, [double]3.2); Four = [int]4}"

            Test-Format -Strong -Expand 0 "[ordered]@{One = [int]1; Two = [int]2; Three = [hashtable]@{One = [double]3.1}; Four = [int]4}"

            Test-Format -Strong -Expand 0 "[ordered]@{One = [int]1; Two = [int]2; Three = [ordered]@{One = [double]3.1; Two = [double]3.2}; Four = [int]4}"

            Test-Format -Strong -Expand 0 @"
[ordered]@{String = [string]'String'; HereString = [string]@'
Hello
World
'@
; Int = [int]67; Double = [double]1.2; Long = [long]1234567890123456; DateTime = [datetime]'1963-10-07T17:56:53.8139055'; Version = [version]'1.2.34567.890'; Guid = [guid]'5f167621-6abe-4153-a26c-f643e1716720'; Script = [scriptblock]{2 * 3}; Array = [Object[]]([string]'One', [string]'Two', [string]'Three', [string]'Four'); ByteArray = [Object[]]([int]1, [int]2, [int]3); StringArray = [Object[]]([string]'One', [string]'Two', [string]'Three'); EmptyArray = [Object[]]@(); SingleValueArray = [Object[]][string]'one'; SubArray = [Object[]]([string]'One', [Object[]]([string]'Two', [string]'Three'), [string]'Four'); HashTable = [hashtable]@{Name = [string]'Value'}; Ordered = [ordered]@{One = [int]1; Two = [int]2; Three = [int]3; Four = [int]4}; Object = [pscustomobject]@{Name = [string]'Value'}}
"@ | Should -BeTrue
    }

        It 'formatting -expand -1 (compressed)' {

            Test-Format -Expand -1 "1" | Should -BeTrue

            Test-Format -Expand -1 "'One'" | Should -BeTrue

            Test-Format -Expand -1 "1,2,3" | Should -BeTrue

            Test-Format -Expand -1 "'One','Two','Three'" | Should -BeTrue

            Test-Format -Expand -1 "'One','Two','Three','Four'" | Should -BeTrue

            Test-Format -Expand -1 "'One',(,'Two'),'Three','Four'" | Should -BeTrue

            Test-Format -Expand -1 "'One',('Two','Three'),'Four'" | Should -BeTrue

            Test-Format -Expand -1 "'One',@{Two=2},'Three','Four'" | Should -BeTrue

            Test-Format -Expand -1 "[pscustomobject]@{value=1},[pscustomobject]@{value=2},[pscustomobject]@{value=3}" | Should -BeTrue

            Test-Format -Expand -1 "[pscustomobject]@{One=1;Two=2;Three=3;Four=4}" | Should -BeTrue

            Test-Format -Expand -1 "'One',[ordered]@{Two=2;Three=3},'Four'" | Should -BeTrue

            Test-Format -Expand -1 "@{One=1}" | Should -BeTrue

            Test-Format -Expand -1 "[ordered]@{One=1;Two=2;Three=3;Four=4}" | Should -BeTrue

            Test-Format -Expand -1 "[ordered]@{One=1;Two=2;'Three.1'=,3.1;Four=4}" | Should -BeTrue

            Test-Format -Expand -1 "[ordered]@{One=1;Two=2;'Three.12'=3.1,3.2;Four=4}" | Should -BeTrue

            Test-Format -Expand -1 "[ordered]@{One=1;Two=2;Three=@{One=3.1};Four=4}" | Should -BeTrue

            Test-Format -Expand -1 "[ordered]@{One=1;Two=2;Three=[ordered]@{One=3.1;Two=3.2};Four=4}" | Should -BeTrue

            Test-Format -Expand -1 @"
[ordered]@{String='String';HereString=@'
Hello
World
'@
;Int=67;Double=1.2;Long=1234567890123456;DateTime=[datetime]'1963-10-07T17:56:53.8139055';Version=[version]'1.2.34567.890';Guid=[guid]'5f167621-6abe-4153-a26c-f643e1716720';Script={2 * 3};Array='One','Two','Three','Four';ByteArray=1,2,3;StringArray='One','Two','Three';EmptyArray=@();SingleValueArray=,'one';SubArray='One',('Two','Three'),'Four';HashTable=@{Name='Value'};Ordered=[ordered]@{One=1;Two=2;Three=3;Four=4};Object=[pscustomobject]@{Name='Value'}}
"@ | Should -BeTrue
    }

        It 'strong formatting -expand -1 (compressed)' {
    
            Test-Format -Strong -Expand -1 "[int]1" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[string]'One'" | Should -BeTrue

        # Test-Format -Strong -Expand -1 "[byte[]](1,2,3)" | Should -BeTrue

        # Test-Format -Strong -Expand -1 "[string[]]('One','Two','Three')" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[Object[]]([string]'One',[string]'Two',[string]'Three',[string]'Four')" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[Object[]]([string]'One',[Object[]][string]'Two',[string]'Three',[string]'Four')" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[Object[]]([string]'One',[Object[]]([string]'Two',[string]'Three'),[string]'Four')" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[Object[]]([string]'One',[hashtable]@{Two=[int]2},[string]'Three',[string]'Four')" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[Object[]]([pscustomobject]@{value=[int]1},[pscustomobject]@{value=[int]2},[pscustomobject]@{value=[int]3})" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[pscustomobject]@{One=[int]1;Two=[int]2;Three=[int]3;Four=[int]4}" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[Object[]]([string]'One',[ordered]@{Two=[int]2;Three=[int]3},[string]'Four')" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[hashtable]@{One=[int]1}" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[ordered]@{One=[int]1;Two=[int]2;Three=[int]3;Four=[int]4}" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[ordered]@{One=[int]1;Two=[int]2;'Three.1'=[Object[]][double]3.1;Four=[int]4}" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[ordered]@{One=[int]1;Two=[int]2;'Three.12'=[Object[]]([double]3.1,[double]3.2);Four=[int]4}" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[ordered]@{One=[int]1;Two=[int]2;Three=[hashtable]@{One=[double]3.1};Four=[int]4}" | Should -BeTrue

            Test-Format -Strong -Expand -1 "[ordered]@{One=[int]1;Two=[int]2;Three=[ordered]@{One=[double]3.1;Two=[double]3.2};Four=[int]4}" | Should -BeTrue

            Test-Format -Strong -Expand -1 @"
[ordered]@{String=[string]'String';HereString=[string]@'
Hello
World
'@
;Int=[int]67;Double=[double]1.2;Long=[long]1234567890123456;DateTime=[datetime]'1963-10-07T17:56:53.8139055';Version=[version]'1.2.34567.890';Guid=[guid]'5f167621-6abe-4153-a26c-f643e1716720';Script=[scriptblock]{2 * 3};Array=[Object[]]([string]'One',[string]'Two',[string]'Three',[string]'Four');ByteArray=[Object[]]([int]1,[int]2,[int]3);StringArray=[Object[]]([string]'One',[string]'Two',[string]'Three');EmptyArray=[Object[]]@();SingleValueArray=[Object[]][string]'one';SubArray=[Object[]]([string]'One',[Object[]]([string]'Two',[string]'Three'),[string]'Four');HashTable=[hashtable]@{Name=[string]'Value'};Ordered=[ordered]@{One=[int]1;Two=[int]2;Three=[int]3;Four=[int]4};Object=[pscustomobject]@{Name=[string]'Value'}}
"@ | Should -BeTrue

        }
        It 'Bug #1 Single quote in Hashtable key' {
            Test-Format "@{ab = 'a''b'}" | Should -BeTrue
            Test-Format "@{'a''b' = 'ab'}" | Should -BeTrue
            Test-Format "[pscustomobject]@{ab = 'a''b'}" | Should -BeTrue
            Test-Format "[pscustomobject]@{'a''b' = 'ab'}" | Should -BeTrue
        }
}

    Context 'recursive references' {
    
        It "recursive hash table" {
            $Object = @{
                Name = "Tree"
                Parent = @{
                    Name = "Parent"
                    Child = @{
                        Name = "Child"
                    }
                }
            }
            $Object.Parent.Child.Parent = $Object.Parent
            $Expression = $Object | ConvertTo-Expression
            
            $Actual = &([ScriptBlock]::Create($Expression))
            
            $Actual.Parent.Child.Name | Should -Be $Object.Parent.Child.Name
    
        }

        It "recursive custom object" {
            $Parent = [PSCustomObject]@{
                Name = "Parent"
            }
            $Child = [PSCustomObject]@{
                Name = "Child"
            }
            $Parent | Add-Member Child $Child
            $Child | Add-Member Parent $Parent
            
            $Expression = $Parent | ConvertTo-Expression
            
            $Actual = &([ScriptBlock]::Create($Expression))
            
            $Actual.Child.Parent.Name | Should -Be $Parent.Child.Parent.Name
        }
    }
    
    Context 'Credentials and SecureString' {
        
        BeforeAll {
            $Username = 'Username'
            $Password = 'P@ssword1'
            $SecureString = $Password | ConvertTo-SecureString -AsPlainText -Force
            $Credential = New-Object PSCredential $Username, $SecureString
        }
        
        It "Default expression" {
            $Expression = $Credential | ConvertTo-Expression
            
            $Actual = &([ScriptBlock]::Create($Expression))
            $Actual.UserName | Should -Be $Username
            $Actual.GetNetworkCredential().password | Should -Be $Password
        }
        
        It "Strong expression" {
            $Expression = $Credential | ConvertTo-Expression -Strong
            
            $Actual = &([ScriptBlock]::Create($Expression))
            $Actual.UserName | Should -Be $Username
            $Actual.GetNetworkCredential().password | Should -Be $Password
        }
    }
}

Describe 'Issues' {

    Context '#6 Consider preserving specific collection types, if they can be initialized from arrays' {
        
        BeforeAll {
            $Collection = (1..5).Where({ $_ % 2 })
        }
        
        It "Default collection" {
            ConvertTo-Expression $Collection | Should -Be @'
1,
3,
5
'@
        }

        It "Strong collection" {
            ConvertTo-Expression $Collection -Strong | Should -Be @'
[System.Collections.ObjectModel.Collection[psobject]](
    1,
    3,
    5
)
'@
        }

        It "Collapsed strong expression" {
            ConvertTo-Expression $Collection -Strong -Expand 0 |
            Should -Be '[System.Collections.ObjectModel.Collection[psobject]](1, 3, 5)'
        }

        It "Compressed strong expression" {
            ConvertTo-Expression $Collection -Strong -Expand -1 | 
            Should -Be '[System.Collections.ObjectModel.Collection[psobject]](1,3,5)'

        }
    }
}
