
CC = gcc
KVER  := $(shell uname -r)
KSRC := /lib/modules/$(KVER)/build
MODDESTDIR := /lib/modules/$(KVER)/kernel/drivers/net/wireless/rtlwifi
FIRMWAREDIR := /lib/firmware/
PWD := $(shell pwd)
CLR_MODULE_FILES := *.mod.c *.mod *.o .*.cmd *.ko *~ .tmp_versions* modules.order Module.symvers
SYMBOL_FILE := Module.symvers

EXTRA_CFLAGS += -O2
obj-m := rtlwifi.o
PCI_MAIN_OBJS	:= base.o	\
		rc.o	\
		debug.o	\
		regd.o	\
		efuse.o	\
		cam.o	\
		ps.o	\
		core.o	\
		stats.o	\
		pci.o	\

rtlwifi-objs += $(PCI_MAIN_OBJS)

all: 
	$(MAKE) -C $(KSRC) M=$(PWD) modules
	@cp $(SYMBOL_FILE) btcoexist/
	@make -C btcoexist/
	@cp $(SYMBOL_FILE) rtl8723be/
	@cp btcoexist/$(SYMBOL_FILE) rtl8723be/
	@make -C rtl8723be/
install: all
	find /lib/modules/$(shell uname -r) -name "btcoexist_*.ko" -exec rm {} \;
	find /lib/modules/$(shell uname -r) -name "r8723be_*.ko" -exec rm {} \;
	@rm -fr $(FIRMWAREDIR)/`uname -r`/rtlwifi

	$(shell rm -fr $(MODDESTDIR))
	$(shell mkdir $(MODDESTDIR))
	$(shell mkdir $(MODDESTDIR)/btcoexist)
	$(shell mkdir $(MODDESTDIR)/rtl8723be)
	@install -p -m 644 rtlwifi.ko $(MODDESTDIR)	
	@install -p -m 644 ./btcoexist/btcoexist.ko $(MODDESTDIR)/btcoexist
	@install -p -m 644 ./rtl8723be/rtl8723be.ko $(MODDESTDIR)/rtl8723be
	
	@depmod -a

	@#copy firmware img to target fold
	@#$(shell [ -d "$(FIRMWAREDIR)/`uname -r`" ] && cp -fr firmware/rtlwifi/ $(FIRMWAREDIR)/`uname -r`/.)
	@#$(shell [ ! -d "$(FIRMWAREDIR)/`uname -r`" ] && cp -fr firmware/rtlwifi/ $(FIRMWAREDIR)/.)
	@cp -fr firmware/rtlwifi/ $(FIRMWAREDIR)/

uninstall:
	$(shell [ -d "$(MODDESTDIR)" ] && rm -fr $(MODDESTDIR))
	
	@depmod -a
	
	@#delete the firmware img
	@rm -fr /lib/firmware/rtlwifi/
	@rm -fr /lib/firmware/`uname -r`/rtlwifi/

clean:
	rm -fr *.mod.c *.mod *.o .*.cmd *.ko *~
	rm -fr .tmp_versions
	rm -fr Modules.symvers
	rm -fr Module.symvers
	rm -fr Module.markers
	rm -fr modules.order
	rm -fr tags
	@find -name "tags" -exec rm {} \;
	@rm -fr $(CLR_MODULE_FILES)
	@make -C btcoexist/ clean
	@make -C rtl8723be/ clean
