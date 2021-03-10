rem Script to Sync Files from Development Terminal to Version Control

@echo off
setlocal enabledelayedexpansion

:: Source Directory where Expert Advisor is located
set SOURCE_DIR="%PATH_T2_E%\03_FALCON_A"
:: Destination Directory where Version Control Repository is located
set DEST_DIR="%PATH_DSS_Repo%\FALCON_A"

:: Copy only files with *.mq4 extension
ROBOCOPY %SOURCE_DIR% %DEST_DIR% Falcon_A.mq4