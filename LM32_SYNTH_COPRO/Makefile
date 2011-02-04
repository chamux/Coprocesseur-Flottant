export TOPDIR = $(shell pwd)

.PHONY: all clean software simu syn

all: syn

software:
	make all -C soft

simu: software
	make all -C simulation

syn: software
	make all -C target/syn

program:
	make -C target/syn program

clean:
	make clean -C soft
	make clean -C simulation
	make clean -C target/syn
