#include "ARM6581.i"

	.global SID_reset
	.global frequency_reset
	.global soundmode
	.global SID_W
	.global SID_R
	.global SID_StartMixer
	.global SoundVariables

#define NSEED	0x7FFFF8		;@ Noise Seed

								;@ These values are for the SN76496 sound chip.
//#define WFEED	0x6000			;@ White Noise Feedback
//#define PFEED	0x4000			;@ Periodic Noise Feedback

#define ch1freq_offset			0
#define ch1freq_low_offset		0
#define ch1freq_high_offset		1
#define ch1pulsew_offset		2
#define ch1pulsew_low_offset	2
#define ch1pulsew_high_offset	3
#define ch1ctrl_offset			4
#define ch1ad_offset			5
#define ch1sr_offset			6

#define ch2freq_offset			7
#define ch2freq_low_offset		7
#define ch2freq_high_offset		8
#define ch2pulsew_offset		9
#define ch2pulsew_low_offset	9
#define ch2pulsew_high_offset	10
#define ch2ctrl_offset			11
#define ch2ad_offset			12
#define ch2sr_offset			13

#define ch3freq_offset			14
#define ch3freq_low_offset		14
#define ch3freq_high_offset		15
#define ch3pulsew_offset		16
#define ch3pulsew_low_offset	16
#define ch3pulsew_high_offset	17
#define ch3ctrl_offset			18
#define ch3ad_offset			19
#define ch3sr_offset			20

#define filterfreq_offset		21
#define filterfreq_low_offset	21
#define filterfreq_high_offset	22
#define filterctrl_offset		23
#define filtermode_offset		24
#define paddle1_offset			25
#define paddle2_offset			26
#define osc3rnd_offset			27
#define env3out_offset			28

//#define PCMWAVSIZE				312
#define PCMWAVSIZE				528


	.section .text
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
mixer_pulse:
;@----------------------------------------------------------------------------
	add r10,r10,r9,lsl#8+5
	cmp r10,r3,lsl#20
	mov r0,#0x000
	movhi r0,#-1
	mov r0,r0,lsr#20		;@ Pulse finnished.

	ands r1,r8,#0x3
	bne norelease_p
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b env_done_p
norelease_p:
	cmp r1,#1
	bne noattack_p
	adds r8,r8,r4			;@ Attack mode
	orrcs r8,r8,#0xFF000000	;@ Clamp to full vol
	orrcs r8,r8,#0x00000002	;@ Set decay mode
	b env_done_p
noattack_p:
	cmp r8,r6
	bls env_done_p
	subs r8,r8,r5			;@ Decay/sustain mode
	movcc r8,#3


env_done_p:
	mov r1,r8,lsr#24
	mul r1,r0,r1			;@ Multiply pulse with envelope
	mov r1,r1,lsr#4
	strh r1,[r12],#2

	subs r11,r11,#1
	bhi mixer_pulse

	bx lr
;@----------------------------------------------------------------------------
;@ r8  = envelope.
;@ r9  = frequency.
;@ r10 = counter.
;@ r11 = length.
;@ r12 = mixer buffer.
;@ lr  = return address.
;@----------------------------------------------------------------------------
mixer_saw:
;@----------------------------------------------------------------------------
	add r10,r10,r9,lsl#8+5
	mov r0,r10,lsr#20		;@ Saw done.


	ands r1,r8,#0x3
	bne norelease_s
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b env_done_s
norelease_s:
	cmp r1,#1
	bne noattack_s
	adds r8,r8,r4			;@ Attack mode
	orrcs r8,r8,#0xFF000000	;@ Clamp to full vol
	orrcs r8,r8,#0x00000002	;@ Set decay mode
	b env_done_s
noattack_s:
	cmp r8,r6
	bls env_done_s
	subs r8,r8,r5			;@ Decay/sustain mode
	movcc r8,#3

