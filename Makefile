
ARCHS = arm64 arm64e

MOBILE_THEOS=1
ifeq ($(MOBILE_THEOS),1)
  # path to you
  SDK_PATH = $(THEOS)/sdks/iPhoneOS11.2.sdk/
  $(info ===> Setting SYSROOT to $(SDK_PATH)...)
  SYSROOT = $(SDK_PATH)
else
  TARGET = iphone:clang:latest:8.0
endif

## Common frameworks ##
PROJ_COMMON_FRAMEWORKS = UIKit Foundation Security QuartzCore CoreGraphics CoreText

## source files ##
MEM_SRC = $(wildcard mem/*.c)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = @@PROJECTNAME@@

@@PROJECTNAME@@_CFLAGS = -fobjc-arc

@@PROJECTNAME@@_FILES = Tweak.x $(MEM_SRC) 

@@PROJECTNAME@@_LIBRARIES += substrate

@@PROJECTNAME@@_FRAMEWORKS = $(PROJ_COMMON_FRAMEWORKS)


include $(THEOS)/makefiles/tweak.mk


include $(THEOS)/makefiles/aggregate.mk
