call %~dp0tools\hhc\find-hhc.bat
if "%CMD_HHC%" == "" (
	echo hhc.exe was not found.
	exit /b 1
)

for %%H in (
	help\macro\macro.HHP
	help\plugin\plugin.hhp
	help\sakura\sakura.hhp
) do (
	"%CMD_HHC%" "%%H"
	@rem hhc.exe returns 1 on success, and returns 0 on failure
	if not errorlevel 1 (
		echo error %%H errorlevel %errorlevel%
		if exist "%%~dpnH.chm" (
			echo found output file. ignore errorexit.
		) else (
			exit /b 1
		)
	)
)

exit /b 0
