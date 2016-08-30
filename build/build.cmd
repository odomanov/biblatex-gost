:: The script is intended for Windows 7 but requires GnuWin32 (for sed)
@ECHO OFF

set BUILDDIR=%CD%

:: Check WMIC is available
WMIC.EXE Alias /? >NUL 2>&1 || GOTO s_error
:: Use WMIC to retrieve date and time
FOR /F "skip=1 tokens=1-6" %%G IN ('WMIC Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') DO (
   IF "%%~L"=="" goto s_error
      Set _yyyy=%%L
      Set _mm=00%%J
      Set _dd=00%%G
	  GOTO:dateok
)
:dateok
:: Pad digits with leading zeros
      Set _mm=%_mm:~-2%
      Set _dd=%_dd:~-2%

:: Date in TeX format:
rem Set _texdate=%_yyyy%\/%_mm%\/%_dd%
IF "%1"=="" goto s_error
set VERS=%1
Echo Version is %VERS%, today is %_yyyy%/%_mm%/%_dd%
sed -e s/\\def\\bbx@gost@date{.*}/\\def\\bbx@gost@date{%_yyyy%\/%_mm%\/%_dd%}/ -i ../tex/latex/biblatex-gost/bbx/gost-standard.bbx
sed -e s/\\def\\bbx@gost@version{.*}/\\def\\bbx@gost@version{%VERS%}/ -i ../tex/latex/biblatex-gost/bbx/gost-standard.bbx
sed -e "s/\[.*\\space v.*\\space biblatex-gost styles\]/\[%_yyyy%\/%_mm%\/%_dd%\\space v%VERS%\\space biblatex-gost styles\]/" -i ../tex/latex/biblatex-gost/bbx/*.bbx
sed -e "s/\[.*\\space v.*\\space biblatex-gost styles\]/\[%_yyyy%\/%_mm%\/%_dd%\\space v%VERS%\\space biblatex-gost styles\]/" -i ../tex/latex/biblatex-gost/cbx/*.cbx
sed -e "s/\[.*\\space v.*\\space biblatex-gost styles\]/\[%_yyyy%\/%_mm%\/%_dd%\\space v%VERS%\\space biblatex-gost styles\]/" -i ../tex/latex/biblatex-gost/lbx/*.lbx
sed -e "s/\[.*\\space v.*\\space biblatex-gost styles\]/\[%_yyyy%\/%_mm%\/%_dd%\\space v%VERS%\\space biblatex-gost styles\]/" -i ../tex/latex/biblatex-gost/*.def
del /S ..\sed*
rmdir /S /Q tds
rmdir /S /Q ctan
mkdir tds\tex\latex\biblatex-gost
mkdir tds\doc\latex\biblatex-gost
xcopy /Y ..\tex\latex\biblatex-gost\biblatex-gost.def tds\tex\latex\biblatex-gost\
xcopy /Y ..\tex\latex\biblatex-gost\bbx\*.bbx tds\tex\latex\biblatex-gost\bbx\
xcopy /Y ..\tex\latex\biblatex-gost\cbx\*.cbx tds\tex\latex\biblatex-gost\cbx\
xcopy /Y ..\tex\latex\biblatex-gost\lbx\*.lbx tds\tex\latex\biblatex-gost\lbx\
xcopy /Y ..\tex\latex\biblatex-gost\dbx\*.dbx tds\tex\latex\biblatex-gost\dbx\
xcopy /Y ..\README.md tds\doc\latex\biblatex-gost\
xcopy /Y ..\doc\latex\biblatex-gost\*.bib tds\doc\latex\biblatex-gost\
xcopy /Y ..\doc\latex\biblatex-gost\*.cfg tds\doc\latex\biblatex-gost\
xcopy /Y ..\doc\latex\biblatex-gost\*.tex tds\doc\latex\biblatex-gost\
chdir /D %BUILDDIR%\tds\doc\latex\biblatex-gost
pdflatex -interaction=batchmode biblatex-gost.tex
pdflatex -interaction=batchmode biblatex-gost.tex
pdflatex -interaction=batchmode biblatex-gost.tex
pdflatex -interaction=batchmode biblatex-gost-examples.tex
biber biblatex-gost-examples
pdflatex -interaction=batchmode biblatex-gost-examples.tex
pdflatex -interaction=batchmode biblatex-gost-examples.tex
if exist errors.txt del errors.txt
echo ---- errors ----------------------- >> errors.txt
grep -E -A 3 "^!" *.log >> errors.txt
grep -E -i "error" *.log | grep -v "info/warning/error" >> errors.txt
grep -E -i "error" *.blg >> errors.txt
echo ---- warnings ----------------------- >> errors.txt
grep -E -i "warning" *.log | grep -v "info/warning/error" >> errors.txt
grep -E -i "warn" *.blg >> errors.txt
xcopy /Y %BUILDDIR%\tds\doc\latex\biblatex-gost\biblatex-gost.log %BUILDDIR%\
xcopy /Y %BUILDDIR%\tds\doc\latex\biblatex-gost\biblatex-gost-examples.log %BUILDDIR%\
xcopy /Y %BUILDDIR%\tds\doc\latex\biblatex-gost\errors.txt %BUILDDIR%\
del -f *.aux *.bbl *.bcf *.blg *.log *.lot *.out *.toc *.run.xml errors.txt
chdir /D %BUILDDIR%\tds
del %BUILDDIR%\biblatex-gost-%VERS%.tds.zip
zip -r -ll %BUILDDIR%\biblatex-gost-%VERS%.tds.zip *
xcopy /Y %BUILDDIR%\tds\doc\latex\biblatex-gost\biblatex-gost.pdf %BUILDDIR%\
xcopy /Y %BUILDDIR%\tds\doc\latex\biblatex-gost\biblatex-gost-examples.pdf %BUILDDIR%\
mkdir %BUILDDIR%\ctan\biblatex-gost
chdir /D %BUILDDIR%\ctan\biblatex-gost
xcopy /E/Y %BUILDDIR%\tds\doc\latex\biblatex-gost %BUILDDIR%\ctan\biblatex-gost\doc\
xcopy /E/Y %BUILDDIR%\tds\tex\latex\biblatex-gost %BUILDDIR%\ctan\biblatex-gost\tex\
move %BUILDDIR%\ctan\biblatex-gost\doc\README.md %BUILDDIR%\ctan\biblatex-gost\
chdir /D %BUILDDIR%\ctan
del %BUILDDIR%\biblatex-gost-%VERS%.zip
zip -r -ll %BUILDDIR%\biblatex-gost-%VERS%.zip *
pause
GOTO:EOF

:s_error
Echo Something is wrong. Either version is not set or WMIC is not found.
Echo Usage: build.cmd Version
Echo     For example: build.cmd 0.7
GOTO:EOF
