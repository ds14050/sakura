@echo off
@setlocal enabledelayedexpansion
set platform=%1
set configuration=%2

if "%platform%" == "Win32" (
	@rem OK
) else if "%platform%" == "x64" (
	@rem OK
) else (
	call :showhelp %0
	exit /b 1
)

if "%configuration%" == "Release" (
	@rem OK
) else if "%configuration%" == "Debug" (
	@rem OK
) else (
	call :showhelp %0
	exit /b 1
)

if "%platform%" == "x64" (
	set ALPHA=alpha
) else (
	set ALPHA=
)

rem Definitions and Dependencies

call :Set_BASENAME
set SRC=%~dp0
set SRC=%SRC:~0,-1%
set DST=%~dp0%BASENAME%
set TAB=	
set RECIPE_FILE=%~dpn0.txt
set    HASH_BAT=!SRC!\calc-hash.bat
set     ZIP_BAT=!SRC!\tools\zip\zip.bat
set   UNZIP_BAT=!SRC!\tools\zip\unzip.bat

rem Setup

rmdir /s /q "%DST%" 2>nul
mkdir       "%DST%"

rem Processor object

set WORKING_ZIP=
set WORKING_PATH=.\
set WORKING_FILE=

goto :end_Processor

:OnZip
	rem Make a zip before switching WORKING_ZIP.
	call :MakeZip "%WORKING_ZIP%"
	set WORKING_ZIP=
	set WORKING_PATH=.\
	set WORKING_FILE=

	setlocal ENABLEDELAYEDEXPANSION

	set rpnx1=%~dpnx1
	set rpnx1=!rpnx1:%CD%\=!

	@echo ZIP  %rpnx1%

	rem Prepare working directory for a zip.
	mkdir 2>nul  "%DST%\%rpnx1%"
	if not exist "%DST%\%rpnx1%" (
		exit /b 1
	)

	endlocal & set WORKING_ZIP=%rpnx1%
exit /b 0

:OnPath
	setlocal ENABLEDELAYEDEXPANSION

	set rp1=%~dp1
	set rp1=!rp1:%CD%\=!

	@echo PATH %rp1%

	rem Unfinished preparation.
	if not defined WORKING_ZIP (
		@echo>&2 ERROR: Give zip name before path.
		exit /b 1
	)
	if not exist "%DST%\%WORKING_ZIP%" (
		@echo>&2 ERROR: Missing directory: !DST!\!WORKING_ZIP!
		exit /b 1
	)

	rem Prepare working directory for a path.
	mkdir 2>nul  "%DST%\%WORKING_ZIP%\%rp1%"
	if not exist "%DST%\%WORKING_ZIP%\%rp1%" (
		exit /b 1
	)

	endlocal & set WORKING_PATH=%rp1%& set WORKING_FILE=%~nx1
exit /b 0

:OnFile
	setlocal ENABLEDELAYEDEXPANSION

	@echo FILE %~1

	rem Unfinished preparation.
	if not exist "%DST%\%WORKING_ZIP%\%WORKING_PATH%" (
		@echo>&2 ERROR: Missing directory: !DST!\!WORKING_ZIP!\!WORKING_PATH!
		exit /b 1
	)

	rem Prepare working file.
	set SourcePath=%SRC%\%~1
	call :TryUnzipPath SourcePath
	if not "%SourcePath%" == "%SRC%\%~1" echo FILE %SourcePath%
	copy /Y /B "%SourcePath%" "%DST%\%WORKING_ZIP%\%WORKING_PATH%%WORKING_FILE%"
exit /b 0

:MakeZip
	setlocal

	set WORKING_ZIP=%~1
	if not defined WORKING_ZIP exit /b 0
	for /F "delims=" %%P in (
		"%DST%\%WORKING_ZIP%"
	) do set ZipSrc=%%~P& set ZipName=%%~nxP

	cmd /C "pushd "%ZipSrc%" &"%HASH_BAT%" sha256.txt . >nul"^
	|| del 2>nul "%ZipSrc%\sha256.txt"
	cmd /C ""%ZIP_BAT%" "%SRC%\%ZipName%" "%ZipSrc%\*""^
	|| del 2>nul "%SRC%\%ZipName%"
	rmdir /S /Q "%ZipSrc%"
exit /b 0

:end_Processor

rem Main loop

for /F "usebackq tokens=* eol=# delims=" %%L in ("!RECIPE_FILE!" 'FINISHED') do (
	rem TODO: Forbid ".."
	rem Prevent the next 'for' command from merging empty columns.
	set L=%%L%TAB%%TAB%%TAB%
	set L=!L:%TAB%= %TAB%!
for /F "usebackq tokens=1,2,3 delims=%TAB%" %%A in ('!L!') do (
	rem First column: Zip name (relative to %DST% for working & relative to %SRC% for output)
	call :OnColumn "%%~A" OnZip^
	|| (call :Clean & exit /b 1)

	rem Second column: Path (destination, relative to Zip)		
	call :OnColumn "%%~B" OnPath^
	|| (call :Clean & exit /b 1)

	rem Third column: File (source, relative to %SRC%)		
	call :OnColumn "%%~C" OnFile^
	|| (call :Clean & exit /b 1)
))
call :Clean & exit /b 0

:OnColumn
	setlocal
	set C=%~1
	call :Trim C
	endlocal & if not "%C%" == "" call :%2 "%C%"^
	|| exit /b 1
exit /b 0

