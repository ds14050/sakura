@echo off
set platform=%1
set configuration=%2

if "%platform%" == "Win32" (
	@rem OK
) else if "%platform%" == "x64" (
	@rem OK
) else if "%platform%" == "MinGW" (
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

@echo PLATFORM      %PLATFORM%
@echo CONFIGURATION %CONFIGURATION%
@echo.

@echo ---- start externals\cppcheck\install-cppcheck.bat ----
call externals\cppcheck\install-cppcheck.bat        || (echo error externals\cppcheck\install-cppcheck.bat && exit /b 1)
@echo ---- end   externals\cppcheck\install-cppcheck.bat ----
@echo.

@echo ---- start cppcheck.bat but not wait. ----
call :start_concurrent cppcheck_is_running run-cppcheck.bat %PLATFORM% %CONFIGURATION%
@echo.

@echo ---- start build-chm.bat but not wait. ----
call :start_concurrent build-chm_is_runnint build-chm.bat
@echo.

if "%platform%" == "MinGW" (
	@echo call build-gnu.bat %PLATFORM% %CONFIGURATION%
	call build-gnu.bat   %PLATFORM% %CONFIGURATION% || (echo error build-gnu.bat       && exit /b 1)
	exit /b 0
)

@echo ---- start build-sln.bat ----
call build-sln.bat       %PLATFORM% %CONFIGURATION% || (echo error build-sln.bat       && exit /b 1)
@echo ---- end   build-sln.bat ----
@echo.

@echo ---- start build-installer.bat ----
call build-installer.bat %PLATFORM% %CONFIGURATION% || (echo error build-installer.bat && exit /b 1)
@echo ---- end   build-installer.bat ----
@echo.

@echo ---- wait for cppcheck ----
call :wait_concurrent cppcheck_is_running 7200
for %%F in (
	cppcheck-%platform%-%configuration%.xml
	cppcheck-%platform%-%configuration%.log
) do (
	if exist "%%~F" (
		echo Result file is found at "%%~F".
	) else (
		echo WARN: Result file is not found at "%%~F".
	)
)
@echo ---- end waiting for cppcheck ----
@echo.

@echo ---- wait for build-chm ----
call :wait_concurrent build-chm_is_running
for %%F in (
	help\macro\macro.chm
	help\plugin\plugin.chm
	help\sakura\sakura.chm
) do (
	if exist "%%~F" (
		echo help file is found at "%%~F".
	) else (
		echo help file is not found at "%%~F".
	)
)
@echo ---- end waiting for build-chm ----
@echo.

@echo ---- start zipArtifacts.bat ----
call zipArtifacts.bat    %PLATFORM% %CONFIGURATION% || (echo error zipArtifacts.bat    && exit /b 1)
@echo ---- end   zipArtifacts.bat ----
@echo.

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
@echo    platform      : Win32   or x64   or MinGW
@echo    configuration : Release or Debug
@echo.
@echo example
@echo    %~nx1 Win32 Release
@echo    %~nx1 Win32 Debug
@echo    %~nx1 x64   Release
@echo    %~nx1 x64   Debug
@echo    %~nx1 MinGW Release
@echo    %~nx1 MinGW Debug
exit /b 0

@rem ------------------------------------------------------------------------------
@rem utility for concurrent execution.
@rem
@rem NOTE: waittoken is just a filename of current directory.
@rem       * Moving directory between start_concurrent and wait_concurrent
@rem         invalidates waittoken, therefore, wait_concurrent returns immediately.
@rem       * Path to the filename within waittoken is removed, therefore,
@rem         two paths with a filename are identical waittokens.
@rem ------------------------------------------------------------------------------
:start_concurrent (waittoken, command)
	setlocal
	set Token=%~nx1

	if exist ".\%Token%" (
		echo ERROR: The waittoken file: ".\%Token%" exists.
		exit /B 1
	)
	echo > ".\%Token%"
	if not exist ".\%Token%" (
		echo ERROR: cannot make the waittoken file: ".\%Token%".
		exit /B 1
	)
	start "" /BELOWNORMAL "%COMSPEC%" /C "%2 %3 %4 %5 %6 %7 %8 %9 >".\%Token%"&&del ".\%Token%""
	if errorlevel 1 (
		echo ERROR: faild command: start "" "%COMSPEC%" /C "%2 %3 %4 %5 %6 %7 %8 %9 >".\%Token%"&&del ".\%Token%""
	)

exit /B 0

:wait_concurrent (waittoken, timeout)
	set Token=%~nx1
	if "%Timeout%" == "" (
		set Timeout=0
	) else (
		set /A Timeout=%~2
	)
	set StartDate=%DATE%
	set StartTime=%TIME: =0%
	set /A StartTime=1%StartTime:~0,2% * 3600 + 1%StartTime:~3,2% * 60 + 1%StartTime:~6,2%

:waiting
	if not exist ".\%Token%" (
		exit /B 0
	)

	set Elapsed=%TIME: =0%
	set /A Elapsed=1%Elapsed:~0,2% * 3600 + 1%Elapsed:~3,2% * 60 + 1%Elapsed:~6,2% - %StartTime%
	if not "%StartDate%" == "%DATE%" (
		set /A Elapsed=%Elapsed% + 60 * 3600
	)
	if %Elapsed% lss %Timeout% (
		rem keep waiting.
	) else exit /B 1

	timeout /T 1
goto :waiting
