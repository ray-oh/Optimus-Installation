@echo off
@echo ================ OPTIMUS INSTALLATION ============================
@echo Arguments: -h for additional help e.g. install -h
@echo ==================================================================
@ECHO OFF     

rem call:header INSTALL OPTIMUS

echo The current directory is %~dp0
rem CHECK ARGUMENTS for requested package
setlocal enabledelayedexpansion

	rem capture all arguments into argumentString
	set arguments=%* 
	echo Arguments provided: %arguments%

	rem Count arguments
	set argCount=0
	for %%x in (%*) do Set /A argCount+=1
	echo The number of arguments passed is %argCount%.

	if %argCount% neq 0 (

		rem To capture the last argument
		for %%a in (%*) do set lastArg=%%a
		echo The last argument is %lastArg%.

		rem check if arguments contains optimus_package
		if /I "%lastArg%" neq "%lastArg:optimus_package=%" (
			rem True - contains the string
			set package=!lastArg!
		) else (
			rem False
			set package=optimus_package.zip
		)
	) else (
		set package=optimus_package.zip
	)
	echo package= !package!

pause
EXIT /B %ERRORLEVEL%

rem help requested with -h
IF /I "%1" == "-h" (
	@echo Install optimus automation suite
	@echo [HOW TO USE]
	@echo - Install.bat should be placed in the directory you wish to install OPTIMUS.
	@echo   - Example: D:\Optimus
	@echo If installing over existing program, an upgrade will be performed installed
	@echo   - autobot program files will be updated.  And libraries will be reinstalled if NEW requirements detected
	@echo .
	@echo [WHAT HAPPENS]
	@echo - Latest packages will be downloaded, unpacked and updated in the directory:
	@echo   - Optimus Pacakge.
	@echo     - Default is optimus_package.zip.
	@echo     - If another release is required, then e.g. install -s optimus_package_20231228_mini.zip
	@echo       The specific package must be the last argument
	@echo   - Python. Minimalist package with tkinter and version 3.10.9.
	@echo   - If optimus package or python package files are present, download will be skipped.
	@echo - Installs external programs - prefect, jupyter, playwright, robot framework browser
	@echo - Installs Pip libraries used by Optimus autobot
	@echo .
	@echo ------------------------------------------------------------------
	@echo -h or -H for help
	@echo -s or -S for silent mode full installation e.g. install -s
	@echo          Generates install.log for details of installation run
	@echo ------------------------------------------------------------------
	pause
	EXIT /B %ERRORLEVEL%
)

type nul > install.log

rem silent mode full installation
IF /I "%1" == "-s" (
	echo [SILENT] mode >> install.log
)
rem create silentMode variable as input for silent mode or prompt for confirmation
call:stringExistInFile [SILENT] silentMode install.log
rem echo %silentMode%

call:installOptimusPackage %package%
rem optimus_package.zip
call:installPython_winpython
.\autobot\venv\Scripts\python --version
.\autobot\venv\Scripts\python --version >> install.log
.\autobot\venv\Scripts\pip --version
.\autobot\venv\Scripts\pip --version >> install.log

call:START_INSTALL_AUTOBOT_LIB
call:INSTALL_PREFECT
call:INSTALL_JUPYTER

@echo ================ LIBRARIES INSTALLED - INITIALIZE ==========================
@echo ================ LIBRARIES INSTALLED - INITIALIZE ========================== >> install.log

call:INSTALL_PLAYWRIGHT
call:INSTALL_MITO

:: ... put your business logic here
:: ... make sure EXIT below is present
:: ... so you don't run into actual functions without the call

call:header Operation Finished Successfully
rem clean up installation files
if exist disable_tmp (
	rmdir tmp /S /Q
)
if exist disable_optimus_package.zip (
	del optimus_package.zip
)
if exist python_installation.zip (
	del python_installation.zip
)

EXIT /B %ERRORLEVEL%

::-------------------------------------------------------------

