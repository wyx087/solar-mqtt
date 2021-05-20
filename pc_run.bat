@echo off 
:: To enable display of timed out choice 
setlocal enableDelayedExpansion  
set normalinitialwait=20

::If in above range, run night mode. When hour changes to %nighthourhigh%, GOTO NIGHTFINISH   
set nighthourlow=00
set nighthourhigh=7

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
        taskkill /IM MSIAfterburner.exe
        TIMEOUT /T 1 > nul
        tasklist /fi "imagename eq MSIAfterburner.exe" |find "MSIAfterburner.exe" > nul
        if errorlevel 1   (GOTO CONTINUE_NORMAL )    else    (GOTO TERMINATE_NORMAL )
    :CONTINUE_NORMAL 
	tasklist /fi "imagename eq NiceHashMiner.exe" |find "NiceHashMiner.exe" > nul
	if errorlevel 1    (GOTO RUN_C_NOT_M)    else    (GOTO RUN_C_MINING)
	:: Above line says if (process not running) else (running).  

  :RUN_C_MINING 
    tasklist /fi "imagename eq chia.exe" |find "chia.exe" > nul
    if errorlevel 1    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 1 1 1 25 )    else    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 0 1 1 25 )
    :: Above line says if (process not running) else (running).  
  GOTO END

  :RUN_C_NOT_M 
    tasklist /fi "imagename eq chia.exe" |find "chia.exe" > nul
    if errorlevel 1    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 1 1 0 25 )    else    (wsl /mnt/g/programs/NiceHash_auto/pc.exe 0 1 0 25 )
    :: Above line says if (process not running) else (running).  
  GOTO END 


:NIGHTRUN
echo Night time direct mining: 

	TIMEOUT /T 30
	rem turn off display using this: c:\windows\system32\DisplaySwitch /external
	
	start "" "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe" -Profile4
    TIMEOUT /T 5
    :TERMINATE_NIGHT 
        taskkill /IM MSIAfterburner.exe
        TIMEOUT /T 1 > nul
        tasklist /fi "imagename eq MSIAfterburner.exe" |find "MSIAfterburner.exe" > nul
        if errorlevel 1   (GOTO CONTINUE_NIGHT )    else    (GOTO TERMINATE_NIGHT )
    :CONTINUE_NIGHT 
  "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe" --power-limit=150
	start "" "c:\Users\wyx\AppData\Local\Programs\NiceHash Miner\NiceHashMiner.exe"

	:LOOP
		TIMEOUT /T 120  > nul
		for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set %%x 
		IF %hour% GEQ %nighthourhigh%  IF %minute% GEQ 20 (GOTO NIGHTFINISH)
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
start "" "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe" -Profile5
shutdown -a
