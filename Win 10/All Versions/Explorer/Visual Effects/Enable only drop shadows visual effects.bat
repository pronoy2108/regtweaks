@echo off
:: You need admin rights to execute the script.
:: Set performance radio button to best performance
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /V VisualFXSetting /T REG_DWORD /D 2 /F

:: Set performance radio button to custom
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /V VisualFXSetting /T REG_DWORD /D 3 /F

:: The below are set with a UserPreferencesMask, 9012038010 represents those settings converted from binary to hex.

:: (A) Animate controls and elements inside windows
:: (B) Smooth-scroll list boxes
:: (C) Slide open combo boxes
:: (D) Fade or slide menus into view
:: (E) Show shadows under mouse pointer
:: (F) Fade or slide ToolTips into view
:: (G) Fade out menu items after clicking
:: (H) Show shadows under windows

REG ADD "HKCU\Control Panel\Desktop" /V "UserPreferencesMask" /T REG_BINARY /D 9012038010000000 /F

:: To maintain the order of the Windows 10 performance menu, references will be made for all of the UserPreferencesMask settings

:: Animate controls and elements inside windows

:: Animate windows when minimizing and maximizing
REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics" /V MinAnimate /T REG_SZ /D 0 /F

:: Animations in taskbar
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V TaskbarAnimations /T REG_DWORD /D 0 /F

:: Enable Peek (this might work on some computers, I'm leaving it in, see below)
REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V DisablePreviewDesktop /T REG_DWORD /D 1 /F

:: Enable Peek (works on my computer)
REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM" /V EnableAeroPeek /T REG_DWORD /D 0 /F

:: Fade or slide menus into view
:: See UserPreferencesMask

:: Fade or slide menus into view
:: See UserPreferencesMask

:: Fade out menu items after clicking
:: See UserPreferencesMask

:: Show shadows under windows
:: See UserPreferencesMask

:: Save taskbar thumbnail previews
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM" /V AlwaysHibernateThumbnails /T REG_DWORD /D 0 /F

:: Show shadows under mouse pointer
:: See UserPreferencesMask

:: Show thumbnails instead of icons
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V IconsOnly /T REG_DWORD /D 0 /F

:: Show translucent selection rectangle
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V ListviewAlphaSelect /T REG_DWORD /D 0 /F

:: Show window contents while dragging
REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /V DragFullWindows /T REG_SZ /D 1 /F

:: Slide open combo boxes
:: See UserPreferencesMask

::Smooth edges of screen fonts
REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /V FontSmoothing /T REG_SZ /D 2 /F

:: Smooth-scroll list boxes

:: Use drop shadows for icon labels on the desktop
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"  /V ListviewShadow /T REG_DWORD /D 1 /F

:: Restart explorer via kill will not work, you need to logout and login again.
:: taskkill /f /im explorer.exe
:: start explorer.exe