env_done_s:
	mov r1,r8,lsr#24
	mul r1,r0,r1			;@ Multiply saw with envelope
	mov r1,r1,lsr#4
	strh r1,[r12],#2

	subs r11,r11,#1
	bhi mixer_saw

	bx lr
;@----------------------------------------------------------------------------
;@ r8  = envelope.
;@ r9  = frequency.
;@ r10 = counter.
;@ r11 = length.
;@ r12 = mixer buffer.
;@ lr = return address.
;@----------------------------------------------------------------------------
mixer_triangle:
;@----------------------------------------------------------------------------
	add r10,r10,r9,lsl#8+5
	mov r1,r10,asr#15
	eor r1,r1,r10,lsl#1
	mov r0,r1,lsr#20

	ands r1,r8,#0x3
	bne norelease_t
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b env_done_t
norelease_t:
	cmp r1,#1
	bne noattack_t
	adds r8,r8,r4			;@ Attack mode
	orrcs r8,r8,#0xFF000000	;@ Clamp to full vol
	orrcs r8,r8,#0x00000002	;@ Set decay mode
	b env_done_t
noattack_t:
	cmp r8,r6
	bls env_done_t
	subs r8,r8,r5			;@ Decay/sustain mode
	movcc r8,#3

env_done_t:
	mov r1,r8,lsr#24
	mul r1,r0,r1			;@ Multiply triangle with envelope
	mov r1,r1,lsr#4
	strh r1,[r12],#2

	subs r11,r11,#1
	bhi mixer_triangle

	bx lr
;@----------------------------------------------------------------------------
;@ r8  = envelope.
;@ r9  = frequency.
;@ r10 = counter.
;@ r11 = length.
;@ r12 = mixer buffer.
;@ lr = return address.
;@----------------------------------------------------------------------------
mixer_noise:
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
	bne norelease_n
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b env_done_n
norelease_n:
	cmp r1,#1
	bne noattack_n
	adds r8,r8,r4			;@ Attack mode
	orrcs r8,r8,#0xFF000000	;@ Clamp to full vol
	orrcs r8,r8,#0x00000002	;@ Set decay mode
	b env_done_n
noattack_n:
	cmp r8,r6
	bls env_done_n
	subs r8,r8,r5			;@ Decay/sustain mode
	movcc r8,#3

env_done_n:
	mov r1,r8,lsr#24
	mul r1,r0,r1			;@ Multiply noise with envelope
	mov r1,r1,lsr#4
	strh r1,[r12],#2

	subs r11,r11,#1
	bhi mixer_noise

	bx lr
;@----------------------------------------------------------------------------
mixer_silence:
;@----------------------------------------------------------------------------
	add r10,r10,r9,lsl#8+5
	mov r0,#0

	ands r1,r8,#0x3
	bne norelease_si
	subs r8,r8,r7			;@ Release mode
	biccc r8,r8,#0xFF000000
	b env_done_si
norelease_si:
	cmp r1,#1
	bne noattack_si
	adds r8,r8,r4			;@ Attack mode
	orrcs r8,r8,#0xFF000000	;@ Clamp to full vol
	orrcs r8,r8,#0x00000002	;@ Set decay mode
	b env_done_si
noattack_si:
	cmp r8,r6
	bls env_done_si
	subs r8,r8,r5			;@ Decay/sustain mode
	movcc r8,#3

env_done_si:
	mov r1,r8,lsr#24
	mul r1,r0,r1			;@ Multiply noise with envelope
	mov r1,r1,lsr#4
	strh r0,[r12],#2

	subs r11,r11,#1
	bhi mixer_silence

	bx lr
;@----------------------------------------------------------------------------
mix_channels:
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
	bhi mix_channels

	bx lr

;@----------------------------------------------------------------------------

//	.section .text

;@----------------------------------------------------------------------------
m6581Init:
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r7,lr}
//	mov r1,#REG_BASE


	ldr r0,=0x0b040000			;@ Stop all channels, output ratio=100% dsA.  use directsound A for L&R, timer 0
