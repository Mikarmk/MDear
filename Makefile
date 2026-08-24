.PHONY: build clean open

build:
	./scripts/build.sh

clean:
	rm -rf build dist

open: build
	open build/MDore.app

