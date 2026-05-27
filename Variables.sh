#!/bin/bash

echo "All variables passed to script $@"

echo "Total number of variables passed to script $#"
echo "script name is $0"
echo "First variable passed to script $1"
echo "Second variable passed to script $2"
echo "user name $USER"
echo "home directory of user $HOME"
echo "current working directory $PWD"
echo "current shell $SHELL"
echo "current pid of script $$"

