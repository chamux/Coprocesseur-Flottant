SRC_DIR= 	../src/

SRC= $(wildcard $(SRC_DIR)/*.sv)

all: compile


compile : $(patsubst $(SRC_DIR)/%.sv,comp-%,$(SRC))


comp-%: $(SRC_DIR)%.sv
	vlog +acc $<

