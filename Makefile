.PHONY: preview publish

# Fully renders every page before serving, avoiding a quarto preview race
# where the pre-render scripts (which redownload/regenerate data on every
# on-demand render) can bounce an in-flight nav click back to the previous
# page. See README.md "Local development".
preview:
	quarto preview --render all

# Renders and pushes the site to the gh-pages branch.
publish:
	quarto publish gh-pages
