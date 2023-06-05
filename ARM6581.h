#ifndef ARM6581_HEADER
#define ARM6581_HEADER

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
	u8 ch1freq[2];
	u8 ch1pulsew[2];
	u8 ch1ctrl;
	u8 ch1ad;			// Attack/Decay
	u8 ch1sr;			// Sustain/Release
	u8 ch2freq[2];
	u8 ch2pulsew[2];
	u8 ch2ctrl;
	u8 ch2ad;			// Attack/Decay
	u8 ch2sr;			// Sustain/Release
	u8 ch3freq[2];
	u8 ch3pulsew[2];
	u8 ch3ctrl;
	u8 ch3ad;			// Attack/Decay
	u8 ch3sr;			// Sustain/Release
	u8 filterfreq[2];
	u8 filterctrl;		// Filter
	u8 filtermode;		// Filtermode/volume
	u8 paddle1;
	u8 paddle2;
	u8 osc3rnd;
	u8 env3out;
	u8 unused[3];

	u32 ch1counter;
	u32 ch2counter;
	u32 ch3counter;
	u32 ch1envelope;
	u32 ch2envelope;
	u32 ch3envelope;
	u32 ch1noise;
	u32 ch2noise;
	u32 ch3noise;
	u32 ch3noise_r;

} M6581;

void m6581Init(const M6581 *chip);

void m6581Reset(const M6581 *chip);

/**
 * Saves the state of the M6581 chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The M6581 chip to save.
 * @return The size of the state.
 */
int m6581SaveState(void *destination, const M6581 *chip);

/**
 * Loads the state of the M6581 chip from the source.
 * @param  *chip: The M6581 chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int m6581LoadState(M6581 *chip, const void *source);

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

