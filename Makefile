.PHONY: rpm
rpm:
	git clone https://github.com/packpack/packpack.git || true
	OS=el DIST=7 ./packpack/packpack