//	str r0,[r1,#REG_SGCNT_L]

	mov r0,#0x80
//	strh r0,[r1,#REG_SGCNT_X]		;@ Sound master enable

									;@ Triangle reset
	mov r0,#0
//	str r0,[r1,#REG_SG3CNT_L]		;@ Sound3 disable, mute, write bank 0

									;@ Mixer channels
//	strh r1,[r1,#REG_DM1CNT_H]		;@ DMA1 stop, Left channel
//	add r0,r1,#REG_FIFO_A_L			;@ DMA1 destination..
//	str r0,[r1,#REG_DM1DAD]
//	ldr r0,pcmptr
//	str r0,[r1,#REG_DM1SAD]			;@ DMA1 src=..


//	add r1,r1,#REG_TM0CNT_L			;@ Timer 0 controls sample rate:
	mov r0,#0
//	str r0,[r1]						;@ Stop timer 0
	ldr r3,mixrate					;@ 924=Low, 532=High.
	mov r2,#0x10000					;@ Frequency = 0
	sub r0,r2,r3					;@ Frequency = 0x1000000/r3 Hz
	orr r0,r0,#0x800000				;@ Timer 0 on
//	str r0,[r1],#4
	mov r0,#0

	ldmfd sp!,{r3-r7,lr}
;@----------------------------------------------------------------------------
SID_reset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	adrl r0,SoundVariables
	mov r1,#0
	mov r2,#14						;@ 56/4=14
	bl memset_						;@ Clear variables

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
Attack_len:
	.long 0x04000000,0x01000000,0x00800000,0x00500000,0x00380000,0x00250000,0x001E0000,0x001A0000
	.long 0x00140000,0x00080000,0x00040000,0x00030000,0x00020000,0x0000B200,0x00006B00,0x00004000
Decay_len:
	.long 0x01400000,0x00500000,0x00280000,0x001A0000,0x00126564,0x000C7BA8,0x000A47B8,0x0008BCF4
	.long 0x0006FD90,0x0002CBD0,0x000165E0,0x0000DFB0,0x0000AAA8,0x00003B54,0x000023A8,0x00001554
Release_len:
	.long 0x01400000,0x00500000,0x00280000,0x001A0000,0x00126564,0x000C7BA8,0x000A47B8,0x0008BCF4
	.long 0x0006FD90,0x0002CBD0,0x000165E0,0x0000DFB0,0x0000AAA8,0x00003B54,0x000023A8,0x00001554
;@----------------------------------------------------------------------------
SID_StartMixer:
;@----------------------------------------------------------------------------
	;@ Update DMA buffer for PCM

	stmfd sp!,{r3-r12,lr}
	str r0,pcmptr

	ldr r0,ch3noise
	str r0,ch3noise_r
