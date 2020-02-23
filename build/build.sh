#!/bin/bash

if [[ -z $1 ]] 
then
    echo "Usage: build.sh Version"
    echo "For example: build.sh 1.18"
    exit
else
    ver=$1
fi
   
now=$(date +'%Y/%m/%d')
echo "Version is $ver, today is $now"

BUILDDIR=$(pwd)
TEXSRC="$BUILDDIR/../tex/latex/biblatex-gost"
DOCSRC="$BUILDDIR/../doc/latex/biblatex-gost"

echo -n "Replacing version, date..."

sed "s!\\\\def\\\\bbx@gost@date{.*}!\\\\def\\\\bbx@gost@date{$now}!" \
    -i "$TEXSRC/bbx/gost-standard.bbx" 
sed "s/\\\\def\\\\bbx@gost@version{.*}/\\\\def\\\\bbx@gost@version{$ver}/" \
    -i "$TEXSRC/bbx/gost-standard.bbx" 

for file in $TEXSRC/bbx/*.bbx $TEXSRC/cbx/*.cbx $TEXSRC/dbx/*.dbx $TEXSRC/lbx/*.lbx $TEXSRC/*.def
do
    sed "s!\[.*\\\\space v.*\\\\space biblatex-gost!\[$now\\\\space v$ver\\\\space biblatex-gost!" \
        -i $file
done    

echo "done"


###  Preparing directories  #########################


rm -rf $BUILDDIR/tds
rm -rf $BUILDDIR/ctan

echo -n "Preparing TDS directory...";

mkdir -p $BUILDDIR/tds/tex/latex/biblatex-gost/bbx
mkdir -p $BUILDDIR/tds/tex/latex/biblatex-gost/cbx 
mkdir -p $BUILDDIR/tds/tex/latex/biblatex-gost/dbx 
mkdir -p $BUILDDIR/tds/tex/latex/biblatex-gost/lbx
mkdir -p $BUILDDIR/tds/doc/latex/biblatex-gost

cp "$TEXSRC/biblatex-gost.def" $BUILDDIR/tds/tex/latex/biblatex-gost/

for ext in bbx cbx dbx lbx
do
    cp $TEXSRC/$ext/*.$ext "$BUILDDIR/tds/tex/latex/biblatex-gost/$ext/"
done


cp "$BUILDDIR/../README.md" $BUILDDIR/tds/doc/latex/biblatex-gost/

for ext in bib cfg tex cls
do
    cp $DOCSRC/*.$ext $BUILDDIR/tds/doc/latex/biblatex-gost/
done

echo "done"


# Compiling .tex files
#
cd "$BUILDDIR/tds/doc/latex/biblatex-gost"
lualatex -interaction=batchmode biblatex-gost.tex
lualatex -interaction=batchmode biblatex-gost.tex
lualatex -interaction=batchmode biblatex-gost.tex
lualatex -interaction=batchmode biblatex-gost-examples.tex
biber biblatex-gost-examples
lualatex -interaction=batchmode biblatex-gost-examples.tex
lualatex -interaction=batchmode biblatex-gost-examples.tex

err_file="errors.txt"

echo "---- errors -------------------------" > $err_file
grep -E -A 3 "^!" *.log >> $err_file
grep -E -i "error" *.log | grep -v "info/warning/error" >> $err_file
grep -E -i "error" *.blg >> $err_file
echo "---- warnings -----------------------" >> $err_file
grep -E -i "warning" *.log | grep -v "info/warning/error" >> $err_file
grep -E -i "warn" *.blg >> $err_file


cp biblatex-gost.log $BUILDDIR
cp biblatex-gost.pdf $BUILDDIR
cp biblatex-gost-examples.log $BUILDDIR
cp biblatex-gost-examples.pdf $BUILDDIR
cp $err_file $BUILDDIR
rm -f *.aux *.bbl *.bcf *.blg *.log *.lot *.out *.toc *.run.xml
rm -f $err_file

# The directory is ready, zip it
echo -n "Zip TSD file..."
cd "$BUILDDIR/tds" && zip -rq -ll --filesync "../biblatex-gost-$ver.tds.zip" . 
echo "done"


echo -n "Preparing CTAN directory..."

mkdir -p "$BUILDDIR/ctan/biblatex-gost/doc" "$BUILDDIR/ctan/biblatex-gost/tex"
cp -r $BUILDDIR/tds/doc/latex/biblatex-gost/* "$BUILDDIR/ctan/biblatex-gost/doc/"
cp -r $BUILDDIR/tds/tex/latex/biblatex-gost/* "$BUILDDIR/ctan/biblatex-gost/tex/"
mv "$BUILDDIR/ctan/biblatex-gost/doc/README.md" "$BUILDDIR/ctan/biblatex-gost"

echo "done"

# The directory is ready, zip it
echo -n "Zip CTAN file..."
cd "$BUILDDIR/ctan" && zip -rq -ll --filesync "../biblatex-gost-$ver.zip" . 
echo "done"

# For uploading to CTAN
cp "$BUILDDIR/biblatex-gost-$ver.zip" biblatex-gost.zip

read -n1 -p "Press a key..."
