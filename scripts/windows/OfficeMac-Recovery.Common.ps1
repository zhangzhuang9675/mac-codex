# Requires Windows PowerShell 5.1. Dot-sourcing only defines helpers and constants.
Set-StrictMode -Version 2.0

$OfficeMacRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$OfficeMacExpectedRoot = 'E:\CodexBackups\office-mac-chrome-20261023'
if (-not [string]::Equals($OfficeMacRoot.TrimEnd('\'), $OfficeMacExpectedRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Keep these helpers in $OfficeMacExpectedRoot. No files have been changed."
}
$OfficeMacIdentity = 'C:\Users\zhang\.ssh\codex-office-mac-repair'
$OfficeMacDestination = 'apple@10.1.1.211'
$OfficeMacForward = '127.0.0.1:18081:127.0.0.1:10808'
$OfficeMacStatePath = Join-Path $OfficeMacRoot 'office-mac-tunnel.json'
$OfficeMacPidPath = Join-Path $OfficeMacRoot 'office-mac-tunnel.pid'
$OfficeMacCheckOut = Join-Path $OfficeMacRoot 'checks.stdout.log'
$OfficeMacCheckErr = Join-Path $OfficeMacRoot 'checks.stderr.log'
$OfficeMacSsh = Join-Path $env:WINDIR 'System32\OpenSSH\ssh.exe'
$OfficeMacSshOptions = @(
    '-F', 'none', '-i', $OfficeMacIdentity,
    '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes',
    '-o', 'StrictHostKeyChecking=yes', '-o', 'ConnectTimeout=6',
    '-o', 'ControlMaster=no', '-o', 'ControlPath=none'
)

function Enter-OfficeMacRecoveryLock {
    $mutex = [Threading.Mutex]::new($false, 'Local\CodexOfficeMacChromeRecovery_10_1_1_211_18081')
    $acquired = $false
    try { $acquired = $mutex.WaitOne(0) }
    catch [Threading.AbandonedMutexException] { $acquired = $true }
    if (-not $acquired) {
        $mutex.Dispose()
        throw 'Another Connect/Stop helper is running in this Windows session. Wait for it to finish, then retry.'
    }
    return $mutex
}

function Exit-OfficeMacRecoveryLock($Mutex) {
    try { $Mutex.ReleaseMutex() }
    finally { $Mutex.Dispose() }
}

function Test-OfficeMacWindowsProxy {
    $client = New-Object Net.Sockets.TcpClient
    try {
        $connect = $client.ConnectAsync('127.0.0.1', 10808)
        if (-not $connect.Wait(2000)) { return $false }
        return $client.Connected
    }
    catch { return $false }
    finally { $client.Dispose() }
}

function ConvertTo-OfficeMacProcessArgument([string] $Value) {
    # Windows CommandLineToArgvW quoting, including trailing backslashes.
    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') { return $Value }
    return '"' + [regex]::Replace([regex]::Replace($Value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1') + '"'
}

function Invoke-OfficeMacCommand([string] $PythonSource) {
    # Send fixed source on stdin; avoid nested Windows/PowerShell/POSIX quoting.
    $previousErrorPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @($PythonSource | & $OfficeMacSsh @OfficeMacSshOptions $OfficeMacDestination '/usr/bin/python3 -' 2>> $OfficeMacCheckErr)
        $nativeExitCode = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $previousErrorPreference }
    $stamp = [DateTime]::UtcNow.ToString('o')
    Add-Content -LiteralPath $OfficeMacCheckOut -Value "$stamp exit=$nativeExitCode" -Encoding UTF8
    if ($output.Count -gt 0) { Add-Content -LiteralPath $OfficeMacCheckOut -Value $output -Encoding UTF8 }
    return [pscustomobject]@{ ExitCode = $nativeExitCode; Output = ($output -join "`n").Trim() }
}

function Test-OfficeMacRemoteProxy {
    # A SOCKS5 greeting checks the remote listener without accessing any website.
    $source = @'
import socket, sys
try:
    with socket.create_connection(("127.0.0.1", 18081), 3) as sock:
        sock.settimeout(3)
        sock.sendall(bytes([5, 1, 0]))
        reply = b""
        while len(reply) < 2:
            part = sock.recv(2 - len(reply))
            if not part:
                break
            reply += part
    if reply != bytes([5, 0]):
        print("REMOTE_PORT_IS_NOT_EXPECTED_SOCKS5")
        sys.exit(14)
    print("REMOTE_SOCKS5_OK")
except (OSError, TimeoutError):
    print("REMOTE_PROXY_NOT_READY")
    sys.exit(13)
'@
    return Invoke-OfficeMacCommand $source
}

function Read-OfficeMacTunnelState {
    if (-not (Test-Path -LiteralPath $OfficeMacStatePath -PathType Leaf)) { return $null }
    $state = Get-Content -LiteralPath $OfficeMacStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($field in @('SchemaVersion', 'Pid', 'StartTimeUtcTicks', 'ExecutablePath', 'CommandLine', 'IdentityPath', 'Destination', 'RemoteForward')) {
        if ($state.PSObject.Properties.Name -notcontains $field) { throw "Tunnel state is missing $field; review $OfficeMacStatePath manually." }
    }
    if ($state.SchemaVersion -ne 1 -or $state.IdentityPath -cne $OfficeMacIdentity -or
        $state.Destination -cne $OfficeMacDestination -or $state.RemoteForward -cne $OfficeMacForward) {
        throw "Tunnel state does not describe this dedicated tunnel; review $OfficeMacStatePath manually."
    }
    return $state
}

function Get-OfficeMacRecordedProcess($State) {
    if ($null -eq $State) { return $null }
    $recordedPid = 0
    if (-not [int]::TryParse([string]$State.Pid, [ref]$recordedPid) -or $recordedPid -le 0) { throw 'Invalid tunnel PID in state file.' }
    try { $liveProcess = [Diagnostics.Process]::GetProcessById($recordedPid) }
    catch [ArgumentException] { return $null }
    try {
        # Acquire a process handle and compare its creation time to reject PID reuse.
        $null = $liveProcess.Handle
        $metadata = Get-CimInstance Win32_Process -Filter "ProcessId = $recordedPid" -ErrorAction Stop
        if ($null -eq $metadata) { $liveProcess.Dispose(); return $null }
        $sameExecutable = [string]::Equals([string]$metadata.ExecutablePath, $OfficeMacSsh, [StringComparison]::OrdinalIgnoreCase)
        $sameRecordedExecutable = [string]::Equals([string]$State.ExecutablePath, $OfficeMacSsh, [StringComparison]::OrdinalIgnoreCase)
        $sameCommand = [string]::Equals([string]$metadata.CommandLine, [string]$State.CommandLine, [StringComparison]::Ordinal)
        $sameStart = $liveProcess.StartTime.ToUniversalTime().Ticks.ToString() -ceq [string]$State.StartTimeUtcTicks
        $command = [string]$metadata.CommandLine
        $required = @(
            '(?:^|\s)-F\s+none(?:\s|$)',
            ('(?:^|\s)-i\s+"?' + [regex]::Escape($OfficeMacIdentity) + '"?(?:\s|$)'),
            '(?:^|\s)-o\s+IdentitiesOnly=yes(?:\s|$)',
            '(?:^|\s)-o\s+BatchMode=yes(?:\s|$)',
            ('(?:^|\s)-R\s+' + [regex]::Escape($OfficeMacForward) + '(?:\s|$)'),
            '(?:^|\s)-N(?:\s|$)', '(?:^|\s)-T(?:\s|$)',
            ('(?:^|\s)' + [regex]::Escape($OfficeMacDestination) + '\s*$')
        )
        $hasExpectedArguments = $true
        foreach ($pattern in $required) { if ($command -notmatch $pattern) { $hasExpectedArguments = $false } }
        if (-not ($sameExecutable -and $sameRecordedExecutable -and $sameCommand -and $sameStart -and $hasExpectedArguments)) {
            throw "PID $recordedPid no longer matches this helper's dedicated SSH process. No process will be stopped. Review $OfficeMacStatePath."
        }
        return $liveProcess
    }
    catch { $liveProcess.Dispose(); throw }
}

function Start-OfficeMacCodexIfSafe {
    $source = @'
import os, plistlib, shlex, subprocess, sys
app = "/Applications/ChatGPT.app"
with open(app + "/Contents/Info.plist", "rb") as handle:
    info = plistlib.load(handle)
version = str(info.get("CFBundleShortVersionString", ""))
if version != "26.727.51351":
    print("APP_VERSION_CHANGED_REVIEW_REQUIRED " + version)
    sys.exit(26)
executable = app + "/Contents/MacOS/" + info["CFBundleExecutable"]
proxy_arg = "--proxy-server=socks5://127.0.0.1:18081"
rows = subprocess.check_output(["/bin/ps", "-axo", "pid=,command="], text=True)
running = []
for row in rows.splitlines():
    parts = row.strip().split(None, 1)
    if len(parts) != 2:
        continue
    command = parts[1]
    if command == executable or command.startswith(executable + " "):
        try:
            args = shlex.split(command)
        except ValueError:
            args = []
        has_proxy = proxy_arg in args or any(args[i] == "--proxy-server" and args[i + 1] == "socks5://127.0.0.1:18081" for i in range(len(args) - 1))
        running.append(has_proxy)
if running:
    if all(running):
        print("APP_ALREADY_RUNNING_WITH_EXPECTED_PROXY")
        sys.exit(0)
    print("APP_RUNNING_WITHOUT_EXPECTED_PROXY_SAVE_AND_QUIT_MANUALLY")
    sys.exit(20)
subprocess.run(["/usr/bin/open", "-a", app, "--args", proxy_arg], check=True)
print("APP_LAUNCH_REQUESTED_WITH_EXPECTED_PROXY")
'@
    $result = Invoke-OfficeMacCommand $source
    if ($result.ExitCode -eq 20) {
        Write-Warning 'Codex is already running without the required proxy argument. Save tasks and quit Codex manually on the Mac, then run Connect-OfficeMacChrome.ps1 -LaunchCodex again. This helper will not quit or kill the app.'
        return
    }
    if ($result.ExitCode -ne 0) { throw "Codex launch check failed: $($result.Output). See $OfficeMacCheckErr." }
    Write-Host $result.Output
    Write-Host 'A launch request or running process does not prove Chrome automation works; verify a page in the Mac Codex chat.'
}