;@--------------------------
	ldr lr,=SoundVariables
	ldrb r9,[lr,#ch1freq_low_offset]
	ldrb r0,[lr,#ch1freq_high_offset]
	orr r9,r9,r0,lsl#8

	ldrb r3,[lr,#ch1pulsew_low_offset]
	ldrb r0,[lr,#ch1pulsew_high_offset]
	orr r3,r3,r0,lsl#8

	ldrb r0,[lr,#ch1ad_offset]
	adr r1,Attack_len
	and r2,r0,#0xF0
	ldr r4,[r1,r2,lsr#2]
	adr r1,Decay_len
	and r2,r0,#0x0F
	ldr r5,[r1,r2,lsl#2]

	ldrb r0,[lr,#ch1sr_offset]
	adr r1,Release_len
	and r2,r0,#0x0F
	ldr r7,[r1,r2,lsl#2]
	and r0,r0,#0xF0
	mov r6,r0,lsl#24

	ldr r2,ch1noise
	ldr r8,ch1envelope
	ldr r10,ch1counter
	ldr r11,mixlength
	ldr r12,sidptr

	ldrb r0,[lr,#ch1ctrl_offset]
	tst r0,#0x01
	biceq r8,r8,#0x03
	orrne r8,r8,#0x01
	bl mixer_select
	str r2,ch1noise
	str r8,ch1envelope
	str r10,ch1counter

;@----------------------
	ldr lr,=SoundVariables
	ldrb r9,[lr,#ch2freq_low_offset]
	ldrb r0,[lr,#ch2freq_high_offset]
	orr r9,r9,r0,lsl#8

	ldrb r3,[lr,#ch2pulsew_low_offset]
	ldrb r0,[lr,#ch2pulsew_high_offset]
	orr r3,r3,r0,lsl#8


	ldrb r0,[lr,#ch2ad_offset]
	adr r1,Attack_len
	and r2,r0,#0xF0
	ldr r4,[r1,r2,lsr#2]
	adr r1,Decay_len
	and r2,r0,#0x0F
	ldr r5,[r1,r2,lsl#2]

	ldrb r0,[lr,#ch2sr_offset]
	adr r1,Release_len
	and r2,r0,#0x0F
	ldr r7,[r1,r2,lsl#2]
	and r0,r0,#0xF0
	mov r6,r0,lsl#24


	ldr r2,ch2noise
	ldr r8,ch2envelope
	ldr r10,ch2counter
	ldr r11,mixlength
	ldr r12,sidptr
	add r12,r12,#PCMWAVSIZE*2

	ldrb r0,[lr,#ch2ctrl_offset]
	tst r0,#0x01
	biceq r8,r8,#0x03
	orrne r8,r8,#0x01
	bl mixer_select
	str r2,ch2noise
	str r8,ch2envelope
	str r10,ch2counter

;@----------------------
	ldr lr,=SoundVariables
	ldrb r9,[lr,#ch3freq_low_offset]
	ldrb r0,[lr,#ch3freq_high_offset]
	orr r9,r9,r0,lsl#8

	ldrb r3,[lr,#ch3pulsew_low_offset]
	ldrb r0,[lr,#ch3pulsew_high_offset]
	orr r3,r3,r0,lsl#8

	ldrb r0,[lr,#ch3ad_offset]
	adr r1,Attack_len
	and r2,r0,#0xF0
	ldr r4,[r1,r2,lsr#2]
	adr r1,Decay_len
	and r2,r0,#0x0F
	ldr r5,[r1,r2,lsl#2]

	ldrb r0,[lr,#ch3sr_offset]
	adr r1,Release_len
	and r2,r0,#0x0F
	ldr r7,[r1,r2,lsl#2]
	and r0,r0,#0xF0
	mov r6,r0,lsl#24

	ldr r2,ch3noise
	ldr r8,ch3envelope
	ldr r10,ch3counter
	ldr r11,mixlength
	ldr r12,sidptr
	add r12,r12,#PCMWAVSIZE*4

	ldrb r0,[lr,#ch3ctrl_offset]
	tst r0,#0x01
	biceq r8,r8,#0x03
	orrne r8,r8,#0x01
	bl mixer_select
	str r2,ch3noise
	str r8,ch3envelope
	str r10,ch3counter
;@----------------------------------------------------------------------------

	ldr lr,=SoundVariables
	ldrb r3,[lr,#filtermode_offset]
	and r3,r3,#0x0F				;@ Main Volume
	ldr r11,mixlength
	ldr r12,pcmptr
	ldr r8,sidptr
	add r9,r8,#PCMWAVSIZE*2
	add r10,r8,#PCMWAVSIZE*4
	bl mix_channels


	ldmfd sp!,{r3-r12,pc}
;@----------------------------------------------------------------------------
mixer_select:
	tst r0,#0x08
	bne mixer_silence
	tst r0,#0x10
	bne mixer_triangle
	tst r0,#0x20
	bne mixer_saw
	tst r0,#0x40
	bne mixer_pulse
	tst r0,#0x80
	bne mixer_noise
	b mixer_silence
	bx lr
;@----------------------------------------------------------------------------
SID_W_OFF:
	bx lr
;@----------------------------------------------------------------------------
SID_W:
	adr r2,SoundVariables
	and r1,addy,#0x1F
	strb r0,[r2,r1]
	cmp r1,#0x04
	beq SetCtrl1
	cmp r1,#0x0B
	beq SetCtrl2
	cmp r1,#0x12
	beq SetCtrl3
	bx lr
SetCtrl1:
	tst r0,#0x08
	ldrne r1,=NSEED
	strne r1,ch1noise
	tst r0,#0x01
	ldr r1,ch1envelope
	biceq r1,r1,#3
	str r1,ch1envelope
	bx lr
SetCtrl2:
	tst r0,#0x08
	ldrne r1,=NSEED
	strne r1,ch2noise
	tst r0,#0x01
	ldr r1,ch2envelope
	biceq r1,r1,#3
	str r1,ch2envelope
	bx lr
SetCtrl3:
	tst r0,#0x08
	ldrne r1,=NSEED
	strne r1,ch3noise
	tst r0,#0x01
	ldr r1,ch3envelope
	biceq r1,r1,#3
	str r1,ch3envelope
	bx lr

;@----------------------------------------------------------------------------
SID_R:
	and r1,addy,#0x1F
	cmp r1,#0x1b
	beq SID_OSC3_R
	mov r11,r11
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
SID_OSC3_R:
;@----------------------------------------------------------------------------
	ldr r1,ch3noise_r
	movcs r1,r1,lsl#1
	eor r0,r1,r1,lsl#5
	and r0,r0,#0x00400000
	orr r1,r1,r0,lsr#22
	str r1,ch3noise_r
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
ch1freq:		.byte 0,0
ch1pulsew:		.byte 0,0
ch1ctrl:		.byte 0
ch1ad:			.byte 0		;@ Attack/Decay
ch1sr:			.byte 0		;@ Sustain/Release
ch2freq:		.byte 0,0
ch2pulsew:		.byte 0,0
ch2ctrl:		.byte 0
ch2ad:			.byte 0		;@ Attack/Decay
ch2sr:			.byte 0		;@ Sustain/Release
ch3freq:		.byte 0,0
ch3pulsew:		.byte 0,0
ch3ctrl:		.byte 0
ch3ad:			.byte 0		;@ Attack/Decay
ch3sr:			.byte 0		;@ Sustain/Release
filterfreq:		.byte 0,0
filterctrl:		.byte 0		;@ Filter
filtermode:		.byte 0		;@ Filtermode/volume
paddle1:		.byte 0
paddle2:		.byte 0
osc3rnd:		.byte 0
env3out:		.byte 0
unused:			.byte 0,0,0

ch1counter:		.long 0
ch2counter:		.long 0
ch3counter:		.long 0
ch1envelope:	.long 0
ch2envelope:	.long 0
ch3envelope:	.long 0
ch1noise:		.long NSEED
ch2noise:		.long NSEED
ch3noise:		.long NSEED
ch3noise_r:		.long NSEED


mixlength:		.long PCMWAVSIZE	;@ Mixlength (528=high, 304=low)
sidptr:			.long SIDWAV
pcmptr:			.long SIDWAV
;@----------------------------------------------------------------------------

mixrate:			.long 532		;@ Mixrate (532=high, 924=low), (mixrate=0x1000000/mixer_frequency)
freqconvPAL:		.long 0x70788	;@ Frequency conversion (0x70788=high, 0xC3581=low) (3546893/mixer_frequency)*4096
freqconvNTSC:		.long 0x71819	;@ Frequency conversion (0x71819=high, 0xC5247=low) (3579545/mixer_frequency)*4096
freqconv:			.long 0
soundmode:			.long 1		;@ Soundmode (OFF/ON)

	.bss
SIDWAV:
	.space PCMWAVSIZE*6			;@ 16bit 3ch.
;@----------------------------------------------------------------------------
