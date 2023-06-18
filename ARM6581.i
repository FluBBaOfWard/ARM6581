//
//  ARM6581.i
//  MOS 6581 "SID" chip emulator for ARM32.
//
//  Created by Fredrik Ahlström on 2006-12-01.
//  Copyright © 2006-2023 Fredrik Ahlström. All rights reserved.
//

				;@ r0,r1,r2=temp regs
//	m6502nz		.req r3			;@ Bit 31=N, Z=1 if bits 0-7=0
	addy		.req r12		;@ Keep this at r12 (scratch for APCS)

	.struct 0					;@ Changes section so make sure it is set before real code.
m6581Start:
m6581StateStart:
m6581Ch1Freq:
m6581Ch1FreqLo:		.byte 0		;@ 0x00
m6581Ch1FreqHi:		.byte 0		;@ 0x01
m6581Ch1PulseW:
m6581Ch1PulseWLo:	.byte 0		;@ 0x02
m6581Ch1PulseWHi:	.byte 0		;@ 0x03
m6581Ch1Ctrl:		.byte 0		;@ 0x04
m6581Ch1AD:			.byte 0		;@ 0x05 Attack/Decay
m6581Ch1SR:			.byte 0		;@ 0x06 Sustain/Release

m6581Ch2Freq:
m6581Ch2FreqLo:		.byte 0		;@ 0x07
m6581Ch2FreqHi:		.byte 0		;@ 0x08
m6581Ch2PulseW:
m6581Ch2PulseWLo:	.byte 0		;@ 0x09
m6581Ch2PulseWHi:	.byte 0		;@ 0x0A
m6581Ch2Ctrl:		.byte 0		;@ 0x0B
m6581Ch2AD:			.byte 0		;@ 0x0C Attack/Decay
m6581Ch2SR:			.byte 0		;@ 0x0D Sustain/Release

m6581Ch3Freq:
m6581Ch3FreqLo:		.byte 0		;@ 0x0E
m6581Ch3FreqHi:		.byte 0		;@ 0x0F
m6581Ch3PulseW:
m6581Ch3PulseWLo:	.byte 0		;@ 0x10
m6581Ch3PulseWHi:	.byte 0		;@ 0x11
m6581Ch3Ctrl:		.byte 0		;@ 0x12
m6581Ch3AD:			.byte 0		;@ 0x13 Attack/Decay
m6581Ch3SR:			.byte 0		;@ 0x14 Sustain/Release

m6581FilterFreq:
m6581FilterFreqLo:	.byte 0		;@ 0x15
m6581FilterFreqHi:	.byte 0		;@ 0x16
m6581FilterCtrl:	.byte 0		;@ 0x17 Filter
m6581FilterMode:	.byte 0		;@ 0x18 Filtermode/volume
m6581Paddle1:		.byte 0		;@ 0x19
m6581Paddle2:		.byte 0		;@ 0x1A
m6581Osc3Rnd:		.byte 0		;@ 0x1B
m6581Env3Out:		.byte 0		;@ 0x1C
m6581Unused:		.skip 3		;@ 0x1D-0x1F

m6581LastWrite:		.byte 0
m6581Padding:		.skip 3

m6581Ch1Counter:	.long 0
m6581Ch2Counter:	.long 0
m6581Ch3Counter:	.long 0
m6581Ch1Envelope:	.long 0
m6581Ch2Envelope:	.long 0
m6581Ch3Envelope:	.long 0
m6581Ch1Noise:		.long 0
m6581Ch2Noise:		.long 0
m6581Ch3Noise:		.long 0
m6581Ch3Noise_r:	.long 0
m6581StateEnd:
m6581End:

m6581Size = m6581End-m6581Start
m6581StateSize = m6581StateEnd-m6581StateStart

;@----------------------------------------------------------------------------
