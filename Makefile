.PHONY: build test snapshot clean open

build: test
	./scripts/build.sh

test:
	./scripts/test.sh

snapshot:
	./scripts/snapshot.sh

clean:
	rm -rf build dist

open: build
	open build/MDore.app
