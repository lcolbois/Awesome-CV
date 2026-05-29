.PHONY: all clean cleantemp app base master help list new check diff

# 1. CONFIGURATION
APPDIR = applications
BASEDIR = _base
SHAREDDIR = shared

# 2. LATEXMK CONFIGURATION
LATEXMK_BASE = latexmk -pdf -lualatex -synctex=1 -interaction=nonstopmode

# 3. FILE DISCOVERY
APP_DIRS := $(patsubst %/cv.tex,%,$(wildcard $(APPDIR)/*/cv.tex))
SHARED_SRCS := $(shell find $(SHAREDDIR) -name '*.tex' -o -name '*.png' -o -name '*.jpg' 2>/dev/null)

# 4. BUILD RULES

# Default: Build all applications
all: $(addsuffix /build/cv.pdf,$(APP_DIRS))
	@echo "All applications built."

# List available applications
list:
	@echo "Available applications:"
	@for dir in $(APP_DIRS); do echo "  - $$(basename $$dir)"; done

# Build the canonical _base template (smoke test)
base:
	@mkdir -p $(BASEDIR)/build
	cd $(BASEDIR) && $(LATEXMK_BASE) -outdir=build cv.tex
	@if [ -f $(BASEDIR)/cl.tex ]; then \
		cd $(BASEDIR) && $(LATEXMK_BASE) -outdir=build cl.tex; \
	fi
	@echo "--------------------------------------------------"
	@echo "Base template built in $(BASEDIR)/build/"
	@echo "--------------------------------------------------"

# Build a specific application by ID
# Usage: make app ID=bfh_ai_expert
app:
ifndef ID
	$(error Please specify an ID. Usage: make app ID=bfh_ai_expert)
endif
	@$(MAKE) $(APPDIR)/$(ID)/build/cv.pdf
	@if [ -f $(APPDIR)/$(ID)/cl.tex ]; then \
		$(MAKE) $(APPDIR)/$(ID)/build/cl.pdf; \
	fi

# Build legacy master templates from shared/
master:
	@mkdir -p $(SHAREDDIR)/build
	$(LATEXMK_BASE) -outdir=$(SHAREDDIR)/build $(SHAREDDIR)/master_cv.tex
	$(LATEXMK_BASE) -outdir=$(SHAREDDIR)/build $(SHAREDDIR)/master_cl.tex
	@echo "--------------------------------------------------"
	@echo "Master templates built in $(SHAREDDIR)/build/"
	@echo "--------------------------------------------------"

# Create a new application from _base (or fork an existing app)
# Usage: make new ID=company_role [FROM=existing_app]
new:
ifndef ID
	$(error Please specify an ID. Usage: make new ID=company_role [FROM=existing_app])
endif
	@if [ -d $(APPDIR)/$(ID) ]; then \
		echo "Error: Application '$(ID)' already exists."; \
		exit 1; \
	fi
	@if [ -n "$(FROM)" ]; then \
		SOURCE=$(APPDIR)/$(FROM); \
	else \
		SOURCE=$(BASEDIR); \
	fi; \
	if [ ! -d "$$SOURCE" ]; then \
		echo "Error: Source directory '$$SOURCE' does not exist."; \
		exit 1; \
	fi; \
	echo "Creating application '$(ID)' from $$SOURCE ..."; \
	mkdir -p $(APPDIR)/$(ID)/build; \
	for f in meta.tex summary.tex experience.tex skills.tex education.tex publications.tex cl.tex cv.tex offer.md profile_small.jpg; do \
		src="$$SOURCE/$$f"; \
		if [ -f "$$src" ] && [ ! -L "$$src" ]; then \
			cp "$$src" "$(APPDIR)/$(ID)/$$f"; \
		fi; \
	done; \
	ln -sf ../../awesome-cv.cls $(APPDIR)/$(ID)/awesome-cv.cls; \
	ln -sf ../../profile.jpg $(APPDIR)/$(ID)/profile.jpg; \
	echo "--------------------------------------------------"; \
	echo "Created: $(APPDIR)/$(ID)/"; \
	echo "  1. Edit meta.tex with company name, job title, position"; \
	echo "  2. Customize summary.tex, experience.tex, skills.tex"; \
	echo "  3. Fill offer.md with the job description"; \
	echo "  4. Run: make app ID=$(ID)"; \
	echo "--------------------------------------------------"
	@$(MAKE) check ID=$(ID)

# Check for unfilled placeholders and copy-paste hazards
# Usage: make check [ID=name]   (omit ID to check all apps)
PLACEHOLDERS = COMPANY NAME JOB TITLE POSITION SUBTITLE ADDRESS LINE SPECIFIC REASON "Paste job description here" "\*\*\* CUSTOMIZE"
check:
ifdef ID
	@$(MAKE) _check_app CHECKDIR=$(APPDIR)/$(ID)
else
	@for dir in $(APP_DIRS); do \
		$(MAKE) _check_app CHECKDIR=$$dir; \
	done
endif

_check_app:
	@found=0; \
	for term in "COMPANY NAME" "JOB TITLE" "POSITION SUBTITLE" "ADDRESS LINE" "SPECIFIC REASON" "Paste job description here" "\*\*\* CUSTOMIZE"; do \
		matches=$$(grep -rls "$$term" "$(CHECKDIR)" 2>/dev/null | grep -E '\.(tex|md)$$'); \
		if [ -n "$$matches" ]; then \
			printf "WARN $(CHECKDIR): placeholder '%s' found in: %s\n" "$$term" "$$(echo $$matches | tr '\n' ' ')"; \
			found=1; \
		fi; \
	done; \
	if [ -f "$(CHECKDIR)/meta.tex" ] && [ -f "$(CHECKDIR)/offer.md" ]; then \
		company=$$(sed -n 's/.*\\appCompany}{\(.*\)}/\1/p' "$(CHECKDIR)/meta.tex" 2>/dev/null | head -1); \
		if [ -n "$$company" ] && [ "$$company" != "COMPANY NAME" ]; then \
			if ! grep -qi "$$company" "$(CHECKDIR)/offer.md" 2>/dev/null; then \
				echo "WARN $(CHECKDIR): '$$company' in meta.tex not found in offer.md — verify company name was updated after copying"; \
				found=1; \
			fi; \
		fi; \
	fi; \
	if [ "$$found" -eq 0 ]; then echo "OK   $(CHECKDIR)"; fi

# Show diff of an app's content sections against _base
# Usage: make diff ID=bfh_ai_expert
diff:
ifndef ID
	$(error Please specify an ID. Usage: make diff ID=bfh_ai_expert)
endif
	@echo "=== Diff: $(BASEDIR) → $(APPDIR)/$(ID) ==="
	@any=0; \
	for f in summary.tex experience.tex skills.tex education.tex publications.tex; do \
		base_f="$(BASEDIR)/$$f"; \
		app_f="$(APPDIR)/$(ID)/$$f"; \
		if [ -f "$$base_f" ] && [ -f "$$app_f" ]; then \
			d=$$(diff --label "_base/$$f" --label "$(ID)/$$f" "$$base_f" "$$app_f"); \
			if [ -n "$$d" ]; then \
				echo ""; \
				echo "$$d"; \
				any=1; \
			fi; \
		elif [ -f "$$app_f" ] && [ ! -f "$$base_f" ]; then \
			echo ""; \
			echo "--- (not in _base)"; \
			echo "+++ $(ID)/$$f  (app-only file)"; \
			any=1; \
		fi; \
	done; \
	if [ "$$any" -eq 0 ]; then echo "(no differences in content sections)"; fi

# Generic Rule: Build CV for any application
# Prints a banner when meta.tex is present (new-style apps)
$(APPDIR)/%/build/cv.pdf: $(APPDIR)/%/cv.tex $(wildcard $(APPDIR)/%/*.tex) $(SHARED_SRCS)
	@mkdir -p $(dir $@)
	@if [ -f $(APPDIR)/$*/meta.tex ]; then \
		company=$$(sed -n 's/.*\\appCompany}{\(.*\)}/\1/p' $(APPDIR)/$*/meta.tex | head -1); \
		jobtitle=$$(sed -n 's/.*\\appJobTitle}{\(.*\)}/\1/p' $(APPDIR)/$*/meta.tex | head -1); \
		echo ""; \
		echo "=================================================="; \
		echo "  Building CV: $$company / $$jobtitle"; \
		echo "=================================================="; \
	fi
	cd $(APPDIR)/$* && $(LATEXMK_BASE) -outdir=build cv.tex
	@echo "--------------------------------------------------"
	@echo "Build successful: $@"
	@echo "--------------------------------------------------"

# Generic Rule: Build Cover Letter for any application
$(APPDIR)/%/build/cl.pdf: $(APPDIR)/%/cl.tex $(wildcard $(APPDIR)/%/*.tex) $(SHARED_SRCS)
	@mkdir -p $(dir $@)
	@if [ -f $(APPDIR)/$*/meta.tex ]; then \
		company=$$(sed -n 's/.*\\appCompany}{\(.*\)}/\1/p' $(APPDIR)/$*/meta.tex | head -1); \
		jobtitle=$$(sed -n 's/.*\\appJobTitle}{\(.*\)}/\1/p' $(APPDIR)/$*/meta.tex | head -1); \
		echo ""; \
		echo "=================================================="; \
		echo "  Building CL: $$company / $$jobtitle"; \
		echo "=================================================="; \
	fi
	cd $(APPDIR)/$* && $(LATEXMK_BASE) -outdir=build cl.tex
	@echo "--------------------------------------------------"
	@echo "Build successful: $@"
	@echo "--------------------------------------------------"

# 5. CLEANING RULES

# Clean EVERYTHING (all build folders)
clean:
	rm -rf $(APPDIR)/*/build
	rm -rf $(SHAREDDIR)/build
	rm -rf $(BASEDIR)/build
	@echo "All build folders removed."

# Clean only auxiliary files, keep PDFs
cleantemp:
	@for dir in $(APP_DIRS); do \
		find $$dir/build -type f ! -name '*.pdf' -delete 2>/dev/null || true; \
	done
	@find $(SHAREDDIR)/build -type f ! -name '*.pdf' -delete 2>/dev/null || true
	@find $(BASEDIR)/build -type f ! -name '*.pdf' -delete 2>/dev/null || true
	@echo "Temporary files removed. PDFs are preserved."

# Help
help:
	@echo "Available commands:"
	@echo "  make                        : Build all applications"
	@echo "  make list                   : List available applications"
	@echo "  make new ID=name            : Create new application from _base"
	@echo "  make new ID=name FROM=other : Fork from an existing application"
	@echo "  make app ID=name            : Build only 'name' (cv + cl if present)"
	@echo "  make base                   : Build _base/ canonical template (smoke test)"
	@echo "  make check                  : Check all apps for placeholders/copy-paste hazards"
	@echo "  make check ID=name          : Check one application"
	@echo "  make diff ID=name           : Diff app content sections against _base"
	@echo "  make master                 : Build legacy shared master templates"
	@echo "  make cleantemp              : Delete auxiliary files, keep PDFs"
	@echo "  make clean                  : Delete all build folders"
