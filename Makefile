# lib_mysqludf_redis Makefile

PLUGIN_SOURCE = lib_mysqludf_redis.c
PLUGIN_NAME   = lib_mysqludf_redis


# Environment variants
WITH_COMPILE_HIREDIS ?=1
WITH_COMPILE_CJSON   ?=1
HIREDIS_MODULE_VER   ?=0.13.3
CJSON_MODULE_VER     ?=1.6.0

INCLUDE_PATH ?=/usr/include/mysql/server
PLUGIN_PATH  ?=
PLUGIN_SEARCH_PATH:=/usr/lib/mysql/plugin /usr/lib64/mysql/plugin

CURRENT_PATH  =$(dir $(abspath $(lastword $(MAKEFILE_LIST))))


# $(call get-plugin-path)
define get-plugin-path
$(strip 
  $(foreach p, $(PLUGIN_SEARCH_PATH),
    $(if $(wildcard $p),
      $p)))
endef



# Constant variants
CC       = gcc
CFLAGS  := -shared -fPIC
CRPATH   = -Wl,-rpath,$(PLUGIN_PATH)
COPTIONS = -I$(INCLUDE_PATH) -I./include $(CRPATH)

CCCOLOR  ="\033[34m"
LINKCOLOR="\033[34;1m"
SRCCOLOR ="\033[33m"
BINCOLOR ="\033[37;1m"
MAKECOLOR="\033[32;1m"
ENDCOLOR ="\033[0m"

DYLIBSUFFIX=so
PLUGIN_LIBNAME=$(PLUGIN_NAME).$(DYLIBSUFFIX)


# Initialize variants
ifeq ("","$(PLUGIN_PATH)")
  PLUGIN_PATH=$(call get-plugin-path)
endif
DEP_MODULES:=
DEP_LIBRARY:=
ifeq (1,$(WITH_COMPILE_HIREDIS))
  DEP_MODULES:=$(DEP_MODULES) hiredis
  DEP_LIBRARY:=$(DEP_LIBRARY) $(PLUGIN_PATH)/libhiredis.so
endif
ifeq (1,$(WITH_COMPILE_CJSON))
  DEP_MODULES:=$(DEP_MODULES) cJSON
  DEP_LIBRARY:=$(DEP_LIBRARY) $(PLUGIN_PATH)/libcjson.so
endif



all: $(PLUGIN_LIBNAME)

#Deps
$(PLUGIN_LIBNAME): $(DEP_MODULES)
	@echo "PLUGIN_PATH=$(PLUGIN_PATH)" > INSTALL
	cp -a ./lib/libhiredis.*  $(PLUGIN_PATH)
	-(restorecon $(PLUGIN_PATH)/libhiredis.*)
	cp -a ./lib/libcjson.*  $(PLUGIN_PATH)
	-(restorecon $(PLUGIN_PATH)/libcjson.*)
	$(CC) $(PLUGIN_SOURCE) $(DEP_LIBRARY) $(CFLAGS) $(COPTIONS) -o $@

hiredis:
	@(cd deps && $(MAKE) $@ HIREDIS_MODULE_VER=$(HIREDIS_MODULE_VER) INSTALL_PATH=$(CURRENT_PATH))

cJSON:
	@(cd deps && $(MAKE) $@ CJSON_MODULE_VER=$(CJSON_MODULE_VER) INSTALL_PATH=$(CURRENT_PATH))

.PHONY: all

INSTALL?= cp -a
ifneq ("$(wildcard INSTALL)", "")
  PLUGIN_PATH=$(shell grep 'PLUGIN_PATH=' INSTALL | awk -F'=' '{print $$2}')
endif

install:
	$(INSTALL) $(PLUGIN_LIBNAME) $(PLUGIN_PATH)
	-(cd $(PLUGIN_PATH) && restorecon $(PLUGIN_LIBNAME))
	-(setsebool -P mysql_connect_any 1)
	@echo ""
	@echo "To register UDF, running the following sql statement in Mysql/MariaDB."
	@echo ""
	@echo "CREATE FUNCTION \`redis\` RETURNS STRING SONAME 'lib_mysqludf_redis.so';"
	@echo ""


.PHONY: install

clean:
	@-(rm -f INSTALL)
	rm -f $(PLUGIN_LIBNAME)
	rm -rf include lib

.PHONY: clean
