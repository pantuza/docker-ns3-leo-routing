
# Internal container directory that is the root folder for executing all the code in this project
WORKDIR := /src/ns-allinone-3.30.1/ns-3.30.1

# Examples that are available in the ns-3-leo-main folder
LEO_ORBIT_EXAMPLE := examples/leo-circular-orbit-tracing-example.cc
LEO_DELAY_EXAMPLE := examples/leo-delay-tracing-example.cc
LEO_THROUGHPUT_EXAMPLE := examples/leo-bulk-send-example.cc

# Local directory that will allow simulations results to be saved outside the container
DATA_DIR := data

# We ONLY mount the examples files in order to avoid messing with compilation files that only exists inside the container image
DOCKER_RUN=docker run --rm -it \
	--mount type=bind,source="$(PWD)/ns-3-leo-main/$(LEO_ORBIT_EXAMPLE)",target=$(WORKDIR)/contrib/leo/$(LEO_ORBIT_EXAMPLE) \
	--mount type=bind,source="$(PWD)/ns-3-leo-main/$(LEO_DELAY_EXAMPLE)",target=$(WORKDIR)/contrib/leo/$(LEO_DELAY_EXAMPLE) \
	--mount type=bind,source="$(PWD)/ns-3-leo-main/$(LEO_THROUGHPUT_EXAMPLE)",target=$(WORKDIR)/contrib/leo/$(LEO_THROUGHPUT_EXAMPLE) \
	--mount type=bind,source="$(PWD)/$(DATA_DIR)",target=/opt/$(DATA_DIR) \
	ns-3-leo

.PHONY: all
all: image

.PHONY: image
image: Dockerfile
	docker build -t ns-3-leo .

.PHONY: shell
shell:
	$(DOCKER_RUN) /bin/bash

.PHONY: leo-orbit
leo-orbit:
	$(DOCKER_RUN) /bin/bash -c './waf --run "leo-orbit \
		--orbitFile=$(WORKDIR)/contrib/leo/data/orbits/starlink.csv \
		--duration=100 \
		--traceFile=/opt/$(DATA_DIR)/orbit.log"'

.PHONY: leo-delay
leo-delay:
	$(DOCKER_RUN) /bin/bash -c './waf --run "leo-delay \
		--destOnly=true \
		--orbitFile=$(WORKDIR)/contrib/leo/data/orbits/telesat.csv \
		--constellation=TelesatGateway \
		--traceFile=/opt/$(DATA_DIR)/delay.log \
		--islRate=2Gbps \
		--islEnabled=true \
		--duration=100"'

.PHONY: leo-throughput
leo-throughput:
	$(DOCKER_RUN) /bin/bash -c './waf --run "leo-bulk-send \
		--destOnly=true \
		--orbitFile=$(WORKDIR)/contrib/leo/data/orbits/telesat.csv \
		--constellation=TelesatGateway \
		--traceFile=/opt/$(DATA_DIR)/throughput.log \
		--islRate=2Gbps \
		--islEnabled=true \
		--duration=100 \
		--routing=gpsr"'
