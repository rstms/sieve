
# thunderbird extension makefile

project = sieve
gitclean = if git status --porcelain | grep '^.*$$'; then echo git status is dirty; false; else echo git status is clean; true; fi

src = $(shell find src -type f -name '*.js') $(shell find src -type f -name '*.mjs')
html = $(shell find src -type f -name '*.html')
schema = $(wildcard src/wx/api/*.json)

version != cat VERSION

all: $(html) $(src) fix .fmt lint assets
	touch manifest.json

fix: .fix

.fix: $(src)
	fix eslint fix $(src)

lint:
	eslint $(src)

fmt:	.fmt

.fmt: fix $(html)
	prettier --tab-width 2 --write "src/**/.js" "src/**/*.mjs" "src/**/*.html"
	touch $@

release_file = build/$(project)-$(version)-rstms.xpi

$(release_file): $(src) $(html)
	rm -f build/*.xpi
	npm run gulp wx:package-xpi
	cp build/*.xpi $@

dist: $(release_file)

build/wx/manifest.json: $(src) $(html)
	npm run gulp wx:package

dev: build/wx/manifest.json

release: $(release_file)
	@$(gitclean) || { [ -n "$(dirty)" ] && echo "allowing dirty release"; }
	gh release create v$(version)-rstms --notes "v$(version)-rstms"
	( cd build && gh release upload v$(version)-rstms $(notdir $<) )

clean:
	rm -rf build/wx && mkdir build/wx

sterile:
	rm -rf build && mkdir build
