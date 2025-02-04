# Options
NB_NODES ?= 4
ID_WITH_BALANCES ?=
CPUCORES ?= $$(docker run --rm nixos/nix nproc)
TENDERMINT_VERSION ?= 0.35.4
ABCI_TAG ?= "latest"
LEDGER_TAG ?= "latest"

# Constants
VOLUME = $(abspath $(dir $(abspath $(dir $(abspath $(dir $(abspath $(dir $$PWD))))))))
UINFO = $$(id -u):$$(id -g)
BUILDER_COMMAND = docker run --rm -e CPUCORES=$(CPUCORES) -e UINFO=$(UINFO) -v $(VOLUME):/volume -v nix-store:/nix -w /volume/many-framework/docker/e2e/ nixos/nix bash build-image.sh $@
SHELL = bash

.PHONY: clean
clean:
	if [ -d "${PWD}/genfiles/docker-compose.json" ]; then \
		docker-compose -f genfiles/docker-compose.json -p e2e down || true; \
	fi
	rm -rf genfiles

.PHONY: lockfile
lockfile:
	cd ../..; cargo fetch

../../Cargo.lock: lockfile

Cargo.nix: lockfile
	docker run --rm -e CPUCORES=$(CPUCORES) -e UINFO=$(UINFO) -v nix-store:/nix -v $(VOLUME):/volume -w /volume/many-framework nixos/nix bash docker/e2e/generate-cargo-nix.sh

genfiles/many-ledger.tar.gz: $(shell find ../../src -type f) flake.nix flake.lock
	@mkdir -p genfiles
	$(BUILDER_COMMAND) .#docker-many-ledger

.PHONY: many/many-ledger
many/many-ledger: genfiles/many-ledger.tar.gz
	docker load < genfiles/many-ledger.tar.gz

genfiles/many-abci.tar.gz: $(shell find ../../src -type f) flake.nix flake.lock
	@mkdir -p genfiles
	$(BUILDER_COMMAND) .#docker-many-abci

.PHONY: many/many-abci
many/many-abci: genfiles/many-abci.tar.gz
	docker load < genfiles/many-abci.tar.gz

genfiles/tendermint-docker:
	@mkdir -p genfiles
	docker pull tendermint/tendermint:v$(TENDERMINT_VERSION)
	touch $@

genfiles/openssl-docker:
	@mkdir -p genfiles
	docker pull alpine/openssl
	touch $@

genfiles/jsonnet-docker:
	@mkdir -p genfiles
	docker pull bitnami/jsonnet
	touch $@

genfiles/docker-compose.json: genfiles/jsonnet-docker docker-compose.jsonnet
	docker run --user $$(id -u):$$(id -g) --rm -v "${PWD}:/volume:ro" -v "${PWD}/genfiles:/genfiles" bitnami/jsonnet \
		/volume/docker-compose.jsonnet \
		--tla-code nb_nodes=$(NB_NODES) \
		--tla-code user=$$(id -u) \
		--tla-code id_with_balances=\"$(ID_WITH_BALANCES)\" \
		--tla-code abci_tag=\"$(ABCI_TAG)\" \
		--tla-code ledger_tag=\"$(LEDGER_TAG)\" \
		--tla-code tendermint_tag=\"$(TENDERMINT_VERSION)\" \
		-o /$@

genfiles/node%: genfiles/openssl-docker
	mkdir -p "$@/tendermint"
	docker run --user $$(id -u) -it --rm -v "${PWD}/$@/tendermint:/tendermint" tendermint/tendermint:v$(TENDERMINT_VERSION) init validator
	docker run --user $$(id -u) -it --rm -v ${PWD}/$@/:/export alpine/openssl genpkey -algorithm Ed25519 -out /export/ledger.pem
	docker run --user $$(id -u) -it --rm -v ${PWD}/$@/:/export alpine/openssl genpkey -algorithm Ed25519 -out /export/abci.pem
	mkdir -p "$@/persistent-ledger"
	cp ledger_state.json $@/ledger_state.json5

genfiles/generate-tendermint-e2e-config:
	I=0; while [[ $$I -lt ${NB_NODES} ]]; do \
		echo $$I genfiles/node$$I; \
		make genfiles/node$$I; \
		(( I = I + 1 )); \
	done
	bash update_config.sh -c "genfiles/node%/tendermint/config" -i tendermint-% $(NB_NODES)
	mkdir -p $(dir $@) && touch $@

.PHONY: start-nodes
start-nodes: many/many-ledger many/many-abci genfiles/generate-tendermint-e2e-config genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e up

.PHONY: start-abci-%
start-abci-%: genfiles/docker-compose.json many/many-abci
	docker-compose -f genfiles/docker-compose.json -p e2e up abci-$*

.PHONY: start-ledger-%
start-ledger-%: genfiles/docker-compose.json many/many-ledger genfiles/generate-tendermint-e2e-config
	docker-compose -f genfiles/docker-compose.json -p e2e up ledger-$*

.PHONY: start-tendermint-%
start-tendermint-%: genfiles/docker-compose.json genfiles/generate-tendermint-e2e-config
	docker-compose -f genfiles/docker-compose.json -p e2e up tendermint-$*

.PHONY: down-nodes
down-nodes: genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e down

.PHONY: down-abci-%
down-abci-%: genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e down abci-$*

.PHONY: down-ledger-%
down-ledger-%: genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e down ledger-$*

.PHONY: down-tendermint-%
down-tendermint-%: genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e down tendermint-$*

.PHONY: stop-nodes
stop-nodes: genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e stop

.PHONY: stop-single-node-%
stop-single-node-%: genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e stop abci-$*
	docker-compose -f genfiles/docker-compose.json -p e2e stop ledger-$*
	docker-compose -f genfiles/docker-compose.json -p e2e stop tendermint-$*

.PHONY: stop-abci-%
stop-abci-%: genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e stop abci-$*

.PHONY: stop-ledger-%
start-ledger-%: genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e stop ledger-$*

.PHONY: stop-tendermint-%
stop-tendermint-%: genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e stop tendermint-$*

.PHONY: start-nodes-dettached
start-nodes-dettached: many/many-ledger many/many-abci genfiles/generate-tendermint-e2e-config genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e up --detach

.PHONY: start-nodes-dettached-no-img-regen
start-nodes-dettached-no-img-regen: genfiles/generate-tendermint-e2e-config genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e up --detach

.PHONY: start-single-node-dettached-%
start-single-node-dettached-%: many/many-ledger many/many-abci genfiles/generate-tendermint-e2e-config genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e up abci-$* --detach
	docker-compose -f genfiles/docker-compose.json -p e2e up ledger-$* --detach
	docker-compose -f genfiles/docker-compose.json -p e2e up tendermint-$* --detach

.PHONY: start-single-node-dettached-no-img-regen-%
start-single-node-dettached-no-img-regen-%: genfiles/generate-tendermint-e2e-config genfiles/docker-compose.json
	docker-compose -f genfiles/docker-compose.json -p e2e up abci-$* --detach
	docker-compose -f genfiles/docker-compose.json -p e2e up ledger-$* --detach
	docker-compose -f genfiles/docker-compose.json -p e2e up tendermint-$* --detach
