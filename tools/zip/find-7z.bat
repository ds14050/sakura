@rem see readme.md
@echo off
if "%FORCE_POWERSHELL_ZIP%" == "1" (
	set CMD_7Z=
	exit /b 0
)

setlocal ENABLEDELAYEDEXPANSION

set FOUND=
for %%X in (
	"%CMD_7Z%"
	"7z"
	"7za"
	"%ProgramFiles%\7-Zip\7z.exe"
	"%ProgramFiles(x86)%\7-Zip\7z.exe"
	"%ProgramW6432%\7-Zip\7z.exe"
) do if not "%%~X" == "" (
	@echo Testing %%~X.
	where "%%~X" 1>nul 2>nul
	if errorlevel 1 (
		@echo Failed.
	) else (
		@echo Passed.
		set FOUND=%%~X
		goto :break
	)
)
:break

endlocal & @echo set CMD_7Z=%FOUND%& set CMD_7Z=%FOUND%
