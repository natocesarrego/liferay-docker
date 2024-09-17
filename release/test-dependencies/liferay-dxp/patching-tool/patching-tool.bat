@echo off

pushd "%~dp0"

path %PATH%;%JAVA_HOME%\bin\
set "PT_OPTS="

for /f tokens^=2-3^ delims^=.-_^" %%j in ('java -fullversion 2^>^&1') do (
	set /a "JAVA_VERSION=%%j%%k"
)
if %JAVA_VERSION% LSS 18 (
	set "PT_OPTS=-XX:MaxPermSize=512m -XX:PermSize=256m"
)

set "PT_OPTS=%PT_OPTS% -Xmx1024m -Xms512m -Dfile.encoding=UTF8"

if not exist "./patching-temp/" (
    mkdir patching-temp
)

java %PT_OPTS% -Djava.io.tmpdir=./patching-temp/ -jar lib\patching-tool.jar %*

if exist patching-temp\ rmdir patching-temp /s /q

popd

@echo on