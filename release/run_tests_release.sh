#!/bin/bash

function main {
	find . -name "test_*.sh" ! -name "test_bom.sh" -type f -exec ./{} \;
}

main