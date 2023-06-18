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
	.global sidWrite
	.global sidRead
	.global SID_StartMixer
	.global m6581SaveState
	.global m6581LoadState
	.global m6581GetStateSize

#define NSEED	0x7FFFF8		;@ Noise Seed

#define PCMWAVSIZE				640

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------

;@ r0  = Destination buffer (16bit).
;@ r1  = .
;@ r2  = .
;@ r3  = PulseWidth (12bit).
;@ r4  = Attack.
;@ r5  = Decay.
;@ r6  = Sustain.
;@ r7  = Release.
;@ r8  = Envelope (Top 8 bits). bit 0 & 1 = mode (adsr).
;@ r9  = Frequency.
;@ r10 = Counter.
;@ r11 = Length.
;@ r12 = ChannelPtr.
;@ lr = return address.
;@----------------------------------------------------------------------------
mixerPulse:
;@----------------------------------------------------------------------------
	ldrb r3,[r12,#m6581ChPulseWLo]
	ldrb r2,[r12,#m6581ChPulseWHi]
	orr r3,r3,r2,lsl#8

pulseLoop:
	add r10,r10,r9,lsl#8+5

	ands r2,r8,#0x3
	bne noReleaseP
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b envDoneP
noReleaseP:
	cmp r2,#1
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
	cmp r10,r3,lsl#20
	mov r2,#0
	movcs r2,r8,lsr#16		;@ Use envelope directly for pulse
	strh r2,[r0],#2

	subs r11,r11,#1
	bhi pulseLoop

	bx lr
;@----------------------------------------------------------------------------
;@ r0  = Destination buffer (16bit).
;@ r4  = attack.
;@ r5  = decay.
;@ r6  = sustain.
;@ r7  = release.
;@ r8  = envelope.
;@ r9  = frequency.
;@ r10 = counter.
;@ r11 = length.
;@ r12 = ChannelPtr.
;@ lr  = return address.
;@----------------------------------------------------------------------------
mixerSaw:
;@----------------------------------------------------------------------------
sawLoop:
	add r10,r10,r9,lsl#8+5

	ands r2,r8,#0x3
	bne noReleaseS
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b envDoneS
noReleaseS:
	cmp r2,#1
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
	mov r3,r10,lsr#20		;@ Saw done.
	mov r2,r8,lsr#24
	mul r2,r3,r2			;@ Multiply saw with envelope
	mov r2,r2,lsr#4
	strh r2,[r0],#2

	subs r11,r11,#1
	bhi sawLoop

	bx lr
;@----------------------------------------------------------------------------
;@ r0  = Destination buffer (16bit).
;@ r4  = attack.
;@ r5  = decay.
;@ r6  = sustain.
;@ r7  = release.
;@ r8  = envelope.
;@ r9  = frequency.
;@ r10 = counter.
;@ r11 = length.
;@ r12 = ChannelPtr.
;@ lr = return address.
;@----------------------------------------------------------------------------
mixerTriangle:
;@----------------------------------------------------------------------------
triangleLoop:
	add r10,r10,r9,lsl#8+5

	ands r2,r8,#0x3
	bne noReleaseT
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b envDoneT
noReleaseT:
	cmp r2,#1
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
	mov r3,r10,asr#15
	eor r3,r3,r10,lsl#1
	mov r3,r3,lsr#20
	mov r2,r8,lsr#24
	mul r2,r3,r2			;@ Multiply triangle with envelope
	mov r2,r2,lsr#4
	strh r2,[r0],#2

	subs r11,r11,#1
	bhi triangleLoop

	bx lr
;@----------------------------------------------------------------------------
;@ r0  = Destination buffer (16bit).
;@ r3  = LFSR.
;@ r4  = attack.
;@ r5  = decay.
;@ r6  = sustain.
;@ r7  = release.
;@ r8  = envelope.
;@ r9  = frequency.
;@ r10 = counter.
;@ r11 = length.
;@ r12 = ChannelPtr.
;@ lr = return address.
;@----------------------------------------------------------------------------
mixerNoise:
;@----------------------------------------------------------------------------
	mov r10,r10,ror#32-4
noiseLoop:
	adds r10,r10,r9,lsl#8+4+5
	movcs r3,r3,lsl#1
	eor r2,r3,r3,lsl#5		;@ Tap bit 17 & 22
	and r2,r2,#0x00400000
	orr r3,r3,r2,lsr#22
	mov r2,#0
	tst r3,#0x00100000		;@ Bit 20
	orrne r2,r2,#0x800
	tst r3,#0x00040000		;@ Bit 18
	orrne r2,r2,#0x400
	tst r3,#0x00004000		;@ Bit 14
	orrne r2,r2,#0x200
	tst r3,#0x00000800		;@ Bit 11
	orrne r2,r2,#0x100
	tst r3,#0x00000200		;@ Bit 9
	orrne r2,r2,#0x080
	tst r3,#0x00000020		;@ Bit 5
	orrne r2,r2,#0x040
	tst r3,#0x00000004		;@ Bit 2
	orrne r2,r2,#0x020
	tst r3,#0x00000001		;@ Bit 0
	orrne r2,r2,#0x010

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
	mul r1,r2,r1			;@ Multiply noise with envelope
	mov r1,r1,lsr#4
	strh r1,[r0],#2

	subs r11,r11,#1
	bhi noiseLoop

	mov r10,r10,ror#4
	bx lr
;@----------------------------------------------------------------------------
;@ r0  = Destination buffer (16bit).
;@ r11 = length.
;@ r12 = ChannelPtr.
;@ lr = return address.
;@----------------------------------------------------------------------------
mixerSilence:
;@----------------------------------------------------------------------------
	add r10,r10,r9,lsl#8+5

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
	mov r1,#0
	strh r1,[r0],#2

	subs r11,r11,#1
	bhi mixerSilence

	bx lr
;@----------------------------------------------------------------------------
mixChannels:			;@ r0 = dest, r1 = src1, r2 = length, r3 = volume
;@----------------------------------------------------------------------------
	add r7,r1,#PCMWAVSIZE*2
	add r8,r1,#PCMWAVSIZE*4
mixLoop:
	ldrh r4,[r1],#2
	ldrh r5,[r7],#2
	ldrh r6,[r8],#2
	add r4,r4,r5
	add r4,r4,r6
	mul r5,r4,r3
	add r5,r5,r5,lsr#2
//	mov r5,r5,lsr#14		;@ 14
//	eor r5,r5,#0x80
//	strb r5,[r0],#1
	mov r5,r5,lsr#6
	eor r5,r5,#0x8000
	strh r5,[r0],#2

	subs r2,r2,#1
	bhi mixLoop

	bx lr

;@----------------------------------------------------------------------------

//	.section .text
//	.align 2
;@----------------------------------------------------------------------------
m6581Init:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r0,#0

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
m6581Reset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	adrl r0,SoundVariables
	mov r1,#0
	mov r2,#m6581StateSize/4		;@ 56/4=14
	bl memset_						;@ Clear variables

	ldr r1,=NSEED
	str r1,[r0,#m6581Ch1Noise]
	str r1,[r0,#m6581Ch2Noise]
	str r1,[r0,#m6581Ch3Noise]
	str r1,[r0,#m6581Ch3Noise_r]

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

	ldr lr,=SoundVariables
	ldr r0,[lr,#m6581Ch3Noise]
	str r0,[lr,#m6581Ch3Noise_r]
;@--------------------------
	add r12,lr,#m6581Channel1
	ldr r3,[lr,#m6581Ch1Noise]
	ldr r8,[lr,#m6581Ch1Envelope]
	ldr r10,[lr,#m6581Ch1Counter]
	ldr r0,sidptr
	bl mixerSelect
	ldr lr,=SoundVariables
	str r3,[lr,#m6581Ch1Noise]
	str r8,[lr,#m6581Ch1Envelope]
	str r10,[lr,#m6581Ch1Counter]

;@----------------------
	add r12,lr,#m6581Channel2
	ldr r3,[lr,#m6581Ch2Noise]
	ldr r8,[lr,#m6581Ch2Envelope]
	ldr r10,[lr,#m6581Ch2Counter]
	ldr r0,sidptr
	add r0,r0,#PCMWAVSIZE*2
	bl mixerSelect
	ldr lr,=SoundVariables
	str r3,[lr,#m6581Ch2Noise]
	str r8,[lr,#m6581Ch2Envelope]
	str r10,[lr,#m6581Ch2Counter]

;@----------------------
	add r12,lr,#m6581Channel3
	ldr r3,[lr,#m6581Ch3Noise]
	ldr r8,[lr,#m6581Ch3Envelope]
	ldr r10,[lr,#m6581Ch3Counter]
	ldr r0,sidptr
	add r0,r0,#PCMWAVSIZE*4
	bl mixerSelect
	ldr lr,=SoundVariables
	str r3,[lr,#m6581Ch3Noise]
	str r8,[lr,#m6581Ch3Envelope]
	str r10,[lr,#m6581Ch3Counter]
;@----------------------------------------------------------------------------

	ldrb r3,[lr,#m6581FilterMode]
	and r3,r3,#0x0F				;@ Main Volume
	ldr r2,mixLength
	ldr r0,pcmptr
	ldr r1,sidptr
	bl mixChannels

	ldmfd sp!,{r4-r12,pc}
;@----------------------------------------------------------------------------
mixerSelect:
	ldrb r9,[r12,#m6581ChFreqLo]
	ldrb r2,[r12,#m6581ChFreqHi]
	orr r9,r9,r2,lsl#8

	ldrb r5,[r12,#m6581ChAD]
	adr r2,attackLen
	and r4,r5,#0xF0
	ldr r4,[r2,r4,lsr#2]
	adr r2,decayLen
	and r5,r5,#0x0F
	ldr r5,[r2,r5,lsl#2]

	ldrb r6,[r12,#m6581ChSR]
	adr r2,releaseLen
	and r7,r6,#0x0F
	ldr r7,[r2,r7,lsl#2]
	and r6,r6,#0xF0				;@ Sustain value
	mov r6,r6,lsl#24

	ldrb r2,[r12,#m6581ChCtrl]
	tst r2,#0x01
	biceq r8,r8,#0x03
	orrne r8,r8,#0x01

	ldr r11,mixLength
	tst r2,#0x08				;@ Test bit, not silence.
	bne mixerSilence
	tst r2,#0x10
	bne mixerTriangle
	tst r2,#0x20
	bne mixerSaw
	tst r2,#0x40
	bne mixerPulse
	tst r2,#0x80
	bne mixerNoise
	b mixerSilence
	bx lr
;@----------------------------------------------------------------------------
sidWriteOff:
	bx lr
;@----------------------------------------------------------------------------
sidWrite:
	adr r2,SoundVariables
	strb r0,[r2,#m6581LastWrite]
	and r1,addy,#0x1F
	cmp r1,#0x19
	strbmi r0,[r2,r1]
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
	strne r1,[r2,#m6581Ch1Noise]
	tst r0,#0x01
	ldr r1,[r2,#m6581Ch1Envelope]
	biceq r1,r1,#3
	str r1,[r2,#m6581Ch1Envelope]
	bx lr
setCtrl2:
	tst r0,#0x08
	ldrne r1,=NSEED
	strne r1,[r2,#m6581Ch2Noise]
	tst r0,#0x01
	ldr r1,[r2,#m6581Ch2Envelope]
	biceq r1,r1,#3
	str r1,[r2,#m6581Ch2Envelope]
	bx lr
setCtrl3:
	tst r0,#0x08
	ldrne r1,=NSEED
	strne r1,[r2,#m6581Ch3Noise]
	tst r0,#0x01
	ldr r1,[r2,#m6581Ch3Envelope]
	biceq r1,r1,#3
	str r1,[r2,#m6581Ch3Envelope]
	bx lr

;@----------------------------------------------------------------------------
sidRead:
	adr r2,SoundVariables
	and r1,addy,#0x1F
	cmp r1,#0x19
	beq sidPotXR
	cmp r1,#0x1A
	beq sidPotYR
	cmp r1,#0x1B
	beq sidOsc3R
	cmp r1,#0x1C
	beq sidEnv3R
	mov r11,r11
	ldrb r0,[r2,#m6581LastWrite]
	bx lr
;@----------------------------------------------------------------------------
sidPotXR:
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
sidPotYR:
;@----------------------------------------------------------------------------
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
sidOsc3R:
;@----------------------------------------------------------------------------
	ldr r1,[r2,#m6581Ch3Noise_r]
	movcs r1,r1,lsl#1
	eor r0,r1,r1,lsl#5
	and r0,r0,#0x00400000
	orr r1,r1,r0,lsr#22
	str r1,[r2,#m6581Ch3Noise_r]
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
sidEnv3R:
;@----------------------------------------------------------------------------
	ldrb r0,[r2,#m6581Ch3Envelope+3]
	bx lr
;@----------------------------------------------------------------------------
SoundVariables:
	.skip m6581Size

mixLength:		.long PCMWAVSIZE
sidptr:			.long SIDWAV
pcmptr:			.long SIDWAV
;@----------------------------------------------------------------------------

	.section .bss
	.align 2
SIDWAV:
	.space PCMWAVSIZE*6			;@ 16bit 3ch.
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
