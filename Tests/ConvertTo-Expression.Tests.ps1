$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Function Should-BeEqualTo ($Value2, [Parameter(ValueFromPipeLine = $True)]$Value1) {
	$Value1 | Should -Be $Value2
	$Value1 | Should -BeOfType $Value2.GetType().Name
}

Describe 'ConvertTo-PSON' {
	
	$Version  = $PSVersionTable.PSVersion
	$TimeSpan = New-TimeSpan -Hour 1 -Minute 25
	$DateTime = Get-Date
	Mock Get-Date -ParameterFilter {$null -eq $Date} {$DateTime}
	
	Context 'Convert custom object' {

	$DataTable = New-Object Data.DataTable
	$DataColumn = New-Object Data.DataColumn
	$DataColumn.ColumnName = "Name"
	$DataTable.Columns.Add($DataColumn)
	$DataRow = $DataTable.NewRow()
	$DataRow.Item("Name") = "Hello"
	$DataTable.Rows.Add($DataRow)
	$DataRow = $DataTable.NewRow()
	$DataRow.Item("Name") = "World"
	$DataTable.Rows.Add($DataRow)

	$Object = @{
		String    = [String]"String"
		Text      = [String]"Hello`r`nWorld"
		Char      = [Char]65
		Byte      = [Byte]66
		Int       = [Int]67
		Long      = [Long]68
		Null      = $Null
		Booleans  = $False, $True
		Decimal   = [Decimal]69
		Single    = [Single]70
		Double    = [Double]71
		DateTime  = $DateTime
		TimeSpan  = $TimeSpan
		Version   = $Version
		Array     = @("One", "Two", @("Three", "Four"), "Five")
		HashTable = @{city="New York"; currency="Dollar	(`$)"; postalCode=10021; Etc = @("Three", "Four", "Five")}
		Ordered   = [Ordered]@{One = 1; Two = 2; Three = 3; Four = 4}
		Object    = New-Object PSObject -Property @{Name = "One"; Value = 1; Group = @("First", "Last")}
		DataTable = $DataTable
		Xml       = [Xml]@"
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

		It "casts type" {
			
			$PSON = $Object | PSON
			
			$PSON | Should -BeOfType [String]
			
			$Test = $PSON | ConvertFrom-PSON
			
			$Test.String      | Should -Be $Object.String
			$Test.Text        | Should -Be $Object.Text
			$Test.Char        | Should -Be $Object.Char
			$Test.Byte        | Should -Be $Object.Byte
			$Test.Int         | Should -Be $Object.Int
			$Test.Long        | Should -Be $Object.Long
			$Test.Null        | Should -Be $Object.Null
			$Test.Booleans[0] | Should -Be $Object.Booleans[0]
			$Test.Booleans[1] | Should -Be $Object.Booleans[1]
			$Test.Decimal     | Should -Be $Object.Decimal
			$Test.Single      | Should -Be $Object.Single
			$Test.Double      | Should -Be $Object.Double
			$Test.Long        | Should -Be $Object.Long
			$Test.DateTime    | Should -Be $DateTime
			$Test.TimeSpan    | Should -Be $TimeSpan
			$Test.Version     | Should -Be $Version
			$Test.Array       | Should -Be $Object.Array
			$Test.HashTable.City       | Should -Be $Object.HashTable.City
			$Test.HashTable.Currency   | Should -Be $Object.HashTable.Currency
			$Test.HashTable.PostalCode | Should -Be $Object.HashTable.PostalCode
			$Test.HashTable.Etc        | Should -Be $Object.HashTable.Etc
			$Test.Ordered.One          | Should -Be $Object.Ordered.One
			$Test.Ordered.Two          | Should -Be $Object.Ordered.Two
			$Test.Ordered.Three        | Should -Be $Object.Ordered.Three
			$Test.Ordered.Four         | Should -Be $Object.Ordered.Four
			$Test.Object.Name          | Should -Be $Object.Object.Name
			$Test.Object.Value         | Should -Be $Object.Object.Value
			$Test.Object.Group         | Should -Be $Object.Object.Group
			$Test.DataTable.Name[0]    | Should -Be $Object.DataTable.Name[0]
			$Test.DataTable.Name[1]    | Should -Be $Object.DataTable.Name[1]
		}

		It "compress" {
			
			$PSON = $Object | PSON -Expand -1
			
			$PSON | Should -BeOfType [String]
			
			$Test = $PSON | ConvertFrom-PSON
			
			$Test.String      | Should -Be $Object.String
			$Test.Text        | Should -Be $Object.Text
			$Test.Char        | Should -Be $Object.Char
			$Test.Byte        | Should -Be $Object.Byte
			$Test.Int         | Should -Be $Object.Int
			$Test.Long        | Should -Be $Object.Long
			$Test.Null        | Should -Be $Object.Null
			$Test.Booleans[0] | Should -Be $Object.Booleans[0]
			$Test.Booleans[1] | Should -Be $Object.Booleans[1]
			$Test.Decimal     | Should -Be $Object.Decimal
			$Test.Single      | Should -Be $Object.Single
			$Test.Double      | Should -Be $Object.Double
			$Test.Long        | Should -Be $Object.Long
			$Test.DateTime    | Should -Be $DateTime
			$Test.TimeSpan    | Should -Be $TimeSpan
			$Test.Version     | Should -Be $Version
			$Test.Array       | Should -Be $Object.Array
			$Test.HashTable.City       | Should -Be $Object.HashTable.City
			$Test.HashTable.Currency   | Should -Be $Object.HashTable.Currency
			$Test.HashTable.PostalCode | Should -Be $Object.HashTable.PostalCode
			$Test.HashTable.Etc        | Should -Be $Object.HashTable.Etc
			$Test.Ordered.One          | Should -Be $Object.Ordered.One
			$Test.Ordered.Two          | Should -Be $Object.Ordered.Two
			$Test.Ordered.Three        | Should -Be $Object.Ordered.Three
			$Test.Ordered.Four         | Should -Be $Object.Ordered.Four
			$Test.Object.Name          | Should -Be $Object.Object.Name
			$Test.Object.Value         | Should -Be $Object.Object.Value
			$Test.Object.Group         | Should -Be $Object.Object.Group
			$Test.DataTable.Name[0]    | Should -Be $Object.DataTable.Name[0]
			$Test.DataTable.Name[1]    | Should -Be $Object.DataTable.Name[1]
		}
		
		It "converts strict type" {
			
			$PSON = $Object | PSON -Type Strict
			
			$PSON | Should -BeOfType [String]
			
			$Test = $PSON | ConvertFrom-PSON
			
			$Test.String      | Should-BeEqualTo $Object.String
			$Test.Text        | Should-BeEqualTo $Object.Text
			$Test.Char        | Should-BeEqualTo $Object.Char
			$Test.Byte        | Should-BeEqualTo $Object.Byte
			$Test.Int         | Should-BeEqualTo $Object.Int
			$Test.Long        | Should-BeEqualTo $Object.Long
			$Test.Null        | Should -Be $Object.Null
			$Test.Booleans[0] | Should-BeEqualTo $Object.Booleans[0]
			$Test.Booleans[1] | Should-BeEqualTo $Object.Booleans[1]
			$Test.Decimal     | Should-BeEqualTo $Object.Decimal
			$Test.Single      | Should-BeEqualTo $Object.Single
			$Test.Double      | Should-BeEqualTo $Object.Double
			$Test.Long        | Should-BeEqualTo $Object.Long
			$Test.DateTime    | Should-BeEqualTo $DateTime
			$Test.TimeSpan    | Should-BeEqualTo $TimeSpan
			$Test.Version     | Should-BeEqualTo $Version
			$Test.Array       | Should -Be $Object.Array
			$Test.HashTable.City       | Should -Be $Object.HashTable.City
			$Test.HashTable.Currency   | Should -Be $Object.HashTable.Currency
			$Test.HashTable.PostalCode | Should -Be $Object.HashTable.PostalCode
			$Test.HashTable.Etc        | Should -Be $Object.HashTable.Etc
			$Test.Ordered.One          | Should -Be $Object.Ordered.One
			$Test.Ordered.Two          | Should -Be $Object.Ordered.Two
			$Test.Ordered.Three        | Should -Be $Object.Ordered.Three
			$Test.Ordered.Four         | Should -Be $Object.Ordered.Four
			$Test.Object.Name          | Should -Be $Object.Object.Name
			$Test.Object.Value         | Should -Be $Object.Object.Value
			$Test.Object.Group         | Should -Be $Object.Object.Group
			$Test.DataTable.Name[0]    | Should -Be $Object.DataTable.Name[0]
			$Test.DataTable.Name[1]    | Should -Be $Object.DataTable.Name[1]
			$Test.XML                  | Should -BeOfType [System.Xml.XmlDocument]
		}
		
		It "convert calendar to PSON" {
		
			$Calandar = (Get-UICulture).Calendar | ConvertTo-Pson
			
			$PSON = $Calandar | PSON
			
			$PSON | Should -BeOfType [String]
			
			$Test = $PSON | ConvertFrom-PSON
		
			$Test.AlgorithmType        | Should -Be $Calendar.AlgorithmType
			$Test.CalendarType         | Should -Be $Calendar.CalendarType
			$Test.Eras                 | Should -Be $Calendar.Eras
			$Test.IsReadOnly           | Should -Be $Calendar.IsReadOnly
			$Test.MaxSupportedDateTime | Should -Be $Calendar.MaxSupportedDateTime
			$Test.MinSupportedDateTime | Should -Be $Calendar.MinSupportedDateTime
			$Test.TwoDigitYearMax      | Should -Be $Calendar.TwoDigitYearMax
			
		}

		It "compress PSON" {
		
			$User = @{Account="User01";Domain="Domain01";Admin=$True}
			
			$PSON = $User | PSON -Expand -1
			
			$PSON.Contains(" ") | Should -Be $False
			
			$Test = $PSON | ConvertFrom-PSON
		
			$Test.Account | Should-BeEqualTo $User.Account
			$Test.Domain  | Should-BeEqualTo $User.Domain
			$Test.Admin   | Should-BeEqualTo $User.Admin
			
		}

		It "convert Date" {
		
			$Date = Get-Date | Select-Object -Property *
			
			$PSON = $Date | PSON 
			
			$PSON | Should -BeOfType [String]
			
			$Test = $PSON | ConvertFrom-PSON

			$Test.Date        | Should -Be $Date.Date
			$Test.DateTime    | Should -Be $Date.DateTime
			$Test.Day         | Should -Be $Date.Day
			$Test.DayOfWeek   | Should -Be $Date.DayOfWeek
			$Test.DayOfYear   | Should -Be $Date.DayOfYear
			$Test.DisplayHint | Should -Be $Date.DisplayHint
			$Test.Hour        | Should -Be $Date.Hour
			$Test.Kind        | Should -Be $Date.Kind
			$Test.Millisecond | Should -Be $Date.Millisecond
			$Test.Minute      | Should -Be $Date.Minute
			$Test.Month       | Should -Be $Date.Month
			$Test.Second      | Should -Be $Date.Second
			$Test.Ticks       | Should -Be $Date.Ticks
			$Test.TimeOfDay   | Should -Be $Date.TimeOfDay
			$Test.Year        | Should -Be $Date.Year

		}

		It "convert (wininit) process" {
		
			$WinInitProcess = Get-Process WinInit

			$PSON = $WinInitProcess | PSON 
			
			$PSON | Should -BeOfType [String]
			
			$Test = $PSON | ConvertFrom-PSON
			
			$Test.ProcessName | Should-BeEqualTo $WinInitProcess.ProcessName
			
		}
	}
}

