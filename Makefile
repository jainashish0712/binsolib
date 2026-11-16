TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VibeManager

VibeManager_FILES = VibeManager.mm
VibeManager_CFLAGS = -fobjc-arc -O3 -std=c++17
VibeManager_FRAMEWORKS = Foundation QuartzCore UIKit
VibeManager_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/tweak.mk
