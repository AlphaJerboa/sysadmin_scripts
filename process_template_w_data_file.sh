#!/bin/bash

# Feed a template file with value stored in a data file

! [[ $# -eq 2 ]] && cat << USAGE && exit
$0 <data_filename> <template_filename>

<data-filename> should start with a header line like :
FIELD1 FIELD2 FIELD3
value1 value2 value3
value4 value5 value6

<template_filename> should be have fields inserted between ## like
MY FIRST FIELD HAS A VALUE OF ##FIELD1##
MY SECOND FIELD HAS A VALUE OF ##FIELD2##
USAGE

DEBUG=0 # 0=ON 1=OFF

TEMPLATE="$2"
DATA="$1"

FIELDS=$(head -n1 "$DATA")

[[ -z "$FIELDS" ]] && echo "Header not found in $DATA" && exit 0
! [[ "$FIELDS" =~ ^[[:alnum:][:blank:]_-]*$ ]] && echo "Bad header in $DATA" && exit 0


while read $FIELDS
do
  SED_CMD="sed"
  for FIELD in $FIELDS
  do
    [[ $DEBUG -eq 0 ]] && echo "## ${FIELD}=${!FIELD}"
    [[ -z "${!FIELD}" || "${!FIELD}" == " " ]] && echo "## [WARNING] $FIELD not defined"
    SED_CMD="$SED_CMD -e \"s/##$FIELD##/${!FIELD}/g\""
  done

  eval $SED_CMD $TEMPLATE

  echo
done < <(tail -n +2 "$DATA")
