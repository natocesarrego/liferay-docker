#!/bin/bash

function main {
	find . -name "test_*.sh" -type f ! -name "test_bom.sh" -exec ./{} \;
}

main