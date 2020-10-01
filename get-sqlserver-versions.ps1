# requires:
# Set-ExecutionPolicy Unrestricted -scope CurrentUser
#
# script source
# https://github.com/devio-at/PowerShell-Snippets
# https://devio.wordpress.com/2020/10/01/retrieving-sp-and-cu-of-installed-sql-server-instances/

$basedir = "C:\Program Files\Microsoft SQL Server"

$exes = Get-ChildItem -Path $basedir -Filter sqlservr.exe -Recurse -ErrorAction SilentlyContinue -Force 

$exes | foreach-object -Process {     
    $ip = Get-ItemProperty -Path $_.FullName 
    $vi = $ip.VersionInfo
    [pscustomobject]@{ ProductVersion = $vi.ProductVersion; FileVersion = $vi.FileVersion; DirectoryName = $_.DirectoryName; LastWriteTime = $_.LastWriteTime;  }
} | format-table
