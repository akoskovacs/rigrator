PREFIX=/usr/local
INSTALL_DIR=$(PREFIX)/bin
RIGRATOR_SYSTEM=$(INSTALL_DIR)/micrate

OUT_DIR=$(CURDIR)/bin
RIGRATOR=$(OUT_DIR)/micrate
RIGRATOR_SOURCES=$(shell find src/ -type f -name '*.cr')

all: build

build: lib $(RIGRATOR)

lib:
	@shards install --production

$(RIGRATOR): $(RIGRATOR_SOURCES) | $(OUT_DIR)
	@echo "Building micrate in $@"
	@crystal build -o $@ src/micrate-bin.cr -p --no-debug

$(OUT_DIR) $(INSTALL_DIR):
	 @mkdir -p $@

run:
	$(RIGRATOR)

install: build | $(INSTALL_DIR)
	@rm -f $(RIGRATOR_SYSTEM)
	@cp $(RIGRATOR) $(RIGRATOR_SYSTEM)

link: build | $(INSTALL_DIR)
	@echo "Symlinking $(RIGRATOR) to $(RIGRATOR_SYSTEM)"
	@ln -s $(RIGRATOR) $(RIGRATOR_SYSTEM)

force_link: build | $(INSTALL_DIR)
	@echo "Symlinking $(RIGRATOR) to $(RIGRATOR_SYSTEM)"
	@ln -sf $(RIGRATOR) $(RIGRATOR_SYSTEM)

clean:
	rm -rf $(RIGRATOR)

distclean:
	rm -rf $(RIGRATOR) .crystal .shards libs lib
