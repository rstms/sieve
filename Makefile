
# thunderbird extension makefile

project = sieve
gitclean = if git status --porcelain | grep '^.*$$'; then echo git status is dirty; false; else echo git status is clean; true; fi
version != cat VERSION
timestamp != date --rfc-3339=seconds

src = $(shell find src -type f -name '*.js') $(shell find src -type f -name '*.mjs')
html = $(shell find src -type f -name '*.html')
schema = $(wildcard src/wx/api/*.json)

dev: build/wx/manifest.json

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
	rm build/*.xpi
	sed <build/wx/manifest.json \
	  's/^\(\s*"version": "\)[^"]*",$$/\1$(version)", "homepage_url": "https:\/\/github.com\/rstms\/sieve\/tree\/v$(version)-rstms",/' \
	  | jq . >manifest.json
	mv manifest.json build/wx
	cd build/wx && zip -r ../$(notdir $@) *

dist: $(release_file)

build/wx/manifest.json: $(src) $(html)
	npm run gulp wx:package


release: $(release_file)
	@$(gitclean) || { [ -n "$(dirty)" ] && echo "allowing dirty release"; }
	gh release create v$(version)-rstms --title "v$(version)-rstms" --notes "v$(version)-rstms release build $(timestamp)"
	( cd build && gh release upload v$(version)-rstms $(notdir $<) )

clean:
	rm -rf build && mkdir build
