TTCTL := tt
ifeq (,$(shell which tt 2>/dev/null))
$(error tt is not found)
endif

.PHONY: all
all:
	@echo "Available commands: .rocks, lint, test, perf, clean"

.rocks: checks-scm-1.rockspec
	$(TTCTL) rocks make
	$(TTCTL) rocks install luacheck 0.26.0
	$(TTCTL) rocks install luatest 0.5.7

.PHONY: lint
lint: .rocks
	.rocks/bin/luacheck .

.PHONY: test
test: .rocks
	.rocks/bin/luatest -c -v ./test/test.lua

.PHONY: perf
perf: .rocks
	.rocks/bin/luatest -c ./test/perftest.lua

.PHONY: clean
clean:
	rm -rf .rocks
