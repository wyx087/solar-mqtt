@echo off 

set nighthourlow=0
set nighthourhigh=7
::If in above range, run night mode. When hour changes to %nighthourhigh%, GOTO NIGHTFINISH   

set hour=%time:~0,2%
if "%hour:~0,1%" == " " set hour=0%hour:~1,1%
rem echo hour=%hour%
set min=%time:~3,2%
if "%min:~0,1%" == " " set min=0%min:~1,1%
rem echo min=%min%
IF %hour% GEQ %nighthourlow% IF %hour% LSS %nighthourhigh% (GOTO NIGHTRUN)

:NORMAL 
echo Not night time, run normally: 

	tasklist /fi "imagename eq NiceHashMiner.exe" |find "NiceHashMiner.exe" > nul
	if errorlevel 1    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 1 1 0)    else    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 1 1 1)
	:: Above line says if (process not running) else (running).  

	taskkill /T /IM NiceHashMiner.exe
	nvidia-smi --power-limit=260
	shutdown -a

GOTO END 
:NIGHTRUN
echo Night time mining 

	nvidia-smi --power-limit=165
	start "" "c:\Users\wyx\AppData\Local\Programs\NiceHash Miner\NiceHashMiner.exe"

	:LOOP
		TIMEOUT /T 30 
		set hour=%time:~0,2%
		if "%hour:~0,1%" == " " set hour=0%hour:~1,1%
		IF %hour% GEQ %nighthourhigh% (GOTO NIGHTFINISH)
	GOTO LOOP 

	:NIGHTFINISH
	nvidia-smi --power-limit=260
	shutdown.exe -s -t 300

GOTO END 
:END 

pause