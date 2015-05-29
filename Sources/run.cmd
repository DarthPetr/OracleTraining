rem --------------------------------------------------------------
rem -  run this this file with connect string in next format :
rem -        "USER_NAME/USER_PASSWORD@DB_ALIAS_NAME" 
rem - 
rem -  e.g. run.cmd crds_amdm_qa/crds_amdm_qa@osrm_dev
rem -       run.cmd crds_amdm_qa/crds_amdm_qa@osrm_dev NOUSER NOROLE Y
rem - 
rem --------------------------------------------------------------

cls
@Echo Off
Set _CURR_DIR=%~dp0
For /D %%a In ("%_CURR_DIR:~0,-1%") Do Set _CURR_DIR=%%~na

set _OWNER=%1%
set _USER=%2%
set _ROLE=%3%
set _SKIP=%4%

if "%_USER%"=="" (set _USER=NOUSER)
if "%_ROLE%"=="" (set _ROLE=NOROLE)
if "%_SKIP%"=="" (set _SKIP=N)

cd scripts
sqlplus -s %_OWNER% @#patch#.sql %_CURR_DIR% %_USER% %_ROLE% %_SKIP%
cd ..

if "%_SKIP%"=="Y" (exit)

