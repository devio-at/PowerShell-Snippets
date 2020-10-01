# requires:
# Set-ExecutionPolicy Unrestricted -scope CurrentUser

$basedir = "C:\Program Files\Microsoft SQL Server"

$exes = Get-ChildItem -Path $basedir -Filter sqlservr.exe -Recurse -ErrorAction SilentlyContinue -Force 

$exes | foreach-object -Process {     
    $ip = Get-ItemProperty -Path $_.FullName 
    $vi = $ip.VersionInfo
    [pscustomobject]@{ ProductVersion = $vi.ProductVersion; FileVersion = $vi.FileVersion; DirectoryName = $_.DirectoryName; LastWriteTime = $_.LastWriteTime;  }
} | format-table
