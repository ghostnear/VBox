### [Back to the main document.](../README.md)

# Gameboy

## Information used

- [emudev.org](https://emudev.org/)
- [Gameboy test ROMs suite](https://github.com/c-sp/gameboy-test-roms)
- [Algorithmically decode opcodes](https://gb-archive.github.io/salvage/decoding_gbz80_opcodes/Decoding%20Gamboy%20Z80%20Opcodes.html)

## Test results:

- Blargg’s test ROMs
    - cpu_instrs
        - individual
            - [ ] 01-special.gb
                - Mismatch in CPU state at line 148318 (previous opcode: 0xF1 POP AF)
            - [ ] 02-interrupts.gb
                - unimplemented interrupts
            - [ ] 03-op sp,hl.gb
                - unimplemented opcode
            - [x] 04-op r,imm.gb
            - [x] 05-op rp.gb
            - [x] 06-ld r,r.gb
            - [ ] 07-jr,jp,call,ret,rst.gb
                - Mismatch in CPU state at line 205978 (previous opcode: 0xF1 POP AF)
                - unimplemented opcode
            - [ ] 08-misc instrs.gb
                - Mismatch in CPU state at line 208109 (previous opcode: 0xF1 POP AF)
            - [x] 09-op r,r.gb
            - [x] 10-bit ops.gb
            - [ ] 11-op a,(hl).gb
                - unimplemented opcode