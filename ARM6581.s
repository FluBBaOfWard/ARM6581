//
//  ARM6581.s
//  MOS 6581 "SID" chip emulator for ARM32.
//
//  Created by Fredrik Ahlström on 2006-12-01.
//  Copyright © 2006-2023 Fredrik Ahlström. All rights reserved.
//

#ifdef __arm__

#include "ARM6581.i"

	.global m6581Init
	.global m6581Reset
	.global frequency_reset
	.global soundMode
	.global sidWrite
	.global sidRead
	.global SID_StartMixer
	.global m6581SaveState
	.global m6581LoadState
	.global m6581GetStateSize

	.global SoundVariables

#define NSEED	0x7FFFF8		;@ Noise Seed

								;@ These values are for the SN76496 sound chip.
//#define WFEED	0x6000			;@ White Noise Feedback
//#define PFEED	0x4000			;@ Periodic Noise Feedback

//#define PCMWAVSIZE				312
#define PCMWAVSIZE				720

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------

;@ r0 = .
;@ r1 = .
;@ r2 = .
;@ r3 = pulsewidth.


;@ r4  = attack.
;@ r5  = decay.
;@ r6  = sustain.
;@ r7  = release.
;@ r8  = envelope. bit 0 & 1 = mode (adsr).
;@ r9  = frequency.
;@ r10 = counter.
;@ r11 = length.
;@ r12 = mixer buffer.
;@ lr = return address.
;@----------------------------------------------------------------------------
mixerPulse:
;@----------------------------------------------------------------------------
	add r10,r10,r9,lsl#8+5
	cmp r10,r3,lsl#20
	mov r0,#0x000
	movhi r0,#-1
	mov r0,r0,lsr#20		;@ Pulse finnished.

	ands r1,r8,#0x3
	bne noReleaseP
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b envDoneP
noReleaseP:
	cmp r1,#1
	bne noAttackP
	adds r8,r8,r4			;@ Attack mode
	orrcs r8,r8,#0xFF000000	;@ Clamp to full vol
	orrcs r8,r8,#0x00000002	;@ Set decay mode
	b envDoneP
noAttackP:
	cmp r8,r6
	bls envDoneP
	subs r8,r8,r5			;@ Decay/sustain mode
	movcc r8,#3


envDoneP:
	mov r1,r8,lsr#24
	mul r1,r0,r1			;@ Multiply pulse with envelope
	mov r1,r1,lsr#4
	strh r1,[r12],#2

	subs r11,r11,#1
	bhi mixerPulse

	bx lr
;@----------------------------------------------------------------------------
;@ r8  = envelope.
;@ r9  = frequency.
;@ r10 = counter.
;@ r11 = length.
;@ r12 = mixer buffer.
;@ lr  = return address.
;@----------------------------------------------------------------------------
mixerSaw:
;@----------------------------------------------------------------------------
	add r10,r10,r9,lsl#8+5
	mov r0,r10,lsr#20		;@ Saw done.


	ands r1,r8,#0x3
	bne noReleaseS
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b envDoneS
noReleaseS:
	cmp r1,#1
	bne noAttackS
	adds r8,r8,r4			;@ Attack mode
	orrcs r8,r8,#0xFF000000	;@ Clamp to full vol
	orrcs r8,r8,#0x00000002	;@ Set decay mode
	b envDoneS
noAttackS:
	cmp r8,r6
	bls envDoneS
	subs r8,r8,r5			;@ Decay/sustain mode
	movcc r8,#3

envDoneS:
	mov r1,r8,lsr#24
	mul r1,r0,r1			;@ Multiply saw with envelope
	mov r1,r1,lsr#4
	strh r1,[r12],#2

	subs r11,r11,#1
	bhi mixerSaw

	bx lr
;@----------------------------------------------------------------------------
;@ r8  = envelope.
;@ r9  = frequency.
;@ r10 = counter.
;@ r11 = length.
;@ r12 = mixer buffer.
;@ lr = return address.
;@----------------------------------------------------------------------------
mixerTriangle:
;@----------------------------------------------------------------------------
	add r10,r10,r9,lsl#8+5
	mov r1,r10,asr#15
	eor r1,r1,r10,lsl#1
	mov r0,r1,lsr#20

	ands r1,r8,#0x3
	bne noReleaseT
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b envDoneT
noReleaseT:
	cmp r1,#1
	bne noAttackT
	adds r8,r8,r4			;@ Attack mode
	orrcs r8,r8,#0xFF000000	;@ Clamp to full vol
	orrcs r8,r8,#0x00000002	;@ Set decay mode
	b envDoneT
