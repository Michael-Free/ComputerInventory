@echo off
Powershell.exe -executionpolicy bypass -File  ".\InventoryLocal.ps1" >> InventoryLocal.csv
pause