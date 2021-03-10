rem Script to copy DAT files from tester to Files folder of the Terminals
rem IMPORTANT: This script will also clean up all relevant files to start from the beginning
rem To be used to start from the beginning

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

:: ### TERMINAL 1 ###
:: delete Order Results files
del "%PATH_T1%\OrdersResultsT1.csv" \q
:: delete files with MarketType prediction
del "%PATH_T1%\AI_MarketType_*.csv" \q
:: delete files with MarketType log
del "%PATH_T1%\MarketTypeLog*.csv" \q
:: ### TERMINAL 3 ###
:: delete Order Results files
del "%PATH_T3%\OrdersResultsT3.csv" \q
:: delete files with MarketType prediction
del "%PATH_T3%\AI_MarketType_*.csv" \q
:: delete files with MarketType log
del "%PATH_T3%\MarketTypeLog*.csv" \q
:: delete files with Reinforcement Learning Policy
del "%PATH_T3%\SystemControlMT*.csv" \q

:: delete control files with extension *.rds
del "%PATH_DSS_Repo%\R_tradecontrol\_RL_MT\control\*.rds" \q