noAttackT:
	cmp r8,r6
	bls envDoneT
	subs r8,r8,r5			;@ Decay/sustain mode
	movcc r8,#3

envDoneT:
	mov r1,r8,lsr#24
	mul r1,r0,r1			;@ Multiply triangle with envelope
	mov r1,r1,lsr#4
	strh r1,[r12],#2

	subs r11,r11,#1
	bhi mixerTriangle

	bx lr
;@----------------------------------------------------------------------------
;@ r8  = envelope.
;@ r9  = frequency.
;@ r10 = counter.
;@ r11 = length.
;@ r12 = mixer buffer.
;@ lr = return address.
;@----------------------------------------------------------------------------
mixerNoise:
;@----------------------------------------------------------------------------
	adds r10,r10,r9,lsl#8+9			;@ 8+5
	movcs r2,r2,lsl#1
	eor r0,r2,r2,lsl#5
	and r0,r0,#0x00400000
	orr r2,r2,r0,lsr#22
	mov r0,#0
	tst r2,#0x00400000		;@ Bit 22
	orrne r0,r0,#0x800
	tst r2,#0x00100000		;@ Bit 20
	orrne r0,r0,#0x400
	tst r2,#0x00010000		;@ Bit 16
	orrne r0,r0,#0x200
	tst r2,#0x00002000		;@ Bit 13
	orrne r0,r0,#0x100
	tst r2,#0x00000800		;@ Bit 11
	orrne r0,r0,#0x080
	tst r2,#0x00000080		;@ Bit 7
	orrne r0,r0,#0x040
	tst r2,#0x00000010		;@ Bit 4
	orrne r0,r0,#0x020
	tst r2,#0x00000004		;@ Bit 2
	orrne r0,r0,#0x010

	ands r1,r8,#0x3
	bne noReleaseN
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b envDoneN
noReleaseN:
	cmp r1,#1
	bne noAttackN
	adds r8,r8,r4			;@ Attack mode
	orrcs r8,r8,#0xFF000000	;@ Clamp to full vol
	orrcs r8,r8,#0x00000002	;@ Set decay mode
	b envDoneN
noAttackN:
	cmp r8,r6
	bls envDoneN
	subs r8,r8,r5			;@ Decay/sustain mode
	movcc r8,#3

envDoneN:
	mov r1,r8,lsr#24
	mul r1,r0,r1			;@ Multiply noise with envelope
	mov r1,r1,lsr#4
	strh r1,[r12],#2

	subs r11,r11,#1
	bhi mixerNoise

	bx lr
;@----------------------------------------------------------------------------
mixerSilence:
;@----------------------------------------------------------------------------
	add r10,r10,r9,lsl#8+5
	mov r0,#0

	ands r1,r8,#0x3
	bne noReleaseSi
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b envDoneSi
noReleaseSi:
	cmp r1,#1
	bne noAttackSi
	adds r8,r8,r4			;@ Attack mode
	orrcs r8,r8,#0xFF000000	;@ Clamp to full vol
	orrcs r8,r8,#0x00000002	;@ Set decay mode
	b envDoneSi
noAttackSi:
	cmp r8,r6
	bls envDoneSi
	subs r8,r8,r5			;@ Decay/sustain mode
	movcc r8,#3

envDoneSi:
	mov r1,r8,lsr#24
	mul r1,r0,r1			;@ Multiply noise with envelope
	mov r1,r1,lsr#4
	strh r0,[r12],#2

	subs r11,r11,#1
	bhi mixerSilence

	bx lr
;@----------------------------------------------------------------------------
mixChannels:
;@----------------------------------------------------------------------------
	ldrh r0,[r8],#2
	ldrh r1,[r9],#2
	ldrh r2,[r10],#2
	add r0,r0,r1
	add r0,r0,r2
	mul r1,r0,r3
	add r1,r1,r1,lsr#2
//	mov r1,r1,lsr#14		;@ 14
//	eor r1,r1,#0x80
//	strb r1,[r12],#1
	mov r1,r1,lsr#6
	eor r1,r1,#0x8000
	strh r1,[r12],#2

	subs r11,r11,#1
	bhi mixChannels

	bx lr

