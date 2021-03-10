rem Script to copy DAT files from tester to Files folder of the Terminals
rem To be used after training of the robot using Strategy Tester

@echo off
setlocal enabledelayedexpansion

:: files generated in the tester\files folder
set SOURCE_DIR="%PATH_T2_T%\tester\files"
:: files copied to the sandbox folder MQL4\Files
set DEST_DIR1="%PATH_T1%"
set DEST_DIR2="%PATH_T3%"
set DEST_DIR3="%PATH_T4%"

rem only copy *.dat files
ROBOCOPY %SOURCE_DIR% %DEST_DIR1% *.dat
ROBOCOPY %SOURCE_DIR% %DEST_DIR2% *.dat
ROBOCOPY %SOURCE_DIR% %DEST_DIR3% *.dat

::pause
