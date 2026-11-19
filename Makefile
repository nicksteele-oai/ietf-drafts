LIBDIR := lib
ID_TEMPLATE_REV := d2ce969b54014edf5671856b6866866c258bf8f5
BRANCH_FETCH ?= false
XML2RFC_REFCACHEDIR ?= $(CURDIR)/.refcache

-include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
	@set -eu; \
	tmp=$$(mktemp -d "$(LIBDIR).tmp.XXXXXX"); \
	trap 'rm -rf "$$tmp"' EXIT; \
	git -C "$$tmp" init -q; \
	git -C "$$tmp" remote add origin https://github.com/martinthomson/i-d-template.git; \
	git -C "$$tmp" fetch -q --depth 1 origin $(ID_TEMPLATE_REV); \
	git -C "$$tmp" checkout -q --detach FETCH_HEAD; \
	mv "$$tmp" "$(LIBDIR)"