;@----------------------------------------------------------------------------

//	.section .text
//	.align 2
;@----------------------------------------------------------------------------
m6581Init:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r3,mixRate					;@ 924=Low, 532=High.
	mov r2,#0x10000					;@ Frequency = 0
	sub r0,r2,r3					;@ Frequency = 0x1000000/r3 Hz
	orr r0,r0,#0x800000				;@ Timer 0 on
//	str r0,[r1],#4
	mov r0,#0

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
m6581Reset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	adrl r0,SoundVariables
	mov r1,#0
	mov r2,#14						;@ 56/4=14
	bl memset_						;@ Clear variables

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
m6581SaveState:		;@ In r0=destination, r1=VICII chip. Out r0=state size.
	.type m6581SaveState STT_FUNC
;@----------------------------------------------------------------------------
	adrl r1,SoundVariables
	add r1,r1,#m6581StateStart
	mov r2,#m6581StateSize
	stmfd sp!,{r2,lr}
	bl memcpy

	ldmfd sp!,{r0,lr}
	bx lr
;@----------------------------------------------------------------------------
m6581LoadState:		;@ In r0=VICII chip, r1=source. Out r0=state size.
	.type m6581LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	adrl r0,SoundVariables
	add r0,r0,#m6581StateStart
	mov r2,#m6581StateSize
	bl memcpy

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
m6581GetStateSize:	;@ Out r0=state size.
	.type m6581GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#m6581StateSize
	bx lr

;@----------------------------------------------------------------------------
attackLen:
	.long 0x04000000,0x01000000,0x00800000,0x00500000,0x00380000,0x00250000,0x001E0000,0x001A0000
	.long 0x00140000,0x00080000,0x00040000,0x00030000,0x00020000,0x0000B200,0x00006B00,0x00004000
decayLen:
	.long 0x01400000,0x00500000,0x00280000,0x001A0000,0x00126564,0x000C7BA8,0x000A47B8,0x0008BCF4
	.long 0x0006FD90,0x0002CBD0,0x000165E0,0x0000DFB0,0x0000AAA8,0x00003B54,0x000023A8,0x00001554
releaseLen:
	.long 0x01400000,0x00500000,0x00280000,0x001A0000,0x00126564,0x000C7BA8,0x000A47B8,0x0008BCF4
	.long 0x0006FD90,0x0002CBD0,0x000165E0,0x0000DFB0,0x0000AAA8,0x00003B54,0x000023A8,0x00001554
;@----------------------------------------------------------------------------
SID_StartMixer:			;@ r0=length, r1=pointer
;@----------------------------------------------------------------------------
	;@ Update DMA buffer for PCM

	stmfd sp!,{r4-r12,lr}
	str r0,mixLength
	str r1,pcmptr

	ldr r0,ch3Noise
	str r0,ch3Noise_r
