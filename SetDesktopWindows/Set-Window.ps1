#Not done. Need to work on calling logic

function Set-Window{
    <#
    
    Author: Matt Pichelmayer 
    Going to add functionality to compile this as a service exe so you can set windows up automatically 
    #>
    [CmdletBinding()]
    param([parameter]
          [int32]$Process,
          [parameter]
          [Object[]]$InputObject,
          [parameter]
          [switch]$Maximize,
          [parameter]
          [switch]$Minimize

          )

    [string]$user32_assembly_import =  '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
    [string]$user32_assembly_import += '[DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);'
    $script:user32_dll = Add-Type -MemberDefinition $user32_assembly_import -name NativeMethods -namespace Win32

    function Maximize($Process, [Switch]$Maximize){
        $hwnd = $process.MainWindowHandle
        $user32_dll::ShowWindowAsync($hwnd, 3)
        $user32_dll::SetForegroundWindow($hwnd) 
    }
    function Minimize(){
        $hwnd = $process.MainWindowHandle
        $user32_dll::ShowWindowAsync($hwnd, 4)
        $user32_dll::SetForegroundWindow($hwnd) 
    }

    Function Set-WindowPosition {

        [OutputType('System.Automation.WindowInfo')]
        [cmdletbinding()]
        Param (
            [parameter(ValueFromPipelineByPropertyName=$True)]
            $ProcessName,
            [int]$X,
            [int]$Y,
            [int]$Width,
            [int]$Height,
            [switch]$Passthru
        )
        Begin {
            Try{
                [void][Window]
            } Catch {
            Add-Type @"
                using System;
                using System.Runtime.InteropServices;
                public class Window {
                    [DllImport("user32.dll")]
                    [return: MarshalAs(UnmanagedType.Bool)]
                    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

                    [DllImport("User32.dll")]
                    public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
                }
                public struct RECT
                {
                    public int Left;        // x position of upper-left corner
                    public int Top;         // y position of upper-left corner
                    public int Right;       // x position of lower-right corner
                    public int Bottom;      // y position of lower-right corner
                }
"@
            }
        }
        Process {
            $Rectangle = New-Object RECT
            $Handle = [system.intptr](Get-Process -Name $Processname).MainWindowHandle
            $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
            If (-NOT $PSBoundParameters.ContainsKey('Width')) {            
                $Width = $Rectangle.Right - $Rectangle.Left            
            }
            If (-NOT $PSBoundParameters.ContainsKey('Height')) {
                $Height = $Rectangle.Bottom - $Rectangle.Top
            }
            If ($Return) {
                $Return = [Window]::MoveWindow($Handle, $x, $y, $Width, $Height,$True)
            }
            If ($PSBoundParameters.ContainsKey('Passthru')) {
                $Rectangle = New-Object RECT
                $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
                If ($Return) {
                    $Height = $Rectangle.Bottom - $Rectangle.Top
                    $Width = $Rectangle.Right - $Rectangle.Left
                    $Size = New-Object System.Management.Automation.Host.Size -ArgumentList $Width, $Height
                    $TopLeft = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Left, $Rectangle.Top
                    $BottomRight = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Right, $Rectangle.Bottom
                    If ($Rectangle.Top -lt 0 -AND $Rectangle.LEft -lt 0) {
                        Write-Warning "Window is minimized! Coordinates will not be accurate."
                    }
                    $Object = [pscustomobject]@{
                        ProcessName = $ProcessName
                        Size = $Size
                        TopLeft = $TopLeft
                        BottomRight = $BottomRight
                    }
                    $Object.PSTypeNames.insert(0,'System.Automation.WindowInfo')
                    $Object            
                }
            }
        }
    }

    function Start-ProcessToForeground{

        [cmdletbinding()]
        Param ( [string]$FilePath,
                [string]$ArgumentList
                )
        
        $startproc = Start-Process -FilePath $FilePath
        $startproc.MainWindowHandle
        $started = $false

        Do {

            $status = Get-Process notepad -ErrorAction SilentlyContinue

            if (!($status)) { Write-Host '[*] Waiting for process to start' ; Start-Sleep -Seconds 1 }
            
            else { Write-Host '[+] Process has started' ; $started = $true }

        }
        Until ( $started )
        $process = (Get-Process | Where-Object { $_.Path -eq $FilePath })
        $process_name = $process.processname 
        $hwnd = @($process_name)[0].MainWindowHandle
        # Minimize window
        
        $user32_dll::ShowWindowAsync($hwnd, 2)
        # Restore window
        $user32_dll::ShowWindowAsync($hwnd, 4)

        return $process 

        }
}
