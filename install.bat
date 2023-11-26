@echo off
@echo ================ OPTIMUS INSTALLATION ============================
@echo Install optimus automation suite
@echo - Check python version - 3.10
@echo - Download latest package, unpack and update files
@echo - Install external programs - prefect, jupyter, playwright, robot framework browser
@echo - Install Pip libraries used by Optimus autobot
@echo ==================================================================

@ECHO OFF     

call:header INSTALL OPTIMUS

powershell wget https://github.com/ray-oh/Optimus/raw/master/installation/optimus_package.zip -o ./optimus_package.zip



call:installPython_winpython
EXIT /B %ERRORLEVEL%


set pythonExist=
call:programExist python pythonExist
@echo ================ SETUP PYTHON VIRTUALENV ==========================
SET /P AREYOUSURE=Install Python and VirtualEnv - Are you sure (Y/[N])
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_PYTHONVENV
if "%pythonExist%" equ "True" (
	:: check if python is 3.10 version - if true, return path
	set pythonPath=
	call:getPythonPath 3.10 pythonPath
	if "%pythonPath%" equ "" (
		@echo Python 3.10 not installed %pythonExist%  Installing python 3.10.9 ...
		:: install python
		rem call:installPython
		call:installPython_winpython
	) ELSE (
		@echo Python 3.10 already installed "%pythonPath%"
		if exist .\autobot\venv (
			rmdir .\autobot\venv /S /Q
		)
		PAUSE
		rem replace python below with specific version of python if required - use version 3.10.9
		%pythonPath% -m venv .\autobot\venv
	)
) ELSE (
	@echo No python installed %pythonExist%  Installing python 3.10.9 ...
	:: install python
	rem call:installPython
	call:installPython_winpython
)
:END_PYTHONVENV

.\autobot\venv\Scripts\python --version
.\autobot\venv\Scripts\pip --version

@echo ================ DOWNLOAD LATEST PACKAGE ==========================
SET /P AREYOUSURE=Install latest optimus package - Are you sure (Y/[N])
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_OPT_PACKAGE
rem bitsadmin /transfer downloadjob /download /priority FOREGROUND https://github.com/ray-oh/Optimus/raw/master/installation/optimus_package.zip %~dp0\optimus_package.zip
powershell wget https://github.com/ray-oh/Optimus/raw/master/installation/optimus_package.zip -o ./optimus_package.zip

@echo ================ UNPACK AND UPDATE FILES ==========================
powershell Expand-Archive -Path .\optimus_package.zip -DestinationPath .\tmp
set destSync=.
robocopy .\tmp "%destSync%" /XD __pycache__ Lib venv /XF install.bat /e /copy:DAT /mt /z
rem robocopy .\tmp "%destSync%" /XD __pycache__ Lib venv /XF install-optimus.bat /e /copy:DAT /mt /z
rmdir tmp /S /Q
:END_OPT_PACKAGE

@echo ================ INSTALL AUTOBOT ==========================
SET /P AREYOUSURE=Install Optimus libraries - Are you sure (Y/[N])
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_OPT_LIB
.\autobot\venv\Scripts\pip install -r .\autobot\requirements.txt
rem @echo ================ INSTALL wkhtmltoimage =================
rem xcopy .\autobot\wkhtml*.* .\autobot\venv\scripts\.
rem SET PATH=%PATH%;%cd%\autobot
PAUSE
:END_OPT_LIB

@echo ================ INSTALL PREFECT ==========================
SET /P AREYOUSURE=Install Prefect - Are you sure (Y/[N])
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_PREFECT
.\autobot\venv\Scripts\pip install -U prefect
.\autobot\venv\Scripts\prefect version
:END_PREFECT

@echo ================ INSTALL JUPYTER NOTEBOOK =================
SET /P AREYOUSURE=Install Jupyter Notebook - Are you sure (Y/[N])
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_JUPYTER
pip install jupyter
.\autobot\venv\Scripts\pip install ipykernel
for %%I in (.) do set CurrDirName=%%~nxI
rem echo %CurrDirName%
.\autobot\venv\Scripts\python -m ipykernel install --user --name=%CurrDirName%
:END_JUPYTER

@echo ================ LIBRARIES INSTALLED - INITIALIZE ==========================

