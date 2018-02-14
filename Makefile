DOCKER  := docker
NAIS    := nais
VERSION := $(shell cat ./VERSION)
REGISTRY:= repo.adeo.no:5443

.PHONY: all build test docker hiv hoi testapi docker-push bump-version release manifest

all: build test docker
release: tag docker-push

build:
	$(DOCKER) run --rm -it \
		-v ${PWD}:/usr/src \
		-w /usr/src \
		-v ${HOME}/.m2:/root/.m2 \
		maven:3.5-jdk-8 mvn clean package -DskipTests=true -B -V

test:
	$(DOCKER) run --rm -it \
		-v ${PWD}:/usr/src \
		-w /usr/src \
		-v ${HOME}/.m2:/root/.m2 \
		maven:3.5-jdk-8 mvn test -B

docker: hiv hoi testapi

hiv:
	$(NAIS) validate -f hiv/nais.yaml
	$(DOCKER) build --pull -t $(REGISTRY)/tortuga-hiv -t $(REGISTRY)/tortuga-hiv:$(VERSION) hiv

hoi:
	$(NAIS) validate -f hoi/nais.yaml
	$(DOCKER) build --pull -t $(REGISTRY)/tortuga-hoi -t $(REGISTRY)/tortuga-hoi:$(VERSION) hoi

testapi:
	$(NAIS) validate -f testapi/nais.yaml
	$(DOCKER) build --pull -t $(REGISTRY)/tortuga-testapi -t $(REGISTRY)/tortuga-testapi:$(VERSION) testapi

docker-push:
	$(DOCKER) push $(REGISTRY)/tortuga-hiv:$(VERSION)
	$(DOCKER) push $(REGISTRY)/tortuga-hoi:$(VERSION)
	$(DOCKER) push $(REGISTRY)/tortuga-testapi:$(VERSION)

bump-version:
	@echo $$(($$(cat ./VERSION) + 1)) > ./VERSION

tag:
	git add VERSION
	git commit -m "Bump version to $(VERSION) [skip ci]"
	git tag -a $(VERSION) -m "auto-tag from Makefile"

manifest:
	curl --fail -v -u $(NEXUS_USERNAME):$(NEXUS_PASSWORD) --upload-file hiv/nais.yaml https://repo.adeo.no/repository/raw/nais/tortuga-hiv/$(VERSION)/nais.yaml
	curl --fail -v -u $(NEXUS_USERNAME):$(NEXUS_PASSWORD) --upload-file hoi/nais.yaml https://repo.adeo.no/repository/raw/nais/tortuga-hoi/$(VERSION)/nais.yaml
	curl --fail -v -u $(NEXUS_USERNAME):$(NEXUS_PASSWORD) --upload-file testapi/nais.yaml https://repo.adeo.no/repository/raw/nais/tortuga-testapi/$(VERSION)/nais.yaml
