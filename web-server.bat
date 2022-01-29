@echo off
setlocal EnableDelayedExpansion

set command=%1
set isHelp=
set SRV_APACHE=Apache2.4
set SRV_MARIADB=MariaDB
set ERR=0
set OUT=
set OPTS.v=false

if "%command%" == "help" (
	set isHelp=true
) else if "%command%" == "" (
	set isHelp=true
) else (
	set isHelp=false
)
if "%isHelp%"=="true" (
	echo Usage: web-server [{start^|restart^|stop^|help}] [/v]
	echo Starts, stops and restarts Apache HTTP Server and MariaDB server
	echo Options:
	echo 	/v           Enable verbose output
	echo Commands:
	echo 	start        Starts web server
	echo 	restart      Restarts web server
	echo 	stop         Stops web server
	echo 	help         Shows this help
	echo Calling the batch without commands also shows the help
	exit /b
)

where /q httpd || echo Apache HTTP Server is not installed or is not set in the PATH environment variable. && exit /b 1
sc query Apache2.4 > nul || echo Installing Apache HTTP Server as a Windows service... && httpd -k install && echo Apache HTTP Server service has been installed successfully.
sc query MariaDB > nul || echo MariaDB server is not installed as a Windows service. && exit /b 1

:shiftParams
if "%1" neq "" (
	if /i "%1" == "/v" (
		set OPTS.v=true
	)
	shift
	goto :shiftParams
)

if !OPTS.v! == true (
	set OUT="&2"
) else (
	set OUT="nul"
)

if "%command%" == "start" (
	call :startService %SRV_APACHE%
	call :startService %SRV_MARIADB%
) else if "%command%" == "restart" (
	sc query %SRV_APACHE% | findstr RUNNING > nul && (
		call :msg "BEFORE_ACTION" %SRV_APACHE% "Restarting"
		httpd -k restart > %OUT% && (
			call :msg "AFTER_ACTION" %SRV_APACHE% "restarted"
		) || (
			call :msg "FAIL" %SRV_APACHE% "restart"
			set ERR=1
		)
	) || (
		call :startService %SRV_APACHE%
	)
) else if "%command%" == "stop" (
	call :stopService %SRV_APACHE%
	call :stopService %SRV_MARIADB%
) else (
	echo Unknown command %command%.
	set ERR=1
)

exit /b %ERR%

@REM %~1 - Service name
:startService
	sc query %~1 | findstr RUNNING > nul && (
		call :msg "ACTION" %~1 "running"
	) || (
		call :msg "BEFORE_ACTION" %~1 "Starting"
		sc start %~1 > %OUT% && (
			call :msg "AFTER_ACTION" %~1 "started"
		) || (
			call :msg "FAIL" %~1 "start"
			set ERR=1
		)
	)
exit /b 0

@REM %~1 - Service name
:stopService
	sc query %~1 | findstr RUNNING > nul && (
		call :msg "BEFORE_ACTION" %~1 "Stopping"
		sc stop %~1 > %OUT% && (
			call :msg "AFTER_ACTION" %~1 "stopped"
		) || (
			call :msg "FAIL" %~1 "stop"
			set ERR=1
		)
	) || (
		call :msg "ACTION" %~1 "stopped"
	)
exit /b 0

@REM %~1 - Type of message: FAIL, BEFORE_ACTION, AFTER_ACTION, ACTION
@REM %~2 - Service name
@REM %~3 - Form of: start, restart, stop
:msg
	if "%~1" == "FAIL" (
		net session > nul 2>&1 && (
			set isAdmin=true
		) || (
			set isAdmin=false
		)
		if "%isAdmin%"=="true" (
			echo Failed to %~3 %~2 service.
		) else (
			echo Failed to %~3 %~2 service. Try to run as Administrator.
		)
	) else if "%~1" == "BEFORE_ACTION" (
		echo %~3 %~2 service...
	) else if "%~1" == "AFTER_ACTION" (
		echo %~2 service has been %~3.
	) else if "%~1" == "ACTION" (
		echo %~2 service is already %~3.
	)
exit /b 0
