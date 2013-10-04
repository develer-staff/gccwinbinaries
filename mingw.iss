; gcc-mingw installer script
; by Giovanni Bajo <rasky@develer.com>
; Released under the GPLv2
;
; The installer produced by this script has the following features:
;
; - Install a complete MinGW tree. I use this script to produce a single
;   binary package with:
;   * GCC 4.1.2
;     (http://www.tdragon.net/gcc412.html, thanks TDM!)
;   * binutils 2.17.50-20060824
;     (http://downloads.sourceforge.net/mingw/binutils-2.17.50-20060824-1.tar.gz)
;   * mingw32-make-3.81-1
;     (http://downloads.sourceforge.net/mingw/mingw32-make-3.81-1.tar.gz)
;   * mingw-runtime-3.11
;     (http://downloads.sourceforge.net/mingw/mingw-runtime-3.11.tar.gz)
;   * w32api-3.7
;     (http://downloads.sourceforge.net/mingw/w32api-3.7.tar.gz)
;
; - Install a script (called 'gccmrt') that lets the user change the
;   Microsoft runtime library to use. This basically lets the users
;   solve the problems with MSVCRT.DLL vs MSVCR71.DLL!
;
; - During installation, the user can configure the runtime library
;   to use (the installer runs 'gccmrt' after it is installed).
;
; - Optionally configure Python installations to use GCC to compile
;   extensions by default. This is done by creating/editing the global
;   "distutils.cfg" configuration file. The installer allows the user
;   to choose which Python installation to modify.
;
; - Optionally add the bin directory to the PATH.
;

[Setup]
AppName=GCC
AppVerName=GCC 4.3.3
AppPublisher=MinGW
AppPublisherURL=http://www.mingw.org
AppSupportURL=http://www.mingw.org
AppUpdatesURL=http://www.mingw.org
DefaultDirName=c:\mingw
DefaultGroupName=MinGW
AllowNoIcons=true
LicenseFile=LICENSE.GPL
OutputBaseFilename=gcc-mingw-4.3.3-setup
Compression=lzma
SolidCompression=true
ChangesEnvironment=true

[Languages]
Name: english; MessagesFile: compiler:Default.isl

[Files]
Source: C:\mingw\*; DestDir: {app}; Flags: ignoreversion recursesubdirs createallsubdirs; Languages: 
Source: C:\mingw\lib\libmsvcrt.a; DestDir: {app}\lib; DestName: libmsvcr60.a; Flags: ignoreversion
Source: C:\mingw\lib\libmsvcrtd.a; DestDir: {app}\lib; DestName: libmsvcr60d.a; Flags: ignoreversion
Source: C:\mingw\lib\libmoldname.a; DestDir: {app}\lib; DestName: libmoldname60.a; Flags: ignoreversion
Source: C:\mingw\lib\libmoldnamed.a; DestDir: {app}\lib; DestName: libmoldname60d.a; Flags: ignoreversion
Source: gccmrt.bat; DestDir: {app}\bin; Flags: ignoreversion

#if !FileExists("c:\mingw\lib\gcc\mingw32\4.3.3\specs")
#error "Use 'mkspec.py c:\mingw' to create the spec files"
#endif

[Icons]
Name: {group}\{cm:UninstallProgram,GCC}; Filename: {uninstallexe}

[CustomMessages]
PythonForm_Caption=Python bindings
PythonForm_Description=Select which versions of Python to customize so that GCC is the default compiler for distutils.
PythonForm_NoPythonFound=No Python installation found in the registried. It won't be possble to install the bindings.

[Tasks]
Name: modifypath; Description: &Add GCC to your system PATH. Mandatory for usage with Python.; Flags: checkablealone
Name: bind_python; Description: Bind to &Python installations (configure distutils to use this GCC by default); Flags: checkedonce dontinheritcheck
Name: set_mrt; Description: "Set the default runtime library to use. This can be changed after installation by running ""gccmrt""."; Flags: checkedonce; Languages: 
Name: set_mrt\60; Description: Link with MSVCRT.DLL (for Python 2.3 and older); Flags: exclusive unchecked
Name: set_mrt\70; Description: Link with MSVCR70.DLL; Flags: exclusive unchecked
Name: set_mrt\71; Description: Link with MSVCR71.DLL (for Python 2.4 and 2.5); Flags: exclusive
Name: set_mrt\80; Description: Link with MSVCR80.DLL; Flags: exclusive unchecked
Name: set_mrt\90; Description: Link with MSVCR90.DLL; Flags: exclusive unchecked

[Code]
var
  PythonList: TNewCheckListBox;
  PythonListInited: Boolean;
  PythonVersions: array of String;

{
 *********************************************************
 Script functions to setup GCC with Python distutils.
 *********************************************************
}

{ GetInstalledPythonVersions(): Return the list of Python installations
  (version numbers) found in the system registry.
}
function GetInstalledPythonVersions() : array of String;
begin
	RegGetSubkeyNames(HKEY_LOCAL_MACHINE, 'SOFTWARE\Python\PythonCore', Result);
end;

{ GetPythonInstallPath(Ver): Return the installation path of a specific
  Python installation.
}
function GetPythonInstallPath(Ver: String) : String;
begin
	RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Python\PythonCore\' + Ver + '\InstallPath', '', Result);
end;

{ BindToPythonVersion(Ver): Configure distutils (in a specific Python
  installation) to use the mingw32 GCC compiler.

  distutils.cfg is a standard INI file, so we are lucky here since
  we can use the INI functions provided by InnoSetup. The global
  (platform) distutils.cfg file is located in "PYTHON\Lib\distutils".
  Normally, it does not even exist.

  At install time:
    - Add "compiler=mingw32" to section "[build]". This specifies
      to use GCC by default when building extensions.

  At uninstall time:
    - Remove "compiler=mingw32" from section "[build]".
    - If section "[build]" is empty, remove it.
    - If "distutils.cfg" is now an empty file, remove it.

  NOTE: distutils will actually use whatever GCC will find in the PATH.
  There is no way we can force it to use *this* GCC installation.
  We can't help that, but we suggest the use to add the target
  installation directory to the PATH (and we provide a task to do
  that automatically!).
}
procedure BindToPythonVersion(Ver : String);
var
	Content,Path : String;
begin
	Path := GetPythonInstallPath(Ver) + '\Lib\distutils\distutils.cfg';
	if not IsUninstaller() then
		SetIniString('build', 'compiler', 'mingw32', Path)
	else begin
		if GetIniString('build', 'compiler', '', Path) = 'mingw32' then
		begin
			DeleteIniEntry('build', 'compiler', Path);
			if IsIniSectionEmpty('build', Path) then
			begin
				DeleteIniSection('build', Path);
				LoadStringFromFile(Path, Content)
				if Content = '' then
					DeleteFile(Path);
			end;
		end;
	end;
end;

{ BindToPython(): Task that takes care of configuring distutils
  for all the user-requested Python versions.

  At install time:
    - Go through the checkboxes to find out which Python installations
      the user asked us to modify.
    - Modify the specified installations.
    - Save a file called 'uninsPyVers.txt' containing the list of
      Python installations we modified, to be able to clean up.
      Append to it if exist (so that we can install multiple times).

  At uninstall time:
    - Read the list of Python installations that were modified
      from 'uninsPyVers.txt'.
    - Reset the specified installations.
    - Delete 'uninsPyVers.txt'.
}
procedure BindToPython();
var
	I : Integer;
	appdir : String;
begin
	appdir := ExpandConstant('{app}')

	if IsUninstaller() then
		LoadStringsFromFile(appdir + '\uninsPyVers.txt', PythonVersions)
	else
		for I:=0 to GetArrayLength(PythonVersions)-1 do
			if not PythonList.Checked[I] then
				PythonVersions[i] := '';

	for I:=0 to GetArrayLength(PythonVersions)-1 do
		if PythonVersions[i] <> '' then
			BindToPythonVersion(PythonVersions[i])

	if not IsUninstaller() then
		SaveStringsToFile(appdir + '\uninsPyVers.txt', PythonVersions, True)
	else
		DeleteFile(appdir + '\uninsPyVers.txt')
end;

{ PythonForm_Activate() - Hook called by InnoSetup when
  the PythonForm page is activated.

  The first time this happens, populate the listbox with
  a checkbox for each Python installation we can find in the
  registry.

  We do this only the first time the page is shown (and not
  at startup time) because we want to show a MessageBox if
  no Python installations are found, and that just does not
  make sense at startup (not everybody is supposed to
  have Python installed...).
}

procedure PythonForm_Activate(Page: TWizardPage);
var
	I : Integer;
	Path : String;
begin
	if not PythonListInited then
	begin
		PythonListInited := True;
		with PythonList do
		begin
			PythonVersions := GetInstalledPythonVersions();
			if GetArrayLength(PythonVersions) = 0 then
			begin
				MsgBox(ExpandConstant('{cm:PythonForm_NoPythonFound}'), mbError, MB_OK);
			end else begin
				for I:=0 to GetArrayLength(PythonVersions)-1 do
				begin
					Path := GetPythonInstallPath(PythonVersions[i]);
					AddCheckBox('Python ' + PythonVersions[i] + ' (' + Path + ')', '', 0, True, True, False, True, nil);
				end;
			end;
		end;
	end;
end;

{ PythonForm_ShouldSkipPage() - Hook called by InnoSetup to
  know whether to display this page or not.

  The PythonForm must be displayed only when the user has
  selected the specific task from the task list (it's
  called 'bind_python' internally.
}
function PythonForm_ShouldSkipPage(Page: TWizardPage): Boolean;
begin
  // Skip the Python form page if the user did not select the Python bindings
  Result := not IsTaskSelected('bind_python');
end;

{ PythonForm_BackButtonClick }

function PythonForm_BackButtonClick(Page: TWizardPage): Boolean;
begin
  Result := True;
end;

{ PythonForm_NextkButtonClick }

function PythonForm_NextButtonClick(Page: TWizardPage): Boolean;
begin
  Result := True;
end;

{ PythonForm_CancelButtonClick }

procedure PythonForm_CancelButtonClick(Page: TWizardPage; var Cancel, Confirm: Boolean);
begin
  // enter code here...
end;


{ PythonForm_CreatePage() - Create the form which will contain
  the list of Python installations found on the user computer.

  This code has been generated with ISFD (InnoSetup Form Designer,
  http://isfd.kaju74.de). You don't really believe I was going
  to study Delphi VCL, do you? :)
}
function PythonForm_CreatePage(PreviousPageId: Integer): Integer;
var
  Page: TWizardPage;
begin
  Page := CreateCustomPage(
    PreviousPageId,
    ExpandConstant('{cm:PythonForm_Caption}'),
    ExpandConstant('{cm:PythonForm_Description}')
  );

  PythonList := TNewCheckListBox.Create(Page);
  with PythonList do
  begin
    Parent := Page.Surface;
    Left := ScaleX(0);
    Top := ScaleY(0);
    Width := ScaleX(413);
    Height := ScaleY(241);
    TabOrder := 0;
  end;
  PythonListInited := False;

  with Page do
  begin
    OnActivate := @PythonForm_Activate;
    OnShouldSkipPage := @PythonForm_ShouldSkipPage;
    OnBackButtonClick := @PythonForm_BackButtonClick;
    OnNextButtonClick := @PythonForm_NextButtonClick;
    OnCancelButtonClick := @PythonForm_CancelButtonClick;
  end;

  Result := Page.ID;
end;

{ InitializeWizard() - Hook called by InnoSetup when the
  installation begins.

  Here we just create our custom forms (the Python installation
  selection form).
}
procedure InitializeWizard();
begin
  PythonForm_CreatePage(wpSelectTasks);
end;

{ ModPathDir(): Hook called by ModPath (see below).

  Return the directory to add to the PATH. In our case,
  it's the "bin" directory where the user installed GCC.
}
function ModPathDir(): String;
begin
	Result := ExpandConstant('{app}\bin');
end;

{
 *********************************************************
 Script functions to setup 'gccmrt'
 *********************************************************

 GCC by default always links to msvcrt. This is because there's
 a "-lmsvcrt" line in the specs file (use gcc -dumpspecs to see
 the builtin specs with newer GCCs). Anyway, even modifying
 the specs to (for instance) "-lmsvcr71" isn't enough. I have
 not investigated in detail, but I believe that "libmsvcrt.a"
 is still brought in with some dependency.

 This mail explains how to force GCC to only use msvcr71:
 http://mail.python.org/pipermail/python-list/2004-December/297986.html
 The trick there is to use -L with a renamed file. But this trick
 would require to patch distutils, which is not something which
 I am willing to do within a MinGW installer.

 So, what 'gccmrt' does is simply overwriting libmsvcrt.a with a copy
 of libmsvcr71.a (or whatever version you want). The installer
 script backs up "libmsvcrt.a" as "libmsvcr60.a" (which is the
 correct version number), so that it can still be recovered.

 Have a look at gccmrt.bat for the implementation of the script.
 The code here in the installer is only needed to spawn gccmrt.bat
 once after the installer is done.
}

{ SetMrt(Ver): Invoke the "gccmrt" script to configure a
  specific Microsoft runtime library as default.
}
procedure SetMrt(Ver: String);
var
	ResultCode : Integer;
begin
	Exec(ExpandConstant('{app}\bin\gccmrt.bat'), Ver, '', SW_SHOW,
	     ewWaitUntilTerminated, ResultCode);
end;


// ----------------------------------------------------------------------------
//
// Inno Setup Ver:  5.1.8
// Script Version:  1.2.4
// Author:          Jared Breland <jbreland@legroom.net>
// Homepage:		http://www.legroom.net/mysoft
//
// Script Function:
//	Enable modification of system path directly from Inno Setup installers
//
// Instructions:
//	Copy modpath.iss to the same directory as your setup script
//
//	Add this statement to your [Setup] section
//		ChangesEnvironment=yes
//
//	Add this statement to your [Tasks] section
//	You can change the Description and Flags, but the Name must be modifypath
//		Name: modifypath; Description: &Add application directory to your system path; Flags: unchecked
//
//	Add the following to the end of your [Code] section
//	Result should be set to the path that you want to add
//		function ModPathDir(): String;
//		begin
//			Result := ExpandConstant('{app}');
//		end;
//		#include "modpath.iss"
//
// ----------------------------------------------------------------------------

procedure ModPath();
var
	oldpath:	String;
	newpath:	String;
	pathArr:	TArrayOfString;
	aExecFile:	String;
	aExecArr:	TArrayOfString;
	i:			Integer;
	pathdir:	String;
begin
	pathdir := ModPathDir();
	// Modify WinNT path
	if UsingWinNT() = true then begin

		// Get current path, split into an array
		RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'Path', oldpath);
		oldpath := oldpath + ';';
		i := 0;
		while (Pos(';', oldpath) > 0) do begin
			SetArrayLength(pathArr, i+1);
			pathArr[i] := Copy(oldpath, 0, Pos(';', oldpath)-1);
			oldpath := Copy(oldpath, Pos(';', oldpath)+1, Length(oldpath));
			i := i + 1;

			// Check if current directory matches app dir
			if pathdir = pathArr[i-1] then begin
				// if uninstalling, remove dir from path
				if IsUninstaller() = true then begin
					continue;
				// if installing, abort because dir was already in path
				end else begin
					abort;
				end;
			end;

			// Add current directory to new path
			if newpath = '' then begin
				newpath := pathArr[i-1];
			end else begin
				newpath := newpath + ';' + pathArr[i-1];
			end;
		end;

		// Prepend app dir to path if not already included
		if IsUninstaller() = false then
			newpath := pathdir + ';' + newpath;

		// Write new path
		RegWriteStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'Path', newpath);

	// Modify Win9x path
	end else begin

		// Convert to shortened dirname
		pathdir := GetShortName(pathdir);

		// If autoexec.bat exists, check if app dir already exists in path
		aExecFile := 'C:\AUTOEXEC.BAT';
		if FileExists(aExecFile) then begin
			LoadStringsFromFile(aExecFile, aExecArr);
			for i := 0 to GetArrayLength(aExecArr)-1 do begin
				if IsUninstaller() = false then begin
					// If app dir already exists while installing, abort add
					if (Pos(pathdir, aExecArr[i]) > 0) then
						abort;
				end else begin
					// If app dir exists and = what we originally set, then delete at uninstall
					if aExecArr[i] = 'SET PATH=%PATH%;' + pathdir then
						aExecArr[i] := '';
				end;
			end;
		end;

		// If app dir not found, or autoexec.bat didn't exist, then (create and) append to current path
		if IsUninstaller() = false then begin
			SaveStringToFile(aExecFile, #13#10 + 'SET PATH=%PATH%;' + pathdir, True);

		// If uninstalling, write the full autoexec out
		end else begin
			SaveStringsToFile(aExecFile, aExecArr, False);
		end;
	end;

	// Write file to flag modifypath was selected
	//   Workaround since IsTaskSelected() cannot be called at uninstall and AppName and AppId cannot be "read" in Code section
	if IsUninstaller() = false then
		SaveStringToFile(ExpandConstant('{app}') + '\uninsTasks.txt', WizardSelectedTasks(False), False);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
	if CurStep = ssPostInstall then
		if IsTaskSelected('modifypath') then
			ModPath();
		if IsTaskSelected('bind_python') then
			BindToPython();
		if IsTaskSelected('set_mrt\60') then
			SetMrt('60');
		if IsTaskSelected('set_mrt\70') then
			SetMrt('70');
		if IsTaskSelected('set_mrt\71') then
			SetMrt('71');
		if IsTaskSelected('set_mrt\80') then
			SetMrt('80');
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
	appdir:			String;
	selectedTasks:	String;
begin
	appdir := ExpandConstant('{app}')
	if CurUninstallStep = usUninstall then begin
		if LoadStringFromFile(appdir + '\uninsTasks.txt', selectedTasks) then
			if Pos('modifypath', selectedTasks) > 0 then
				ModPath();
			if Pos('bind_python', selectedTasks) > 0 then
				BindToPython();
		DeleteFile(appdir + '\uninsTasks.txt')
	end;
end;

function NeedRestart(): Boolean;
begin
	if IsTaskSelected('modifypath') and not UsingWinNT() then begin
		Result := True;
	end else begin
		Result := False;
	end;
end;
