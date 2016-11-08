#!/usr/bin/perl
use warnings;
use strict;
use File::Find; 
use File::Spec::Functions;
use File::Copy; 
use File::Copy::Recursive qw( dircopy );
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Path qw(remove_tree make_path); 
use Cwd;

unless ($ARGV[0]) { print "Usage: build.pl Version\n    For example: build.pl 1.2"; exit(); }
my $ver=$ARGV[0];

use POSIX qw(strftime);
my $now_string = POSIX::strftime('%Y/%m/%d', localtime());  # Date in TeX format
printf "Version is %s, today is %s\n", $ver, $now_string;

my $BUILDDIR = cwd();
my $TEXSRC = catdir($BUILDDIR, "/../tex/latex/biblatex-gost/");
my $DOCSRC = catdir($BUILDDIR, "/../doc/latex/biblatex-gost/");

print "Replacing version, date...";

my $file=catfile(($TEXSRC, "bbx/"), "gost-standard.bbx");
{
    # print "\n$file" ;
    local (@ARGV) = ($file);
    local($^I) = '.bak';        # must be backed up on Windows

    while (<>)
    {
        s/\\def\\bbx\@gost\@date{.*}/\\def\\bbx\@gost\@date{$now_string}/;
        s/\\def\\bbx\@gost\@version{.*}/\\def\\bbx\@gost\@version{$ver}/;
    }
    continue
    {
        print;
    }
} 

my @filesToRun = ();
foreach my $filePattern ('\.bbx', '\.cbx', '\.dbx', '\.lbx', '\.def')
{ 
    find( sub { push @filesToRun, $File::Find::name if ( m/^(.*)$filePattern$/ ) }, $TEXSRC) ;
}

foreach  my $file ( @filesToRun  ) 
{
    # print "\n$file" ;
    local (@ARGV) = ($file);
    local($^I) = '.bak';        # must be backed up on Windows

    while (<>)
    {
        s/\[.*\\space v.*\\space biblatex-gost/\[$now_string\\space v$ver\\space biblatex-gost/;
    }
    continue
    {
        print;
    }
} 

find sub {unlink $File::Find::name if /\.bak$/}, $TEXSRC; # remove .bak files

print "done\n";
    
# Compress Subdir to Zip_file
#
sub makezip {
    my ($subdir, $zip_file) = @_;
    chdir (catdir ($BUILDDIR, $subdir));
    unlink $zip_file;
    my $zip = Archive::Zip->new();
    unless ($zip->addTree( '.', '' ) == AZ_OK) {die "zip error"};
    unless ($zip->writeToFileNamed($zip_file) == AZ_OK) {die "zip error"};
}

print "Preparing TDS directory...";

remove_tree ("tds");
remove_tree ("ctan");

# Preparing 'tds' directory
#
make_path ('tds/tex/latex/biblatex-gost/bbx',
           'tds/tex/latex/biblatex-gost/cbx', 
           'tds/tex/latex/biblatex-gost/dbx', 
           'tds/tex/latex/biblatex-gost/lbx');
make_path 'tds/doc/latex/biblatex-gost';

copy (catfile($TEXSRC, "biblatex-gost.def"), "tds/tex/latex/biblatex-gost/") or die "Copy failed: $!";
foreach my $ext ( 'bbx', 'cbx', 'dbx', 'lbx' )
{
    my @files = glob (catfile(($TEXSRC, "$ext"), "*.$ext"));
    foreach my $file ( @files )
    {
        # print "Copy: $file\n";
        copy ($file, "tds/tex/latex/biblatex-gost/$ext/") or die "Copy failed: $!";
    }
}

copy (catfile(($BUILDDIR, ".."), "README.md"), "tds/doc/latex/biblatex-gost/") or die "Copy failed: $!";
foreach my $ext ( 'bib', 'cfg', 'tex' )
{
    my @files = glob (catfile($DOCSRC, "*.$ext"));
    foreach my $file ( @files )
    {
        # print "Copy: $file\n";
        copy ($file, "tds/doc/latex/biblatex-gost/") or die "Copy failed: $!";
    }
}

print "done\n";

# Compiling .tex files
#
chdir (catdir ($BUILDDIR, "/tds/doc/latex/biblatex-gost"));
system ("pdflatex -interaction=batchmode biblatex-gost.tex");
system ("pdflatex -interaction=batchmode biblatex-gost.tex");
system ("pdflatex -interaction=batchmode biblatex-gost.tex");
system ("pdflatex -interaction=batchmode biblatex-gost-examples.tex");
system ("biber biblatex-gost-examples");
system ("pdflatex -interaction=batchmode biblatex-gost-examples.tex");
system ("pdflatex -interaction=batchmode biblatex-gost-examples.tex");

my $err_file = "errors.txt";
if ( -e $err_file) { unlink $err_file };
open ERRLOG, ">$err_file";
print ERRLOG "---- errors -------------------------\n";
print ERRLOG `grep -E -A 3 "^!" *.log`;
print ERRLOG `grep -E -i "error" *.log | grep -v "info/warning/error"`;
print ERRLOG `grep -E -i "error" *.blg`;
print ERRLOG "---- warnings -----------------------\n";
print ERRLOG `grep -E -i "warning" *.log | grep -v "info/warning/error"`;
print ERRLOG `grep -E -i "warn" *.blg`;
close ERRLOG;

copy ("biblatex-gost.log", $BUILDDIR) or die $!;
copy ("biblatex-gost.pdf", $BUILDDIR) or die $!;
copy ("biblatex-gost-examples.log", $BUILDDIR) or die $!;
copy ("biblatex-gost-examples.pdf", $BUILDDIR) or die $!;
copy ($err_file, $BUILDDIR) or die $!;
unlink (<*.aux>, <*.bbl>, <*.bcf>, <*.blg>, <*.log>, <*.lot>, <*.out>, <*.toc>, <*.run.xml>);
unlink ($err_file) or die $!;

# The directory is ready, zip it
print "Zip TSD file...";
makezip "tds", catfile($BUILDDIR, "biblatex-gost-$ver.tds.zip");
print "done\n";

print "Preparing CTAN directory...";

# Preparing 'ctan' directory
#
chdir $BUILDDIR;
make_path ("ctan/biblatex-gost/doc", "ctan/biblatex-gost/tex");
chdir catdir($BUILDDIR, "ctan/biblatex-gost");
dircopy (catdir($BUILDDIR, "/tds/doc/latex/biblatex-gost"), "doc/") or die $!;
dircopy (catdir($BUILDDIR, "/tds/tex/latex/biblatex-gost"), "tex/") or die $!;
move (catfile(($BUILDDIR, "ctan/biblatex-gost/doc"), "README.md"), ".") or die "move error";

print "done\n";

# The directory is ready, zip it
print "Zip CTAN file...";
makezip "ctan", catfile($BUILDDIR, "biblatex-gost-$ver.zip");
print "done\n";

# <STDIN>;
