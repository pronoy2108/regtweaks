Function Start-WindowsCleanup
{
    <#
    .SYNOPSIS
        Cleans-up a system clutter and reclaims disk space.

    .DESCRIPTION
        Cleans-up multiple areas of the Windows file system for both the current running user and the global system.
        Sets the StateFlags property on the VolumeCache subkeys in the registry and runs the Windows Disk Clean-up utility in advanced mode as a .NET process.
        Removes the StateFlags property on the VolumeCache subkeys once the Windows Disk Clean-up utility has completed.
        Cleans-up the WinSxS Component Store by removing superseded component files and resetting the image base.
        Logs all clean-up actions to a transcript that is saved in the C:\Windows\Temp directory.

    .PARAMETER Include
        Includes user-specific directories, outside of temporary and logging directories, in the clean-up process. The acceptable values for this parameter are: Downloads, RestorePoints, EventLogs, DuplicateDrivers, Chrome, Firefox, IE and Edge.

        Downloads = Removes all content from all download folders and directories.
        RestorePoints = Removes all system restore points.
        EventLogs = Removes all event logs and event tracing log files.
        DuplicateDrivers = Outputs a Gridview list of any outdated and duplicate drivers for selective removal.
        Chrome = Removes all cache, cookie, history and logging directories for the Google Chrome web browser.
        Firefox = Removes all cache, cookie, history and logging directories for the Mozilla Firefox web browser.
        IE = Removes all cache, cookie, history and logging directories for the Internet Explorer web browser.
        Edge = Removes all cache, cookie, history and logging directories for the Microsoft Edge web browser.

        More than one parameter value may be entered at a time. If, for example, you want to also remove all Restore Points, Event Logs and all content from the Chrome, Firefox and Internet Explorer user and system profile directories, the following values would be passed with the parameter:
        -Include 'RestorePoints', 'EventLogs', 'Chrome', 'Firefox', 'IE'

    .PARAMETER GUI
        Outputs a Gridview GUI list of all of the values in the -Include parameter allowing for the selection of items to include in the removal process as opposed to manually entering them.

        This switch can be used in place of the -Include parameter.

    .PARAMETER Additional
        Removes any user-specific file, folder or directory passed to the parameter when the function is called. This can be a single object or an array of multiple objects.

    .PARAMETER ComponentCleanup
        Removes all superseded components in the component store.

    .PARAMETER ResetBase
        Removes all superseded components in the component store and also resets the image base, further reducing the size of the component store.

        By default the ResetBase feature is disabled for Windows 10 builds 18362 and above unless the -Force switch is used.

    .PARAMETER Force
        This switch is only processed when the Additional parameter or ResetBase switch is used.

        When used with the Additional parameter, any objects that contain access control list permissions will be force removed.
        When used with ResetBase switch, the ComponentCleanup with Image Base Reset will run on Windows 10 builds 18362 and above.

    .EXAMPLE
        PS C:\> Start-WindowsCleanup

        This command will clean-up all distribution, logging, temporary content, icon cache databases and thumbnail cache databases.

    .EXAMPLE
        PS C:\> Start-WindowsCleanup -Include Downloads -ComponentCleanup

        This command will clean-up all distribution, logging, temporary content, icon cache databases and thumbnail cache databases, remove any downloaded items and perform a clean-up of the Component Store.

    .EXAMPLE
        PS C:\> Start-WindowsCleanup -Include 'RestorePoints', 'EventLogs', 'DuplicateDrivers'

        This command will clean-up all distribution, logging, temporary content, icon cache databases and thumbnail cache databases, remove all system restore points and output a Gridview list of any outdated and duplicate drivers for selective removal.

    .EXAMPLE
        PS C:\> Start-WindowsCleanup -Include 'Downloads', 'RestorePoints', 'EventLogs', 'Chrome', 'FireFox', 'Edge' -Additional 'C:\My Notes', 'C:\Executable', 'D:\MapData' -Force

        This command will perform six primary clean-up tasks:
        1 - Remove all distribution, logging, temporary content, icon cache databases and thumbnail cache databases.
        2 = Remove any downloaded content.
        3 - Remove all system restore points.
        4 - Remove all event logs and event tracing log files.
        5 - Remove all cache, cookies, logging and temporary files and saved history for Google Chrome, Mozilla FireFox and Microsoft Edge.
        6 - Remove all additionally added objects by bypassing access control list permissions.

    .EXAMPLE
        PS C:\> Start-WindowsCleanup -GUI -ResetBase -Force

        This command will remove distribution, logging, temporary content, icon cache databases and thumbnail cache databases, output a Gridview GUI list allowing for the selection of additional items to include in the clean-up process, clean-up the Component Store and perform an image base reset even if the Windows 10 build is 18362+ due to the -Force switch being used.

    .NOTES
        The integer value for the StateFlags registry property is randomly created each time the function is run and is not set to a static value.
        On Windows 10 builds 18362 and above, the ResetBase switch and 'Update Cleanup' are excluded from the cleanup process due to a current bug in these builds preventing future updates from installing if previous updates have been removed.
        On Windows 10 builds 18362 and above, the excluded ResetBase feature can be invoked if used with the Force switch.
        When removing outdated and duplicate drivers, ensure the current device driver is functioning properly as you will not be able to roll back the driver for that specific device.
        If the removal of outdated and duplicate drivers has been included in the removal process, realize it can take some time for the list of drivers installed on the system to be compiled so just be patient.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Include',
        ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    Param
    (
        [Parameter(ParameterSetName = 'Include',
            Mandatory = $true,
            Position = 0,
            HelpMessage = 'Includes the clean-up of Downloads, Restore Points, Event Logs, Google Chrome, Mozilla Firefox, Internet Explorer and Microsoft Edge.')]
        [ValidateSet('Downloads', 'RestorePoints', 'EventLogs', 'DuplicateDrivers', 'Chrome', 'Firefox', 'IE', 'Edge')]
        [String[]]$Include,
        [Parameter(ParameterSetName = 'GUI',
            Mandatory = $true,
            Position = 0,
            HelpMessage = 'Outputs a Gridview GUI list of all of the values in the -Include parameter allowing for the selection of items to include in the removal process as opposed to manually entering them.')]
        [Switch]$GUI,
        [Parameter(HelpMessage = 'Removes any user-specific file, folder or directory passed to the parameter when the function is called. This can be a single object or an array of multiple objects.')]
        [String[]]$Additional,
        [Parameter(HelpMessage = 'Removes all superseded components in the component store.')]
        [Switch]$ComponentCleanup,
        [Parameter(HelpMessage = 'Removes all superseded components in the component store and also resets the image base, further reducing the size of the component store.')]
        [Switch]$ResetBase,
        [Parameter(HelpMessage = 'This switch is only processed when the Additional parameter or ResetBase switch is used.')]
        [Switch]$Force
    )

    Begin
    {
        # Check to make sure we are running with administrator permissions.
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Write-Warning "This script requires elevated access. Please relaunch Start-WindowsCleanup with administrator permissions."; Exit }

        # Create helper functions to aid in the clean-up process.
        Function Remove-Items
        {
            [CmdletBinding()]
            Param
            (
                [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true)]
                [Alias('FullName', 'PSPath')]
                [String[]]$Path,
                [Switch]$Force
            )

            Process
            {
                ForEach ($Item In $Path)
                {
                    $Item = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Item)
                    If ($PSBoundParameters.Additional)
                    {
                        If ($Force.IsPresent)
                        {
                            If ($null -eq $Item) { Continue }
                            $Retries = 5
                            If ((Get-Item -Path $Item -Force -ErrorAction SilentlyContinue) -is [IO.DirectoryInfo]) { $TAKEOWN = ('TAKEOWN.EXE /F "{0}" /A /R /D Y' -f $Item) }
                            Else { $TAKEOWN = ('TAKEOWN.EXE /F "{0}" /A' -f $Item) }
                            Do
                            {
                                $RET = $TAKEOWNRET = $ICACLSRET = $ATTRIBRET = $REMRET = $null
                                Write-Verbose ('Performing the operation "{0}"' -f $TAKEOWN) -Verbose
                                $TAKEOWNRET = Invoke-Expression $TAKEOWN
                                $ICACLS = ('ICACLS.EXE "{0}" /INHERITANCE:E /GRANT *S-1-5-32-544:F /T /Q /C /L' -f $Item)
                                Write-Verbose ('Performing the operation "{0}"' -f $ICACLS) -Verbose
                                $ICACLSRET = Invoke-Expression $ICACLS
                                $ATTRIB = ('ATTRIB.EXE -A "{0}" /S /D /L' -f $Item)
                                Write-Verbose ('Performing the operation "{0}"' -f $ATTRIB) -Verbose
                                $ATTRIBRET = Invoke-Expression $ATTRIB
                                Try { Remove-Item -Path $Item -Recurse -Force -Verbose }
                                Catch { $REMRET = $PSItem.Exception.Message }
                                $RET = ($TAKEOWNRET + $ICACLSRET + $ATTRIBRET + $REMRET) | Select-String -Pattern 'Access is denied'
                            }
                            While ($null -ne $RET -or (--$Retries -le 0))
                        }
                        Else
                        {
                            Try { Remove-Item -Path $Item -Recurse -Force -Verbose -ErrorAction SilentlyContinue }
                            Catch [UnauthorizedAccessException], [Management.Automation.ItemNotFoundException] { }
                        }
                    }
                    Else
                    {
                        Try
                        {
                            If ((Get-Item -Path $Item -Force -ErrorAction SilentlyContinue) -is [IO.DirectoryInfo]) { Get-ChildItem -Path $Item -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -Verbose -ErrorAction SilentlyContinue }
                            Else { Remove-Item -Path $Item -Recurse -Force -Verbose -ErrorAction SilentlyContinue }
                        }
                        Catch [UnauthorizedAccessException], [Management.Automation.ItemNotFoundException] { }
                    }
                }
            }
        }

        Function Stop-Running
        {
            [CmdletBinding()]
            Param
            (
                [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true)]
                [String[]]$Name
            )

            Process
            {
                ForEach ($Object In $Name)
                {
                    $Running = Get-Process | Where-Object -Property Name -Like *$Object*
                    If (!$Running) { $Running = Get-Service | Where-Object -Property Name -EQ $Object }
                    $Running | ForEach-Object -Process {
                        If ($PSItem -is [Diagnostics.Process])
                        {
                            If ($PSItem.Name -eq 'explorer')
                            {
                                While ((Get-Process -Name explorer).HasExited -eq $false) { Stop-Process -Name explorer -Force -Verbose }
                            }
                            Else
                            {
                                $Retries = 5
                                While ($Retries -gt 0 -and ((Get-Process -Name $PSItem.Name -ErrorAction SilentlyContinue).Responding -eq $true))
                                {
                                    Stop-Process -Name $PSItem.Name -Force -Verbose -ErrorAction SilentlyContinue
                                    Start-Sleep 1
                                    If ((Get-Process -Name $PSItem.Name -ErrorAction SilentlyContinue).Responding -eq $true) { Start-Sleep 5 }
                                    $Retries--
                                }
                            }
                        }
                        ElseIf ($PSItem -is [ServiceProcess.ServiceController])
                        {
                            If ((Get-Service -Name $PSItem.Name -ErrorAction SilentlyContinue).Status -ne 'Stopped')
                            {
                                $Retries = 5
                                While ($Retries -gt 0 -and ((Get-Service -Name $PSItem.Name -ErrorAction SilentlyContinue).Status -ne 'Stopped'))
                                {
                                    Stop-Service -Name $PSItem.Name -Force -Verbose -ErrorAction SilentlyContinue
                                    Start-Sleep 1
                                    If ((Get-Service -Name $PSItem.Name -ErrorAction SilentlyContinue).Status -eq 'Running') { Start-Sleep 5 }
                                    $Retries--
                                }
                            }
                        }
                        Else { $null }
                    }
                }
            }
        }

        # Assign the local and global paths to their own variables for easier path building.
        $GlobalAppData = $Env:APPDATA
        $LocalAppData = $Env:LOCALAPPDATA
        $RootAppData = "$(Split-Path -Path $LocalAppData)\*"

        # Generate the StateFlags integer string and set it to its registry property name.
        $StateFlags = [Convert]::ToString($(Get-Random -Minimum 1 -Maximum 9999))
        $PropertyName = "StateFlags{0:D4}" -f $StateFlags

        # Assign the name of the transcript log using Unix time.
        $Transcript = Join-Path -Path $Env:SystemRoot\Temp -ChildPath "Start-WindowsCleanup_$(Get-Date -Date (Get-Date).ToUniversalTime() -UFormat %s -Millisecond 0).log"

        # Exclude downloads folders by default.
        $ExcludedList = [Collections.Generic.List[String]]@('DownloadsFolder')

        # If the -Force switch is enabled without the required -Additional parameter or -ResetBase switch, disable it.
        If (!$Additional -or !$ResetBase.IsPresent -and $Force.IsPresent) { $Force = $false }

        # If both the -ComponentCleanup and -ResetBase switches are used, disable ResetBase and only run a Component Store clean-up.
        If ($ComponentCleanup.IsPresent -and $ResetBase.IsPresent) { $ResetBase = $false }

        # If the running system is Windows 10 build 18362 or greater, disable the ResetBase features unless the -Force switch is used.
        If ((Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber -ge 18362 -and $PSBoundParameters.ResetBase -and !$Force.IsPresent) { $ResetBase = $false }

        # If the ResetBase parameter set name is present, assign the name of the log that will be used for the PowerShell job using Unix time.
        If ($PSBoundParameters.ComponentCleanup -or $PSBoundParameters.ResetBase) { $DISMLog = Join-Path -Path $Env:TEMP -ChildPath "DismCleanupImage_$(Get-Date -Date (Get-Date).ToUniversalTime() -UFormat %s -Millisecond 0).log" }

        # If the running system is Windows 10 build 18362 or greater, disable the cleanup of updates.
        If ((Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber -ge 18362) { $ExcludedList.Add('Update Cleanup') }

        # Assign the path testing results for the icon and thumbnail caches to their own variables.
        $IconCache = @($LocalAppData, (Join-Path -Path $LocalAppData -ChildPath 'Microsoft\Windows\Explorer')) | Test-Path -Filter iconcache*.db
        $ThumbnailCache = (Join-Path -Path $LocalAppData -ChildPath 'Microsoft\Windows\Explorer') | Test-Path -Filter thumbcache_*.db

        # Assign the pre-cleanup storage state to a variable.
        $PreClean = (Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object -Property DriveType -EQ 3 | Select-Object -Property @{ Name = 'Drive'; Expression = { ($PSItem.DeviceID) } },
            @{ Name = 'Size (GB)'; Expression = { '{0:N1}' -f ($PSItem.Size / 1GB) } },
            @{ Name = 'FreeSpace (GB)'; Expression = { '{0:N1}' -f ($PSItem.Freespace / 1GB) } },
            @{ Name = 'PercentFree'; Expression = { '{0:P1}' -f ($PSItem.FreeSpace / $PSItem.Size) } } | Format-Table -AutoSize | Out-String).Trim()
    }
    Process
    {
        If (!$PSCmdlet.ShouldProcess($Env:COMPUTERNAME, 'Start-WindowsCleanup')) { Break }

        Clear-Host

        Start-Transcript -Path $Transcript

        If ($PSBoundParameters.ComponentCleanup -or $PSBoundParameters.ResetBase)
        {
            If ($PSCmdlet.ShouldProcess($Env:COMPUTERNAME, 'Remove all superseded components in the component store'))
            {
                If ($PSBoundParameters.ComponentCleanup)
                {
                    # Start a PowerShell Dism job to clean-up the Component Store.
                    Write-Verbose "Removing all superseded components in the component store." -Verbose
                    $DISMJob = Start-Job -ScriptBlock { Param ($DISMLog) Dism.exe /Online /Cleanup-Image /StartComponentCleanup | Out-File -FilePath $DISMLog } -ArgumentList $DISMLog -ErrorAction SilentlyContinue
                }
                ElseIf ($PSBoundParameters.ResetBase)
                {
                    # Start a PowerShell Dism job to clean-up the Component Store and reset the image base.
                    Write-Verbose "Removing all superseded components in the component store and resetting the image base." -Verbose
                    $DISMJob = Start-Job -ScriptBlock { Param ($DISMLog) Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-File -FilePath $DISMLog } -ArgumentList $DISMLog -ErrorAction SilentlyContinue
                }

                Do
                {
                    Start-Sleep 5
                    Get-Content -Path $DISMLog -Tail 3 | Select-String -Pattern '%' | Select-Object -Last 1
                }
                While ((Get-Job -Id $DISMJob.Id).State -eq 'Running')

                If ((Get-Job -Id $DISMJob.Id).State -eq 'Completed') { $DISMJob | Remove-Job -ErrorAction SilentlyContinue }

                $DISMLog | Remove-Items
            }
        }

        # The list of initial items that will be cleaned-up.
        $RemovalList = [Collections.Generic.List[Object]]@(
            (Join-Path -Path $Env:TEMP -ChildPath "\*"),
            (Join-Path -Path $RootAppData -ChildPath "Temp\*"),
            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Windows\WER\*"),
            (Join-Path -Path $RootAppData -ChildPath "Microsoft\Windows\WER\*"),
            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Terminal Server Client\Cache\*"),
            (Join-Path -Path $RootAppData -ChildPath "Microsoft\Terminal Server Client\Cache\*"),
            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Terminal Server Client\Cache\*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "debug\WIA\*.log"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "drivers\*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "INF\*.log*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "Logs\CBS\*Persist*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "Logs\DISM\*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "Logs\dosvc\*.*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "Logs\MeasuredBoot\*.log"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "Logs\NetSetup\*.*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "Logs\SIH\*.*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "Logs\WindowsBackup\*.etl"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "minidump\*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "Panther\UnattendGC\*.log"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "Prefetch\*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "security\logs\*.*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "Temp\*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "WinSxS\ManifestCache\*"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "*.log"),
            (Join-Path -Path $Env:SystemRoot -ChildPath "*.dmp"),
            (Join-Path -Path $Env:SystemDrive -ChildPath "*.dmp"),
            (Join-Path -Path $Env:SystemDrive -ChildPath "File*.chk"),
            (Join-Path -Path $Env:SystemDrive -ChildPath "Found.*\*.chk"),
            (Join-Path -Path $Env:SystemDrive -ChildPath "LiveKernelReports\*.dmp"),
            (Join-Path -Path $Env:SystemDrive -ChildPath "swsetup\*"),
            (Join-Path -Path $Env:SystemDrive -ChildPath "swtools\*"),
            (Join-Path -Path $Env:SystemDrive -ChildPath "Windows.old"),
            (Join-Path -Path $Env:HOMEDRIVE -ChildPath "Config.Msi"),
            (Join-Path -Path $Env:HOMEDRIVE -ChildPath "inetpub\logs\LogFiles\*"),
            (Join-Path -Path $Env:HOMEDRIVE -ChildPath "Intel\*"),
            (Join-Path -Path $Env:HOMEDRIVE -ChildPath "PerfLogs\*")
        )

        Switch ($PSCmdlet.ParameterSetName)
        {
            'GUI'
            {
                # If the GUI parameter set name is present, create an output Gridview list allowing for the selection of items to include in the removal process.
                $IncludeList = [Ordered]@{
                    Downloads        = 'Removes all content from all download folders and directories.'
                    RestorePoints    = 'Removes all system restore points.'
                    EventLogs        = 'Removes all event logs and event tracing log files.'
                    DuplicateDrivers = 'Outputs a Gridview list of any outdated and duplicate drivers for selective removal.'
                    Chrome           = 'Removes all cache, cookie, history and logging directories for the Google Chrome web browser.'
                    Firefox          = 'Removes all cache, cookie, history and logging directories for the Mozilla Firefox web browser.'
                    IE               = 'Removes all cache, cookie, history and logging directories for the Internet Explorer web browser.'
                    Edge             = 'Removes all cache, cookie, history and logging directories for the Microsoft Edge web browser.'
                }
                $IncludeList = $IncludeList.Keys | Select-Object -Property @{ Label = 'Name'; Expression = { $PSItem } }, @{ Label = 'Description'; Expression = { $IncludeList[$PSItem] } } | Out-GridView -Title "Select items to include in the clean-up process." -PassThru
                If ($IncludeList) { $IncludeList = $IncludeList.GetEnumerator().Name }
                Break
            }
            Default { $IncludeList = $Include; Break }
        }

        Switch ($IncludeList)
        {
            'Downloads'
            {
                # Before adding downloads content to the removal list, verify the parameter value was not issued by accident.
                Add-Type -AssemblyName PresentationFramework
                $Verify = [Windows.MessageBox]::Show('Are you sure you want to remove all downloads?', 'Verify Removal', 'YesNo', 'Question')
                Switch ($Verify)
                {
                    Yes { [Void]$ExcludedList.Remove('DownloadsFolder'); Break }
                    No { Break }
                    Default { Break }
                }

                # If verified, add all download folders and directories to the removal list.
                If ($ExcludedList -notcontains 'DownloadsFolder')
                {
                    $RemovalList.Add((
                            (Join-Path -Path $RootAppData -ChildPath "Downloads\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Downloads\*"),
                            (Join-Path -Path $Env:SystemDrive -ChildPath "Users\Administrator\Downloads\*"),
                            (Join-Path -Path (Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}" -ErrorAction SilentlyContinue) -ChildPath "\*")
                        ))
                }
            }
            'RestorePoints'
            {
                # Delete all system shadow copies if the -Include parameter with the 'RestorePoints' value is used.
                If (Get-WmiObject -Class Win32_ShadowCopy)
                {
                    Get-WmiObject -Class Win32_ShadowCopy | ForEach-Object -Process {
                        Write-Verbose ('Performing the operation "Delete ShadowCopy" on target "{0}"' -f $PSItem.ID) -Verbose
                        $PSItem.Delete()
                    }
                }
            }
            'EventLogs'
            {
                # Delete all event logs and event tracer log files if the -Include parameter with the 'EventLogs' value is used.
                Get-WinEvent -ListLog * | Where-Object { $PSItem.IsEnabled -eq $true -and $PSItem.RecordCount -gt 0 } | ForEach-Object -Process {
                    Write-Verbose ('Performing the operation "ClearLog" on target "{0}"' -f $PSItem.LogName) -Verbose
                    [Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($PSItem.LogName)
                } 2> $null
            }
            'DuplicateDrivers'
            {
                # Delete all outdated and duplicate drivers if the -Include parameter with the 'DuplicateDrivers' value is used.
                Write-Verbose "Compiling a list of any outdated and duplicate system drivers." -Verbose
                $AllDrivers = Get-WindowsDriver -Online -All | Where-Object -Property Driver -Like oem*inf | Select-Object -Property @{ Name = 'OriginalFileName'; Expression = { $PSItem.OriginalFileName | Split-Path -Leaf } }, Driver, ClassDescription, ProviderName, Date, Version
                $DuplicateDrivers = $AllDrivers | Group-Object -Property OriginalFileName | Where-Object -Property Count -GT 1 | ForEach-Object -Process { $PSItem.Group | Sort-Object -Property Date -Descending | Select-Object -Skip 1 }
                If ($DuplicateDrivers)
                {
                    $DuplicateDrivers | Out-GridView -Title 'Remove Duplicate Drivers' -PassThru | ForEach-Object -Process {
                        $Driver = $PSItem.Driver.Trim()
                        Write-Verbose ('Performing the action "Delete Driver" on target {0}' -f $Driver) -Verbose
                        Start-Process -FilePath PNPUTIL -ArgumentList ('/Delete-Driver {0} /Force' -f $Driver) -WindowStyle Hidden -Wait
                    }
                }
            }
            'Chrome'
            {
                # Add all Google Chrome cache, cookie, history and logging directories if the -Include parameter with the 'Chrome' value is used.
                'chrome' | Stop-Running
                $RemovalList.Add((
                        (Join-Path -Path $RootAppData -ChildPath "Google\Chrome\User Data\Default\Cache*\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Google\Chrome\User Data\Default\Cache*\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Google\Chrome\User Data\Default\Cookies\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Google\Chrome\User Data\Default\Cookies\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Google\Chrome\User Data\Default\Media Cache\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Google\Chrome\User Data\Default\Media Cache\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Google\Chrome\User Data\Default\Cookies-Journal\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Google\Chrome\User Data\Default\Cookies-Journal\*")
                    ))
            }
            'Firefox'
            {
                # Add all Mozilla Firefox cache, cookie, history and logging directories if the -Include parameter with the 'Firefox' value is used.
                'firefox' | Stop-Running
                $RemovalList.Add((
                        (Join-Path -Path $RootAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\Cache*\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\Cache*\*"),
                        (Join-Path -Path $GlobalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\Cache*\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\jumpListCache\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\jumpListCache\*"),
                        (Join-Path -Path $GlobalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\jumpListCache\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\thumbnails\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\thumbnails\*"),
                        (Join-Path -Path $GlobalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\*sqlite*"),
                        (Join-Path -Path $RootAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\*.log"),
                        (Join-Path -Path $LocalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\*.log"),
                        (Join-Path -Path $GlobalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\*.log"),
                        (Join-Path -Path $RootAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\storage\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\storage\*"),
                        (Join-Path -Path $GlobalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\storage\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Mozilla\Firefox\Crash Reports\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Mozilla\Firefox\Crash Reports\*"),
                        (Join-Path -Path $GlobalAppData -ChildPath "Mozilla\Firefox\Crash Reports\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\startupCache\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\startupCache\*"),
                        (Join-Path -Path $GlobalAppData -ChildPath "Mozilla\Firefox\Profiles\*.default\datareporting\*")
                    ))
            }
            'IE'
            {
                # Add all Internet Explorer cache, cookie, history and logging directories if the -Include parameter with the 'IE' value is used.
                'iexplore' | Stop-Running
                $RemovalList.Add((
                        (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Internet Explorer\*.log"),
                        (Join-Path -Path $RootAppData -ChildPath "Microsoft\Internet Explorer\*.log"),
                        (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Internet Explorer\*.txt"),
                        (Join-Path -Path $RootAppData -ChildPath "Microsoft\Internet Explorer\*.txt"),
                        (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Internet Explorer\CacheStorage\*.*"),
                        (Join-Path -Path $RootAppData -ChildPath "Microsoft\Internet Explorer\CacheStorage\*.*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Windows\INetCache\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Microsoft\Windows\INetCache\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Windows\Temporary Internet Files\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Microsoft\Windows\Temporary Internet Files\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Windows\IECompatCache\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Microsoft\Windows\IECompatCache\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Windows\IECompatUaCache\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Microsoft\Windows\IECompatUaCache\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Windows\IEDownloadHistory\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Microsoft\Windows\IEDownloadHistory\*"),
                        (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Windows\INetCookies\*"),
                        (Join-Path -Path $RootAppData -ChildPath "Microsoft\Windows\INetCookies\*")
                    ))
            }
            'Edge'
            {
                # Add Microsoft Edge HTML and Microsoft Edge Chromium cache, cookie, history and logging directories if the -Include parameter with the 'Edge' value is used.
                'msedge', 'MicrosoftEdge*' | Stop-Running
                If (Get-AppxPackage -Name Microsoft.MicrosoftEdge | Select-Object -ExpandProperty PackageFamilyName)
                {
                    $EdgePackageName = Get-AppxPackage -Name Microsoft.MicrosoftEdge | Select-Object -ExpandProperty PackageFamilyName
                    $RemovalList.Add((
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\AC\#!00*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\AC\#!00*"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\AC\Temp\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\AC\Temp\*"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\AC\Microsoft\Cryptnet*Cache\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\AC\Microsoft\Cryptnet*Cache\*"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\Cookies\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\Cookies\*"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\UrlBlock\*.tmp"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\UrlBlock\*.tmp"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\User\Default\ImageStore\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\User\Default\ImageStore\*"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\User\Default\Recovery\Active\*.dat"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\User\Default\Recovery\Active\*.dat"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\User\Default\DataStore\Data\nouser1\*\DBStore\LogFiles\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\User\Default\DataStore\Data\nouser1\*\DBStore\LogFiles\*"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\User\Default\DataStore\Data\nouser1\*\Favorites\*.ico"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\AC\MicrosoftEdge\User\Default\DataStore\Data\nouser1\*\Favorites\*.ico"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\AppData\User\Default\Indexed DB\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\AppData\User\Default\Indexed DB\*"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\TempState\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\TempState\*"),
                            (Join-Path -Path $RootAppData -ChildPath "Packages\$EdgePackageName\LocalState\Favicons\PushNotificationGrouping\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Packages\$EdgePackageName\LocalState\Favicons\PushNotificationGrouping\*")
                        ))
                }

                If ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" -ErrorAction Ignore) -or @((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction Ignore | Where-Object -Property DisplayName -EQ 'Microsoft Edge'), (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction Ignore | Where-Object -Property DisplayName -EQ 'Microsoft Edge')))
                {
                    $RemovalList.Add((
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Cache\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Code Cache\js\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Code Cache\wasm\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Cookies\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\CrashPad\*.pma"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\CrashPad\metadata"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\data_reduction_proxy_leveldb\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Extension State\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Feature Engagement Package\AvailabilityDB\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Feature Engagement Package\EventDB\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\File System\000\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\File System\Origins\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\IndexedDB\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Service Worker\CacheStorage\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Service Worker\Database\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Service Worker\ScriptCache\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Current Tabs"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Last Tabs"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\History"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\History Provider Cache"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\History-journal"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Network Action Predictor"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Top Sites"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Visited Links"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Login Data"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\*\*.log"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\*\*log*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\*\MANIFEST-*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Shortcuts"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\QuotaManager"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Web Data"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Current Session"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Last Session"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Session Storage\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Site Characteristics Database\*"),
                            (Join-Path -Path $LocalAppData -ChildPath "Microsoft\Edge\User Data\Profile *\Sync Data\LevelDB\*"),
                            (Join-Path -Path $Env:ProgramData -ChildPath "Microsoft\EdgeUpdate\Log\*"),
                            (Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "Microsoft\Edge\Application\SetupMetrics\*.pma"),
                            (Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "Microsoft\EdgeUpdate\Download\*")
                        ))
                }
            }
        }

        If ($ExcludedList -notcontains 'Update Cleanup')
        {
            # If 'Update Cleanup' has not been excluded, add the 'SoftwareDistribution\Downloads' directory and log files.
            'wuauserv' | Stop-Running
            $RemovalList.Add((
                    (Join-Path -Path $Env:SystemRoot -ChildPath "SoftwareDistribution\Download\*"),
                    (Join-Path -Path $Env:SystemRoot -ChildPath "SoftwareDistribution\DataStore\Logs\*.*"),
                    (Join-Path -Path $Env:SystemRoot -ChildPath "Logs\WindowsUpdate\*.*"),
                    (Join-Path -Path $Env:ProgramData -ChildPath "USOShared\Logs\*.*")
                ))
        }

        # Remove all content from each path added to the array list.
        $RemovalList | Remove-Items

        If ($RemovalList -match 'SoftwareDistribution')
        {
            # Restart the Windows Update Service if it was originally running since the 'SoftwareDistribution\Downloads' directory has been cleared.
            Start-Service -Name wuauserv -Verbose -ErrorAction SilentlyContinue
        }

        If ($PSBoundParameters.Additional)
        {
            # Remove any additional files, folders or directories that were passed with the -Additional parameter.
            $Additional | Remove-Items -Force:$Force
        }

        # Remove any junk folders from the Windows directory.
        Get-ChildItem -Path $Env:SystemRoot -Directory -Force -ErrorAction SilentlyContinue | Where-Object { ($PSItem.Name -match "^\{\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\}$") -and ($PSItem.Name -notmatch "win|prog|res|rec|driv") } | Remove-Items

        # Remove any junk folders from the root directory.
        Get-ChildItem -Path $Env:SystemDrive -Directory -Force -ErrorAction SilentlyContinue | Where-Object { ($PSItem.Name -notmatch "win|prog|res|rec|driv") -and ($PSItem.Name -match "^[a-z0-9]{15,}$") -and ((("$($PSItem.Name)" -replace '[0-9]', '').Length * .9) -lt ("$($PSItem.Name)" -replace '[^0-9]', '').Length) } | Remove-Items

        # Remove all Recycle Bin items from all system drives. This method is more thorough than using its shell object or the Clear-RecycleBin cmdlet.
        Get-PSDrive -PSProvider FileSystem | ForEach-Object -Process {
            $RecycleBin = Join-Path -Path $PSItem.Root -ChildPath '$Recycle.Bin\'
            If (Test-Path -Path $RecycleBin) { Get-ChildItem -Path (Join-Path -Path $RecycleBin -ChildPath '*\$I*') -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object -Process { $($PSItem.FullName.Replace('$I', '$R')), $($PSItem.FullName) | Remove-Items } }
        }

        If ($IconCache -or $ThumbnailCache)
        {
            # Disable the AutoRestartShell so Explorer does not automatically restart.
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoRestartShell -Value 0 -Force -Verbose -ErrorAction SilentlyContinue

            # Stop the Explorer process.
            'explorer' | Stop-Running

            Start-Sleep 3

            If ($IconCache)
            {
                # Refresh the icon cache.
                Invoke-Expression -Command ('IE4UINIT.EXE -SHOW')

                # Delete the icon cache databases.
                @($LocalAppData, (Join-Path -Path $LocalAppData -ChildPath 'Microsoft\Windows\Explorer')) | Get-ChildItem -Filter iconcache*.db -Force -ErrorAction SilentlyContinue | Remove-Items
            }

            If ($ThumbnailCache)
            {
                # Delete the thumbnail cache databases.
                (Join-Path -Path $LocalAppData -ChildPath 'Microsoft\Windows\Explorer') | Get-ChildItem -Filter thumbcache_*.db -Force -ErrorAction SilentlyContinue | Remove-Items
            }

            Start-Sleep 3

            # Re-enable the AutoRestartShell.
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoRestartShell -Value 1 -Force -Verbose -ErrorAction SilentlyContinue

            # Start the Explorer process.
            Start-Process -FilePath explorer -Wait
        }

        # Clear the recent document history for WordPad
        Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Wordpad\Recent File List" -Recurse -Force -ErrorAction SilentlyContinue

        # Remove the last accessed registry key.
        Remove-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit -Name LastKey -Force -Verbose -ErrorAction SilentlyContinue

        # Add the StateFlags property name to the registry.
        Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches -Exclude $ExcludedList -ErrorAction SilentlyContinue | Set-ItemProperty -Name $PropertyName -Value 2 -Force -ErrorAction SilentlyContinue

        # Start the Microsoft Windows Disk Clean-up utility in advanced mode as a .NET process.
        $ProcessInfo = New-Object -TypeName Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = '{0}' -f "$Env:SystemRoot\System32\cleanmgr.exe"
        $ProcessInfo.Arguments = '/SAGERUN:{0}' -f $StateFlags
        $ProcessInfo.CreateNoWindow = $true
        $Process = New-Object -TypeName Diagnostics.Process
        $Process.StartInfo = $ProcessInfo
        Write-Verbose "Running the Windows Disk Clean-up utility in advanced mode as a .NET process." -Verbose
        [Void]$Process.Start()
        $Process.WaitForExit()
        If ($null -ne $Process) { $Process.Dispose() }

        # Remove the StateFlags property name from the registry.
        Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches -Exclude $ExcludedList -ErrorAction SilentlyContinue | Remove-ItemProperty -Name $PropertyName -Force -ErrorAction SilentlyContinue

        # Restart the Windows Explorer process.
        'explorer' | Stop-Running
    }
    End
    {
        # Assign the post-cleanup storage state to a variable.
        $PostClean = (Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object -Property DriveType -EQ 3 | Select-Object -Property @{ Name = 'Drive'; Expression = { ($PSItem.DeviceID) } },
            @{ Name = 'Size (GB)'; Expression = { '{0:N1}' -f ($PSItem.Size / 1GB) } },
            @{ Name = 'FreeSpace (GB)'; Expression = { '{0:N1}' -f ($PSItem.Freespace / 1GB) } },
            @{ Name = 'PercentFree'; Expression = { '{0:P1}' -f ($PSItem.FreeSpace / $PSItem.Size) } } | Format-Table -AutoSize | Out-String).Trim()

        # Display the disk space reclaimed by the clean-up process.
        @(("`n`n`tBefore Clean-up:`n{0}" -f $PreClean), ("`n`n`tAfter Clean-up:`n{0}`n" -f $PostClean)) | Write-Output

        # Stop the transcript.
        Stop-Transcript -ErrorAction Ignore
        Write-Output ''
    }
}
