@echo OFF
setlocal enabledelayedexpansion
cd Scripts
echo ---------------------------------------
echo       List of uncalled scripts:
echo ---------------------------------------
for %%i in (*.*) do (
set /a skip = 0
if "%%i" EQU "#patch#.sql" (set /a skip = 1) 
if "%%i" EQU "1_main.sql"   (set /a skip = 1)
if "%%i" EQU "2_Before.sql" (set /a skip = 1)
if "%%i" EQU "3_After.sql"  (set /a skip = 1) 
if !skip! EQU 0 (
set /a cnt = 0
for /f "tokens=2 delims=:" %%f in ('findstr /n /i /c:"@%%i" *') do (set /a cnt=!cnt!+%%f)
if !cnt! EQU 0 (echo %%i))
)
echo ---------------------------------------
cd ..
pause