TTCTL := tt
ifeq (,$(shell which tt 2>/dev/null))
	TTCTL := tarantoolctl
endif

.PHONY: all
all:
	@echo "Available commands: .rocks, lint, test, perf, clean"

.rocks: rockspecs/checks-scm-1.rockspec
	$(TTCTL) rocks make
	$(TTCTL) rocks install luacheck 0.26.0
	$(TTCTL) rocks install luatest 0.5.7

.PHONY: lint
lint: .rocks
	.rocks/bin/luacheck .

.PHONY: test
test: .rocks
	.rocks/bin/luatest -c -v ./test.lua

.PHONY: perf
perf:
	.rocks/bin/luatest -c ./perftest.lua

.PHONY: clean
clean:
	rm -rf .rocks
