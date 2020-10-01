# requires:
# Set-ExecutionPolicy Unrestricted -scope CurrentUser
#
# Install-Module ImportExcel
#   or
# Install-Module ImportExcel -Scope CurrentUser
# https://github.com/dfinke/ImportExcel
# https://devblogs.microsoft.com/scripting/introducing-the-powershell-excel-module-2/

param (
    [switch] $updateXlsx = $false
)

$versions = @{}
$versionWorksheetNames = @{}

$xlsxFilename = "SQL Server Builds V3.xlsx"     # https://support.microsoft.com/en-us/help/321185/how-to-determine-the-version-edition-and-update-level-of-sql-server-an

if (!(Test-Path $xlsxFilename) -or $updateXlsx) {
    Write-Host "downloading Server Builds xlsx"
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://aka.ms/SQLServerbuilds", $xlsxFilename)
}

if (Test-Path $xlsxFilename) {

    $esi = Get-ExcelSheetInfo -path ".\${xlsxFilename}"

    $esi | where-object Name -ne "Data" | foreach-object -Process {
        Write-Host "importing worksheet '"$_.Name"'"

        $worksheetName = $_.Name

        $xlsx = Import-Excel -path ".\${xlsxFilename}" -WorksheetName $_.Name

        $xlsx | foreach-object -Process {
            if ($_."Build number") {
                $b = $_."Build number";
                if ($versions.ContainsKey($b)) {
                    $versions[$b] += $_;
                } else {
                    $versions.add($b, @( $_) );
                    $versionWorksheetNames.add($b, $worksheetName);
                }
            }
        }

    #2019    Build number	KB number	Release Date	Cumulative Update number/Security ID    Incremental Servicing Model
    #2017    Build number	KB number	Release Date	Cumulative Update number/Security ID	Modern Servicing Model
    #2016    Build number	KB number	Release Date	Service Pack/RTM	Cumulative Update number/Security ID
    #2014    Build number	KB number	Release Date	Service Pack/RTM	Cumulative Update number/Security ID	Incremental Servicing Model
    #2012    Build number	KB number	Release Date	Service Pack/RTM	Cumulative Update number/Security ID	Incremental Servicing Model
    #2008R2  Build number	KB number	Release Date	Service Pack/RTM	Cumulative Update number/Security ID	Incremental Servicing Model
    #2008    Build number	KB number	Release Date	Service Pack/RTM	Cumulative Update number/Security ID	Incremental Servicing Model
    #2005    Build number	KB number	Release Date	Service Pack/RTM	Cumulative Update number/Security ID	Incremental Servicing Model
    }
}

$basedir = "C:\Program Files\Microsoft SQL Server"

$exes = Get-ChildItem -Path $basedir -Filter sqlservr.exe -Recurse -ErrorAction SilentlyContinue -Force 

$exes | foreach-object -Process {     
    $ip = Get-ItemProperty -Path $_.FullName 
    $vi = $ip.VersionInfo
    $ver = "not found"
    if ($versions.ContainsKey($vi.ProductVersion)) {
        $vers = $versions[$vi.ProductVersion];

        $ver = $versionWorksheetNames[$vi.ProductVersion] + " " + 
            ($vers | foreach-object -Process { 
                $( if($_."Service Pack/RTM") { $_."Service Pack/RTM" + " " } else { "" } ) + 
                $_."Cumulative Update number/Security ID" + 
                $( if($_."Incremental Servicing Model") { " (" + $_."Incremental Servicing Model" + ")" } else { "" } )
            }) -join ", "
    }
    [pscustomobject]@{ 
        ProductVersion = $vi.ProductVersion;
        SQLVersion = $ver;
        FileVersion = $vi.FileVersion; 
        DirectoryName = $_.DirectoryName; 
        LastWriteTime = $_.LastWriteTime; 
    }
} | format-table

