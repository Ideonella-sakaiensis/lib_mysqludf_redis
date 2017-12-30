# lib_mysqludf_redis dependency Makefile

HIREDIS_MODULE_VER ?=
CJSON_MODULE_VER   ?=
INSTALL_PATH       ?=
INSTALL_OPTIONS=
ifneq ("","$(INSTALL_PATH)")
  INSTALL_OPTIONS=PREFIX=$(INSTALL_PATH)
endif

CCCOLOR  ="\033[34m"
LINKCOLOR="\033[34;1m"
SRCCOLOR ="\033[33m"
BINCOLOR ="\033[37;1m"
MAKECOLOR="\033[32;1m"
ENDCOLOR ="\033[0m"




default:
	@echo "Explicit target required"

.PHONY: default



hiredis:
ifeq ("","$(wildcard hiredis)")
  ifeq ("","$(HIREDIS_MODULE_VER)")
	$(error required HIREDIS_MODULE_VER)
  endif
	sh download-hiredis.sh $(HIREDIS_MODULE_VER)
endif
	@printf '%b %b\n' $(MAKECOLOR)MAKE$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR)
	cd hiredis && $(MAKE)
	@printf '%b %b\n' $(LINKCOLOR)INSTALL$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR)
	cd hiredis && $(MAKE) install $(INSTALL_OPTIONS)

.PHONY: hiredis



cJSON:
ifeq ("","$(wildcard cJSON)")
  ifeq ("","$(CJSON_MODULE_VER)")
	$(error required CJSON_MODULE_VER)
  endif
	sh download-cJSON.sh $(CJSON_MODULE_VER)
endif
	@printf '%b %b\n' $(MAKECOLOR)MAKE$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR)
	cd cJSON && $(MAKE)
	@printf '%b %b\n' $(LINKCOLOR)INSTALL$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR)
	cd cJSON && $(MAKE) install $(INSTALL_OPTIONS)

.PHONY: cJSON



distclean:
	-rm -rf hiredis cJSON

.PHONY: distclean
