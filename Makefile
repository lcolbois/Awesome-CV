.PHONY: all clean cleantemp app help

# 1. CONFIGURATION
SRCDIR = applications
CONTENTDIR = sections
OUTDIR = builds
# The "messy" files go here (hidden from view)
AUXDIR = $(OUTDIR)/temp

# 2. LATEXMK CONFIGURATION
# -pdf       : Generate PDF
# -lualatex  : Use LuaLaTeX
# -outdir    : Output all intermediate files to the temp folder
# -interaction=nonstopmode : Don't stop for errors
LATEXMK = latexmk -pdf -lualatex -outdir=$(AUXDIR) -interaction=nonstopmode

# 3. FILE DISCOVERY (Automatic)
# Finds all .tex files to build the default "all" target
SOURCES := $(wildcard $(SRCDIR)/*.tex)
TARGETS := $(patsubst $(SRCDIR)/%.tex,$(OUTDIR)/%.pdf,$(SOURCES))
CONTENT_SRCS := $(shell find $(CONTENTDIR) -name '*.tex')

# 4. BUILD RULES

# Default: Build everything
all: $(TARGETS)

# Shortcut: Build a specific application by ID
# Usage: make app ID=2026_Google
app:
ifndef ID
	$(error Please specify an ID. Usage: make app ID=2026_Google)
endif
	@$(MAKE) $(OUTDIR)/$(ID)_cv.pdf
	@# Only try to build the cover letter if the source file actually exists
	@if [ -f $(SRCDIR)/$(ID)_cl.tex ]; then \
		$(MAKE) $(OUTDIR)/$(ID)_cl.pdf; \
	fi

# Generic Rule: How to build ANY pdf from ANY tex
$(OUTDIR)/%.pdf: $(SRCDIR)/%.tex $(CONTENT_SRCS)
	@mkdir -p $(AUXDIR)
	@mkdir -p $(OUTDIR)
	# 1. Build into temp folder
	$(LATEXMK) $<
	# 2. Copy final PDF to output folder
	@cp $(AUXDIR)/$(notdir $@) $@
	@cp $(AUXDIR)/$(notdir $(basename $@)).synctex.gz $(OUTDIR)/ 2>/dev/null || true
	@echo "--------------------------------------------------"
	@echo "Build successful: $@"
	@echo "--------------------------------------------------"

# 5. CLEANING RULES

# Clean EVERYTHING (PDFs + Temp files)
clean:
	rm -rf $(OUTDIR)

# Clean ONLY the temp files (Keep the PDFs)
cleantemp:
	rm -rf $(AUXDIR)
	@echo "Temporary files removed. PDFs are safe in $(OUTDIR)/"

# Help command to remind you how to use this
help:
	@echo "Available commands:"
	@echo "  make                  : Build ALL applications found in $(SRCDIR)"
	@echo "  make app ID=Name      : Build only Name_cv.pdf and Name_cl.pdf"
	@echo "  make cleantemp        : Delete auxiliary files, keep PDFs"
	@echo "  make clean            : Delete everything (PDFs included)"