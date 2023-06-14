//
//  ARM6581.h
//  MOS 6581 "SID" chip emulator for ARM32.
//
//  Created by Fredrik Ahlström on 2006-12-01.
//  Copyright © 2006-2023 Fredrik Ahlström. All rights reserved.
//

#ifndef ARM6581_HEADER
#define ARM6581_HEADER

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
	u8 ch1Freq[2];
	u8 ch1PulseW[2];
	u8 ch1Ctrl;
	u8 ch1AD;			// Attack/Decay
	u8 ch1SR;			// Sustain/Release
	u8 ch2Freq[2];
	u8 ch2PulseW[2];
	u8 ch2Ctrl;
	u8 ch2AD;			// Attack/Decay
	u8 ch2SR;			// Sustain/Release
	u8 ch3Freq[2];
	u8 ch3PulseW[2];
	u8 ch3Ctrl;
	u8 ch3AD;			// Attack/Decay
	u8 ch3SR;			// Sustain/Release
	u8 filterFreq[2];
	u8 filterCtrl;		// Filter
	u8 filterMode;		// Filtermode/volume
	u8 paddle1;
	u8 paddle2;
	u8 osc3Rnd;
	u8 env3Out;
	u8 unused[3];

	u32 ch1Counter;
	u32 ch2Counter;
	u32 ch3Counter;
	u32 ch1Envelope;
	u32 ch2Envelope;
	u32 ch3Envelope;
	u32 ch1Noise;
	u32 ch2Noise;
	u32 ch3Noise;
	u32 ch3Noise_r;

} M6581;

void m6581Init(const M6581 *chip);

void m6581Reset(const M6581 *chip);

/**
 * Saves the state of the M6581 chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The M6581 chip to save.
 * @return The size of the state.
 */
int m6581SaveState(void *destination);
//int m6581SaveState(void *destination, const M6581 *chip);

/**
 * Loads the state of the M6581 chip from the source.
 * @param  *chip: The M6581 chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int m6581LoadState(const void *source);
//int m6581LoadState(M6581 *chip, const void *source);

/**
 * Gets the state size of a M6581.
 * @return The size of the state.
 */
int m6581GetStateSize(void);

void m6581Mixer(int length, void *dest);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // ARM6581_HEADER

