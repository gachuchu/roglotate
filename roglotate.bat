@echo off
setlocal EnableDelayedExpansion

set ROTATE=5
set MAXSIZE=0
set DRYRUN=0
set COMPRESS=0
set DATEEXT=0
set KEYWAIT=0
set VERBOSE=0
set EXEC_MODE=0

REM ---------------------------------------------------------------------
REM ���s���[�h������
REM 0  : �t�@�C�����[�e�[�g
REM 1  : �f�B���N�g�����[�e�[�g
call :SetExecMode "%~1" EXEC_MODE
set TARGET_PATH="%~1"

REM ---------------------------------------------------------------------
REM �I�v�V���������
:parse_opt
@shift
if "%1" == "" (
 goto exec_rotate
)
set OPT=%1
:opt_jumpin
if %OPT% == "" (
 goto exec_rotate
)
@shift
if not "%1" == "" (
 set PARAM=%1
) else (
 set PARAM=""
)

if /i %OPT% equ /rotate (
 REM --------------------------
 REM echo rotate��ݒ�
 set TPARAM=%PARAM%
 for %%i in (0 1 2 3 4 5 6 7 8 9) do if defined TPARAM call set TPARAM=%%TPARAM:%%i=%%
 if defined TPARAM (
  call :Usage %PARAM% rotate�̐��㐔�w���1�ȏ�̐����l�ōs���Ă�������
 )
 if %PARAM% leq 0 (
  call :Usage %PARAM% rotate�̐��㐔�w���1�ȏ�̐����l�ōs���Ă�������
 )
 set ROTATE=%PARAM%

) else if /i %OPT% equ /maxsize (
 REM --------------------------
 REM echo maxsize��ݒ�
 if not "!PARAM!" == "!PARAM:k=!" (
   set /a PARAM=!PARAM:K= * 1024!
 )
 if not "!PARAM!" == "!PARAM:m=!" (
   set /a PARAM=!PARAM:M= * 1024 * 1024!
 )
 if not "!PARAM!" == "!PARAM:g=!" (
   set /a PARAM=!PARAM:G= * 1024 * 1024 * 1024!
 )
 set TPARAM=!PARAM!
 for %%i in (0 1 2 3 4 5 6 7 8 9) do if defined TPARAM call set TPARAM=%%TPARAM:%%i=%%
 if defined TPARAM (
  call :Usage !PARAM! maxsize�̎w��́A�����l�B�������́Ak�AM�AG�P�ʕt�������w��ōs���Ă�������
 )
 set MAXSIZE=!PARAM!

) else if /i %OPT% equ /compress (
 REM --------------------------
 REM echo ���k�ݒ�
 set COMPRESS=1
 set OPT=%PARAM%
 goto opt_jumpin

) else if /i %OPT% equ /dateext (
 REM --------------------------
 REM echo ����̐ڔ�������ɕύX
 set DATEEXT=1
 set OPT=%PARAM%
 goto opt_jumpin

) else if /i %OPT% equ /d (
 REM --------------------------
 REM echo dry-run�ݒ�
 set DRYRUN=1
 set OPT=%PARAM%
 goto opt_jumpin

) else if /i %OPT% equ /p (
 REM --------------------------
 REM echo �����I���ŃL�[�҂�
 set KEYWAIT=1
 set OPT=%PARAM%
 goto opt_jumpin

) else if /i %OPT% equ /v (
 REM --------------------------
 REM echo ���s�R�}���h��\��
 set VERBOSE=1
 set OPT=%PARAM%
 goto opt_jumpin

) else if /i %OPT% equ /h (
 REM --------------------------
 REM echo �w���v�\��
 call :Usage �w���v
) else (
 REM --------------------------
 REM echo ���Ή��̃I�v�V����
 call :Usage %OPT% �s���ȃI�v�V�����ł�
)
goto parse_opt

REM ---------------------------------------------------------------------
REM ���O���[�e�[�g���s
:exec_rotate
if %EXEC_MODE% equ 0 (
 REM --------------------------
 REM echo �t�@�C�����[�e�[�g
 for %%F in (%TARGET_PATH%) do (
  set FDP=%%~dpF
  set FNAME=%%~nF
  set FEXT=%%~xF
  set FSIZE=%%~zF
 )
 set IS_ROTATE=0
 if !FSIZE! geq %MAXSIZE% (
  set IS_ROTATE=1
 )
 if !IS_ROTATE! neq 0 (
  if !DATEEXT! equ 0 (
   REM --------------------------
   REM �J�E���^�Ő���Ǘ�
   if exist "!FDP!!FNAME!.!ROTATE!!FEXT!" (
    call :DeleteFile "!FDP!!FNAME!.!ROTATE!!FEXT!"
   )
   for /l %%i in (!ROTATE!, -1, 2) do (
    set /a OLD=%%i - 1
    if exist "!FDP!!FNAME!.!OLD!!FEXT!" (
     call :CommnadExec ren "!FDP!!FNAME!.!OLD!!FEXT!" "!FNAME!.%%i!FEXT!"
    )
   )
   call :CommnadExec ren %TARGET_PATH% "!FNAME!.1!FEXT!"
  ) else (
   REM --------------------------
   REM �����ڔ���Ő���Ǘ�
   for /f "usebackq" %%a in (`dir "!FDP!" /b /o-n ^| findstr /r "!FNAME!_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]!FEXT!"`) do (
    if !ROTATE! gtr 1 (
     set /a ROTATE=!ROTATE! - 1
    ) else (
     call :DeleteFile "!FDP!%%a"
    )
   )
   set DATE_STR=%DATE:/=%
   set TIME_TMP1=%TIME: =0%
   set TIME_TMP2=!TIME_TMP1:~0,8!
   set TIME_STR=!TIME_TMP2::=!
   call :CommnadExec ren %TARGET_PATH% "!FNAME!_!DATE_STR!_!TIME_STR!!FEXT!"
  )
 )

) else (
 REM --------------------------
 REM echo �f�B���N�g�����[�e�[�g
 for /f "usebackq" %%a in (`dir %TARGET_PATH% /b /o-d ^| findstr /v .zip`) do (
  if !ROTATE! gtr 0 (
   set /a ROTATE=!ROTATE! - 1
  ) else (
   call :DeleteFile "%TARGET_PATH:"=%\%%a"
   REM "
  )
 )
)

if %KEYWAIT% equ 1 (
 pause
)
endlocal
exit /b

REM ---------------------------------------------------------------------
REM ���s���[�h��ݒ�
REM ---------------------------------------------------------------------
:SetExecMode
setlocal
if not exist "%~1" (
 if /i "%~1" equ "/h" (
  call :Usage �w���v
 ) else (
  call :Usage %~1 �t�@�C��/�t�H���_�����݂��܂���
 )
)
set ATTR=%~a1
set MODE=0
if %ATTR:~0,1%==d (
 set MODE=1
)
endlocal && set %2=%MODE%
exit /b

REM ---------------------------------------------------------------------
REM �w��t�@�C���̍폜 or ���k
REM ---------------------------------------------------------------------
:DeleteFile
setlocal
if %COMPRESS% equ 0 (
 REM --------------------------
 REM �폜
 call :CommnadExec del /f /q "%~1"
) else (
 REM --------------------------
 REM ���k
 set FDP=%~dp1
 set FNAME=%~n1
 set FEXT=%~x1
 set COUNT=1
 set ARCFILE=%~1.zip

:DeleteFile_loop
 if exist "!ARCFILE!" (
  set ARCFILE=!FDP!!FNAME!!FEXT!.!COUNT!.zip
  set /a COUNT=!COUNT!+1
  goto :DeleteFile_loop
 )
 call :CommnadExec powershell Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process; compress-archive -Path '%~1' -DestinationPath '!ARCFILE!' -Force
 call :CommnadExec del /f /q "%~1"
)
endlocal
exit /b

REM ---------------------------------------------------------------------
REM DRY-RUN���l�������R�}���h���s
REM ---------------------------------------------------------------------
:CommnadExec
setlocal
if %DRYRUN% equ 0 (
 call %*
 if %VERBOSE% neq 0 (
  echo VERBOSE: %*
 ) else (
  REM fall
 )
) else (
 echo DRY-RUN: %*
)
endlocal
exit /b

REM ---------------------------------------------------------------------
REM �g�p���@�\�����ďI��
REM ---------------------------------------------------------------------
:Usage
echo. %*
echo.
echo "roglotate.bat <target> [/compress] [/d] [/dateext] [/h] [/maxsize <size>] [/p] [/rotate <n>] [/v]"
echo -----------
echo target    : ���[�e�[�g�Ώۂ̃t�@�C�����f�B���N�g��
echo             �t�@�C�����w�肷��Ƃ��̃t�@�C�����w�肳�ꂽ�����Ń��[�e�[�g����
echo             �f�B���N�g�����w�肷��Ƃ��̃f�B���N�g�����̃t�@�C�����ׂĂ�ΏۂɃ��[�e�[�g����
echo.
echo /compress : ������͂���č폜�ΏۂƂȂ�t�@�C�����폜�ł͂Ȃ�zip���k����
echo             �f�t�H���g�͎w�薳��
echo.
echo /d        : dry-run�B�����͎��s�����Ɏ��s�\��̃R�}���h��\������
echo             �f�t�H���g�͎w�薳��
echo.
echo /dateext  : �t�@�C���̐���Ǘ��ɃJ�E���^�ł͂Ȃ����s���̓����𗘗p����B�t�H�[�}�b�g�� _YYYYMMDD_hhmmss
echo             target���t�@�C���w��̏ꍇ�̂ݗL��
echo             �f�t�H���g�͎w�薳��
echo.
echo /h        : �w���v�\��
echo.
echo /maxsize  : ���[�e�[�g����t�@�C���T�C�Y���w�肷��B���̃T�C�Y���target�̃t�@�C���T�C�Y���傫���ꍇ���[�e�[�g�����s
echo             �t�@�C���T�C�Y�̎w��́A���ڐ��l�ȊO�ɁAk, M, G �𗘗p�\
echo             ��j /maxsize 4k
echo             target���t�@�C���w��̏ꍇ�̂ݗL��
echo             �f�t�H���g��0�i���s���邽�тɃ��[�e�[�g����܂��j
echo.
echo /p        : �����I�����ɃL�[�҂����܂�
echo             �f�t�H���g�͎w�薳��
echo.
echo /rotate   : �����ネ�[�e�[�g���邩�̎w��
echo             �t�@�C���w��̏ꍇ�́Atarget.1�`n�̐���t�@�C�����쐬�����B
echo             �f�B���N�g���w��̏ꍇ�́A.zip�ȊO�̃t�@�C����ΏۂɐV�������Ƀ\�[�g���Đ��㐔�ȏ�̌Â��t�@�C�����폜����
echo             �f�t�H���g��5
echo.
echo /v        : ���s�����R�}���h��\�����܂�
echo             �f�t�H���g�͎w�薳��
echo.
if %KEYWAIT% equ 1 (
 pause
)
exit
