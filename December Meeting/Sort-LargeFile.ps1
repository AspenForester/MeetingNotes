<#
.SYNOPSIS
    Sorts and deduplicates the lines of a file in ascending order
.DESCRIPTION
    This function is optimized to sort the contents of a text file
    with a very large number of lines.

    Unlike Sort-Object, the contents it was written to sort are expected to be unique,
    and if any lines are found to not be unique, this is sent to the output pipeline.
.EXAMPLE
    PS C:\> Sort-LargeFile -path .\myinput.txt -outpath .\mysorted.txt
    Creates a file at the location specified by outpath containing the deduplicated, 
    and sorted contents of the input file
.PARAMETER Path
    Path to the file to be sorted
.PARAMETER OutPath
    Path to the sorted, deduplicated file that the script will generate
.NOTES
    Pretty much stole: https://stackoverflow.com/questions/32385611/sort-very-large-text-file-in-powershell
#>
Function Sort-LargeFile
{
    [CmdletBinding()]
    # Specifies a path to a file to be sorted.
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = "Path to the file to sort.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        # Parameter help description
        [Parameter(Mandatory = $true,
            Position = 1,
            HelpMessage = "Path to the file to create.")]
        [String]
        $OutPath
    )

    begin 
    {
        If (-not (test-path $outpath))
        {
            Throw "Path Not Found: $OutPath"
        }
    }
    process
    {            
        if (Test-path $path)
        {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $hs = new-object System.Collections.Generic.HashSet[string]

            $reader = [System.IO.File]::OpenText($path)
            try
            {
                # Hashset collections don't have duplicates
                # We can examine that $t and it will be false anytime it encounters a duplicate item
                while (($line = $reader.readline()) -ne $null)
                {
                    # Since the input file currently has directories, the
                    # -replace "(FN\d+\\?)" , "" trims that junk out
                    $clean = $line -replace "(FN\d+\\?)" , ""
                    $t = $hs.Add($clean)
                    # output any non-blank duplicates
                    if (-not $t -and $clean -ne '')
                    {
                        $clean
                    }
                }
            }
            finally
            {
                $reader.close()
            }
            $sw.Stop()
            Write-Verbose ("read-unique took {0}" -f $sw.Elapsed)

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            # Now push the Hashset into a List
            $ls = new-object system.collections.generic.List[string] $hs
            $ls.sort()

            $sw.Stop();
            Write-Verbose ("sorting took {0}" -f $sw.Elapsed)

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            try
            {
                $f = New-Object System.IO.StreamWriter $OutPath
                foreach ($s in $ls)
                {
                    $f.WriteLine($s)
                }
            }
            finally
            {
                $f.Close()
            }
            $sw.stop()
            Write-Verbose ("writing took {0}" -f $sw.elapsed)
        }
        else
        {
            Throw "Path Not Found: $Path"
        }
    }
}
