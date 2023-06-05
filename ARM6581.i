
				;@ r0,r1,r2=temp regs
//	m6502nz		.req r3			;@ Bit 31=N, Z=1 if bits 0-7=0
	addy		.req r12		;@ Keep this at r12 (scratch for APCS)

	.struct 0					;@ Changes section so make sure it is set before real code.
m6581Start:
m6581StateStart:
m6581ch1freq:		.byte 0,0
m6581ch1pulsew:		.byte 0,0
m6581ch1ctrl:		.byte 0
m6581ch1ad:			.byte 0		;@ Attack/Decay
m6581ch1sr:			.byte 0		;@ Sustain/Release
m6581ch2freq:		.byte 0,0
m6581ch2pulsew:		.byte 0,0
m6581ch2ctrl:		.byte 0
m6581ch2ad:			.byte 0		;@ Attack/Decay
m6581ch2sr:			.byte 0		;@ Sustain/Release
m6581ch3freq:		.byte 0,0
m6581ch3pulsew:		.byte 0,0
m6581ch3ctrl:		.byte 0
m6581ch3ad:			.byte 0		;@ Attack/Decay
m6581ch3sr:			.byte 0		;@ Sustain/Release
m6581filterfreq:		.byte 0,0
m6581filterctrl:		.byte 0		;@ Filter
m6581filtermode:		.byte 0		;@ Filtermode/volume
m6581paddle1:		.byte 0
m6581paddle2:		.byte 0
m6581osc3rnd:		.byte 0
m6581env3out:		.byte 0
m6581unused:			.byte 0,0,0

m6581ch1counter:		.long 0
m6581ch2counter:		.long 0
m6581ch3counter:		.long 0
m6581ch1envelope:	.long 0
m6581ch2envelope:	.long 0
m6581ch3envelope:	.long 0
m6581ch1noise:		.long 0
m6581ch2noise:		.long 0
m6581ch3noise:		.long 0
m6581ch3noise_r:		.long 0
m6581End:

m6581Size = m6581End-m6581Start
m6581StateSize = m6581StateEnd-m6581StateStart

;@----------------------------------------------------------------------------
