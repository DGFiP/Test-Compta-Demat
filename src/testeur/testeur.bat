@echo off

set curdir = %~dp0  
cd %curdir%

set curdirtest=%cd%
set curdirtest=%curdirtest:\=/%
set curdirtest=%curdirtest:/testeur=%
echo #!/usr/bin/perl -- -*- C -*- > environnement_alto2.pl
echo sub Env_Path { >> environnement_alto2.pl
echo 		$ENV{ProgramFiles} = ^"%curdirtest%^"; >> environnement_alto2.pl
echo 		$ENV{ProgramData} = ^"%curdirtest%^"; >> environnement_alto2.pl
echo } >> environnement_alto2.pl
echo 1; #return true >> environnement_alto2.pl

init.exe CTL

