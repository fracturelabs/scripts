# Constants
$gpgPath = "${env:ProgramFiles(x86)}\GnuPG\bin\gpg.exe"
$successFormat = [char]27 + '[42m'
$importantFormat = [char]27 + '[32m'
$highlightFormat = [char]27 + '[33m'
$resetFormat = [char]27 + '[0m'


# Get the default GPG key ID
$output = gpg --list-keys

# Extract the fingerprint from the output and extract the key ID
$fingerprintRegex = [regex]::new('\b[0-9A-F]{40}\b')
$fingerprint = $fingerprintRegex.Match($output).Value
$keyID = $fingerprint.Substring($fingerprint.Length - 16)

Write-Host "Using GPG Key ID: $keyID"


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
$userInput = $userInput.TrimEnd("`n")

# GPG Encrypt the input
$processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
$processStartInfo.FileName = $gpgPath
$processStartInfo.Arguments = "--encrypt --sign --armor --batch -r $keyID --yes"
$processStartInfo.RedirectStandardInput = $true
$processStartInfo.RedirectStandardOutput = $true
$processStartInfo.UseShellExecute = $false
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processStartInfo
$process.Start() | Out-Null
$process.StandardInput.Write($userInput)
$process.StandardInput.Close()
$encryptedMessage = $process.StandardOutput.ReadToEnd()
$process.WaitForExit()

# Encode the GPG-encrypted message
$encodedMessage = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($encryptedMessage))


# Reverse the process to make sure everything worked
$decodedMessage = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedMessage))

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


# Verify input and check hashes
$hasher = [System.Security.Cryptography.HashAlgorithm]::Create('sha256')
$inputHash = [System.BitConverter]::ToString($hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($userInput)))
$decryptedHash = [System.BitConverter]::ToString($hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($decryptedMessage)))

Write-Host "`n`******************************`n` "
Write-Host $highlightFormat"Verify this matches your input:"$resetFormat
Write-Host ("$highlightFormat{0}$resetFormat" -f $decryptedMessage)
Write-Host "`n`******************************`n` "

if ($inputHash -eq $decryptedHash) {
    Write-Host $successFormat"Hashes: MATCHED"
} else {
    Write-Error "Hashes: DID NOT MATCH!!!"
    exit 1
}

Write-Host ("Input: Length={0} | Hash={1}" -f $userInput.Length, $inputHash)
Write-Host ("Check: Length={0} | Hash={1}" -f $decryptedMessage.Length, $decryptedHash)
Write-Host "`n`******************************`n` "
Write-Host "Encoded Message: `n` "
Write-Host $importantFormat$encodedMessage
Write-Host "`n`******************************`n` "
