
FLUTTER?=fvm flutter
FLUTTER_VERSION?=2.10.2
REPOSITORIES?=lib
RUN_VERSION?=--debug

GREEN_COLOR=\033[32m
NO_COLOR=\033[0m

define print_color_message
	@echo "$(GREEN_COLOR)$(1)$(NO_COLOR)";
endef

##
## ---------------------------------------------------------------
## Installation
## ---------------------------------------------------------------
##

.PHONY: install
install: ## Install environment
	@$(call print_color_message,"Install environment")
	fvm install $(FLUTTER_VERSION)
	fvm use $(FLUTTER_VERSION)
	$(FLUTTER) pub global activate devtools
	$(FLUTTER) pub global activate flutter_gen

##
## ---------------------------------------------------------------
## Flutter
## ---------------------------------------------------------------
##

.PHONY: devices
devices: ## Show connected devices
	@$(call print_color_message,"Show connected devices")
	$(FLUTTER) devices

.PHONY: clean
clean: ## Clear cache
	@$(call print_color_message,"Clear cache")
	$(FLUTTER) clean

.PHONY: dependencies
dependencies: ## Update dependencies
	@$(call print_color_message,"Update dependencies")
	$(FLUTTER) pub get

.PHONY: format
format: ## Format code by default lib directory
	@$(call print_color_message,"Format code by default lib directory")
	$(FLUTTER) format $(REPOSITORIES)

.PHONY: analyze
analyze: ## Analyze Dart code of the project
	@$(call print_color_message,"Analyze Dart code of the project")
	$(FLUTTER) analyze .

.PHONY: format-analyze
format-analyze: format analyze ## Format & Analyze Dart code of the project

.PHONY: run
run: ## Run application by default debug version
	@$(call print_color_message,"Run application by default debug version")
	$(FLUTTER) run $(RUN_VERSION)

.PHONY: devtools
devtools: ## Serving DevTools
	@$(call print_color_message,"Serving DevTools")
	$(FLUTTER) pub global run devtools

##
## ---------------------------------------------------------------
## scrcpy
## ---------------------------------------------------------------
##

.PHONY: mirror
mirror: ## Mirror screen (using scrcpy)
	@$(call print_color_message,"Mirror screen (using scrcpy)")
	scrcpy --max-size 1024 --window-title 'My device'

.PHONY: record
record: ## Record screen (using scrcpy)
	@$(call print_color_message,"Record screen (using scrcpy)")
	scrcpy --max-size 1024 --no-display --record "flutter_$(shell date +%Y%m%d-%H%M%S).mp4"

#
# ----------------------------------------------------------------
# Help
# ----------------------------------------------------------------
#

.DEFAULT_GOAL := help
.PHONY: help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN_COLOR)%-30s$(NO_COLOR) %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