;@--------------------------
	ldr lr,=SoundVariables
	ldrb r9,[lr,#m6581Ch1FreqLo]
	ldrb r0,[lr,#m6581Ch1FreqHi]
	orr r9,r9,r0,lsl#8

	ldrb r3,[lr,#m6581Ch1PulseWLo]
	ldrb r0,[lr,#m6581Ch1PulseWHi]
	orr r3,r3,r0,lsl#8

	ldrb r0,[lr,#m6581Ch1AD]
	adr r1,attackLen
	and r2,r0,#0xF0
	ldr r4,[r1,r2,lsr#2]
	adr r1,decayLen
	and r2,r0,#0x0F
	ldr r5,[r1,r2,lsl#2]

	ldrb r0,[lr,#m6581Ch1SR]
	adr r1,releaseLen
	and r2,r0,#0x0F
	ldr r7,[r1,r2,lsl#2]
	and r0,r0,#0xF0
	mov r6,r0,lsl#24

	ldr r2,ch1Noise
	ldr r8,ch1Envelope
	ldr r10,ch1Counter
	ldr r11,mixLength
	ldr r12,sidptr

	ldrb r0,[lr,#m6581Ch1Ctrl]
	tst r0,#0x01
	biceq r8,r8,#0x03
	orrne r8,r8,#0x01
	bl mixerSelect
	str r2,ch1Noise
	str r8,ch1Envelope
	str r10,ch1Counter

;@----------------------
	ldr lr,=SoundVariables
	ldrb r9,[lr,#m6581Ch2FreqLo]
	ldrb r0,[lr,#m6581Ch2FreqHi]
	orr r9,r9,r0,lsl#8

	ldrb r3,[lr,#m6581Ch2PulseWLo]
	ldrb r0,[lr,#m6581Ch2PulseWHi]
	orr r3,r3,r0,lsl#8


	ldrb r0,[lr,#m6581Ch2AD]
	adr r1,attackLen
	and r2,r0,#0xF0
	ldr r4,[r1,r2,lsr#2]
	adr r1,decayLen
	and r2,r0,#0x0F
	ldr r5,[r1,r2,lsl#2]

	ldrb r0,[lr,#m6581Ch2SR]
	adr r1,releaseLen
	and r2,r0,#0x0F
	ldr r7,[r1,r2,lsl#2]
	and r0,r0,#0xF0
	mov r6,r0,lsl#24


	ldr r2,ch2Noise
	ldr r8,ch2Envelope
	ldr r10,ch2Counter
	ldr r11,mixLength
	ldr r12,sidptr
	add r12,r12,#PCMWAVSIZE*2

	ldrb r0,[lr,#m6581Ch2Ctrl]
	tst r0,#0x01
	biceq r8,r8,#0x03
	orrne r8,r8,#0x01
	bl mixerSelect
	str r2,ch2Noise
	str r8,ch2Envelope
	str r10,ch2Counter

;@----------------------
	ldr lr,=SoundVariables
	ldrb r9,[lr,#m6581Ch3FreqLo]
	ldrb r0,[lr,#m6581Ch3FreqHi]
	orr r9,r9,r0,lsl#8

	ldrb r3,[lr,#m6581Ch3PulseWLo]
	ldrb r0,[lr,#m6581Ch3PulseWHi]
	orr r3,r3,r0,lsl#8

	ldrb r0,[lr,#m6581Ch3AD]
	adr r1,attackLen
	and r2,r0,#0xF0
	ldr r4,[r1,r2,lsr#2]
	adr r1,decayLen
	and r2,r0,#0x0F
	ldr r5,[r1,r2,lsl#2]

	ldrb r0,[lr,#m6581Ch3SR]
	adr r1,releaseLen
	and r2,r0,#0x0F
	ldr r7,[r1,r2,lsl#2]
	and r0,r0,#0xF0
	mov r6,r0,lsl#24

	ldr r2,ch3Noise
	ldr r8,ch3Envelope
	ldr r10,ch3Counter
	ldr r11,mixLength
	ldr r12,sidptr
	add r12,r12,#PCMWAVSIZE*4

	ldrb r0,[lr,#m6581Ch3Ctrl]
	tst r0,#0x01
	biceq r8,r8,#0x03
	orrne r8,r8,#0x01
	bl mixerSelect
	str r2,ch3Noise
	str r8,ch3Envelope
	str r10,ch3Counter
;@----------------------------------------------------------------------------

	ldr lr,=SoundVariables
	ldrb r3,[lr,#m6581FilterMode]
	and r3,r3,#0x0F				;@ Main Volume
	ldr r11,mixLength
	ldr r12,pcmptr
	ldr r8,sidptr
	add r9,r8,#PCMWAVSIZE*2
	add r10,r8,#PCMWAVSIZE*4
	bl mixChannels


	ldmfd sp!,{r4-r12,pc}
;@----------------------------------------------------------------------------
mixerSelect:
	tst r0,#0x08
	bne mixerSilence
	tst r0,#0x10
	bne mixerTriangle
	tst r0,#0x20
	bne mixerSaw
	tst r0,#0x40
	bne mixerPulse
	tst r0,#0x80
	bne mixerNoise
	b mixerSilence
	bx lr
;@----------------------------------------------------------------------------
sidWriteOff:
	bx lr
;@----------------------------------------------------------------------------
sidWrite:
	adr r2,SoundVariables
	and r1,addy,#0x1F
	strb r0,[r2,r1]
	cmp r1,#0x04
	beq setCtrl1
	cmp r1,#0x0B
	beq setCtrl2
	cmp r1,#0x12
	beq setCtrl3
	bx lr
setCtrl1:
	tst r0,#0x08
	ldrne r1,=NSEED
	strne r1,ch1Noise
	tst r0,#0x01
	ldr r1,ch1Envelope
	biceq r1,r1,#3
	str r1,ch1Envelope
	bx lr
setCtrl2:
	tst r0,#0x08
	ldrne r1,=NSEED
	strne r1,ch2Noise
	tst r0,#0x01
	ldr r1,ch2Envelope
	biceq r1,r1,#3
	str r1,ch2Envelope
	bx lr
setCtrl3:
	tst r0,#0x08
	ldrne r1,=NSEED
	strne r1,ch3Noise
	tst r0,#0x01
	ldr r1,ch3Envelope
	biceq r1,r1,#3
	str r1,ch3Envelope
	bx lr

;@----------------------------------------------------------------------------
sidRead:
	and r1,addy,#0x1F
	cmp r1,#0x1b
	beq SID_OSC3_R
	mov r11,r11
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
SID_OSC3_R:
;@----------------------------------------------------------------------------
	ldr r1,ch3Noise_r
	movcs r1,r1,lsl#1
	eor r0,r1,r1,lsl#5
	and r0,r0,#0x00400000
	orr r1,r1,r0,lsr#22
	str r1,ch3Noise_r
	mov r0,#0
	tst r1,#0x00400000		;@ Bit 22
	orrne r0,r0,#0x80
	tst r1,#0x00100000		;@ Bit 20
	orrne r0,r0,#0x40
	tst r1,#0x00010000		;@ Bit 16
	orrne r0,r0,#0x20
	tst r1,#0x00002000		;@ Bit 13
	orrne r0,r0,#0x10
	tst r1,#0x00000800		;@ Bit 11
	orrne r0,r0,#0x08
	tst r1,#0x00000080		;@ Bit 7
	orrne r0,r0,#0x04
	tst r1,#0x00000010		;@ Bit 4
	orrne r0,r0,#0x02
	tst r1,#0x00000004		;@ Bit 2
	orrne r0,r0,#0x01

	bx lr
;@----------------------------------------------------------------------------
SoundVariables:
ch1Freq:		.byte 0,0
ch1PulseW:		.byte 0,0
ch1Ctrl:		.byte 0
ch1AD:			.byte 0		;@ Attack/Decay
ch1SR:			.byte 0		;@ Sustain/Release
ch2Freq:		.byte 0,0
ch2PulseW:		.byte 0,0
ch2Ctrl:		.byte 0
ch2AD:			.byte 0		;@ Attack/Decay
ch2SR:			.byte 0		;@ Sustain/Release
ch3Freq:		.byte 0,0
ch3PulseW:		.byte 0,0
ch3Ctrl:		.byte 0
ch3AD:			.byte 0		;@ Attack/Decay
ch3SR:			.byte 0		;@ Sustain/Release
filterFreq:		.byte 0,0
filterCtrl:		.byte 0		;@ Filter
filterMode:		.byte 0		;@ Filtermode/volume
paddle1:		.byte 0
paddle2:		.byte 0
osc3Rnd:		.byte 0
env3Out:		.byte 0
unused:			.skip 3

ch1Counter:		.long 0
ch2Counter:		.long 0
ch3Counter:		.long 0
ch1Envelope:	.long 0
ch2Envelope:	.long 0
ch3Envelope:	.long 0
ch1Noise:		.long NSEED
ch2Noise:		.long NSEED
ch3Noise:		.long NSEED
ch3Noise_r:		.long NSEED


mixLength:		.long PCMWAVSIZE	;@ Mixlength (528=high, 304=low)
sidptr:			.long SIDWAV
pcmptr:			.long SIDWAV
;@----------------------------------------------------------------------------

mixRate:			.long 532		;@ Mixrate (532=high, 924=low), (mixRate=0x1000000/mixer_frequency)
freqConvPAL:		.long 0x70788	;@ Frequency conversion (0x70788=high, 0xC3581=low) (3546893/mixer_frequency)*4096
freqConvNTSC:		.long 0x71819	;@ Frequency conversion (0x71819=high, 0xC5247=low) (3579545/mixer_frequency)*4096
freqConv:			.long 0
soundMode:			.long 1		;@ Soundmode (OFF/ON)

	.section .bss
	.align 2
SIDWAV:
	.space PCMWAVSIZE*6			;@ 16bit 3ch.
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
