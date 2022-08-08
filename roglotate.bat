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
REM 実行モードを決定
REM 0  : ファイルローテート
REM 1  : ディレクトリローテート
call :SetExecMode "%~1" EXEC_MODE
set TARGET_PATH="%~1"

REM ---------------------------------------------------------------------
REM オプションを解析
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
 REM echo rotateを設定
 set TPARAM=%PARAM%
 for %%i in (0 1 2 3 4 5 6 7 8 9) do if defined TPARAM call set TPARAM=%%TPARAM:%%i=%%
 if defined TPARAM (
  call :Usage %PARAM% rotateの世代数指定は1以上の整数値で行ってください
 )
 if %PARAM% leq 0 (
  call :Usage %PARAM% rotateの世代数指定は1以上の整数値で行ってください
 )
 set ROTATE=%PARAM%

) else if /i %OPT% equ /maxsize (
 REM --------------------------
 REM echo maxsizeを設定
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
  call :Usage !PARAM! maxsizeの指定は、整数値。もしくは、k、M、G単位付き整数指定で行ってください
 )
 set MAXSIZE=!PARAM!

) else if /i %OPT% equ /compress (
 REM --------------------------
 REM echo 圧縮設定
 set COMPRESS=1
 set OPT=%PARAM%
 goto opt_jumpin

) else if /i %OPT% equ /dateext (
 REM --------------------------
 REM echo 世代の接尾を日時に変更
 set DATEEXT=1
 set OPT=%PARAM%
 goto opt_jumpin

) else if /i %OPT% equ /d (
 REM --------------------------
 REM echo dry-run設定
 set DRYRUN=1
 set OPT=%PARAM%
 goto opt_jumpin

) else if /i %OPT% equ /p (
 REM --------------------------
 REM echo 処理終了でキー待ち
 set KEYWAIT=1
 set OPT=%PARAM%
 goto opt_jumpin

) else if /i %OPT% equ /v (
 REM --------------------------
 REM echo 実行コマンドを表示
 set VERBOSE=1
 set OPT=%PARAM%
 goto opt_jumpin

) else if /i %OPT% equ /h (
 REM --------------------------
 REM echo ヘルプ表示
 call :Usage ヘルプ
) else (
 REM --------------------------
 REM echo 未対応のオプション
 call :Usage %OPT% 不正なオプションです
)
goto parse_opt

REM ---------------------------------------------------------------------
REM ログローテート実行
:exec_rotate
if %EXEC_MODE% equ 0 (
 REM --------------------------
 REM echo ファイルローテート
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
   REM カウンタで世代管理
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
   REM 日時接尾語で世代管理
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
 REM echo ディレクトリローテート
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
REM 実行モードを設定
REM ---------------------------------------------------------------------
:SetExecMode
setlocal
if not exist "%~1" (
 if /i "%~1" equ "/h" (
  call :Usage ヘルプ
 ) else (
  call :Usage %~1 ファイル/フォルダが存在しません
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
REM 指定ファイルの削除 or 圧縮
REM ---------------------------------------------------------------------
:DeleteFile
setlocal
if %COMPRESS% equ 0 (
 REM --------------------------
 REM 削除
 call :CommnadExec del /f /q "%~1"
) else (
 REM --------------------------
 REM 圧縮
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
REM DRY-RUNを考慮したコマンド実行
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
REM 使用方法表示して終了
REM ---------------------------------------------------------------------
:Usage
echo. %*
echo.
echo "roglotate.bat <target> [/compress] [/d] [/dateext] [/h] [/maxsize <size>] [/p] [/rotate <n>] [/v]"
echo -----------
echo target    : ローテート対象のファイルかディレクトリ
echo             ファイルを指定するとそのファイルを指定された条件でローテートする
echo             ディレクトリを指定するとそのディレクトリ内のファイルすべてを対象にローテートする
echo.
echo /compress : 世代をはずれて削除対象となるファイルを削除ではなくzip圧縮する
echo             デフォルトは指定無し
echo.
echo /d        : dry-run。処理は実行せずに実行予定のコマンドを表示する
echo             デフォルトは指定無し
echo.
echo /dateext  : ファイルの世代管理にカウンタではなく実行時の日時を利用する。フォーマットは _YYYYMMDD_hhmmss
echo             targetがファイル指定の場合のみ有効
echo             デフォルトは指定無し
echo.
echo /h        : ヘルプ表示
echo.
echo /maxsize  : ローテートするファイルサイズを指定する。このサイズよりtargetのファイルサイズが大きい場合ローテートを実行
echo             ファイルサイズの指定は、直接数値以外に、k, M, G を利用可能
echo             例） /maxsize 4k
echo             targetがファイル指定の場合のみ有効
echo             デフォルトは0（実行するたびにローテートされます）
echo.
echo /p        : 処理終了時にキー待ちします
echo             デフォルトは指定無し
echo.
echo /rotate   : 何世代ローテートするかの指定
echo             ファイル指定の場合は、target.1～nの世代ファイルが作成される。
echo             ディレクトリ指定の場合は、.zip以外のファイルを対象に新しい順にソートして世代数以上の古いファイルを削除する
echo             デフォルトは5
echo.
echo /v        : 実行したコマンドを表示します
echo             デフォルトは指定無し
echo.
if %KEYWAIT% equ 1 (
 pause
)
exit
