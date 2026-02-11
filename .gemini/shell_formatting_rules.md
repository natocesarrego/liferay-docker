## Variables

- Should be declared with modifier local when it's used in a single function only.

```
function function_using_global_variable {
	echo "${global_variable}"
}

function function_using_global_and_local_variables {
	global_variable="content"
	local local_variable="content"

	echo "${global_variable}"
	echo "${local_variable}"
}
```

- Should have its name in uppercase letters and starting with underscore if it's used in multiple functions.
```
function function_using_global_variable {
	echo "${_GLOBAL_VARIABLE}"
}

function function_using_global_and_local_variables {
	_GLOBAL_VARIABLE="content"
	local local_variable="content"

	echo "${_GLOBAL_VARIABLE}"
	echo "${local_variable}"
}
```

- Should be wrapped with double quotes and curly brackets when it's being used.
```
function main {
	local local_variable="content"

	echo "${local_variable}"
}
```