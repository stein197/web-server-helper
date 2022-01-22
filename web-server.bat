@echo off
if "%1" == "help" (
	set isHelp=true
) else if "%1" == "" (
	set isHelp=true
) else (
	set isHelp=false
)
if "%isHelp%"=="true" (
	echo Usage: web-server [{start^|restart^|stop^|help}]
	echo Starts, stops and restarts Apache HTTP Server and MariaDB server
	echo Commands:
	echo 	start      Starts web server
	echo 	restart    Restarts web server
	echo 	stop       Stops web server
	echo 	help       Shows this help
	echo Calling the batch without commands also shows the help
	exit /b
)

where /q httpd || echo Apache HTTP Server is not installed or is not set in the PATH environment variable. && exit /b 1
sc query Apache2.4 > nul || echo Installing Apache HTTP Server as a Windows service... && httpd -k install && echo Apache HTTP Server service has been installed successfully.
sc query MariaDB > nul || echo MariaDB server is not installed as a Windows service. && exit /b 1

if "%1" == "start" (
	sc query MariaDB | findstr RUNNING > nul && (
		echo MariaDB server is already running.
	) || (
		echo Starting MariaDB server...
		sc start MariaDB && (
			echo MariaDB server has been started.
		) || (
			echo Failed to start MariaDB server. Try to run as Administrator. && exit /b 1
		)
	)
	sc query Apache2.4 | findstr RUNNING > nul && (
		echo Apache HTTP Server is already running.
	) || (
		goto :startApache
	)
) else if "%1" == "restart" (
	sc query Apache2.4 | findstr RUNNING > nul && (
		echo Restarting Apache HTTP Server...
		httpd -k restart && (
			echo Apache HTTP Server has been restarted.
		) || (
			echo Failed to restart Apache HTTP Server. Try to run as Administrator. && exit /b 1
		)
	) || (
		goto :startApache
	)
) else if "%1" == "stop" (
	sc query MariaDB | findstr RUNNING > nul && (
		echo Stopping MariaDB server...
		sc stop MariaDB && (
			echo MariaDB server has been stopped.
		) || (
			echo Failed to stop MariaDB server. Try to run as Administrator. && exit /b 1
		)
	) || (
		echo MariaDB server is already stopped.
	)
	sc query Apache2.4 | findstr RUNNING > nul && (
		echo Stopping Apache HTTP Server...
		httpd -k stop && (
			echo Apache HTTP Server has been stopped.
		) || (
			echo Failed to stop Apache HTTP Server. Try to run as Administrator. && exit /b 1
		)
	) || (
		echo Apache HTTP Server is already stopped.
	)
) else (
	echo Unknown command %1. && exit /b 1
)

exit /b

:startApache
echo Starting Apache HTTP Server...
httpd -k start && (
	echo Apache HTTP Server has been started
) || (
	echo Failed to start Apache HTTP Server && exit /b 1
)
