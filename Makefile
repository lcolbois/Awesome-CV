.PHONY: all clean cleantemp app master help list new

# 1. CONFIGURATION
# New structure: applications/<app>/cv.tex, applications/<app>/cl.tex
# Output goes to: applications/<app>/build/
# Shared content: shared/
APPDIR = applications
SHAREDDIR = shared

# 2. LATEXMK CONFIGURATION
# -pdf       : Generate PDF
# -lualatex  : Use LuaLaTeX
# -synctex=1 : Generate SyncTeX file for editor synchronization
# -interaction=nonstopmode : Don't stop for errors
# Note: -outdir is set per-app in the build rule
LATEXMK_BASE = latexmk -pdf -lualatex -synctex=1 -interaction=nonstopmode

# 3. FILE DISCOVERY (Automatic)
# Find all application folders (those with cv.tex)
APP_DIRS := $(patsubst %/cv.tex,%,$(wildcard $(APPDIR)/*/cv.tex))
# Shared content dependencies
SHARED_SRCS := $(shell find $(SHAREDDIR) -name '*.tex' -o -name '*.png')

# 4. BUILD RULES

# Default: Build all applications
all: $(addsuffix /build/cv.pdf,$(APP_DIRS))
	@echo "All applications built."

# List available applications
list:
	@echo "Available applications:"
	@for dir in $(APP_DIRS); do echo "  - $$(basename $$dir)"; done

# Shortcut: Build a specific application by ID
# Usage: make app ID=bfh_ai_expert
app:
ifndef ID
	$(error Please specify an ID. Usage: make app ID=bfh_ai_expert)
endif
	@$(MAKE) $(APPDIR)/$(ID)/build/cv.pdf
	@# Only try to build the cover letter if the source file exists
	@if [ -f $(APPDIR)/$(ID)/cl.tex ]; then \
		$(MAKE) $(APPDIR)/$(ID)/build/cl.pdf; \
	fi

# Build master templates from shared/
master:
	@mkdir -p $(SHAREDDIR)/build
	$(LATEXMK_BASE) -outdir=$(SHAREDDIR)/build $(SHAREDDIR)/master_cv.tex
	$(LATEXMK_BASE) -outdir=$(SHAREDDIR)/build $(SHAREDDIR)/master_cl.tex
	@echo "--------------------------------------------------"
	@echo "Master templates built in $(SHAREDDIR)/build/"
	@echo "--------------------------------------------------"

# Create a new application from master templates
# Usage: make new ID=company_role
new:
ifndef ID
	$(error Please specify an ID. Usage: make new ID=company_role)
endif
	@if [ -d $(APPDIR)/$(ID) ]; then \
		echo "Error: Application '$(ID)' already exists."; \
		exit 1; \
	fi
	@echo "Creating new application: $(ID)"
	@mkdir -p $(APPDIR)/$(ID)/build
	@# Create symlinks
	@ln -s ../../awesome-cv.cls $(APPDIR)/$(ID)/awesome-cv.cls
	@ln -s ../../shared $(APPDIR)/$(ID)/shared
	@# Copy and adapt master templates
	@sed 's|\\input{./|\\input{./shared/|g; s|{./profile.jpg}|{./shared/profile.jpg}|g' $(SHAREDDIR)/master_cv.tex > $(APPDIR)/$(ID)/cv.tex
	@sed 's|\\input{./|\\input{./shared/|g; s|{./profile.jpg}|{./shared/profile.jpg}|g' $(SHAREDDIR)/master_cl.tex > $(APPDIR)/$(ID)/cl.tex
	@# Create placeholder app-specific sections (copy from shared as starting point)
	@cp $(SHAREDDIR)/summary.tex $(APPDIR)/$(ID)/summary.tex
	@cp $(SHAREDDIR)/experience.tex $(APPDIR)/$(ID)/experience.tex
	@cp $(SHAREDDIR)/skills.tex $(APPDIR)/$(ID)/skills.tex
	@# Update CV to use local summary/experience/skills
	@sed -i 's|\\input{./shared/summary.tex}|\\input{./summary.tex}|g' $(APPDIR)/$(ID)/cv.tex
	@sed -i 's|\\input{./shared/experience.tex}|\\input{./experience.tex}|g' $(APPDIR)/$(ID)/cv.tex
	@sed -i 's|\\input{./shared/skills.tex}|\\input{./skills.tex}|g' $(APPDIR)/$(ID)/cv.tex
	@# Create empty offer.md
	@echo "# $(ID)" > $(APPDIR)/$(ID)/offer.md
	@echo "" >> $(APPDIR)/$(ID)/offer.md
	@echo "## Job Description" >> $(APPDIR)/$(ID)/offer.md
	@echo "" >> $(APPDIR)/$(ID)/offer.md
	@echo "(Paste job description here)" >> $(APPDIR)/$(ID)/offer.md
	@echo "--------------------------------------------------"
	@echo "Created new application: $(APPDIR)/$(ID)/"
	@echo ""
	@echo "Files created:"
	@echo "  - cv.tex          (main CV, edit to customize)"
	@echo "  - cl.tex          (cover letter template)"
	@echo "  - summary.tex     (customize your summary)"
	@echo "  - experience.tex  (customize experience)"
	@echo "  - skills.tex      (customize skills)"
	@echo "  - offer.md        (paste job description)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Edit offer.md with the job description"
	@echo "  2. Customize summary.tex, experience.tex, skills.tex"
	@echo "  3. Edit cv.tex and cl.tex as needed"
	@echo "  4. Run: make app ID=$(ID)"
	@echo "--------------------------------------------------"

# Generic Rule: Build CV for any application
$(APPDIR)/%/build/cv.pdf: $(APPDIR)/%/cv.tex $(wildcard $(APPDIR)/%/*.tex) $(SHARED_SRCS)
	@mkdir -p $(dir $@)
	# Build from the application directory so relative paths work
	cd $(APPDIR)/$* && $(LATEXMK_BASE) -outdir=build cv.tex
	@echo "--------------------------------------------------"
	@echo "Build successful: $@"
	@echo "--------------------------------------------------"

# Generic Rule: Build Cover Letter for any application
$(APPDIR)/%/build/cl.pdf: $(APPDIR)/%/cl.tex $(wildcard $(APPDIR)/%/*.tex) $(SHARED_SRCS)
	@mkdir -p $(dir $@)
	# Build from the application directory so relative paths work
	cd $(APPDIR)/$* && $(LATEXMK_BASE) -outdir=build cl.tex
	@echo "--------------------------------------------------"
	@echo "Build successful: $@"
	@echo "--------------------------------------------------"

# 5. CLEANING RULES

# Clean EVERYTHING (all build folders)
clean:
	rm -rf $(APPDIR)/*/build
	rm -rf $(SHAREDDIR)/build
	@echo "All build folders removed."

# Clean only auxiliary files, keep PDFs
cleantemp:
	@for dir in $(APP_DIRS); do \
		find $$dir/build -type f ! -name '*.pdf' -delete 2>/dev/null || true; \
	done
	@find $(SHAREDDIR)/build -type f ! -name '*.pdf' -delete 2>/dev/null || true
	@echo "Temporary files removed. PDFs are preserved."

# Help command
help:
	@echo "Available commands:"
	@echo "  make                  : Build all applications"
	@echo "  make list             : List available applications"
	@echo "  make new ID=name      : Create a new application from templates"
	@echo "  make app ID=name      : Build only 'name' (cv.pdf and cl.pdf if exists)"
	@echo "  make master           : Build master templates from shared/"
	@echo "  make cleantemp        : Delete auxiliary files, keep PDFs"
	@echo "  make clean            : Delete all build folders"
	@echo ""
	@echo "Examples:"
	@echo "  make new ID=google_swe        # Create new application"
	@echo "  make app ID=bfh_ai_expert     # Build existing application"
	@echo "  make applications/logitech_video/build/cv.pdf"