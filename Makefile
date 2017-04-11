URL=https://raw.github.com/SierraWireless/luasched/master/
VERSION=1.0
REVISION=2

.PHONY: install rock fetch clean

install:
	luarocks make --local checks-$(VERSION)-$(REVISION).rockspec 

rock:
	cd .. && tar cvfpz checks/checks-$(VERSION)-$(REVISION).tar.gz checks/checks.[ch]

fetch:
	wget -N $(URL)/c/checks.c $(URL)/c/checks.h

clean:
	$(RM) *.o *.so
