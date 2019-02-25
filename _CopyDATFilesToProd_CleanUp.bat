rem Script to copy DAT files from tester to Files folder of the Terminals
rem IMPORTANT: This script will also clean up all relevant files to start from the beginning
rem To be used to start from the beginning

@echo off
setlocal enabledelayedexpansion

:: files generated in the tester\files folder
set SOURCE_DIR="C:\Program Files (x86)\FxPro - Terminal2\tester\files"
:: files copied to the sandbox folder MQL4\Files
set DEST_DIR1="C:\Program Files (x86)\FxPro - Terminal1\MQL4\Files"
set DEST_DIR2="C:\Program Files (x86)\FxPro - Terminal3\MQL4\Files"
set DEST_DIR3="C:\Program Files (x86)\FxPro - Terminal4\MQL4\Files"

rem only copy *.dat files
ROBOCOPY %SOURCE_DIR% %DEST_DIR1% *.dat
ROBOCOPY %SOURCE_DIR% %DEST_DIR2% *.dat
ROBOCOPY %SOURCE_DIR% %DEST_DIR3% *.dat

::pause

:: ### TERMINAL 1 ###
:: delete Order Results files
del "C:\Program Files (x86)\FxPro - Terminal1\MQL4\Files\OrdersResultsT1.csv" \q
:: delete files with MarketType prediction
del "C:\Program Files (x86)\FxPro - Terminal1\MQL4\Files\AI_MarketType_*.csv" \q
:: delete files with MarketType log
del "C:\Program Files (x86)\FxPro - Terminal1\MQL4\Files\MarketTypeLog*.csv" \q
:: ### TERMINAL 3 ###
:: delete Order Results files
del "C:\Program Files (x86)\FxPro - Terminal3\MQL4\Files\OrdersResultsT3.csv" \q
:: delete files with MarketType prediction
del "C:\Program Files (x86)\FxPro - Terminal3\MQL4\Files\AI_MarketType_*.csv" \q
:: delete files with MarketType log
del "C:\Program Files (x86)\FxPro - Terminal3\MQL4\Files\MarketTypeLog*.csv" \q
:: delete files with Reinforcement Learning Policy
del "C:\Program Files (x86)\FxPro - Terminal3\MQL4\Files\SystemControlMT*.csv" \q

:: delete control files with extension *.rds
del "C:\Users\fxtrams\Documents\000_TradingRepo\R_tradecontrol\_RL_MT\control\*.rds" \q


:: delete data in the file OrdersResultsT1.csv related to the updated systems, also disable sytems in T3
::"C:\Program Files\R\R-3.5.1\bin\Rscript.exe" "C:\Users\fxtrams\Documents\000_TradingRepo\R_tradecontrol\_OT\delete_data_of_re_trained_bots.R"