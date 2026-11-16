#!/usr/bin/env bash

echo ""
echo 'per "$@"'
echo ""
echo "	$(./argomenti.sh "$@")"
echo ""
echo 'per $@'
echo ""
echo "	$(./argomenti.sh $@)"
echo ""

echo 'per "$*"'
echo ""
echo "	$(./argomenti.sh "$*")"
echo ""
echo 'per $*'
echo ""
echo "	$(./argomenti.sh $*)"
echo ""
