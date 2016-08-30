REM ********************************************************************************************************************
REM * Hi-Jack the Auto Build Variables by QtAgent since this is injected after it has REM * setup
REM * Open the autogenerated qtREM * setup in the test run location of
REM * C:\Users\IntegrationTester\AppData\Local\VSEQT\QTAgent\...
REM * For example:
REM * set DeploymentDirectory=C:\Users\INTEGR~1\AppData\Local\VSEQT\QTAgent\54371B~1\RSAKLF~1\DEPLOY~1
REM * set TestRunDirectory=C:\Users\INTEGR~1\AppData\Local\VSEQT\QTAgent\54371B~1\RSAKLF~1
REM * set TestRunResultsDirectory=C:\Users\INTEGR~1\AppData\Local\VSEQT\QTAgent\54371B~1\RSAKLF~1\Results\RSAKLF~1
REM * set TotalAgents=5
REM * set AgentWeighting=100
REM * set AgentLoadDistributor=Microsoft.VisualStudio.TestTools.Execution.AgentLoadDistributor
REM * set AgentId=1
REM * set TestDir=C:\Users\INTEGR~1\AppData\Local\VSEQT\QTAgent\54371B~1\RSAKLF~1
REM * set ResultsDirectory=C:\Users\INTEGR~1\AppData\Local\VSEQT\QTAgent\54371B~1\RSAKLF~1\Results
REM * set DataCollectionEnvironmentContext=Microsoft.VisualStudio.TestTools.Execution.DataCollectionEnvironmentContext
REM * set TestLogsDir=C:\Users\INTEGR~1\AppData\Local\VSEQT\QTAgent\54371B~1\RSAKLF~1\Results\RSAKLF~1
REM * set ControllerName=rsaklfsvrtfsbld:6901
REM * set TestDeploymentDir=C:\Users\INTEGR~1\AppData\Local\VSEQT\QTAgent\54371B~1\RSAKLF~1\DEPLOY~1
REM * set AgentName=RSAKLFTST7X64-3
REM ********************************************************************************************************************

REM ** Check for admin **
@echo off
echo Administrative permissions required. Detecting permissions...
REM using the "net session" command to detect admin, it requires elevation in the most operating systems - Ashley
IF EXIST %windir%\nircmd.exe (nircmd elevate net session >nul 2>&1) else (net session >nul 2>&1)
if %errorLevel% == 0 (
	echo Success: Administrative permissions confirmed.
) else (
	echo Failure: Current permissions inadequate.
	exit 1
)
@echo on

REM Init paths to Warewolf server under test
IF EXIST "%DeploymentDirectory%\DebugServer.zip" powershell.exe -nologo -noprofile -command "& { Expand-Archive '%DeploymentDirectory%\DebugServer.zip' '%DeploymentDirectory%\Server' -Force }"
IF "%DeploymentDirectory%"=="" IF EXIST "%~dp0..\..\..\Dev2.Server\bin\Debug\Warewolf Server.exe" SET DeploymentDirectory=%~dp0..\..\..\Dev2.Server\bin\Debug
IF EXIST "%DeploymentDirectory%\Server\Warewolf Server.exe" SET DeploymentDirectory=%DeploymentDirectory%\Server
IF EXIST "%DeploymentDirectory%\ServerStarted" DEL "%DeploymentDirectory%\ServerStarted"

sc interrogate "Warewolf Server"
if %ERRORLEVEL% EQU 1060 GOTO NotInstalled
if %ERRORLEVEL% EQU 1061 GOTO NotReady
if %ERRORLEVEL% EQU 1062 GOTO NotStarted
if %ERRORLEVEL% EQU 0 GOTO Running

:NotInstalled
IF EXIST %windir%\nircmd.exe (nircmd elevate sc create "Warewolf Server" binPath= "%DeploymentDirectory%\Warewolf Server.exe" obj= dev2\Integrationtester start= demand) else (sc create "Warewolf Server" binPath= "%DeploymentDirectory%\Warewolf Server.exe" obj= dev2\Integrationtester start= demand)
GOTO StartService

:NotReady
set /a LoopCounter=0
:WaitForServiceReadyLoopBody
IF NOT %ERRORLEVEL% EQU 1061 GOTO Running
set /a LoopCounter=LoopCounter+1
IF %LoopCounter% EQU 60 exit 1
rem wait for 10 seconds before trying again
@echo %AgentName% is attempting number %LoopCounter% out of 60: Waiting 10 more seconds for server service to be ready...
ping -n 10 -w 1000 192.0.2.2 > nul
IF EXIST %windir%\nircmd.exe (nircmd elevate taskkill /im "Warewolf Server.exe" /T /F) else (taskkill /im "Warewolf Server.exe" /T /F)
sc interrogate "Warewolf Server"
goto WaitForServiceReadyLoopBody

:Running
IF EXIST %windir%\nircmd.exe (nircmd elevate sc stop "Warewolf Server") else (sc stop "Warewolf Server")
IF EXIST %windir%\nircmd.exe (nircmd elevate sc config "Warewolf Server" binPath= "%DeploymentDirectory%\Warewolf Server.exe") else (sc config "Warewolf Server" binPath= "%DeploymentDirectory%\Warewolf Server.exe")
GOTO StartService

:NotStarted
IF EXIST %windir%\nircmd.exe (nircmd elevate sc config "Warewolf Server" binPath= "%DeploymentDirectory%\Warewolf Server.exe") else (sc config "Warewolf Server" binPath= "%DeploymentDirectory%\Warewolf Server.exe")
GOTO StartService

:StartService

REM ** Delete the Warewolf ProgramData folder
IF EXIST %windir%\nircmd.exe (nircmd elevate cmd /c rd /S /Q "%PROGRAMDATA%\Warewolf\Resources") else (rd /S /Q "%PROGRAMDATA%\Warewolf\Resources")
IF EXIST %windir%\nircmd.exe (nircmd elevate cmd /c rd /S /Q "%PROGRAMDATA%\Warewolf\Workspaces") else (rd /S /Q "%PROGRAMDATA%\Warewolf\Workspaces")
IF EXIST %windir%\nircmd.exe (nircmd elevate cmd /c rd /S /Q "%PROGRAMDATA%\Warewolf\Server Settings") else (rd /S /Q "%PROGRAMDATA%\Warewolf\Server Settings")
IF EXIST "%PROGRAMDATA%\Warewolf\Resources" powershell.exe -nologo -noprofile -command "& { Remove-Item '%PROGRAMDATA%\Warewolf\Resources' -Recurse -Force }"
IF EXIST "%PROGRAMDATA%\Warewolf\Workspaces" powershell.exe -nologo -noprofile -command "& { Remove-Item '%PROGRAMDATA%\Warewolf\Workspaces' -Recurse -Force }"
IF EXIST "%PROGRAMDATA%\Warewolf\Server Settings" powershell.exe -nologo -noprofile -command "& { Remove-Item '%PROGRAMDATA%\Warewolf\Server Settings' -Recurse -Force }"
IF EXIST "%PROGRAMDATA%\Warewolf\Resources" exit 1
IF EXIST "%PROGRAMDATA%\Warewolf\Workspaces" exit 1
IF EXIST "%PROGRAMDATA%\Warewolf\Server Settings" exit 1

IF EXIST %windir%\nircmd.exe (nircmd elevate sc start "Warewolf Server") else (sc start "Warewolf Server")
