
$basedir = "path\to\bin"
$specdll = "specflow-tests.dll"
$featuredir = "path\to\feature\root"

$dlls = get-childitem -path "$basedir\*.dll"
foreach($dll in $dlls) {
    write-host $dll
    $dummy = [System.Reflection.Assembly]::LoadFrom($dll)
}

try
{
    $asm = [System.Reflection.Assembly]::LoadFrom("$basedir\$specdll", $null, 0)
}
catch
{
    $_.Exception.Message
}

try
{
    $types = $asm.GetTypes()
}
catch
{
    #write-host $_.Exception.Message
    write-host $_.Exception.InnerException.LoaderExceptions
}

# SpecFlow attributes
$binding = [TechTalk.SpecFlow.BindingAttribute]
$given = [TechTalk.SpecFlow.GivenAttribute]
$when = [TechTalk.SpecFlow.WhenAttribute]
$then = [TechTalk.SpecFlow.ThenAttribute]

# collect [Binding] classes
$bindingclasses = $types | Where-Object { $_.IsDefined($binding, $false) }

# collect SpecFlow method attributes
$attributes = @()

foreach($bc in $bindingclasses)  {
    foreach($m in $bc.GetMethods()) {

        $a = $m.GetCustomAttributes($given, $false)
        if ($a.Length -gt 0) {
            "Given " + $a[0].Regex
            $attributes += $a[0]
        }

        $a = $m.GetCustomAttributes($when, $false)
        if ($a.Length -gt 0) {
            "When " + $a[0].Regex
            $attributes += $a[0]
        }

        $a = $m.GetCustomAttributes($then, $false)
        if ($a.Length -gt 0) {
            "Then " + $a[0].Regex
            $attributes += $a[0]
        }
    }
}

# collect .feature files
$featurefiles = get-childitem -recurse -path "$featuredir\*.feature"
$featurefilecontents = @{}
foreach($ff in $featurefiles) {
    $featurefilecontents[$ff] = Get-Content $ff
}

$foundattributes = @()
$notfoundattributes = @()

:Outer foreach($a in $attributes) {
    foreach($ff in $featurefiles) {

        $found = $featurefilecontents[$ff] | select-string -Pattern $a.Regex -CaseSensitive
        if ($found.Matches.Length -gt 0) {
            #write-host "found $($a.Regex) in file $ff"
            $foundattributes += $a
            continue Outer
        }
    }

    write-host "did not found reference for $($a.GetType().Name) $($a.Regex)"
    $notfoundattributes += $a
}

$notfoundattributes | select-object Regex
