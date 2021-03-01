$selection = Read-Host "Would you like to Enable or Disable all plugins [D/E]?"
if ( "D" -eq $selection )
    {
        Write-Output "Disabling all plugins..."
        Get-ChildItem -Path "BepInEx\plugins\*" -Recurse | Move-Item -Destination "BepInEx\Disabled_plugins"
        Move-Item "BepInEx\Disabled_plugins\QuickConnect.dll" "BepInex\plugins\"
        Move-Item "BepInEx\Disabled_plugins\BetterUI" "BepInEx\plugins"
        Write-Output "All plugins should now be Disabled. Thank you for playing Legit!"
        pause
        exit
    }
if ( "E" -eq $selection )
    {
        Write-Output "Enabling all plugins..."
        Get-ChildItem -Path "BepInEx\Disabled_plugins\*" -Recurse | Move-Item -Destination "BepInEx\plugins"
                Write-Output "All plugins should now be Enabled. You can now play on the HackShardGaming Valheim Plus server!"
        pause
        exit
    }   
Write-Output "If you are seeing this you have entered an incorrect value Please try again.."
pause
exit