:START_INSTALL_AUTOBOT_LIB
	@echo ================ INSTALL AUTOBOT ==========================
	@echo ================ INSTALL AUTOBOT ========================== >> install.log
	if "%silentMode%" == "True" (
		echo Silent install libraries
		echo INSTALL AUTOBOT libraries >> install.log
		.\autobot\venv\Scripts\pip install -r .\autobot\requirements.txt >> install.log
	) else (
		SET /P AREYOUSURE=Install Optimus libraries - Are you sure (Y/[N])
		IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_OPT_LIB
		.\autobot\venv\Scripts\pip install -r .\autobot\requirements.txt
		PAUSE
	)
	rem @echo ================ INSTALL wkhtmltoimage =================
	rem xcopy .\autobot\wkhtml*.* .\autobot\venv\scripts\.
	rem SET PATH=%PATH%;%cd%\autobot
	:END_OPT_LIB
	goto :eof

:INSTALL_PREFECT
	@echo ================ INSTALL PREFECT ==========================
	@echo ================ INSTALL PREFECT ========================== >> install.log	
	if "%silentMode%" == "True" (
		echo INSTALL PREFECT
		echo INSTALL PREFECT >> install.log
		.\autobot\venv\Scripts\pip install -U prefect >> install.log
		.\autobot\venv\Scripts\prefect version >> install.log
	) else (
		SET /P AREYOUSURE=Install Prefect - Are you sure (Y/[N])
		IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_PREFECT
		.\autobot\venv\Scripts\pip install -U prefect
		.\autobot\venv\Scripts\prefect version
	)
	:END_PREFECT
	goto :eof

:INSTALL_JUPYTER
	@echo ================ INSTALL JUPYTER NOTEBOOK =================
	@echo ================ INSTALL JUPYTER NOTEBOOK ================= >> install.log	
	if "%silentMode%" == "True" (
		echo INSTALL JUPYTER
		echo INSTALL JUPYTER >> install.log
		pip install jupyter >> install.log
		.\autobot\venv\Scripts\pip install ipykernel >> install.log
		for %%I in (.) do set CurrDirName=%%~nxI
		rem echo %CurrDirName%
		.\autobot\venv\Scripts\python -m ipykernel install --user --name=%CurrDirName% >> install.log
	) else (
		SET /P AREYOUSURE=Install Jupyter Notebook - Are you sure (Y/[N])
		IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_JUPYTER
		pip install jupyter
		.\autobot\venv\Scripts\pip install ipykernel
		for %%I in (.) do set CurrDirName=%%~nxI
		rem echo %CurrDirName%
		.\autobot\venv\Scripts\python -m ipykernel install --user --name=%CurrDirName%
	)
	:END_JUPYTER
	goto :eof


:INSTALL_PLAYWRIGHT
	@echo ================ INSTALL PLAYWRIGHT =================
	@echo ================ INSTALL PLAYWRIGHT ================= >> install.log
	if "%silentMode%" == "True" (
		.\autobot\venv\Scripts\playwright install >> install.log
		@echo ================ INSTALL ROBOTFRAMEWORK BROWSER =================
		@echo ================ INSTALL ROBOTFRAMEWORK BROWSER ================= >> install.log

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
		@echo Initialize robot framework browser
		@echo Initialize robot framework browser >> install.log		
		.\autobot\venv\Scripts\rfbrowser init --skip-browsers >> install.log
	) else (
		SET /P AREYOUSURE=Install Playwright - Are you sure (Y/[N])
		IF /I "%AREYOUSURE%" NEQ "Y" GOTO END_PLAYWRIGHT

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
		@echo Initialize robot framework browser
		.\autobot\venv\Scripts\rfbrowser init --skip-browsers
	)

	:END_PLAYWRIGHT
	goto :eof

:INSTALL_MITO
	@echo ================ INSTALL MITO =================
	@echo ================ INSTALL MITO ================= >> install.log	
	if "%silentMode%" == "True" (
		@echo This is skipped for silent install.  Do manual install if required.
		@echo This is skipped for silent install.  Do manual install if required. >> install.log
	) else (
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
	)

	:END_MITO
	goto :eof


:: =============================================================
:: Functions

