rem Script to copy DAT files from tester to Files folder of the Terminals
rem To be used after training of the robot using Strategy Tester

@echo off
setlocal enabledelayedexpansion

:: files generated in the tester\files folder
set SOURCE_DIR="C:\Program Files (x86)\ICMarkets MT4 Terminal2\tester\files"
:: files copied to the sandbox folder MQL4\Files
set DEST_DIR1="C:\Program Files (x86)\ICMarkets MT4 Terminal1\MQL4\Files"
set DEST_DIR2="C:\Program Files (x86)\ICMarkets MT4 Terminal3\MQL4\Files"
set DEST_DIR3="C:\Program Files (x86)\ICMarkets MT4 Terminal4\MQL4\Files"

rem only copy *.dat files
ROBOCOPY %SOURCE_DIR% %DEST_DIR1% *.dat
ROBOCOPY %SOURCE_DIR% %DEST_DIR2% *.dat
ROBOCOPY %SOURCE_DIR% %DEST_DIR3% *.dat


pause
=======
::pause

:: delete data in the file OrdersResultsT1.csv related to the updated systems, also disable sytems in T3
::"C:\Program Files\R\R-3.5.1\bin\Rscript.exe" "C:\Users\fxtrams\Documents\000_TradingRepo\R_tradecontrol\_OT\delete_data_of_re_trained_bots.R"


