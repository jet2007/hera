#!/bin/bash

function fn_header_print()
{
    runtime=`date '+%Y-%m-%d %H:%M:%S'`
    echo ""
    echo "$TOOLS_PRINT_LINE_HEAD_TAIL $runtime INFO  - [介　　绍] - $TOOLS_NAME"
    echo "$TOOLS_PRINT_LINE_HEAD_TAIL $runtime INFO  - [介　　绍] - Copyright:$TOOLS_COPYRIGHT"
    echo "$TOOLS_PRINT_LINE_HEAD_TAIL $runtime INFO  - [介　　绍] - By:$TOOLS_DEVELOPER"
}

function fn_print_info()
{
    runtime=`date '+%Y-%m-%d %H:%M:%S'`
    echo "$TOOLS_PRINT_LINE_HEAD_TAIL $runtime INFO  - [$1] - $2"
}

function fn_print_error()
{
    runtime=`date '+%Y-%m-%d %H:%M:%S'`
    echo "$TOOLS_PRINT_LINE_HEAD_TAIL $runtime ERROR - [$1] - $2"
    exit -1
}