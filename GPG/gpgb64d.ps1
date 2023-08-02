# Constants
$gpgPath = "${env:ProgramFiles(x86)}\GnuPG\bin\gpg.exe"
$importantFormat = [char]27 + '[32m'


# Initialize an empty string to store the user's input
$userInput = ""

# Ask the user for input in a loop until two empty lines are entered
Write-Host "Please enter your input (press Enter twice on empty lines to finish):"
$emptyLineCount = 0
do {
    # Read the current line of input
    $line = Read-Host

    # Check if the current line is empty
    if ($line -eq "") {
        # Increment the emptyLineCount and append the empty line to userInput
        $emptyLineCount++
        $userInput += $line + "`n"
    } else {
        # If a non-empty line is entered after empty lines, reset the emptyLineCount
        $emptyLineCount = 0
        $userInput += $line + "`n"  # Use `n to add a newline character to separate lines
    }
} while ($emptyLineCount -lt 2)

# Trim the trailing newline characters from the userInput
$userInput = $userInput.TrimEnd("`n`n`n")

# Decode and decrypt
$decodedMessage = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($userInput))

Write-Host "`n`******************************`n` "
Write-Host $importantFormat$decodedMessage
Write-Host "`n`******************************`n` "

$processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
$processStartInfo.FileName = $gpgPath
$processStartInfo.Arguments = "--decrypt --batch --yes"
$processStartInfo.RedirectStandardInput = $true
$processStartInfo.RedirectStandardOutput = $true
$processStartInfo.UseShellExecute = $false
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processStartInfo
$process.Start() | Out-Null
$process.StandardInput.Write($decodedMessage)
$process.StandardInput.Close()
$decryptedMessage = $process.StandardOutput.ReadToEnd()
$process.WaitForExit()

Write-Host "`n`******************************`n` "
Write-Host $importantFormat$decryptedMessage
Write-Host "`n`******************************`n` "
