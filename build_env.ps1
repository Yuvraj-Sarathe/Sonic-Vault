$env_vars = @{}
cmd /c "`"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat`" > nul 2>&1 && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $env_vars[$matches[1]] = $matches[2]
    }
}
# Set the VS-related env vars from the vcvars output
foreach ($key in $env_vars.Keys) {
    Set-Item -Path "Env:$key" -Value $env_vars[$key] -ErrorAction SilentlyContinue
}
# Now also set explicit VS paths for Flutter's vswhere alternative
$env:VSINSTALLDIR = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
$env:VisualStudioVersion = "17.0"
$env:VSCMD_ARG_TGT_ARCH = "x64"
$env:VSCMD_ARG_HOST_ARCH = "x64"
# Run flutter doctor and flutter build
Write-Output "=== Visual Studio Env Vars ==="
Get-ChildItem -Path Env: | Where-Object { $_.Name -match "VS|VC|MSVC|WindowsSDK|INCLUDE|LIB" } | Format-Table -AutoSize
