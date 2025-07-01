New-Alias which get-command

<#
.SYNOPSIS
Base64-encodes a string or a file's contents.

.DESCRIPTION
The 'b64' function encodes either a plain string or the contents of a file into Base64 format.
It supports two mutually exclusive parameter sets: one for encoding a string, and one for encoding a file.

.PARAMETER String
The string to encode as Base64. This is the default parameter and can be used positionally.

.PARAMETER File
The path to a file whose contents will be read as bytes and Base64-encoded. 
This parameter is mutually exclusive with -String. You can use -f as an alias.

.EXAMPLE
b64 "hello world"
Encodes the string "hello world" to Base64.

.EXAMPLE
b64 -File "C:\temp\myfile.txt"
Reads the contents of the file and encodes it as Base64.
#>
function b64 {
    [CmdletBinding(DefaultParameterSetName = 'String')]
    [OutputType([string])]
    param(
        [Parameter(ParameterSetName = 'String', Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$String,

        [Parameter(ParameterSetName = 'File', Mandatory = $true, ValueFromPipeline = $false)]
        [Alias('f')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$File
    )

    $location = (Get-Location).path

    $bytes = switch ($PSCmdlet.ParameterSetName) {
        'File'   { [System.IO.File]::ReadAllBytes("$($location)/$($File)") }
        'String' { [System.Text.Encoding]::UTF8.GetBytes($String) }
    }

    Write-Output ([Convert]::ToBase64String($bytes))
}

<#
.SYNOPSIS
    Decode Base64 input to text or binary.

.DESCRIPTION
    The d64 function decodes Base64 data from a literal string (default),
    a file via –File (or –f), or from the clipboard via –Clipboard.
    By default it emits UTF-8 text; use –Bytes to return raw byte values.
    Use –OutFile to save the decoded bytes to disk, and you’ll be prompted
    to open the file after writing.

.PARAMETER String
    Base64-encoded literal string. This is the default parameter set.

.PARAMETER File
    Path to a file containing Base64 text. Alias: –f.

.PARAMETER Clipboard
    Read Base64 text from the Windows clipboard.

.PARAMETER Bytes
    Output the raw byte values (one per line) instead of converting to text.

.PARAMETER OutFile
    Path where decoded bytes will be written. Alias: –o.
    After writing, you’ll be asked if you want to open the file.

.EXAMPLE
    # Decode a literal string to text
    d64 "SGVsbG8gd29ybGQh"

.EXAMPLE
    # Decode a file to raw bytes, display in console
    d64 -File enc.txt -Bytes

.EXAMPLE
    # Decode clipboard contents into a file and open it
    d64 -Clipboard -OutFile decoded.bin
#>
function d64 {
    [CmdletBinding(DefaultParameterSetName = 'String')]
    param(
        [Parameter(
            ParameterSetName = 'String',
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if ($_ -notmatch '^[A-Za-z0-9+/]+={0,2}$') {
                throw "String must be valid Base64."
            }
            $true
        })]
        [string]$String,

        [Parameter(ParameterSetName = 'File', Mandatory = $true)]
        [Alias('f')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not (Test-Path $_ -PathType Leaf)) {
                throw "File '$_' does not exist."
            }
            $true
        })]
        [string]$File,

        [Parameter(ParameterSetName = 'Clipboard')]
        [switch]$Clipboard,

        [switch]$Bytes,

        [Alias('o')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            $dir = Split-Path $_
            if ($dir -and -not (Test-Path $dir -PathType Container)) {
                throw "Directory '$dir' does not exist."
            }
            $true
        })]
        [string]$OutFile
    )

    $location = (Get-Location).path

    # 1) Grab the Base64 source
    switch ($PSCmdlet.ParameterSetName) {
        'String'    { $b64 = $String }
        'File'      { $b64 = Get-Content -Raw -Path "$($location)/$($File)" }
        'Clipboard' { $b64 = Get-Clipboard }
    }

    # 2) Decode to byte[]
    $decodedBytes = [Convert]::FromBase64String($b64)

    # 3) If OutFile is specified, write bytes and prompt to open
    if ($OutFile) {
        [System.IO.File]::WriteAllBytes($OutFile, $decodedBytes)
        $count = $decodedBytes.Length
        Write-Output "Decoded $count bytes and wrote to: '$OutFile'"
        $answer = Read-Host "Do you want to start the decoded file now? (Y/N)"
        if ($answer -match '^[Yy]') {
            try {
                Start-Process -FilePath $OutFile
            } catch {
                Write-Warning "Could not start '$OutFile': $_"
            }
        }
        return
    }

    # 4) Otherwise, output to console
    if ($Bytes) {
        return ,$decodedBytes
    }
    else {
        return [System.Text.Encoding]::UTF8.GetString($decodedBytes)
    }
}
