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

set ZIP_CMD=%~dp0tools\zip\zip.bat
set LIST_ZIP_CMD=%~dp0tools\zip\listzip.bat

@rem ----------------------------------------------------------------
@rem build WORKDIR
@rem ----------------------------------------------------------------
set WORKDIR=%BASENAME%
set WORKDIR_LOG=%WORKDIR%\Log
set WORKDIR_EXE=%WORKDIR%\EXE
set WORKDIR_INST=%WORKDIR%\Installer
set WORKDIR_ASM=%BASENAME%-Asm
set OUTFILE=%BASENAME%-All.zip
set OUTFILE_LOG=%BASENAME%-Log.zip
set OUTFILE_ASM=%BASENAME%-Asm.zip
set OUTFILE_INST=%BASENAME%-Installer.zip
set OUTFILE_EXE=%BASENAME%-Exe.zip

@rem cleanup for local testing
if exist "%OUTFILE%" (
	del %OUTFILE%
)
if exist "%OUTFILE_LOG%" (
	del %OUTFILE_LOG%
)
if exist "%OUTFILE_ASM%" (
	del %OUTFILE_ASM%
)
if exist "%OUTFILE_INST%" (
	del %OUTFILE_INST%
)
if exist "%OUTFILE_EXE%" (
	del %OUTFILE_EXE%
)
if exist "%WORKDIR%" (
	rmdir /s /q "%WORKDIR%"
)
if exist "%WORKDIR_ASM%" (
	rmdir /s /q "%WORKDIR_ASM%"
)

mkdir %WORKDIR%
mkdir %WORKDIR_LOG%
mkdir %WORKDIR_EXE%
mkdir %WORKDIR_EXE%\license\
mkdir %WORKDIR_EXE%\license\bregonig\
mkdir %WORKDIR_EXE%\license\ctags\
mkdir %WORKDIR_INST%
copy /Y /B %platform%\%configuration%\sakura.exe %WORKDIR_EXE%\
copy /Y /B %platform%\%configuration%\*.dll      %WORKDIR_EXE%\
copy /Y /B %platform%\%configuration%\*.pdb      %WORKDIR_EXE%\

: LICENSE
copy /Y .\LICENSE                                   %WORKDIR_EXE%\license\ > NUL

: bregonig
set INSTALLER_RESOURCES_BRON=%~dp0installer\temp\bron
copy /Y %INSTALLER_RESOURCES_BRON%\*.txt            %WORKDIR_EXE%\license\bregonig\

: ctags.exe
set INSTALLER_RESOURCES_CTAGS=%~dp0installer\temp\ctags
copy /Y /B %INSTALLER_RESOURCES_CTAGS%\ctags.exe    %WORKDIR_EXE%\
copy /Y /B %INSTALLER_RESOURCES_CTAGS%\README.md    %WORKDIR_EXE%\license\ctags\
copy /Y /B %INSTALLER_RESOURCES_CTAGS%\license\*.*  %WORKDIR_EXE%\license\ctags\

copy /Y /B help\macro\macro.chm    %WORKDIR_EXE%\
copy /Y /B help\plugin\plugin.chm  %WORKDIR_EXE%\
copy /Y /B help\sakura\sakura.chm  %WORKDIR_EXE%\
copy /Y /B html\sakura-doxygen.chm %WORKDIR_EXE%\
copy /Y /B html\sakura-doxygen.chi %WORKDIR_EXE%\

copy /Y /B installer\Output-%platform%\*.exe       %WORKDIR_INST%\
copy /Y msbuild-%platform%-%configuration%.log     %WORKDIR_LOG%\
copy /Y msbuild-%platform%-%configuration%.log.csv %WORKDIR_LOG%\
if exist "msbuild-%platform%-%configuration%.log.xlsx" (
	copy /Y /B "msbuild-%platform%-%configuration%.log.xlsx" %WORKDIR_LOG%\
)
set ISS_LOG_FILE=iss-%platform%-%configuration%.log
if exist "%ISS_LOG_FILE%" (
	copy /Y /B "%ISS_LOG_FILE%" %WORKDIR_LOG%\
)

copy /Y sakura_core\githash.h                      %WORKDIR_LOG%\
if exist "cppcheck-install.log" (
	copy /Y "cppcheck-install.log" %WORKDIR_LOG%\
)
if exist "cppcheck-%platform%-%configuration%.xml" (
	copy /Y "cppcheck-%platform%-%configuration%.xml" %WORKDIR_LOG%\
)
if exist "cppcheck-%platform%-%configuration%.log" (
	copy /Y "cppcheck-%platform%-%configuration%.log" %WORKDIR_LOG%\
)
if exist "doxygen-%platform%-%configuration%.log" (
	copy /Y "doxygen-%platform%-%configuration%.log" %WORKDIR_LOG%\
)

if exist "set_appveyor_env.bat" (
	copy /Y "set_appveyor_env.bat" %WORKDIR_LOG%\
)

set HASHFILE=sha256.txt
if exist "%HASHFILE%" (
	del %HASHFILE%
)
call calc-hash.bat %HASHFILE% %WORKDIR%\
if exist "%HASHFILE%" (
	copy /Y %HASHFILE%           %WORKDIR%\
)

copy /Y installer\warning.txt   %WORKDIR%\
if defined ALPHA (
	copy /Y installer\warning-alpha.txt   %WORKDIR%\
)
@rem temporally disable to zip all files to a file to workaround #514.
@rem call %ZIP_CMD%       %OUTFILE%      %WORKDIR%

call %ZIP_CMD%       %OUTFILE_LOG%  %WORKDIR_LOG%

@rem copy text files for warning after zipping %OUTFILE% because %WORKDIR% is the parent directory of %WORKDIR_EXE% and %WORKDIR_INST%.
if defined ALPHA (
	copy /Y installer\warning-alpha.txt   %WORKDIR_EXE%\
	copy /Y installer\warning-alpha.txt   %WORKDIR_INST%\
)
copy /Y installer\warning.txt        %WORKDIR_EXE%\
copy /Y installer\warning.txt        %WORKDIR_INST%\
call %ZIP_CMD%       %OUTFILE_INST%  %WORKDIR_INST%
call %ZIP_CMD%       %OUTFILE_EXE%   %WORKDIR_EXE%

@echo start zip asm
mkdir %WORKDIR_ASM%
copy /Y sakura\%platform%\%configuration%\*.asm %WORKDIR_ASM%\ > NUL
call %ZIP_CMD%       %OUTFILE_ASM%  %WORKDIR_ASM%

@echo end   zip asm

if exist "%WORKDIR%" (
	rmdir /s /q "%WORKDIR%"
)
if exist "%WORKDIR_ASM%" (
	rmdir /s /q "%WORKDIR_ASM%"
)

exit /b 0

@rem ---------------------- BASENAME ---------------------------------
@rem "sakura"
@rem BUILD_ACCOUNT (option)
@rem TAG_NAME      (option) "tag-" is prefixed.
@rem PR_NUMBER     (option) "PR" is prefixed.
@rem {BUILD_NUMBER|"Local"} "build" is prefixed.
@rem SHORTHASH     (option) SHORTHASH is leading 8 charactors
@rem PLATFORM
@rem CONFIGURATION
@rem ALPHA         (x64 build only)
@rem ----------------------------------------------------------------

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
	if defined BUILD_NUMBER set BUILD_NUMBER=Local
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
		echo %%V=!%%V!
		if defined %%V set BASENAME=!BASENAME!-!%%V!
	)

	endlocal & set BASENAME=%BASENAME%
exit /b 0

@rem '/' -> '_'
@rem ' ' -> '_'
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
