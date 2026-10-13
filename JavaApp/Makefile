SHELL := /bin/bash
.SHELLFLAGS = -ec

# Prerequisite variables
SOURCEDIR := src
OUTPUTDIR := build

SOURCES := $(shell find $(SOURCEDIR) -type f -name '*.java')
CLASSES := $(SOURCES:$(SOURCEDIR)/%.java=$(OUTPUTDIR)/%.class)

TARGETS := $(shell find $(SOURCEDIR) -mindepth 1 -maxdepth 1 -type d)
TARGETS := $(filter-out $(OUTPUTDIR)/lwjgl.jar,$(TARGETS:$(SOURCEDIR)/%=$(OUTPUTDIR)/%.jar))
LWJGL_VERSION_TABLE := $(shell sed -n 's/^ *X("\([^"]*\)", "\([^"]*\)", "\([^"]*\)").*/\1:\2:\3/p' ../Natives/lwjgl_versions.h)
LWJGL_VERSIONS := $(foreach entry,$(LWJGL_VERSION_TABLE),$(word 1,$(subst :, ,$(entry))))
LWJGL_JARS := $(foreach version,$(LWJGL_VERSIONS),$(OUTPUTDIR)/lwjgl-$(version).jar)
LWJGL_LATEST_VERSION := $(lastword $(LWJGL_VERSIONS))

# Add all jars to classpath and allow compiling with private API.
# This remains the normal classpath for the existing launcher and
# LWJGL 3.3.3 sources.
JCFLAGS := -cp "$(subst $() $(),:,$(wildcard $(SOURCEDIR)/*/):$(wildcard libs/*/*.jar))" -XDignore.symbol.file -implicit:none

# SDL3 builds against the newest bundled LWJGL core.
SDL_JCFLAGS := -cp "$(subst $() $(),:,$(wildcard $(SOURCEDIR)/*/):$(wildcard libs/lwjgl-$(LWJGL_LATEST_VERSION)/*.jar))" -XDignore.symbol.file -implicit:none

all: $(TARGETS) $(LWJGL_JARS)

# Sometimes the CI produces empty class file resulting in broken jar, so we check and abort here
check_empty_classes:
	@set -e
	@echo "Checking for empty class files"
	$(eval EMPTY_CLASSES := $(shell find $(OUTPUTDIR) -name '*.class' -size 0))
	@if [ -n "$(EMPTY_CLASSES)" ]; then \
		echo "Error: found empty class files in $@: $(EMPTY_CLASSES)"; \
		exit 1; \
	fi

# Rules for building java class
$(CLASSES): $(OUTPUTDIR)/%.class: $(SOURCEDIR)/%.java
	@set -e
	$(eval TARGET=$(word 2, $(subst /, ,$@)))
	@mkdir -p $(OUTPUTDIR)/classes
	@mkdir -p $(dir $@)
	@echo "Compiling $<"
	@if [[ "$<" == $(SOURCEDIR)/lwjgl/org/lwjgl/sdl/* ]]; then \
		echo "Using LWJGL $(LWJGL_LATEST_VERSION) classpath for SDL3: $<"; \
		$(BOOTJDK)/javac $(SDL_JCFLAGS) -d $(OUTPUTDIR)/classes $<; \
	else \
		$(BOOTJDK)/javac $(JCFLAGS) -d $(OUTPUTDIR)/classes $<; \
	fi
	@cp $(@:$(OUTPUTDIR)/$(TARGET)/%.class=$(OUTPUTDIR)/classes/%*.class) $(dir $@)/

$(OUTPUTDIR)/launcher.jar: $(CLASSES) check_empty_classes
	@set -e
	@echo "Creating $@"
	@$(BOOTJDK)/jar -cf $@ -C $(basename $@) .

$(OUTPUTDIR)/lwjgl-%.jar: $(CLASSES) check_empty_classes
	@set -e
	@echo "Creating $@"
	@mkdir -p $(OUTPUTDIR)/lwjgl_lib_$*
	@cd $(OUTPUTDIR)/lwjgl_lib_$* && find ../../libs/lwjgl-$* -name 'lwjgl*.jar' -exec $(BOOTJDK)/jar -xf {} \;
	@rm -rf $(OUTPUTDIR)/lwjgl_lib_$*/META-INF
	@cp -R $(OUTPUTDIR)/lwjgl/. $(OUTPUTDIR)/lwjgl_lib_$*/
	@$(BOOTJDK)/jar -cf $@ -C $(OUTPUTDIR)/lwjgl_lib_$* .

$(OUTPUTDIR)/patchjna_agent.jar: $(CLASSES)
	@set -e
	@mv $(basename $@)/com/sun/jna/Platform.class $(basename $@)/com/sun/jna/Platform.class.patch
	@echo "Creating $@"
	@$(BOOTJDK)/jar -cfm $@ $(SOURCEDIR)/patchjna_agent.txt -C $(basename $@) .

clean:
	rm -rf $(OUTPUTDIR)

.SUFFIXES: .java
.PHONY: all clean
