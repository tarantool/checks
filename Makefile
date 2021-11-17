all:
	@echo "Only tests are available: make test"

test:
	./test.lua

perf:
	./perftest.lua
