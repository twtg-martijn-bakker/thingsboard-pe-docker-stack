# STACK ?= local
STACK ?= advanced-full-kafka

STACK_COMPONENTS := $(sort $(wildcard ./environments/$(STACK)/*.yml ./environments/$(STACK)/*.yaml))

all: docker-compose.yml

docker-compose.yml: $(STACK_COMPONENTS) thingsboard-license.env
	docker-compose --project-directory $(CURDIR) $(patsubst %,-f %,$(filter %.yml %.yaml,$^)) config --no-interpolate > .$@
	sed -i -e 's,$(CURDIR),.,g' .$@
	mv .$@ $@
