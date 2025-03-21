VERSION = 0.0.0
NAME = Ordos
NAMEFILE = $(shell echo $(NAME) | tr 'A-Z' 'a-z')

BUILD_DIR = build
KERNEL_DIR = kernel
INCLUDE_DIR = include
TEST_DIR = test
USER_DIR = user
LIB_DIR = lib

# lower case
TARGET = $(BUILD_DIR)/$(NAMEFILE)
TEST_TARGET_DIR = $(BUILD_DIR)/$(TEST_DIR)

DEBUG = 1
LOGLEVEL = 5		# 0: none, 1: error, 2: warning, 3: info, 4: debug 5: trace
BUILD_TRACE =

TESTER =

INCFLAGS = -I$(INCLUDE_DIR)

CFLAGS = -Wall -Werror -W -Wstrict-prototypes -Wmissing-prototypes -std=c23		\
					-mno-sse -fno-builtin -fno-pie -fno-pic -fno-stack-protector 				\
					-nostdinc -nostdlib -m32 $(INCFLAGS) 																\
					-D KVERSION=$(VERSION) -D KNAME=$(NAME) -D LOGLEVEL=$(LOGLEVEL)

ifneq ($(DEBUG),)
CFLAGS += -g -O0 -D DEBUG
else
CFLAGS += -Os
endif

ASFLAGS = $(CFLAGS) -D __ASM__

LDSCRIPT_TEMPLATE = kernel.ld.template
LDSCRIPT = $(BUILD_DIR)/kernel.ld
LDFLAGS = -z noexecstack

targets :=

# if BUILD_TRACE is set, set hide to empty, otherwise set it to @
ifeq ($(BUILD_TRACE),)
hide=@
else
hide=
endif

.PHONY: all clean qemu rebuild

all: $(TARGET)

# 	-------------------- LIB ----------------------
include lib/Makefile

targets += $(patsubst %.o, $(LIB_DIR)/%.o,$(lib_targets))
# 	-----------------------------------------------

# 	-------------------- KERNEL -------------------
include kernel/Makefile

targets += $(patsubst %.o, $(KERNEL_DIR)/%.o,$(kernel_targets))
# 	-----------------------------------------------

# 	-------------------- USER -------------------
include user/Makefile

targets += $(patsubst %.o, $(USER_DIR)/%.o,$(user_targets))
# 	-----------------------------------------------

# 	-------------------- FINAL --------------------
final_objs := $(patsubst %.o,$(BUILD_DIR)/%.o,$(targets))

$(LDSCRIPT): $(LDSCRIPT_TEMPLATE)
	@mkdir -p $(BUILD_DIR)
	$(hide)gcc -E -P $(INCFLAGS) - < $< > $@
	@echo "	[CP] $(LDSCRIPT)"

$(TARGET): $(final_objs) $(LDSCRIPT)
	$(hide)$(LD) $(LDFLAGS) -o $@ -T $(LDSCRIPT) $(final_objs) -Map $(TARGET).map
	@echo "	[LD] $(TARGET)"
# 	-----------------------------------------------

# 	-------------------- UTILS --------------------
ifneq ($(DEBUG),)
qemu: $(TARGET)
	qemu-system-i386 -s -S -drive format=raw,file=$(TARGET)
else
qemu: $(TARGET)
	qemu-system-i386 -drive format=raw,file=$(TARGET)
endif

clean:
	$(hide)rm -rf $(BUILD_DIR)
	@echo "	[RM] $(BUILD_DIR)"

rebuild: clean all
# 	-----------------------------------------------

# 	-------------------- TESTER -------------------
test_targets := $(filter-out $(KERNEL_DIR)/entry.o,$(targets))
test_targets += $(TEST_DIR)/tester.o
test_objs := $(patsubst %.o,$(BUILD_DIR)/%.o,$(test_targets))

include test/Makefile

test: $(patsubst %, $(TEST_TARGET_DIR)/%,$(test_entries))

# makefile remove them for unknown reason (at least idk)
# use this to prevent it
test_entry_objs := $(patsubst %, $(TEST_TARGET_DIR)/%.o,$(test_entries))
.PRECIOUS: $(test_entry_objs)

qemu_test: $(TEST_TARGET_DIR)/$(TESTER)
	qemu-system-i386 -drive format=raw,file=$(TEST_TARGET_DIR)/$(TESTER)
# 	-----------------------------------------------

# 	-------------------- RULES --------------------
$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(dir $@)
	$(hide)$(CC) $(ASFLAGS) -c $< -o $@
	@echo "	[AS] $<"

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(hide)$(CC) $(CFLAGS) -c $< -o $@
	@echo "	[CC] $<"

$(TEST_TARGET_DIR)/%: $(TEST_TARGET_DIR)/%.o $(LDSCRIPT) $(test_objs)
	$(hide)$(LD) $(LDFLAGS) -o $@ -T $(LDSCRIPT) $(test_objs) $<
	@echo "	[TESTER] $@"
# 	-----------------------------------------------