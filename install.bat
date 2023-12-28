@echo off
@echo ================ OPTIMUS INSTALLATION ============================
@echo Install optimus automation suite
@echo - Download latest packages, unpack and update files:
@echo   - Optimus Pacakge. Upgrade over existing installation if requested.
@echo   - Python. Minimalist package with tkinter and version 3.10.9.
@echo - Install external programs - prefect, jupyter, playwright, robot framework browser
@echo - Install Pip libraries used by Optimus autobot
@echo ==================================================================

@ECHO OFF     

rem call:header INSTALL OPTIMUS

call:installOptimusPackage
call:installPython_winpython
.\autobot\venv\Scripts\python --version
.\autobot\venv\Scripts\pip --version

call:START_INSTALL_AUTOBOT_LIB
call:INSTALL_PREFECT
call:INSTALL_JUPYTER

@echo ================ LIBRARIES INSTALLED - INITIALIZE ==========================

call:INSTALL_PLAYWRIGHT
call:INSTALL_MITO

:: ... put your business logic here
:: ... make sure EXIT below is present
:: ... so you don't run into actual functions without the call

call:header Operation Finished Successfully
rmdir tmp /S /Q
del optimus_package.zip
del python_installation.zip

EXIT /B %ERRORLEVEL%

::-------------------------------------------------------------

:START_INSTALL_AUTOBOT_LIB
	@echo ================ INSTALL AUTOBOT ==========================
	SET /P AREYOUSURE=Install Optimus libraries - Are you sure (Y/[N])
	IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_OPT_LIB
	.\autobot\venv\Scripts\pip install -r .\autobot\requirements.txt
	rem @echo ================ INSTALL wkhtmltoimage =================
	rem xcopy .\autobot\wkhtml*.* .\autobot\venv\scripts\.
	rem SET PATH=%PATH%;%cd%\autobot
	PAUSE
	:END_OPT_LIB
	goto :eof

:INSTALL_PREFECT
	@echo ================ INSTALL PREFECT ==========================
	SET /P AREYOUSURE=Install Prefect - Are you sure (Y/[N])
	IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_PREFECT
	.\autobot\venv\Scripts\pip install -U prefect
	.\autobot\venv\Scripts\prefect version
	:END_PREFECT
	goto :eof

:INSTALL_JUPYTER
	@echo ================ INSTALL JUPYTER NOTEBOOK =================
	SET /P AREYOUSURE=Install Jupyter Notebook - Are you sure (Y/[N])
	IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_JUPYTER
	pip install jupyter
	.\autobot\venv\Scripts\pip install ipykernel
	for %%I in (.) do set CurrDirName=%%~nxI
	rem echo %CurrDirName%
	.\autobot\venv\Scripts\python -m ipykernel install --user --name=%CurrDirName%
	:END_JUPYTER
	goto :eof


:INSTALL_PLAYWRIGHT
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
	goto :eof

:INSTALL_MITO
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
	goto :eof



:: =============================================================
:: Functions

:installOptimusPackage
	@echo ================ INSTALL OPTIMUS PACKAGE ==========================
	Powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
	if not exist tmp (
		rem Powershell.exe mkdir tmp
		mkdir tmp
	)
	if not exist optimus_package.zip (
		rem tmp\optimus_package.zip
		@echo Download optimus package
		rem set OPTIMUS_URL=https://github.com/ray-oh/Optimus-Installation/raw/main/installation/packages/optimus_package.zip
		rem powershell wget "%OPTIMUS_URL%" -o ./tmp/optimus_package.zip
		powershell wget https://github.com/ray-oh/Optimus-Installation/raw/main/installation/packages/optimus_package.zip -o ./optimus_package.zip
		rem ./tmp/optimus_package.zip
	)

	@echo Unpack win python
	Powershell.exe Expand-Archive optimus_package.zip -DestinationPath tmp
	rem tmp\optimus_package.zip

	if not exist autobot\src (
		@echo Create Optimus Structure and codes
		rem set destSync=.
		rem robocopy .\tmp "%destSync%" /XD __pycache__ Lib venv /XF install.bat optimus_package.zip python_installation.zip /e /copy:DAT /mt /z
		robocopy .\tmp . /XD __pycache__ Lib venv /XF install.bat optimus_package.zip /e /copy:DAT /mt /z
	) else (
		@echo Update optimus codes
		robocopy .\tmp\autobot\src .\autobot\src /XD __pycache__ Lib venv /XF install.bat /e /copy:DAT /mt /z
	)

	rem rmdir tmp /S /Q
	goto :eof

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

:installPython_winpython
	@echo ================ INSTALL PYTHON ==========================
	Powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
	if not exist python_installation.zip (
		rem tmp\python_installation.zip 
		@echo Download win python minimalist package
		rem set PYTHON_URL=https://github.com/ray-oh/Optimus-Installation/raw/main/installation/3rd_party_tools/python-3.10.9.amd64.zip
		rem powershell wget "%PYTHON_URL%" -o ./installation/tmp/python_installation.zip
		powershell wget https://github.com/ray-oh/Optimus-Installation/raw/main/installation/3rd_party_tools/python-3.10.9.amd64.zip -o ./python_installation.zip
		rem ./tmp/python_installation.zip
	)
	if not exist installation\python-3.10.9.amd64 (
		@echo Unpack win python
		Powershell.exe Expand-Archive python_installation.zip -DestinationPath installation
		rem tmp\python_installation.zip
	)

	@echo Setup virtual env
	if exist .\autobot\venv (
		rmdir .\autobot\venv /S /Q
	)
	.\installation\python-3.10.9.amd64\python.exe -m venv .\autobot\venv
	rem Powershell.exe rm installation\tmp -r -Force
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

