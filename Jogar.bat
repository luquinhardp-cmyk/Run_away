@echo off
setlocal
cd /d "%~dp0"
if defined GODOT_EXE goto launch
set "GODOT_EXE=%~dp0..\.tools\godot\Godot_v4.7.2-stable_win64.exe"
if exist "%GODOT_EXE%" goto launch
echo Abra project.godot na Godot 4.7.2 ou defina GODOT_EXE.
pause
exit /b 1
:launch
"%GODOT_EXE%" --path "%~dp0."
