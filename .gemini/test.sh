#!/bin/bash

function function_using_global_variable {
	echo $global_variable
	echo ${global_variable}
}

function function_using_global_and_local_variables {
	global_variable="content"
	local_variable="content"

	echo $local_variable
	echo ${local_variable}
}