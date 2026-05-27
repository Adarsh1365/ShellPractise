#!/bin/bash

if [ $1 -gt 20 ]; then
    echo "The number is greater than 20"
elif [ $1 -eq 20 ]; then
    echo "The number is equal to 20"
else
    echo "The number is less than 20"
fi

if [ $2 -le -10 ] ; then
  echo "given number is less than equal to -10"
else
  echo "given number is greater than -10"
fi

if [ $3 -neq 43 ] ; then
  echo "given number is not equal to 43"
else
  echo "given number is equal to 43"
fi