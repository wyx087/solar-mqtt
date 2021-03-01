@echo off 

set nighthourlow=00
set nighthourhigh=07
::If in above range, run night mode. When hour changes to %nighthourhigh%, GOTO NIGHTFINISH   

:: Local time 
rem set hour=%time:~0,2%
rem if "%hour:~0,1%" == " " set hour=0%hour:~1,1%
rem echo hour=%hour%
rem set min=%time:~3,2%
rem if "%min:~0,1%" == " " set min=0%min:~1,1%
rem echo min=%min%
:: UTC 
for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set %%x 
echo hour=%hour%; minute=%minute%

IF %hour% GEQ %nighthourlow% IF %hour% LSS %nighthourhigh% (GOTO NIGHTRUN)

:NORMAL 
echo Day time, run normally: 

    start "" "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe" -Profile4
	tasklist /fi "imagename eq NiceHashMiner.exe" |find "NiceHashMiner.exe" > nul
	if errorlevel 1    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 1 1 0 25 )    else    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 1 1 1 25 )
	:: Above line says if (process not running) else (running).  
	
GOTO END 
:NIGHTRUN
echo Night time direct mining: 

	TIMEOUT /T 60
	rem turn off display using this: c:\windows\system32\DisplaySwitch /external
	
	rem using MSIAfterbuner profile instead of this: nvidia-smi --power-limit=150
    start "" "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe" -Profile4
	start "" "c:\Users\wyx\AppData\Local\Programs\NiceHash Miner\NiceHashMiner.exe"

	:LOOP
		TIMEOUT /T 120  > nul
		for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set %%x 
		IF %hour% GEQ %nighthourhigh%  IF %minute% GEQ 20 (GOTO NIGHTFINISH)
	GOTO LOOP 

	:NIGHTFINISH
	echo Ending night time mining. Transition to Daytime program: 
	wsl /mnt/g/programs/NiceHash_auto/pc.exe 1 1 1 2

GOTO END 
:END 
taskkill /T /IM NiceHashMiner.exe
rem using MSIAfterbuner profile instead of this: nvidia-smi --power-limit=260
start "" "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe" -Profile5
shutdown -a