:Clean
	if exist "%LastZipDir%" rmdir /S /Q "%LastZipDir%"
	if defined WORKING_ZIP  rmdir /S /Q "%DST%\%WORKING_ZIP%" 2>nul
	rmdir /Q "%DST%" 2>nul
exit /b 0

rem -------------------------------------------------------

:TryUnzipPath
	setlocal ENABLEDELAYEDEXPANSION

	set VAR=%~1
	if not defined VAR exit /b 1
	set VAL=!%VAR%!
	if not defined VAL exit /b 1
	if exist "%VAL%"   exit /b 1

	set L=
	set R=%VAL%
	:continue
	for /F "tokens=1,* delims=\" %%P in ("%R%") do (
		if not exist "!L!%%P" goto :break
		set L=!L!%%P\
		set R=%%Q
		goto :continue
	)
	:break
	if not defined L exit /b 1
	rem %L% has a trailing \ char, so this is
	rem testing a directory existense.
	rem But the test is not always correct.
	rem If %L% is a path to a file under NTFS Junction...
	if exist "%L%"   exit /b 1

	set Zip=%L:~0,-1%
	set ZipDir=%TEMP%\%Zip::=%
	set VAL=%ZipDir%\%R%

	if not exist "%ZipDir%" (
		@echo Unzipping !Zip!.
		call | "!UNZIP_BAT!" "!Zip!" "!ZipDir!"^
		|| exit /b 1
	) else (
		@echo Destination folder has already existed. Skip unzipping.
		@echo Destination: !ZipDir!
	)
	if not "%LastZipDir%" == "%ZipDir%" if exist "%LastZipDir%" (
		@echo Clean the last unzipped temporary folder.
		@echo Cleaning !LastZipDir!.
		rmdir /S /Q "!LastZipDir!"
	)

	endlocal & set LastZipDir=%ZipDir%& set %VAR%=%VAL%
exit /b 0

rem -------------------------------------------------------

:Trim
	setlocal ENABLEDELAYEDEXPANSION

	set VAR=%~1
	if not defined VAR exit /b 1
	set VAL=!%VAR%!
	if not defined VAL exit /b 0

	call :Set_TRIMMED %VAL%

	endlocal & set %VAR%=%TRIMMED%
exit /b 0

:Set_TRIMMED
	set TRIMMED=%*
exit /b 0

rem ---------------------- BASENAME ---------------------------------
rem "sakura"
rem BUILD_ACCOUNT (option)
rem TAG_NAME      (option) "tag-" is prefixed.
rem PR_NUMBER     (option) "PR" is prefixed.
rem {BUILD_NUMBER|"Local"} "build" is prefixed.
rem SHORTHASH     (option) SHORTHASH is leading 8 charactors
rem PLATFORM
rem CONFIGURATION
rem ALPHA         (x64 build only)
rem ----------------------------------------------------------------

:Set_BASENAME
	setlocal ENABLEDELAYEDEXPANSION

	set BUILD_ACCOUNT=%APPVEYOR_ACCOUNT_NAME%
	if "%BUILD_ACCOUNT%" == "sakuraeditor" set BUILD_ACCOUNT=

	set TAG_NAME=%APPVEYOR_REPO_TAG_NAME%
	if defined TAG_NAME set TAG_NAME=tag-%TAG_NAME%
	call :ReplaceForbiddenPathChars TAG_NAME

	set PR_NUMBER=%APPVEYOR_PULL_REQUEST_NUMBER%
	if defined PR_NUMBER set PR_NUMBER=PR%PR_NUMBER%

	set BUILD_NUMBER=%APPVEYOR_BUILD_NUMBER%
	if not defined BUILD_NUMBER set BUILD_NUMBER=Local
	set BUILD_NUMBER=build%BUILD_NUMBER%

	set SHORTHASH=%APPVEYOR_REPO_COMMIT%
	if defined SHORTHASH set SHORTHASH=%SHORTHASH:~0,8%

	rem PLATFORM

	rem CONFIGURATION

	rem ALPHA

	set BASENAME=sakura
	for %%V in (
		BUILD_ACCOUNT TAG_NAME PR_NUMBER BUILD_NUMBER
		SHORTHASH PLATFORM CONFIGURATION ALPHA
	) do (
		@echo %%V=!%%V!
		if defined %%V set BASENAME=!BASENAME!-!%%V!
	)
	@echo BASENAME=%BASENAME%

	endlocal & set BASENAME=%BASENAME%
exit /b 0

rem '/' -> '_'
rem ' ' -> '_'
:ReplaceForbiddenPathChars
	setlocal ENABLEDELAYEDEXPANSION

	set VAR=%~1
	if not defined VAR exit /b 1
	set VAL=!%VAR%!
	if not defined VAL exit /b 1

	set VAL=%VAL:/=_%
	set VAL=%VAL: =_%

	endlocal & set %VAR%=%VAL%
exit /b 0

@rem ------------------------------------------------------------------------------
@rem show help
@rem see http://orangeclover.hatenablog.com/entry/20101004/1286120668
@rem ------------------------------------------------------------------------------
:showhelp
@echo off
@echo usage
@echo    %~nx1 platform configuration
@echo.
@echo parameter
@echo    platform      : Win32   or x64
@echo    configuration : Release or Debug
@echo.
@echo example
@echo    %~nx1 Win32 Release
@echo    %~nx1 Win32 Debug
@echo    %~nx1 x64   Release
@echo    %~nx1 x64   Debug
exit /b 0
