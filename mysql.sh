#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
N="\e[0m"

dnf list installed mysql
if [ $? -ne 0 ]
then
    echo -e "$R mysql is not installed, going to install...$N"
    dnf install mysql -y
else
    echo -e "$G mysql is already installed, no worries...$N"
fi