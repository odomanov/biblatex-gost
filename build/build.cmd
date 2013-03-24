:: The script is intended for Windows 7 but requires GnuWin32
@ECHO OFF

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
rm -r tds ctan
mkdir tds\tex\latex\biblatex-contrib\biblatex-gost
mkdir tds\doc\latex\biblatex-contrib\biblatex-gost
cd ..
cp -r tex/latex/biblatex-gost build/tds/tex/latex/biblatex-contrib/
cp doc/latex/biblatex-gost/README build/tds/doc/latex/biblatex-contrib/biblatex-gost/
cp doc/latex/biblatex-gost/*.bib build/tds/doc/latex/biblatex-contrib/biblatex-gost/
cp doc/latex/biblatex-gost/*.cfg build/tds/doc/latex/biblatex-contrib/biblatex-gost/
cp doc/latex/biblatex-gost/*.tex build/tds/doc/latex/biblatex-contrib/biblatex-gost/
cd build/tds/doc/latex/biblatex-contrib/biblatex-gost
pdflatex -interaction=batchmode biblatex-gost.tex
pdflatex -interaction=batchmode biblatex-gost.tex
pdflatex -interaction=batchmode biblatex-gost.tex
pdflatex -interaction=batchmode biblatex-gost-examples.tex
biber biblatex-gost-examples
pdflatex -interaction=batchmode biblatex-gost-examples.tex
rm -f *.aux *.bbl *.bcf *.blg *.log *.lot *.out *.toc *.run.xml
cd ../../../..
rm ../biblatex-gost-%VERS%.tds.zip
zip -r -ll ../biblatex-gost-%VERS%.tds.zip *
cp doc/latex/biblatex-contrib/biblatex-gost/biblatex-gost.pdf ../
cp doc/latex/biblatex-contrib/biblatex-gost/biblatex-gost-examples.pdf ../
mkdir ..\ctan\biblatex-gost
cd ../ctan/biblatex-gost
cp -r ../../tds/doc/latex/biblatex-contrib/biblatex-gost doc
cp -r ../../tds/tex/latex/biblatex-contrib/biblatex-gost tex
mv doc/README .
cd ..
rm ../biblatex-gost-%VERS%.zip
cp ../biblatex-gost-%VERS%.tds.zip .
zip -r -ll ../biblatex-gost-%VERS%.zip *
pause
GOTO:EOF

:s_error
Echo Something is wrong. Either version is not set or WMIC is not found.
Echo Usage: build.cmd Version
Echo     For example: build.cmd 0.7
GOTO:EOF