:installOptimusPackage
	@echo ================ INSTALL OPTIMUS PACKAGE ==========================
	@echo ================ INSTALL OPTIMUS PACKAGE ========================== >> install.log	
	Powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

	if not exist %1 (
		rem tmp\optimus_package.zip
		@echo Download optimus package
		rem set OPTIMUS_URL=https://github.com/ray-oh/Optimus-Installation/raw/main/installation/packages/optimus_package.zip
		rem powershell wget "%OPTIMUS_URL%" -o ./tmp/optimus_package.zip
		rem powershell wget https://github.com/ray-oh/Optimus-Installation/raw/main/installation/packages/optimus_package.zip -o ./optimus_package.zip
		powershell wget https://github.com/ray-oh/Optimus-Installation/raw/main/installation/packages/%1 -o ./%1
		rem ./tmp/optimus_package.zip
		echo Download optimus package >> install.log
	)

	if not exist tmp\autobot (

		if not exist tmp (
			rem Powershell.exe mkdir tmp
			mkdir tmp
		)

		@echo Unpack optimus package
		Powershell.exe Expand-Archive %1 -DestinationPath tmp
		rem tmp\optimus_package.zip
		echo Upack optimus package >> install.log
	)

	if not exist autobot\src (
		@echo NEW INSTALL - Create Optimus Structure and codes
		rem set destSync=.
		rem robocopy .\tmp "%destSync%" /XD __pycache__ Lib venv /XF install.bat optimus_package.zip python_installation.zip /e /copy:DAT /mt /z
		robocopy .\tmp . /XD __pycache__ Lib venv /XF install.bat optimus_package.zip /e /copy:DAT /mt /z >> install.log
		echo NEW INSTALL >> install.log
	) else (
		rem @echo UPGRADE - Update optimus codes
		rem robocopy .\tmp\autobot\src .\autobot\src /XD __pycache__ Lib venv /XF install.bat /e /copy:DAT /mt /z

		@echo Check if there is new requirements.txt
		fc /b %~dp0autobot\requirements.txt %~dp0tmp\autobot\requirements.txt > nul
		if errorlevel 1 (
			echo NEW requirements file >> install.log
		) else (
			echo Requirements file unchanged
		)

		@echo UPGRADE - Update optimus autobot files
		robocopy .\tmp\autobot .\autobot /XD __pycache__ Lib venv /XF install.bat /e /copy:DAT /mt /z >> install.log
		echo [UPGRADE] - Update optimus autobot files >> install.log
	)

	rem rmdir tmp /S /Q
	goto :eof

:installNPM
	@echo ================ INSTALL NPM %NODEJS_VERS% ==========================
	@echo ================ INSTALL NPM %NODEJS_VERS% ========================== >> install.log
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
	@echo ================ INSTALL PYTHON ========================== >> install.log
	Powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
	if not exist installation\python-3.10.9.amd64 (

		if not exist python_installation.zip (
			rem tmp\python_installation.zip 
			@echo Download win python minimalist package
			rem set PYTHON_URL=https://github.com/ray-oh/Optimus-Installation/raw/main/installation/3rd_party_tools/python-3.10.9.amd64.zip
			rem powershell wget "%PYTHON_URL%" -o ./installation/tmp/python_installation.zip
			powershell wget https://github.com/ray-oh/Optimus-Installation/raw/main/installation/3rd_party_tools/python-3.10.9.amd64.zip -o ./python_installation.zip
			rem ./tmp/python_installation.zip
		)

		@echo Unpack win python
		Powershell.exe Expand-Archive python_installation.zip -DestinationPath installation
		rem tmp\python_installation.zip

		@echo Check if need to install virtual env and its libraries
		findstr /c:"NEW" install.log > nul
		if %errorlevel% equ 0 (
			echo NEW installation or changes require installation of virtual env and libraries

			@echo Setup virtual env
			if exist .\autobot\venv_DISABLE (
				rmdir .\autobot\venv /S /Q
			)
			rem if not exist .\autobot\venv (
			rem overwrites earlier venv if it exist and is not activated
			.\installation\python-3.10.9.amd64\python.exe -m venv .\autobot\venv

		) else (
			echo No NEW installation or changes found. Re-installation of virtual env and libraries not required.
		)

	)

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

rem Function to check if string exist in file
:stringExistInFile
	@ECHO OFF
	findstr /c:"%1" %3 > nul
	if %errorlevel% equ 0 (
		set %2=True
		@echo %1 case in %3.
	) else (
		set %2=False
		rem @echo %1 not found in %3.
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

