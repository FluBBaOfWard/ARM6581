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
	/// Frequency, 16bit
	u8 freq[2];
	/// Pulse Width, 12bit
	u8 pulseW[2];
	/**
	 * Bit 0 = Gate
	 * Bit 1 = Sync
	 * Bit 2 = Ring
	 * Bit 3 = Test
	 * Bit 4 = Triangle
	 * Bit 5 = Saw
	 * Bit 6 = Pulse
	 * Bit 7 = Noise
	 */
	u8 ctrl;
	/// Attack/Decay
	u8 ad;
	/// Sustain/Release
	u8 sr;
} M6581Channel;

typedef struct {
	M6581Channel ch1;
	M6581Channel ch2;
	M6581Channel ch3;
	/// Filter Frequency, 11bit
	u8 filterFreq[2];
	u8 filterCtrl;		// Filter
	u8 filterMode;		// Filtermode/volume
	u8 paddle1;
	u8 paddle2;
	u8 osc3Rnd;
	u8 env3Out;
	u8 unused[3];

	u8 busValue;
	u8 padding[3];

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

