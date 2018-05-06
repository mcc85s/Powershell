﻿
function Get-NMAPalives{
    <#Take in an NMAP -sn -oG file and strip out terms#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [String]$infile,
        [Parameter(Mandatory=$False,Position=1)]
            [String]$outfile
        )

    $r = [regex] "\(([l].*?)(\.<#DOMAINNAMEHERE#>\))"
    $file_contents = Get-Content $infile
    foreach($line in $file_contents){
        $match = $r.match($line)
        if($match.groups[1].value){
            $match.groups[1].value | Tee-Object -FilePath $outfile -append | foreach {write-host $_}
            }
        }
    }
