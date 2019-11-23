MK_LIVESTATUS := mk-livestatus
MK_LIVESTATUS_DIR := $(MK_LIVESTATUS)-$(CMK_VERSION)

# Attention: copy-n-paste from check_mk/Makefile below...
MK_LIVESTATUS_BUILD := $(BUILD_HELPER_DIR)/$(MK_LIVESTATUS_DIR)-build
MK_LIVESTATUS_UNPACK := $(BUILD_HELPER_DIR)/$(MK_LIVESTATUS_DIR)-unpack
MK_LIVESTATUS_INSTALL := $(BUILD_HELPER_DIR)/$(MK_LIVESTATUS_DIR)-install
MK_LIVESTATUS_PACKAGE := $(PACKAGE_DIR)/$(MK_LIVESTATUS)/$(MK_LIVESTATUS_DIR).tar.gz

#MK_LIVESTATUS_INSTALL_DIR := $(INTERMEDIATE_INSTALL_BASE)/$(MK_LIVESTATUS_DIR)
MK_LIVESTATUS_BUILD_DIR := $(PACKAGE_BUILD_DIR)/$(MK_LIVESTATUS_DIR)
#MK_LIVESTATUS_WORK_DIR := $(PACKAGE_WORK_DIR)/$(MK_LIVESTATUS_DIR)

.PHONY: $(MK_LIVESTATUS) $(MK_LIVESTATUS)-build $(MK_LIVESTATUS)-install $(MK_LIVESTATUS)-skel $(MK_LIVESTATUS)-clean

$(MK_LIVESTATUS): $(MK_LIVESTATUS_BUILD)
$(MK_LIVESTATUS)-install: $(MK_LIVESTATUS_INSTALL)
$(MK_LIVESTATUS)-build: $(MK_LIVESTATUS_BUILD)

$(MK_LIVESTATUS_PACKAGE):
	$(MAKE) -C $(REPO_PATH) omd/packages/mk-livestatus/$(MK_LIVESTATUS_DIR).tar.gz

$(MK_LIVESTATUS_UNPACK): $(MK_LIVESTATUS_PACKAGE)
	$(RM) -r $(BUILD_HELPER_DIR)/$*
	$(MKDIR) $(PACKAGE_BUILD_DIR)
	$(TAR_GZ) $< -C $(PACKAGE_BUILD_DIR)
	$(MKDIR) $(BUILD_HELPER_DIR)
	$(TOUCH) $@

$(MK_LIVESTATUS_BUILD): $(MK_LIVESTATUS_UNPACK) $(RE2_BUILD) $(RRDTOOL_BUILD_LIBRARY)
	cd $(MK_LIVESTATUS_BUILD_DIR) ; \
	    ./configure CXXFLAGS="-g -O3 -Wall -Wextra" --with-re2=$(PACKAGE_RE2_DESTDIR) --prefix=$(OMD_ROOT)
	unset DESTDIR MAKEFLAGS ; \
	    $(MAKE) -C $(MK_LIVESTATUS_BUILD_DIR) \
		PACKAGE_GOOGLETEST=$(PACKAGE_DIR)/googletest \
		PACKAGE_ASIO=$(PACKAGE_DIR)/asio \
		RRDTOOL_SRC_DIR=$(RRDTOOL_BUILD_DIR)/src \
		all
	$(TOUCH) $@

$(MK_LIVESTATUS_INSTALL): $(MK_LIVESTATUS_BUILD)
	$(MAKE) -j1 \
	    -C $(MK_LIVESTATUS_BUILD_DIR) \
	    DESTDIR=$(DESTDIR) \
	    PACKAGE_GOOGLETEST=$(PACKAGE_DIR)/googletest \
	    PACKAGE_ASIO=$(PACKAGE_DIR)/asio \
	    RRDTOOL_SRC_DIR=$(RRDTOOL_BUILD_DIR)/src \
	    install
	$(MKDIR) $(DESTDIR)$(OMD_ROOT)/bin
	install -m 755 $(PACKAGE_DIR)/$(MK_LIVESTATUS)/lq $(DESTDIR)$(OMD_ROOT)/bin
	$(MKDIR) $(DESTDIR)$(OMD_ROOT)/lib/python
	install -m 644 $(MK_LIVESTATUS_BUILD_DIR)/api/python/livestatus.py $(DESTDIR)$(OMD_ROOT)/lib/python
	$(MKDIR) $(DESTDIR)$(OMD_ROOT)/lib/omd/hooks
	install -m 755 $(PACKAGE_DIR)/$(MK_LIVESTATUS)/LIVESTATUS_TCP $(DESTDIR)$(OMD_ROOT)/lib/omd/hooks/
	install -m 755 $(PACKAGE_DIR)/$(MK_LIVESTATUS)/LIVESTATUS_TCP_ONLY_FROM $(DESTDIR)$(OMD_ROOT)/lib/omd/hooks/
	install -m 755 $(PACKAGE_DIR)/$(MK_LIVESTATUS)/LIVESTATUS_TCP_PORT $(DESTDIR)$(OMD_ROOT)/lib/omd/hooks/
	install -m 755 $(PACKAGE_DIR)/$(MK_LIVESTATUS)/LIVESTATUS_TCP_TLS $(DESTDIR)$(OMD_ROOT)/lib/omd/hooks/
	$(TOUCH) $@

$(MK_LIVESTATUS)-skel:

$(MK_LIVESTATUS)-clean:
	$(RM) -r $(MK_LIVESTATUS_BUILD_DIR) $(BUILD_HELPER_DIR)/$(MK_LIVESTATUS)*
