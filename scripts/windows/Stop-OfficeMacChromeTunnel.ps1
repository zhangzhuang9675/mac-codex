# Stops only an SSH process recorded and matched by this helper; never the Mac app.
[CmdletBinding(SupportsShouldProcess = $true)]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'OfficeMac-Recovery.Common.ps1')
$recoveryLock = Enter-OfficeMacRecoveryLock
try {

$state = Read-OfficeMacTunnelState
if ($null -eq $state) {
    Write-Host 'No dedicated tunnel state exists. An existing tunnel created elsewhere will not be stopped.'
    return
}
$process = Get-OfficeMacRecordedProcess $state
if ($null -eq $process) {
    Write-Host 'The recorded PID is no longer running. No process was stopped; stale state is retained for review.'
    return
}
try {
    if ($PSCmdlet.ShouldProcess("dedicated SSH PID $($process.Id) for $OfficeMacDestination (127.0.0.1:18081 -> Windows 127.0.0.1:10808)", 'Stop this recorded tunnel')) {
        Stop-Process -InputObject $process -ErrorAction Stop
        if (-not $process.WaitForExit(5000)) { throw 'The recorded SSH process did not exit within five seconds. State was retained.' }
        Remove-Item -LiteralPath $OfficeMacStatePath -ErrorAction Stop
        if (Test-Path -LiteralPath $OfficeMacPidPath) { Remove-Item -LiteralPath $OfficeMacPidPath -ErrorAction Stop }
        Write-Host 'Stopped the matching dedicated SSH tunnel. Logs are retained. The Mac app was not stopped.'
    }
}
finally { $process.Dispose() }
}
finally { Exit-OfficeMacRecoveryLock $recoveryLock }
