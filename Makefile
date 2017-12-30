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

CURRENT_PATH  =$(dir $(abspath $(lastword $(MAKEFILE_LIST))))



# Constant variants
CC       = gcc
CFLAGS  := -shared -fPIC
CRPATH   = -Wl,-rpath,$(PLUGIN_PATH)
COPTIONS = -I$(INCLUDE_PATH) -I./include $(CRPATH)


MAKE_CC=$(QUIET_CC)$(CC)
MAKE_LD=$(QUIET_LINK)$(CC)
MAKE_INSTALL=$(QUIET_INSTALL)$(INSTALL)


CCCOLOR  ="\033[34m"
LINKCOLOR="\033[34;1m"
SRCCOLOR ="\033[33m"
BINCOLOR ="\033[37;1m"
MAKECOLOR="\033[32;1m"
ENDCOLOR ="\033[0m"

ifndef V
QUIET_CC = @printf '    %b %b\n' $(CCCOLOR)CC$(ENDCOLOR) $(SRCCOLOR)$@$(ENDCOLOR) 1>&2;
QUIET_LINK = @printf '    %b %b\n' $(LINKCOLOR)LINK$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR) 1>&2;
QUIET_INSTALL = @printf '    %b %b\n' $(LINKCOLOR)INSTALL$(ENDCOLOR) $(BINCOLOR)$@$(ENDCOLOR) 1>&2;
endif


DYLIBSUFFIX=so
PLUGIN_LIBNAME=$(PLUGIN_NAME).$(DYLIBSUFFIX)


# Initialize variants
ifeq ("","$(PLUGIN_PATH)")
  PLUGIN_PATH=$(shell mysql_config --plugindir)
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
ifeq ("","$(PLUGIN_PATH)")
	@echo ""
	@echo "Cannot find Mysql/MariaDB plugin_dir. Please specified the PLUGIN_PATH argument and try again."
	@echo ""
	@false
else
	@echo "PLUGIN_PATH=$(PLUGIN_PATH)" > .makeconf
endif
	cp -a ./lib/libhiredis.*  $(PLUGIN_PATH)
	-(restorecon $(PLUGIN_PATH)/libhiredis.*)
	cp -a ./lib/libcjson.*  $(PLUGIN_PATH)
	-(restorecon $(PLUGIN_PATH)/libcjson.*)
	$(MAKE_CC) $(PLUGIN_SOURCE) $(DEP_LIBRARY) $(CFLAGS) $(COPTIONS) -o $@

hiredis:
	@(cd deps && $(MAKE) $@ HIREDIS_MODULE_VER=$(HIREDIS_MODULE_VER) INSTALL_PATH=$(CURRENT_PATH) INCLUDE_PATH=include/hiredis)

cJSON:
	@(cd deps && $(MAKE) $@ CJSON_MODULE_VER=$(CJSON_MODULE_VER) INSTALL_PATH=$(CURRENT_PATH) INCLUDE_PATH=include/cjson)

.PHONY: all



INSTALL?= cp -a
ifneq ("$(wildcard .makeconf)", "")
  PLUGIN_PATH=$(shell grep 'PLUGIN_PATH=' .makeconf | awk -F'=' '{print $$2}')
endif


install:
	$(INSTALL) $(PLUGIN_LIBNAME) $(PLUGIN_PATH)
	-(cd $(PLUGIN_PATH) && restorecon $(PLUGIN_LIBNAME))
	-(setsebool -P mysql_connect_any 1)
	@printf "\033[1;33m"
	@echo ""
	@echo "To register UDF, executing the following command:"
	@printf "\033[0m""\033[1m"
	@echo ""
	@echo "$(MAKE) installdb"
	@echo ""
	@printf "\033[0m"
.PHONY: install



MYSQL_PORT?=$(shell mysql_config --port)
MYSQL=mysql -P $(MYSQL_PORT) -u root -p

installdb:
	$(MYSQL) < install.sql

.PHONY: installdb



uninstalldb:
	$(MYSQL) < uninstall.sql

.PHONY: uninstalldb



clean:
	@-(rm -f .makeconf)
	-rm -f $(PLUGIN_LIBNAME)
	-rm -rf include lib

.PHONY: clean



distclean: clean
	-cd ./deps && $(MAKE) distclean

.PHONY: reset
