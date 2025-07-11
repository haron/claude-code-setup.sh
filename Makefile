.DEFAULT_GOAL := linter
SHELL := /usr/bin/env -S bash -O globstar # makes work globs like **/*.py

linter:
	shellcheck -S warning **/*.sh
