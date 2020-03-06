#!/bin/bash
# This script should be executed from the firehawk folder
. ./scripts/exit_test.sh
source ./update_vars.sh --dev --vagrant; exit_test
echo "testsecret $testsecret"
echo "vault_id $vault_key"
result=$(./scripts/ansible-encrypt.sh --vault-id $vault_key --decrypt $testsecret)
echo $result
if [[ "$result" != "this is a test secret" ]]; then exit 1; fi
echo $firehawksecret
if [[ -z "$firehawksecret" ]]; then echo "ERROR unable to extract password from defined firehawksecret"; exit 1; fi