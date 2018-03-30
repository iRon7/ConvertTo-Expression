Function ConvertFrom-Table {
	Param (
		[Parameter(ValueFromPipeLine = $True)][String[]]$Table, 
		[Char]$HeaderChar = '-', [Char[]]$ArrayMask = '{,}', [Char[]]$ExpressionMask = '`'
	)
	Begin {
		Function Get-Values ($Row) {
			For ($i = 0; $i -lt $Index.Count; $i++) {
				$Start = $Index[$i]
				$End = If ($i -lt $Index.Count - 1) {$Index[$i + 1]} Else {$Row.Length}
				If($End -gt $Row.Length) {$End = $Row.Length}
				If ($Start -lt $End) {$Row.SubString($Start, $End - $Start).TrimEnd()} Else {""}
			}
		}
		$HeaderRow = $Null
		$Property = @{}
		$Name = $Null
		$Index = @()
	}
	Process {
		$Table | ForEach-Object {
			ForEach ($Row in ($_ -Split "[\r\n]+")) {
				If ($Name) {
					$Value = Get-Values $Row
					For ($i = 0; $i -lt $Name.Count; $i++) {
						$Property.($Name[$i]) = 
						If ($ArrayMask[1] -and $Value[$i].StartsWith($ArrayMask[0]) -And $Value[$i].EndsWith($ArrayMask[2])) {
							$Value[$i].SubString(1, $Value[$i].Length - $ArrayMask[2].length - 1) -Split $ArrayMask[1] | ForEach-Object {$_.Trim()}
						} ElseIf ($ExpressionMask -and $Value[$i].StartsWith($ExpressionMask[0]) -And $Value[$i].EndsWith($ExpressionMask[1])) {
							Invoke-Expression $Value[$i].SubString(1, $Value[$i].Length - $ExpressionMask[1].length - 1)
						} Else {$Value[$i]}
					}
					New-Object PSObject -Property $Property
				} Else {
					If ($HeaderRow) {
						$Index = Select-String "(?<!\S)[\x2D]+" -Input $Row -AllMatches | ForEach-Object {$_.Matches} | Select-Object -Expand Index
						If ($Index.Count) {$Name = Get-Values $HeaderRow}
					}
					$HeaderRow = $Row
				}
			}
		}
	}
	End {
		If (!$Name) {Write-Error "No table header found"}
	}
}
