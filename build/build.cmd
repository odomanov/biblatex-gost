@ECHO OFF
:: The script is intended for Windows 7 but requires GnuWin32

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
rm -f ../tex/latex/biblatex-gost/bbx/sed*
rm -r tds\tex\latex\biblatex-gost
rm -r tds\doc\latex\biblatex-gost
mkdir tds\tex\latex\biblatex-gost
mkdir tds\doc\latex\biblatex-gost
cd ..
cp -r tex/latex/biblatex-gost build/tds/tex/latex/
cp doc/latex/biblatex-gost/README build/tds/doc/latex/biblatex-gost/
cp doc/latex/biblatex-gost/*.bib build/tds/doc/latex/biblatex-gost/
cp doc/latex/biblatex-gost/*.cfg build/tds/doc/latex/biblatex-gost/
cp doc/latex/biblatex-gost/*.tex build/tds/doc/latex/biblatex-gost/
cd build/tds/doc/latex/biblatex-gost
pdflatex -interaction=batchmode biblatex-gost.tex
pdflatex -interaction=batchmode biblatex-gost.tex
pdflatex -interaction=batchmode biblatex-gost-examples.tex
biber biblatex-gost-examples
pdflatex -interaction=batchmode biblatex-gost-examples.tex
rm -f *.aux *.bbl *.bcf *.blg *.log *.lot *.out *.toc *.run.xml
cd ../../..
zip -r -ll ../biblatex-gost-%VERS%.tds.zip *
pause
GOTO:EOF

:s_error
Echo Something is wrong
GOTO:EOF