@echo ================ INSTALL PLAYWRIGHT =================
.\autobot\venv\Scripts\playwright install
@echo ================ INSTALL ROBOTFRAMEWORK BROWSER =================

rem Need to install NPM to complete the browser initizliation - https://kinsta.com/blog/how-to-install-node-js/
rem .\installation\node-v18.18.0-x64.msi
set npmExist=
call:programExist npm npmExist
if "%npmExist%" neq "True" (
	rem set NODEJS_VERS=v20.9.0
	mkdir tmp
	call:installNPM v20.9.0
	rmdir tmp /S /Q
)

rem https://stackoverflow.com/questions/39764302/npm-throws-error-unable-to-get-issuer-cert-locally-while-installing-any-package
npm set strict-ssl=false
.\autobot\venv\Scripts\rfbrowser init --skip-browsers

@echo ================ INSTALL MITO =================
SET /P AREYOUSURE=Install Mito sheets for use in Jupyter Notebook - Are you sure (Y/[N])
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_MITO
echo ... Installing Mito - may take some time ...
.\autobot\venv\Scripts\python -m pip install mitoinstaller
.\autobot\venv\Scripts\python -m mitoinstaller install
@echo ================ INSTALLATION COMPLETED ==========================
@echo To use Auto RPA - click runRPA.bat or from the command line with parameters
call runRPA -i 1
call runRPA -h
pause
:END_MITO

:: ... put your business logic here
:: ... make sure EXIT below is present
:: ... so you don't run into actual functions without the call

call:header Operation Finished Successfully

EXIT /B %ERRORLEVEL%

