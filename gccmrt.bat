@echo off

rem ***************************************************************
rem Batch file to change GCC runtime library
rem Coded by Giovanni Bajo <rasky@develer.com>
rem Released under GPLv2
rem ***************************************************************

set MINGW_LIB_DIR=%~dp0\..\lib
if not exist %MINGW_LIB_DIR%\libmsvcrt.a goto errorpath
if "%~1" == "60" goto doit
if "%~1" == "70" goto doit
if "%~1" == "71" goto doit
if "%~1" == "80" goto doit
if "%~1" == "90" goto doit
goto usage

:doit
copy %MINGW_LIB_DIR%\libmsvcr%1.a %MINGW_LIB_DIR%\libmsvcrt.a >NUL
copy %MINGW_LIB_DIR%\libmsvcr%1d.a %MINGW_LIB_DIR%\libmsvcrtd.a >NUL
copy %MINGW_LIB_DIR%\libmoldname%1.a %MINGW_LIB_DIR%\libmoldname.a >NUL
copy %MINGW_LIB_DIR%\libmoldname%1d.a %MINGW_LIB_DIR%\libmoldnamed.a >NUL
rem using "for" to avoid hardcoding the GCC version
for /D %%i in (%MINGW_LIB_DIR%\gcc\mingw32\*) do copy %%i\specs%1 %%i\specs >NUL
echo MinGW runtime library set to %1
goto :end

:usage
echo %~n0: configure the Microsoft runtime library to use for compilation
echo.
echo Usage: %~n0 ^<60^|70^|71^|80^|90^>
echo.
echo   60 - Link with MSVCRT.DLL (like Visual Studio '98 aka VC6)
echo   70 - Link with MSVCR70.DLL (like Visual Studio .NET aka VC70)
echo   71 - Link with MSVCR71.DLL (like Visual Studio .NET 2003 aka VC71)
echo   80 - Link with MSVCR80.DLL (like Visual Studio .NET 2005 aka VC80)
echo   90 - Link with MSVCR90.DLL (like Visual Studio .NET 2008 aka VC90)
goto end

:errorpath
echo Internal error while trying to find the MinGW path
goto end

:end
