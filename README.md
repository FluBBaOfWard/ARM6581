# ARM6581 V0.2.0
A MOS 6581 "SID" (Sound Interface Device) chip emulator for ARM32.

First you need to allocate space for the chip core state, either by using the struct from C or allocating/reserving memory using the "m6581Size"
Next call m6581Init with a pointer to that memory.
