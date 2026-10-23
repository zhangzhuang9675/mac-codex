# Manual connection helper. No startup registration, scheduled task, or config restore.
[CmdletBinding()]
param([switch] $LaunchCodex)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'OfficeMac-Recovery.Common.ps1')
$recoveryLock = Enter-OfficeMacRecoveryLock
try {

if (-not (Test-Path -LiteralPath $OfficeMacSsh -PathType Leaf)) { throw "OpenSSH client not found: $OfficeMacSsh" }
if (-not (Test-Path -LiteralPath $OfficeMacIdentity -PathType Leaf)) { throw "Existing SSH key not found: $OfficeMacIdentity. Do not copy or print its contents." }
if (-not (Test-OfficeMacWindowsProxy)) { throw 'The existing Windows proxy is not listening at 127.0.0.1:10808. Start the existing proxy client, then retry.' }

$probe = Test-OfficeMacRemoteProxy
if ($probe.ExitCode -eq 0 -and $probe.Output -eq 'REMOTE_SOCKS5_OK') {
    Write-Host 'Mac 127.0.0.1:18081 already answers SOCKS5. Reusing it; no process ownership is claimed.'
}
else {
    if ($probe.ExitCode -ne 13) {
        throw "The remote proxy could not be safely checked (exit $($probe.ExitCode)): $($probe.Output). See $OfficeMacCheckErr. No tunnel was started."
    }
    $state = Read-OfficeMacTunnelState
    $existing = Get-OfficeMacRecordedProcess $state
    if ($null -ne $existing) {
        $existing.Dispose()
        throw "The recorded dedicated SSH process is still running but the remote SOCKS proxy is unavailable. Review its logs in $OfficeMacRoot; use Stop-OfficeMacChromeTunnel.ps1 before retrying."
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $stdout = Join-Path $OfficeMacRoot "ssh-$stamp.stdout.log"
    $stderr = Join-Path $OfficeMacRoot "ssh-$stamp.stderr.log"
    $arguments = $OfficeMacSshOptions + @(
        '-o', 'ExitOnForwardFailure=yes', '-o', 'ServerAliveInterval=15', '-o', 'ServerAliveCountMax=4',
        '-R', $OfficeMacForward, '-N', '-T', $OfficeMacDestination
    )
    $argumentString = ($arguments | ForEach-Object { ConvertTo-OfficeMacProcessArgument $_ }) -join ' '
    $tunnel = Start-Process -FilePath $OfficeMacSsh -ArgumentList $argumentString -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    Start-Sleep -Milliseconds 250
    $tunnel.Refresh()
    if ($tunnel.HasExited) { throw "The dedicated SSH tunnel exited with code $($tunnel.ExitCode). See $stderr." }
    $metadata = Get-CimInstance Win32_Process -Filter "ProcessId = $($tunnel.Id)" -ErrorAction Stop
    if ($null -eq $metadata -or [string]::IsNullOrWhiteSpace([string]$metadata.CommandLine)) {
        throw "Unable to record ownership for the newly started SSH PID $($tunnel.Id). Review it manually; no other process was changed. Logs: $stderr."
    }
    $state = [ordered]@{
        SchemaVersion = 1
        Pid = $tunnel.Id
        StartTimeUtcTicks = $tunnel.StartTime.ToUniversalTime().Ticks.ToString()
        ExecutablePath = [string]$metadata.ExecutablePath
        CommandLine = [string]$metadata.CommandLine
        IdentityPath = $OfficeMacIdentity
        Destination = $OfficeMacDestination
        RemoteForward = $OfficeMacForward
        StdoutLog = $stdout
        StderrLog = $stderr
        CreatedAtUtc = [DateTime]::UtcNow.ToString('o')
    }
    $state | ConvertTo-Json | Set-Content -LiteralPath $OfficeMacStatePath -Encoding UTF8
    Set-Content -LiteralPath $OfficeMacPidPath -Value $tunnel.Id -Encoding ASCII
    $ready = $false
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        $tunnel.Refresh()
        if ($tunnel.HasExited) { throw "The dedicated SSH tunnel exited with code $($tunnel.ExitCode). See $stderr." }
        $probe = Test-OfficeMacRemoteProxy
        if ($probe.ExitCode -eq 0 -and $probe.Output -eq 'REMOTE_SOCKS5_OK') { $ready = $true; break }
        Start-Sleep -Milliseconds 400
    }
    if (-not $ready) { throw "The tunnel was started, but the Mac SOCKS5 check did not pass. See $stderr and $OfficeMacCheckErr. Only the dedicated tunnel may be stopped using Stop-OfficeMacChromeTunnel.ps1." }
    Write-Host "Dedicated SSH tunnel is ready. PID $($tunnel.Id); state and logs are in $OfficeMacRoot."
    $tunnel.Dispose()
}

if ($LaunchCodex) { Start-OfficeMacCodexIfSafe }
else { Write-Host 'Connect mode completed. To start Codex when it is not running, rerun this helper with -LaunchCodex.' }
}
finally { Exit-OfficeMacRecoveryLock $recoveryLock }
