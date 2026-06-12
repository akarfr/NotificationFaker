TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NotificationFaker
NotificationFaker_FILES = Tweak.x
NotificationFaker_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = NotificationFakerPrefs
NotificationFakerPrefs_FILES = NotificationFakerPrefs/NotificationFakerPrefs.m
NotificationFakerPrefs_INSTALL_PATH = $(THEOS_PACKAGE_INSTALL_PREFIX)/Library/PreferenceBundles
NotificationFakerPrefs_RESOURCE_DIRS = NotificationFakerPrefs/Resources
NotificationFakerPrefs_CFLAGS = -fobjc-arc
NotificationFakerPrefs_FRAMEWORKS = UIKit
NotificationFakerPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk
