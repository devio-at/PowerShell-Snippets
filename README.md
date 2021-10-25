# PowerShell-Snippets

## tsqlfindstrings.ps1 

a PowerShell script which searches a MS SQL Server database for string literals using SMO

## get-sqlserver-versions.ps1

displays FileVersion and ProductVersion of all installed instances of `sqlservr.exe`, the main executable of MS SQL Server

See blog post [Retrieving SP and CU of installed SQL Server instances](https://devio.wordpress.com/2020/10/01/retrieving-sp-and-cu-of-installed-sql-server-instances/).

## get-sqlserver-versions-xlsx.ps1

retrieves FileVersion and ProductVersion of all installed instances of `sqlservr.exe`, the main executable of MS SQL Server, *and* looks up the ProductVersion in  Microsoft's [SQL Server Builds](https://aka.ms/SQLServerbuilds) Excel sheet

See blog post [Retrieving SP and CU of installed SQL Server instances](https://devio.wordpress.com/2020/10/01/retrieving-sp-and-cu-of-installed-sql-server-instances/).

## unused-specflow-clauses.ps1

analyzes SpecFlow methods marked with [Given], [When], and [Then] attributes whether there `Regex`es are referenced in `.feature` files.

See blog post [Finding unused SpecFlow step implementations with PowerShell](https://devio.wordpress.com/2020/11/17/finding-unused-specflow-step-implementations-with-powershell/)

## update-mailer.ps1

send notification email on pending Windows Updates
