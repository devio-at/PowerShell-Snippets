$emailFrom = "sender@example.com"
$emailTo = "receiver@example.com"
$subject = "Windows updates available"
$smtpServer = "smtp.example.com"

# https://stackoverflow.com/questions/356693/net-windows-update-querying
$updateSession = new-object -com Microsoft.update.Session

$searcher = $updateSession.CreateUpdateSearcher()

# https://stackoverflow.com/questions/121585/best-way-of-detecting-if-windows-has-windows-updates-ready-to-download-install
$result = $searcher.Search("IsInstalled=0") #"IsInstalled=0 and IsPresent=0 and Type='Software'");

$result.Updates.Count

$result.Updates | Select-Object -Property Title, IsInstalled, IsPresent, Type

if ($result.Updates.Count -gt 0) {

    # https://stackoverflow.com/questions/24661972/output-a-powershell-object-into-a-string
    $body = $result.Updates | Select-Object -Property Title | Out-String

    $smtp = new-object Net.Mail.SmtpClient($smtpServer)

	$msg = New-Object Net.Mail.MailMessage($emailFrom, $emailTo, $subject, $body.ToString())
	$smtp.Send($msg)
}

# https://riptutorial.com/powershell/example/20107/bypassing-execution-policy-for-a-single-script
# run from cmd: powershell.exe -ExecutionPolicy Bypass -File C:\MyUnsignedScript.ps1
