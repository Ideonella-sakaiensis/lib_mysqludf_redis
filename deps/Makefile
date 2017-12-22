# lib_mysqludf_redis dependency Makefile

HIREDIS_MODULE_VER ?=
CJSON_MODULE_VER   ?=
INSTALL_PATH       ?=
INSTALL_OPTIONS=
ifneq ("","$(INSTALL_PATH)")
  INSTALL_OPTIONS=PREFIX=$(INSTALL_PATH)
endif



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
	cd hiredis && $(MAKE) && $(MAKE) install $(INSTALL_OPTIONS)


.PHONY: hiredis


cJSON:
ifeq ("","$(wildcard cJSON)")
  ifeq ("","$(CJSON_MODULE_VER)")
	$(error required CJSON_MODULE_VER)
  endif
	sh download-cJSON.sh $(CJSON_MODULE_VER)
endif
	cd cJSON && $(MAKE) && $(MAKE) install $(INSTALL_OPTIONS)

.PHONY: cJSON

