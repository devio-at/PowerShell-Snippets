
# tsqlfindstrings.ps1

#=====================================================================
# Find string literals in TSQL code
# Version 0.10
# http://www.devio.at/index.php/tsqlfindstrings
# (c) 2010 devio IT Services
# support@devio.at


# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

#=====================================================================
# Set the following variables to your system needs
# (Detailed instructions around variables)
#=====================================================================


# adjust to localized program files path

$mspath = "C:\Program Files\Microsoft SQL Server\90\SDK\Assemblies\"
#$mspath = "C:\Programme\Microsoft SQL Server\90\SDK\Assemblies\"
$mspath = "C:\Programme\Microsoft SQL Server\100\SDK\Assemblies\"

&{
# load SMO assemblies

	$dummy = [System.Reflection.Assembly]::LoadFrom(($mspath + "Microsoft.SqlServer.ConnectionInfo.dll")) 
	$dummy = [System.Reflection.Assembly]::LoadFrom($mspath + "Microsoft.SqlServer.Smo.dll")
	# needed for sql2008
	$dummy = [System.Reflection.Assembly]::LoadFrom($mspath + "Microsoft.SqlServer.SmoExtended.dll")

	trap {
		$_;
		break
	}
}

# config declaration

# login info. set to "" for windows authorization, SQL authorization otherwise
$username = ""	# "username"
$password = ""	# "password"

# db server, db names
$dbhost = "localhost"
$dbname = ""	# "database name"

$excludedStrings = @()
$excludedBegins = @()

# begin of config section

$dbname = "mydatabase"

# config examples

$excludedStrings = @(" (", ")", "%", "*",
	"uniqueidentifier", "datetime", "int", "varchar(MAX)", "nvarchar(max)", "decimal(18, 2)",
	"decimal", "bit", "float", "Z", " - ", ", ", "(", "true", "false", " ", """", "=""",
	"string", "boolean", "guid")

$excludedBegins = @("'")

# end of config section

#=====================================================================
# Change Log
# 0.10	101209	initial version

#=====================================================================
# From here on, modify only if you know what you do:
#
#=====================================================================


$ver = "0.10"

$now = Get-Date

# create smo server connection

if ($username -eq "") {
	$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($dbhost)
}
else {
	$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($dbhost, $username, $password)
}
$conn.StatementTimeout = 0

$srv = New-Object Microsoft.SqlServer.Management.Smo.Server($conn)
[void] $srv.Initialize($false) 
[void] $srv.Refresh() 
[void] $srv.SetDefaultInitFields($true) 

$db = $null

foreach($dbT in $srv.Databases |
	Where-Object { $_.IsAccessible -and -not $_.IsSystemObject } |
	Where-Object { [String]::Compare($_.Name, $dbname, $true) -eq 0 })
{
	$db = $dbT
}

if ($db -eq $null)
{
	Write-Host "Database " + $dbname + " not found"
	exit
}

# function definitions

function HasStringLiteral($s)
{
	return $s.Contains("'")
}


function Extract($type, $name, $s)
{
	#Write-Host ($type + " " + $name + ": " + $s)
	
	foreach($m in [RegEx]::Matches($s, "'(.+?)'[^']") |
		Where-Object { ($excludedStrings -notcontains $_.Groups[1]) })
	{
		$g = $m.Groups[1].Value
		$do = $true
		
		foreach($b in $excludedBegins)
		{
			if ($g.StartsWith( $b ))
			{
				$do = $false
			}
		}

		if ($do)
		{
			Write-Host ($type + " " + $name + ": '" + $g + "'")
		}
	}
}

# end of functions

Write-Host "======================================================================"
Write-Host ("tsqlfindstrings " + $ver)
Write-Host "http://www.devio.at/index.php/tsqlfindstrings"
Write-Host ""
Write-Host ("Find Strings in TSQL Code in Database " + $dbhost + "/" + $dbname)
Write-Host "======================================================================"

[void] $db.Refresh()

foreach($t in $db.Tables)
{
	foreach($c in $t.Checks)
	{
		if (HasStringLiteral($c.Text))
		{
			Extract "Check" ($t.Schema + "." + $t.Name + "." + $c.Name) $c.Text
		}
	}
	foreach($c in $t.Columns)
	{
		if ($c.Default -ne "")
		{
			if (HasStringLiteral($c.Default))
			{
				Extract "Default" ($t.Schema + "." + $t.Name + "." + $c.Name) $c.Default
			}
		}
	}
}

foreach($v in $db.Views | 
	Where-Object { !$_.IsSystemObject } )
{
	if (HasStringLiteral($v.TextBody))
	{
		Extract "View" ($v.Schema + "." + $v.Name) $v.TextBody
	}
}
foreach($p in $db.StoredProcedures | 
	Where-Object { !$_.IsSystemObject } )
{
	if (HasStringLiteral($p.TextBody))
	{
		Extract "Procedure" ($p.Schema + "." + $p.Name) $p.TextBody
	}
}
foreach($f in $db.UserDefinedFunctions | 
	Where-Object { !$_.IsSystemObject } )
{
	if (HasStringLiteral($f.TextBody))
	{
		Extract "Function" ($f.Schema + "." + $f.Name) $f.TextBody
	}
}
foreach($t in $db.Triggers | 
	Where-Object { !$_.IsSystemObject } )
{
	if (HasStringLiteral($t.TextBody))
	{
		Extract "Trigger" ($t.Schema + "." + $t.Name) $t.TextBody
	}
}