@echo off
@echo ================ CHECK PYTHON VERSION ==========================
setlocal enabledelayedexpansion
set max_version=0
set target_version=3.10
for /f "delims=" %%i in ('where python.exe') do (
    set command=%%i -V 2^>^&1
    rem echo xxx !command!
    for /f "tokens=2" %%j in ('%%i -V 2^>^&1') do (
        set version=%%j
	rem echo ### %%i
	rem echo $$$ !version!
        set version=!version:~0,-2!
	rem echo --- !version!	

        set /a version_num=!version:.=!
	rem echo +++ !version_num!	

        rem if !version_num! gtr !max_version! (
	rem if !version! gtr !max_version! if !version! leq !target_version! (
	if !version! equ !target_version! (
            set max_version=!version_num!
	    set PYTHON_VER=!version!
            set PYTHON_PATH=%%i
        )
    )
)
if !PYTHON_VER! neq !target_version! (
	@echo Optimus requires a Python version %target_version%.  Please install required python before continuing.
	@echo Check target version !target_version! and installed python version %PYTHON_VER%
	exit /B 1
)
@echo %PYTHON_PATH%
rem exit /B 1
PAUSE

@echo off
@echo ================ DOWNLOAD LATEST PACKAGE ==========================
rem use bitsadmin - github link with raw package
rem bitsadmin /transfer downloadjob /download /priority FOREGROUND "http://example.com/File.zip" "C:\Downloads\File.zip"
rem curl -O https://github.com/ray-oh/Optimus/blob/master/installation/optimus_package_stable_version.zip
rem bitsadmin /transfer mydownloadjob /download /priority FOREGROUND https://github.com/ray-oh/Optimus/raw/master/installation/optimus_package.zip "D:\RPA\Optimus\package.zip"
bitsadmin /transfer downloadjob /download /priority FOREGROUND https://github.com/ray-oh/Optimus/raw/master/installation/optimus_package.zip %~dp0\optimus_package.zip

@echo ================ UNPACK AND UPDATE FILES ==========================
powershell Expand-Archive -Path .\optimus_package.zip -DestinationPath .\tmp
set destSync=.
robocopy .\tmp "%destSync%" /XD __pycache__ Lib venv /XF install.bat /e /copy:DAT /mt /z
rem robocopy .\tmp "%destSync%" /XD __pycache__ Lib venv /XF install-optimus.bat /e /copy:DAT /mt /z
rmdir tmp /S /Q
rem exit /B 1
PAUSE

@echo off

if [%1]==[] goto install_autobot 
rem usage
echo %1
@echo off
@echo ================ UNPACK PACKAGE ==========================
SET /P AREYOUSURE=Unpack package and overwrite existing files - Are you sure (Y/[N])
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END0
echo ... Installing/upgrading package ...
@echo %cd%
if exist tmp (
	rmdir tmp /S /Q
)
if not exist "optimus_package<.zip" (
	@echo Installation aborted - optimus_package.zip not found.
	pause
	EXIT /B
)
powershell Expand-Archive -Path %1 -DestinationPath .\tmp
rem set destSync=.
rem robocopy .\tmp "%destSync%" /XD __pycache__ Lib venv /XF install.bat /e /copy:DAT /mt /z
rem robocopy .\tmp "%destSync%" /XD __pycache__ Lib venv /XF install-optimus.bat /e /copy:DAT /mt /z
robocopy .\tmp . /XD __pycache__ Lib venv /XF install-optimus.bat /e /copy:DAT /mt /z
rmdir tmp /S /Q
:END0

:install_autobot
@echo ================ SETUP PYTHON VIRTUALENV ==========================
:PROMPT1
SET /P AREYOUSURE=Reinstall python libraries - Are you sure (Y/[N])
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END1
echo ... Reinstalling libraries ...
if exist .\autobot\venv (
	rmdir .\autobot\venv /S /Q
)
PAUSE
rem replace python below with specific version of python if required - use version 3.10.9
rem python -m venv .\autobot\venv
rem https://stackoverflow.com/questions/1534210/use-different-python-version-with-virtualenv
rem where python
rem C:\Python310\python.exe -m venv .\autobot\venv
%PYTHON_PATH% -m venv .\autobot\venv
.\autobot\venv\Scripts\pip --version
PAUSE
@echo ================ INSTALL PREFECT ==========================
.\autobot\venv\Scripts\pip install -U prefect
.\autobot\venv\Scripts\prefect version
@echo ================ INSTALL JUPYTER NOTEBOOK =================
pip install jupyter
.\autobot\venv\Scripts\pip install ipykernel
for %%I in (.) do set CurrDirName=%%~nxI
rem echo %CurrDirName%
.\autobot\venv\Scripts\python -m ipykernel install --user --name=%CurrDirName%
@echo ================ INSTALL AUTOBOT ==========================
.\autobot\venv\Scripts\pip install -r .\autobot\requirements.txt
rem @echo ================ INSTALL wkhtmltoimage =================
rem xcopy .\autobot\wkhtml*.* .\autobot\venv\scripts\.
rem SET PATH=%PATH%;%cd%\autobot
@echo ================ LIBRARIES INSTALLED - INITIALIZE ==========================
@echo ================ INSTALL PLAYWRIGHT =================
.\autobot\venv\Scripts\playwright install
@echo ================ INSTALL ROBOTFRAMEWORK BROWSER =================
rem Need to install NPM to complete the browser initizliation - https://kinsta.com/blog/how-to-install-node-js/
.\installation\node-v18.18.0-x64.msi
rem https://stackoverflow.com/questions/39764302/npm-throws-error-unable-to-get-issuer-cert-locally-while-installing-any-package
npm set strict-ssl=false
.\autobot\venv\Scripts\rfbrowser init --skip-browsers

@echo ================ INSTALL MITO =================
SET /P AREYOUSURE=Install Mito sheets for use in Jupyter Notebook - Are you sure (Y/[N])
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END1
echo ... Installing Mito - may take some time ...
.\autobot\venv\Scripts\python -m pip install mitoinstaller
.\autobot\venv\Scripts\python -m mitoinstaller install
@echo ================ INSTALLATION COMPLETED ==========================
@echo To use Auto RPA - click runRPA.bat or from the command line with parameters
call runRPA -i 1
call runRPA -h
pause
:END1
exit /B 1


:: =============================================================
:: Functions

:installNPM
@echo ================ INSTALL NPM %NODEJS_VERS% ==========================
set NODEJS_FILENAME=node-%1-x64.msi
rem set NODEJS_URL=https://nodejs.org/dist/%1/node-%1-x64.msi
set NODEJS_URL=https://github.com/ray-oh/Optimus-Installation/raw/main/installation/3rd_party_tools/node-v18.18.0-x64.msi
rem set NODEJS_URL=https://nodejs.org/dist/%1/node-%1-x64.msi
set NODEJS_DOWNLOAD_LOCATION=%~dp0tmp\
@echo %NODEJS_DOWNLOAD_LOCATION%  %NODEJS_URL%  %NODEJS_FILENAME%
powershell -NoExit -Command "(New-Object Net.WebClient).DownloadFile('%NODEJS_URL%', '%NODEJS_DOWNLOAD_LOCATION%%NODEJS_FILENAME%'); exit;"
msiexec /qn /l* %~dp0tmp\node-log.txt /i %NODEJS_DOWNLOAD_LOCATION%%NODEJS_FILENAME%
goto :eof

:: not used
set NODEJS_FILENAME=node-%NODEJS_VERS%-x64.msi
set NODEJS_URL=https://nodejs.org/dist/%NODEJS_VERS%/node-%NODEJS_VERS%-x64.msi
rem set NODEJS_URL=https://nodejs.org/dist/%NODEJS_VERS%/!NODEJS_FILENAME!
set NODEJS_DOWNLOAD_LOCATION=%~dp0tmp
@echo %NODEJS_DOWNLOAD_LOCATION%  %NODEJS_URL%  %NODEJS_FILENAME%
goto :eof

:installPython_Embedded
@echo ================ INSTALL PYTHON ==========================
	rem Powershell.exe -executionpolicy remotesigned -File  .\installation\embed_python.ps1
	Powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
	rem setup to call from parent directory with ps1 script in installation.  python prog installed in installation, while venv setup in autobot
	Powershell.exe mkdir installation\tmp
	Powershell.exe rm installation\python-3.10.9-embed-amd64 -r -Force
	Powershell.exe wget https://www.python.org/ftp/python/3.10.9/python-3.10.9-embed-amd64.zip -o installation\tmp\python-3.10.9-embed-amd64.zip
	Powershell.exe Expand-Archive installation\tmp\python-3.10.9-embed-amd64.zip -DestinationPath installation\python-3.10.9-embed-amd64
	Powershell.exe wget https://bootstrap.pypa.io/get-pip.py -o installation\tmp\get-pip.py
	Powershell.exe mv installation\python-3.10.9-embed-amd64\python310._pth installation\python-3.10.9-embed-amd64\python310.pth
	Powershell.exe mkdir installation\python-3.10.9-embed-amd64\DLLs
	Powershell.exe installation\python-3.10.9-embed-amd64\python.exe installation\tmp\get-pip.py
	Powershell.exe installation\python-3.10.9-embed-amd64\python.exe -m pip install virtualenv

	robocopy .\installation\tkinter .\installation\python-3.10.9-embed-amd64 /XD __pycache__ venv /XF install.bat /e /copy:DAT /mt /z
	Powershell.exe installation\python-3.10.9-embed-amd64\python.exe -m virtualenv autobot\venv
	rem #cp installation\python-3.10.9-embed-amd64\python310.zip autobot\testenv\Scripts\
	Powershell.exe rm installation\tmp -r -Force
goto :eof

:installPython_winpython
@echo ================ INSTALL PYTHON ==========================
Powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Powershell.exe mkdir installation\tmp
if not exist python_installation.exe (
	@echo Download win python minimalist package
	set PYTHON_URL=https://github.com/ray-oh/Optimus-Installation/raw/main/installation/3rd_party_tools/python-3.10.9.amd64.zip
	powershell wget %PYTHON_URL% -o ./installation/tmp/python_installation.zip
)
if not exist .\installation\python-3.10.9.amd64 (
	@echo Unpack win python
	Powershell.exe Expand-Archive installation\tmp\python_installation.zip -DestinationPath installation\python-3.10.9-embed-amd64
)

@echo Setup virtual env
if exist .\autobot\venv (
	rmdir .\autobot\venv /S /Q
)
.\installation\python-3.10.9.amd64\python.exe -m venv .\autobot\venv
Powershell.exe rm installation\tmp -r -Force
goto :eof

:create_winpython_package
@echo ================ INSTALL PYTHON ==========================
if not exist python_installation.exe (
	@echo Download win python minimalist package
	rem powershell wget https://github.com/winpython/winpython/releases/download/5.3.20221233/Winpython64-3.10.9.0.exe -o ./optimus_package.zip
	rem install winpython minimalist version 25MB with tkinter
	rem powershell wget https://github.com/winpython/winpython/releases/download/5.3.20221233/Winpython64-3.10.9.0dot.exe -o ./python_installation.exe
	set PYTHON_URL=https://github.com/ray-oh/Optimus-Installation/raw/main/installation/3rd_party_tools/python-3.10.9.amd64.zip
	powershell wget %PYTHON_URL% -o ./python_installation.exe
	rem ./tmp/python_installation.exe -o ".\python" -y
)
if not exist .\WPy64-31090\python-3.10.9.amd64 (
	@echo Unpack win python
	python_installation.exe -y -gm2
	rem -InstallPath=".\\python"
	rem flag not working - unpacks to WPy64-31090
)

@echo Move python program to installation path
if exist .\installation\python-3.10.9.amd64 (
	rmdir .\installation\python-3.10.9.amd64 /S /Q
)
move .\WPy64-31090\python-3.10.9.amd64 .\installation\python-3.10.9.amd64
if exist .\WPy64-31090 (
	rmdir .\WPy64-31090 /S /Q
)
if exist python_installation.exe (
	del python_installation.exe
)

@echo Setup virtual env
if exist .\autobot\venv (
	rmdir .\autobot\venv /S /Q
)
.\installation\python-3.10.9.amd64\python.exe -m venv .\autobot\venv
goto :eof

:checkPythonVersion
@echo off
@echo ================ CHECK PYTHON VERSION ==========================
setlocal enabledelayedexpansion
set max_version=0
set target_version=%1
::3.10
for /f "delims=" %%i in ('where python.exe') do (
    set command=%%i -V 2^>^&1
    rem echo xxx !command!
    for /f "tokens=2" %%j in ('%%i -V 2^>^&1') do (
        set version=%%j
	rem echo ### %%i
	rem echo $$$ !version!
        set version=!version:~0,-2!
	rem echo --- !version!	

        set /a version_num=!version:.=!
	rem echo +++ !version_num!	

        rem if !version_num! gtr !max_version! (
	if !version! gtr !max_version! if !version! leq !target_version! (
            set max_version=!version_num!
	    set PYTHON_VER=!version!
            set PYTHON_PATH=%%i
	    rem set %2=%%i
        )
    )
)
if !PYTHON_VER! neq !target_version! (
	@echo Optimus requires a Python version %target_version%.  Please install required python before continuing.
	@echo Check target version !target_version! and installed python version %PYTHON_VER%
	exit /B 1
)
@echo Py path %PYTHON_PATH%
set %2=Test
@echo Py path2 !%2!
rem exit /B 1
rem PAUSE
goto :eof


rem Function to get python path of target python version
:getPythonPath
@ECHO OFF
set max_version=0
set target_version=%1
set PYTHON_VER=

setlocal enabledelayedexpansion
for /f "delims=" %%i in ('where python.exe') do (
    set command=%%i -V 2^>^&1
    for /f "tokens=2" %%j in ('%%i -V 2^>^&1') do (
        set version=%%j
        set version=!version:~0,-2!
        set /a version_num=!version:.=!
	rem if !version! gtr !max_version! if !version! leq !target_version! (
	if !version! equ !target_version! (
            set max_version=!version_num!
	    set PYTHON_VER=!version!
            set PYTHON_PATH=%%i
        )
    )
)
if !PYTHON_VER! neq !target_version! (
	@echo Optimus requires a Python version %target_version%.  Please install required python before continuing.
	@echo Check target version %target_version% and installed python version %PYTHON_VER%
	exit /B 1
)
::Passing variable out of setlocal code
(
	endlocal
    	set "%2=%PYTHON_PATH%"
)
rem @echo %PYTHON_PATH%
rem set %2=Testing
goto :eof


:usage
@echo ================ OPTIMUS INSTALLATION ============================
@echo Install / upgrade optimus software with optimus_package*.zip files
@echo Usage: %0 ^<OptimusPackageFile^>
@echo ==================================================================
pause
goto :eof

:header
ECHO =========================================================== 
ECHO %*
ECHO =========================================================== 
EXIT /B 0

rem Function to check if program installed
:programExist
@ECHO OFF
where %1 -v >nul 2>&1
if %errorlevel% equ 0 (
    set %2=True
    @echo %1 is installed.
) else (
    set %2=False
    @echo %1 is not installed.
)
goto :eof

rem Define the function
:myFunction
echo The first parameter is %1.
echo The second parameter is %2.
goto :eof

rem Call the function with two parameters
call :myFunction param1 param2
exit /B 1

:: END Functions
:: =============================================================

