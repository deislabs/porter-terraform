MIXIN = terraform
PKG = github.com/deislabs/porter-$(MIXIN)
SHELL = bash

PORTER_HOME ?= $(HOME)/.porter

COMMIT ?= $(shell git rev-parse --short HEAD)
VERSION ?= $(shell git describe --tags 2> /dev/null || echo v0)
PERMALINK ?= $(shell git name-rev --name-only --tags --no-undefined HEAD &> /dev/null && echo latest || echo canary)

LDFLAGS = -w -X $(PKG)/pkg.Version=$(VERSION) -X $(PKG)/pkg.Commit=$(COMMIT)
XBUILD = CGO_ENABLED=0 go build -a -tags netgo -ldflags '$(LDFLAGS)'
BINDIR = bin/mixins/$(MIXIN)

CLIENT_PLATFORM = $(shell go env GOOS)
CLIENT_ARCH = $(shell go env GOARCH)
RUNTIME_PLATFORM ?= linux
RUNTIME_ARCH ?= amd64
SUPPORTED_CLIENT_PLATFORMS = linux darwin windows
SUPPORTED_CLIENT_ARCHES = amd64 386

ifeq ($(CLIENT_PLATFORM),windows)
FILE_EXT=.exe
else ifeq ($(RUNTIME_PLATFORM),windows)
FILE_EXT=.exe
else
FILE_EXT=
endif

REGISTRY ?= $(USER)

build: build-client build-runtime

build-runtime:
	mkdir -p $(BINDIR)
	GOARCH=$(RUNTIME_ARCH) GOOS=$(RUNTIME_PLATFORM) go build -ldflags '$(LDFLAGS)' -o $(BINDIR)/$(MIXIN)-runtime$(FILE_EXT) ./cmd/$(MIXIN)

build-client: build-templates
	mkdir -p $(BINDIR)
	go build -ldflags '$(LDFLAGS)' -o $(BINDIR)/$(MIXIN)$(FILE_EXT) ./cmd/$(MIXIN)

build-templates: get-deps
	cd pkg/terraform && packr2 build

HAS_PACKR2 := $(shell command -v packr2)
get-deps:
ifndef HAS_PACKR2
	go get -u github.com/gobuffalo/packr/v2/packr2
endif

xbuild-all: xbuild-runtime $(addprefix xbuild-for-,$(SUPPORTED_CLIENT_PLATFORMS))

xbuild-for-%:
	$(MAKE) CLIENT_PLATFORM=$* xbuild-client

xbuild-runtime:
	GOARCH=$(RUNTIME_ARCH) GOOS=$(RUNTIME_PLATFORM) $(XBUILD) -o $(BINDIR)/$(VERSION)/$(MIXIN)-runtime-$(RUNTIME_PLATFORM)-$(RUNTIME_ARCH)$(FILE_EXT) ./cmd/$(MIXIN)

xbuild-client: $(BINDIR)/$(VERSION)/$(MIXIN)-$(CLIENT_PLATFORM)-$(CLIENT_ARCH)$(FILE_EXT)
$(BINDIR)/$(VERSION)/$(MIXIN)-$(CLIENT_PLATFORM)-$(CLIENT_ARCH)$(FILE_EXT):
	mkdir -p $(dir $@)
	GOOS=$(CLIENT_PLATFORM) GOARCH=$(CLIENT_ARCH) $(XBUILD) -o $@ ./cmd/$(MIXIN)

test: test-unit

test-unit: build
	go test ./...

publish:
	# AZURE_STORAGE_CONNECTION_STRING will be used for auth in the following commands
	if [[ "$(PERMALINK)" == "latest" ]]; then \
	az storage blob upload-batch -d porter/mixins/$(MIXIN)/$(VERSION) -s $(BINDIR)/$(VERSION); \
	fi
	az storage blob upload-batch -d porter/mixins/$(MIXIN)/$(PERMALINK) -s $(BINDIR)/$(VERSION)

install:
	mkdir -p $(PORTER_HOME)/mixins/$(MIXIN)
	install $(BINDIR)/$(MIXIN)$(FILE_EXT) $(PORTER_HOME)/mixins/$(MIXIN)/$(MIXIN)$(FILE_EXT)
	install $(BINDIR)/$(MIXIN)-runtime$(FILE_EXT) $(PORTER_HOME)/mixins/$(MIXIN)/$(MIXIN)-runtime$(FILE_EXT)

clean:
	-rm -fr bin/
