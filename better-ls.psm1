<#
    .SYNOPSIS
     A simple replacement for Get-ChildItem with better ordering and formatting
#>
function ll {
	[CmdLetBinding()]
	param(
		[Parameter(Mandatory = $false, ValueFromPipeline = $true)]
			[PSDefaultValue(Help='Current directory')]
			[string]$Path,
		[Parameter(Mandatory = $false, ValueFromPipeline = $false)]
			[Alias('h')]
			[switch]$Hidden = $false
	)
	Process {
		$items = Get-ChildItem $Path -Force

		# Define a custom order for the Mode property
		$modeSortOrder = @{
		    'd----' = 0
		    'd-r--' = 1
		    'd--h-' = 2
		    'l----' = 3
		    'l--h-' = 4
		    'l--hs' = 5
		    '-a---' = 6
		    '-a-h-' = 7
		    '-a-hs' = 8
		    '---hs' = 9
		    default = 10
		}

        	# Sort the items by Mode using the custom order
	        $sortedItems = $items | Sort-Object -Property {
        	    [int]($modeSortOrder.ContainsKey($_.Mode) ? $modeSortOrder[$_.Mode] : $modeSortOrder['default'])
	        }, Name
	
    		foreach ($item in $sortedItems) {
			$color = switch ($item.Attributes) {
				{ $_ -band [System.IO.FileAttributes]::ReparsePoint } { "Cyan"; break }
				{ $_ -band [System.IO.FileAttributes]::Hidden } { "DarkGray"; break }
				{ $_ -band [System.IO.FileAttributes]::System } { "DarkGray"; break }
				{ $_ -band [System.IO.FileAttributes]::Directory } { "Blue"; break }
				{ $_ -band [System.IO.FileAttributes]::Compressed } { "DarkGreen"; break }
				default { 
					if ($item.Extension -in @(".zip", ".tar", ".gz")) { "DarkYellow"; }
					elseif ($item.Extension -in @(".exe", ".bat", ".cmd")) { "Green"; }
					elseif ($item.Name -match "^[a-zA-Z0-9]") { "Yellow"; }
					else { "Gray" }
				}
			}

			$readableTime = $item.LastWriteTime.ToString("yyyy-MM-dd  HH:mm")
			$readableSize = ConvertTo-ReadableSize -size $item.Length
			$isSymlink = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint
			if ($isSymlink) {
				$target = $item.Target
				$formattedItem = "{0}`t{1,5} {2,8} {3} --> {4}" -f $item.Mode, $readableTime, $readableSize, $item.Name, $target
			} else {
				$formattedItem = "{0}`t{1,5} {2,8} {3}" -f $item.Mode, $readableTime, $readableSize, $item.Name
			}

			if ($h -eq $true) {
				Write-Host $formattedItem -ForegroundColor $color
			} elseif (-not ($item.Attributes -band [System.IO.FileAttributes]::Hidden)) {
				Write-Host $formattedItem -ForegroundColor $color
			}
		}
	}
}

Export-ModuleMember -Function ll