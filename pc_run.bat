@echo off 
:: To enable display of timed out choice 
setlocal enableDelayedExpansion  
set normalinitialwait=40

::If in above range, run night mode. When hour changes to %nighthourhigh%, GOTO NIGHTFINISH   
set nighthourlow=02
set nighthourhigh=06

:: Local time 
set hour=%time:~0,2%
if "%hour:~0,1%" == " " set hour=0%hour:~1,1%
echo hour=%hour%
set minute=%time:~3,2%
if "%minute:~0,1%" == " " set minute=0%minute:~1,1%
echo minute=%minute%
:: UTC 
rem for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set %%x 
rem echo hour=%hour%; minute=%minute%

IF %hour% GEQ %nighthourlow% IF %hour% LSS %nighthourhigh% (GOTO NIGHTRUN)

:NORMAL 
echo Day time, run normally: 
  TIMEOUT /T 8 

  for /l %%N in (%normalinitialwait% -1 1) do (
    set /a "min=%%N/60, sec=%%N%%60, n-=1"
    if !sec! lss 10 set sec=0!sec!
    cls
    choice /c:CN1 /n /m "Start mining in !min!:!sec! - N to Start Now, or C to Cancel: " /t:1 /d:1
    if not errorlevel 3 goto CHOICEBREAK
  )
  cls
  echo Start mining in 0:00 - N to Start Now, or C to Cancel..
  :CHOICEBREAK
  if errorlevel 2 (goto NORMALSTART) else (goto END)  
    
  :NORMALSTART
  start "" "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe" -Profile4
    TIMEOUT /T 2 > nul
    :TERMINATE_NORMAL 
rem        taskkill /IM MSIAfterburner.exe
rem        TIMEOUT /T 2 > nul
rem        tasklist /fi "imagename eq MSIAfterburner.exe" |find "MSIAfterburner.exe" > nul
rem        if errorlevel 1   (GOTO CONTINUE_NORMAL )    else    (GOTO TERMINATE_NORMAL )
    :CONTINUE_NORMAL 
	tasklist /fi "imagename eq NiceHashMiner.exe" |find "NiceHashMiner.exe" > nul
	if errorlevel 1    (GOTO RUN_C_NOT_M)    else    (GOTO RUN_C_MINING)
	:: Above line says if (process not running) else (running).  

  :RUN_C_MINING 
    tasklist /fi "imagename eq chia.exe" |find "chia.exe" > nul
    if errorlevel 1    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 1 1 1 45 )    else    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 0 1 1 45 )
    :: Above line says if (process not running) else (running).  
  GOTO END

  :RUN_C_NOT_M 
    tasklist /fi "imagename eq chia.exe" |find "chia.exe" > nul
    if errorlevel 1    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 1 1 0 45 )    else    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 0 1 0 45 )
    :: Above line says if (process not running) else (running).  
  GOTO END 


:NIGHTRUN
echo Night time direct mining: 

	"G:\programs\ClickMonitorDDC\ClickMonitorDDC_7_2.exe" x 
  TIMEOUT /T 30
	
	start "" "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe" -Profile4
    TIMEOUT /T 5
    :TERMINATE_NIGHT 
rem        taskkill /IM MSIAfterburner.exe
rem        TIMEOUT /T 2 > nul
rem        tasklist /fi "imagename eq MSIAfterburner.exe" |find "MSIAfterburner.exe" > nul
rem        if errorlevel 1   (GOTO CONTINUE_NIGHT )    else    (GOTO TERMINATE_NIGHT )
    :CONTINUE_NIGHT 
  "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe" --power-limit=128
	start "" "c:\Users\wyx\AppData\Local\Programs\NiceHash Miner\NiceHashMiner.exe"

	:LOOP
		TIMEOUT /T 120  > nul
		"G:\programs\ClickMonitorDDC\ClickMonitorDDC_7_2.exe" x 
		
		:: Local time 
		set hour=%time:~0,2%
		if "%hour:~0,1%" == " " set hour=0%hour:~1,1%
		echo hour=%hour%
		set minute=%time:~3,2%
		if "%minute:~0,1%" == " " set minute=0%minute:~1,1%
		echo minute=%minute%
		:: UTC 
		rem for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set %%x 
		rem echo hour=%hour%; minute=%minute%
		
		IF %hour% GEQ %nighthourhigh%  IF %minute% GEQ 0 (GOTO NIGHTFINISH)
	GOTO LOOP 

	:NIGHTFINISH
	echo Ending night time mining. Transition to Daytime program: 
	tasklist /fi "imagename eq chia.exe" |find "chia.exe" > nul
	if errorlevel 1    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 1 1 1 2 )    else    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 0 1 1 2 )
	:: Above line says if (process not running) else (running).  

GOTO END 

:END 
taskkill /T /IM NiceHashMiner.exe
"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe" --power-limit=260
TIMEOUT /T 2 > nul
start "" "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe" -Profile5
shutdown -a
