@echo off

REG ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer /V ScreenshotIndex /T REG_DWORD /D 1 /F
