.PHONY: clean dialyzer_warnings xref_warnings deps test

REBAR=$(PWD)/rebar
RETEST=$(PWD)/deps/retest/retest

prefix="/usr/local/bin"

epoch=$(shell date +%s)
year=$(shell date +%Y)

vendor="basho"
url="http://basho.com/"

project_name="rebar"
project_version=$(shell git describe --always --tags)

commit_hash=$(shell git log -n 1 --format="%H")

all:
	./bootstrap

clean:
	@rm -rf rebar ebin/*.beam inttest/rt.work rt.work .eunit

distclean: clean
	@rm -f dialyzer_warnings
	@rm -rf deps

debug:
	@./bootstrap debug

check: debug xref dialyzer deps test

xref:
	@./rebar xref

dialyzer: dialyzer_warnings
	@diff -U0 dialyzer_reference dialyzer_warnings

dialyzer_warnings:
	-@dialyzer -q -nn -n ebin -Wunmatched_returns -Werror_handling \
		-Wrace_conditions > dialyzer_warnings

binary: VSN = $(shell ./rebar -V)
binary: clean all
	@cp rebar ../rebar.wiki/rebar
	(cd ../rebar.wiki && git commit -m "Update $(VSN)" rebar)

deps:
	@REBAR_EXTRA_DEPS=1 ./rebar get-deps
	@(cd deps/retest && $(REBAR) compile escriptize)

test:
	@$(REBAR) eunit
	@$(RETEST) -v inttest

travis: clean debug xref clean all deps test

rpm: clean all
	fpm -s dir \
		-t rpm \
		-a all \
		--prefix=${prefix} \
		--vendor=${vendor} \
		--url=${url} \
		--epoch=${epoch} \
		--name=${project_name} \
		--version=${project_version} \
		--provides=${project_name} \
		./rebar
