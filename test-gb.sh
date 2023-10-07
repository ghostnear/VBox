#!/bin/bash

prime-run v run . ./configs/example-gameboy.json

cd gameboy-doctor

./gameboy-doctor ./vbox.log cpu_instrs 07