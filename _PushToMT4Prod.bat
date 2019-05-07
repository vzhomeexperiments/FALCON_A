rem Script to Deploy files from Version Control repository to All Terminals
rem Use when you need to publish all files to All Terminals

@echo off
setlocal enabledelayedexpansion

set SOURCE_DIR="C:\LazyTrading\GitHub\FALCON_A"
set DEST_DIR1="C:\Program Files (x86)\ICMarkets MT4 Terminal1\MQL4\Experts\03_FALCON_A"
set DEST_DIR2="C:\Program Files (x86)\ICMarkets MT4 Terminal2\MQL4\Experts\03_FALCON_A"
set DEST_DIR3="C:\Program Files (x86)\ICMarkets MT4 Terminal3\MQL4\Experts\03_FALCON_A"
set DEST_DIR4="C:\Program Files (x86)\ICMarkets MT4 Terminal4\MQL4\Experts\03_FALCON_A"

ROBOCOPY %SOURCE_DIR% %DEST_DIR1% *.mq4
ROBOCOPY %SOURCE_DIR% %DEST_DIR2% *.mq4
ROBOCOPY %SOURCE_DIR% %DEST_DIR3% *.mq4
ROBOCOPY %SOURCE_DIR% %DEST_DIR4% *.mq4



