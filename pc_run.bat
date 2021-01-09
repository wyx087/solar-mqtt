@echo off 

tasklist /fi "imagename eq NiceHashMiner.exe" |find "NiceHashMiner.exe" > nul
if errorlevel 1    (wsl ./pc.exe 1 0)    else    (wsl ./pc.exe 1 1)
:: Above line says if (process not running) else (running).  

taskkill /T /IM NiceHashMiner.exe
nvidia-smi --power-limit=260
pause