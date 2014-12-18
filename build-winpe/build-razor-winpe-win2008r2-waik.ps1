# -*- powershell -*-
# Run this script as:
#   powershell -executionpolicy bypass -file build-razor-winpe.ps1 \
#     -razorurl http://razor:8080/svc -workdir C:\build-winpe
#
# Produce a WinPE image suitable for use with Razor

# Known issue: This results in Powershell not being available on the winpe image,
# causing the install to exit with an error.

# Parameters
#   - razorurl: the URL of the Razor server, something like
#     http://razor-server:8080/svc (note the /svc at the end, not /api)
#   - workdir: where to create the WinPE image and intermediate files
#              Defaults to the directory containing this script
param([String] $workdir, [Parameter(Mandatory=$true)][String] $razorurl)

function test-administrator {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function get-currentdirectory {
    $thisName = $MyInvocation.MyCommand.Name
    [IO.Path]::GetDirectoryName((Get-Content function:$thisName).File)
}


if (-not (test-administrator)) {
    write-error @"
You must be running as administrator for this script to function.
Unfortunately, we can't reasonable elevate privileges ourselves
so you need to launch an administrator mode command shell and then
re-run this script yourself.
"@
    exit 1
}

# Validate the razorurl
$uri = $razorurl -as [System.Uri]
if (-not $uri.scheme -eq 'http' -or -not $uri.scheme -eq 'https') {
  write-error "razor-url must be a http or https URL"
  exit 1
}
if (-not $uri.AbsolutePath.split('/')[-1] -eq 'svc') {
  write-error "razor-url must end with '/svc'"
  exit 1
}

# Basic location stuff...
$cwd = get-currentdirectory
if ($workdir -eq "") {
    $workdir = $cwd
}

$output = join-path $workdir "razor-winpe"
$mount  = join-path $workdir "razor-winpe-mount"


########################################################################
# Some "constants" that might have to change to accomodate different
# versions of of the WinPE building tools or whatever.  These are
# factored out mostly for my convenience, honestly.

$aik = join-path [Environment]::GetFolderPath('ProgramFiles') "Windows AIK"
write-host "AIK is looking in $aik"

if ((-not (test-path $aik))) {
    write-error @"
We could not find the AIK - either it is not installed or not installed in
the default location.
"@
    exit 1
}

# Path to the clean WinPE WIM file.
$wim = join-path $aik "Tools/PETools/amd64/winpe.wim"

# Root for the CAB files for optional features.
$packages = join-path $aik "Tools/PETools/amd64/WinPE_FPs"


########################################################################
# ...and these are "constants" that are calculated from the above.
write-host "* Make sure our working and output directories exist."
if (test-path -path $output) {
    write-error "Output path $output already exists, delete these folders and try again!"
    exit 1
} else {
    new-item -type directory $output
}

if (-not(test-path -path $mount)) {
    new-item -type directory $mount
}


write-host "* Copy the clean AIK WinPE image into our output area."
copy-item $wim $output
# update our wim location...
$wim = join-path $output "winpe.wim"


#$deploymentTools = ( join-path $aik "Servicing" )
#import-module "$deploymentTools\DISM.exe"
$dism = join-path $aik "Tools/Servicing/Dism.exe"

write-host "* Mounting the wim image"
#mount-windowsimage -imagepath $wim -index 1 -path $mount -erroraction stop
& $dism /Mount-Wim /WimFile:$wim /index:1 /MountDir:$mount

write-host "* Adding powershell, and dependencies, to the image"
# Documentation here: http://technet.microsoft.com/en-us/library/dd744533(WS.10).aspx
$cabs = @('Winpe-LegacySetup', 'WinPE-WDS-Tools', 'WinPE-WMI', 'WinPE-Scripting')

foreach ($cab in $cabs ) {
    write-host "** Installing $cab to image"
    # there must be a way to do this without a temporary variable
    $pkg = join-path $packages "$cab.cab"
    & $dism /image:$mount /Add-Package /PackagePath:$pkg
    #add-windowspackage -packagepath $pkg -path $mount
}

write-host "* Writing startup PowerShell script"
$file   = join-path $mount "razor-client.ps1"
$client = join-path $cwd "razor-client.ps1"
copy-item $client $file

$file   = join-path $mount "razor-client-config.ps1"
set-content $file @"
`$baseurl = "$razorurl"
"@

write-host "* Writing Windows\System32\startnet.cmd script"
$file = join-path $mount "Windows\System32\startnet.cmd"
set-content $file @"
@echo off
echo starting wpeinit to detect and boot network hardware
wpeinit
echo starting the razor client
powershell -executionpolicy bypass -noninteractive -file %SYSTEMDRIVE%\razor-client.ps1
echo dropping to a command shell now...
"@

write-host "* Unmounting and saving the wim image"
& $dism /unmount-Wim /MountDir:$mount /Commit
#dismount-windowsimage -save -path $mount -erroraction stop

write-host "* Work is complete and the WIM should be ready to roll!"
