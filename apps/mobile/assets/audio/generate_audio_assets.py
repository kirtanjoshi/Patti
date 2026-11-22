import os
import math
import wave
import numpy as np

SAMPLE_RATE = 44100
AUDIO_DIR = os.path.dirname(os.path.abspath(__file__))

def save_wav(name: str, audio: np.ndarray, peak_db: float = -1.5):
    """Normalize and write 16-bit PCM stereo WAV file."""
    if audio.ndim == 1:
        audio = np.column_stack((audio, audio))
    elif audio.shape[0] == 2 and audio.shape[1] != 2:
        audio = audio.T

    # Peak normalization
    peak_linear = 10.0 ** (peak_db / 20.0)
    current_peak = np.max(np.abs(audio))
    if current_peak > 1e-6:
        audio = (audio / current_peak) * peak_linear
    else:
        audio = np.zeros_like(audio)

    pcm = np.clip(audio * 32767.0, -32768.0, 32767.0).astype(np.int16)
    out_path = os.path.join(AUDIO_DIR, name)
    with wave.open(out_path, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(pcm.tobytes())
    size = os.path.getsize(out_path)
    dur = len(pcm) / SAMPLE_RATE
    print(f"Generated {name:<20} | {dur:5.2f}s | {size:7d} bytes")

def envelope(t, attack, decay, sustain_level=0.0, release=0.0):
    """Generates standard ADSR envelope array."""
    env = np.zeros_like(t)
    total_dur = t[-1]
    sustain_time = max(0.0, total_dur - attack - decay - release)
    
    for i, ti in enumerate(t):
        if ti < attack:
            env[i] = ti / attack if attack > 0 else 1.0
        elif ti < attack + decay:
            progress = (ti - attack) / decay
            env[i] = 1.0 - (1.0 - sustain_level) * progress
        elif ti < attack + decay + sustain_time:
            env[i] = sustain_level
        else:
            rel_prog = (ti - attack - decay - sustain_time) / release if release > 0 else 1.0
            env[i] = sustain_level * (1.0 - min(1.0, rel_prog))
    return env

# ==============================================================================
# 1. CARD SOUNDS
# ==============================================================================

def gen_card_snap():
    # 0.12s total
    dur = 0.12
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # High crisp paper snap click (3200Hz - 5400Hz)
    click = np.sin(2 * np.pi * 3800 * t) * np.exp(-t * 120)
    # Felt slap body (240Hz thud)
    body = np.sin(2 * np.pi * 240 * t) * np.exp(-t * 45)
    # Paper noise burst
    noise = np.random.uniform(-1, 1, len(t)) * np.exp(-t * 90)
    mono = (click * 0.6 + body * 0.5 + noise * 0.3)
    return np.column_stack((mono, mono * 0.95))

def gen_card_slide():
    # 0.18s smooth felt friction slide
    dur = 0.18
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # White noise with bandpass shaping (moving paper on cloth)
    noise = np.random.uniform(-1, 1, len(t))
    # Soft bell envelope
    env = np.sin(np.pi * (t / dur)) ** 1.5
    # Resonance at 1400Hz and 2600Hz
    res1 = np.sin(2 * np.pi * 1400 * t)
    res2 = np.sin(2 * np.pi * 2600 * t)
    slide = noise * env * 0.7 + (res1 + res2) * 0.15 * env
    # Slight stereo pan sweep (left to right)
    pan_l = np.linspace(0.8, 0.4, len(t))
    pan_r = np.linspace(0.4, 0.8, len(t))
    return np.column_stack((slide * pan_l, slide * pan_r))

def gen_deal():
    # 0.16s: fast whoosh + felt placement snap
    dur = 0.16
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # Swept whoosh frequency: 2200Hz down to 800Hz
    freq = np.linspace(2200, 800, len(t))
    phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
    whoosh = np.sin(phase) * (np.sin(np.pi * (t / dur)) ** 2) * 0.4
    noise = np.random.uniform(-1, 1, len(t)) * np.exp(-t * 35) * 0.35
    # Landing snap in second half
    snap_t = np.maximum(0, t - 0.08)
    landing = np.sin(2 * np.pi * 320 * snap_t) * np.exp(-snap_t * 60) * 0.5
    mono = whoosh + noise + landing
    return np.column_stack((mono, mono * 0.9))

def gen_shuffle():
    # 0.80s: Riffle shuffle interleaving 24 cards then cascade bridge
    dur = 0.80
    total_samples = int(SAMPLE_RATE * dur)
    left = np.zeros(total_samples)
    right = np.zeros(total_samples)
    
    # 22 riffle clicks spaced tightly (every 16-25ms)
    t_click = 0.04
    for i in range(22):
        pos = int(t_click * SAMPLE_RATE)
        click_len = int(SAMPLE_RATE * 0.025)
        if pos + click_len < total_samples:
            sub_t = np.linspace(0, 0.025, click_len, endpoint=False)
            freq = 2800 + (i % 5) * 250
            c = (np.sin(2 * np.pi * freq * sub_t) + 0.4 * np.random.uniform(-1, 1, click_len)) * np.exp(-sub_t * 180)
            pan = (i % 2) * 0.4 + 0.3  # alternate between stereo channels
            left[pos:pos+click_len] += c * pan
            right[pos:pos+click_len] += c * (1.0 - pan)
        t_click += 0.016 + (i * 0.0006)
        
    # Bridge sweep at the end (0.55s - 0.78s)
    bridge_start = int(0.52 * SAMPLE_RATE)
    bridge_len = total_samples - bridge_start
    bt = np.linspace(0, bridge_len / SAMPLE_RATE, bridge_len, endpoint=False)
    b_noise = np.random.uniform(-1, 1, bridge_len) * np.sin(np.pi * (bt / (bridge_len / SAMPLE_RATE))) * 0.35
    b_thud = np.sin(2 * np.pi * 180 * bt) * np.exp(-bt * 18) * 0.4
    left[bridge_start:] += b_noise + b_thud
    right[bridge_start:] += b_noise + b_thud
    return np.column_stack((left, right))

def gen_card_fold():
    # 0.30s: Two cards swept into muck (soft double swoosh + felt thud)
    dur = 0.30
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # First card slide
    c1 = np.random.uniform(-1, 1, len(t)) * (np.sin(np.pi * np.clip(t / 0.15, 0, 1)) ** 2) * 0.4
    # Second card slide slightly offset
    t2 = np.maximum(0, t - 0.07)
    c2 = np.random.uniform(-1, 1, len(t)) * (np.sin(np.pi * np.clip(t2 / 0.16, 0, 1)) ** 2) * 0.45
    # Muffled low impact at end
    thud = np.sin(2 * np.pi * 150 * t) * np.exp(-t * 20) * 0.3
    mono = c1 + c2 + thud
    return np.column_stack((mono * 0.8, mono))

# ==============================================================================
# 2. CHIP SOUNDS (CERAMIC CLINK)
# ==============================================================================

def gen_chip():
    # 0.14s: Authentic ceramic clay casino chip
    dur = 0.14
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # High-Q resonant ceramic modes
    m1 = np.sin(2 * np.pi * 2350 * t) * np.exp(-t * 55)
    m2 = np.sin(2 * np.pi * 4400 * t) * np.exp(-t * 70) * 0.5
    m3 = np.sin(2 * np.pi * 6900 * t) * np.exp(-t * 90) * 0.25
    # Low body resonance
    body = np.sin(2 * np.pi * 380 * t) * np.exp(-t * 35) * 0.4
    mono = m1 + m2 + m3 + body
    return np.column_stack((mono, mono * 0.95))

def gen_chip_multi():
    # 0.22s: Triple chip clink for chaal raise / betting stack
    dur = 0.22
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    sig_l = np.zeros_like(t)
    sig_r = np.zeros_like(t)
    
    offsets = [0.0, 0.035, 0.075]
    freqs = [2250, 2600, 2450]
    pans = [0.4, 0.65, 0.5]
    for off, f, p in zip(offsets, freqs, pans):
        st = np.maximum(0, t - off)
        mask = (t >= off).astype(float)
        chip = (np.sin(2 * np.pi * f * st) * np.exp(-st * 50) +
                np.sin(2 * np.pi * (f * 1.85) * st) * np.exp(-st * 65) * 0.4 +
                np.sin(2 * np.pi * 340 * st) * np.exp(-st * 30) * 0.35) * mask
        sig_l += chip * p
        sig_r += chip * (1.0 - p)
    return np.column_stack((sig_l, sig_r))

def gen_pot_collect():
    # 0.70s: Cascade of chips swept into winner's stack
    dur = 0.70
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    left = np.zeros_like(t)
    right = np.zeros_like(t)
    
    np.random.seed(42)
    # 12 chips clattering inwards
    for i in range(12):
        off = i * 0.042 + np.random.uniform(0, 0.015)
        st = np.maximum(0, t - off)
        mask = (t >= off).astype(float)
        f = 2100 + np.random.uniform(0, 900)
        pan = 0.15 + 0.7 * (i / 11.0)
        chip = (np.sin(2 * np.pi * f * st) * np.exp(-st * 60) +
                np.sin(2 * np.pi * 360 * st) * np.exp(-st * 30) * 0.3) * mask
        left += chip * pan
        right += chip * (1.0 - pan)
    # Felt slide sound underlying
    slide = np.random.uniform(-1, 1, len(t)) * (np.sin(np.pi * (t / dur)) ** 2) * 0.25
    left += slide
    right += slide
    return np.column_stack((left, right))

# ==============================================================================
# 3. GAME STATE & UI CUES
# ==============================================================================

def gen_your_turn():
    # 0.75s: Dual warm marimba/vibraphone chime (E5 -> A5)
    dur = 0.75
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # Note 1: E5 (659.25 Hz)
    e5 = (np.sin(2 * np.pi * 659.25 * t) +
          0.35 * np.sin(2 * np.pi * 1318.5 * t) +
          0.15 * np.sin(2 * np.pi * 1977.75 * t)) * np.exp(-t * 8)
    # Note 2: A5 (880.0 Hz) starting at 0.11s
    t2 = np.maximum(0, t - 0.11)
    mask2 = (t >= 0.11).astype(float)
    a5 = (np.sin(2 * np.pi * 880.0 * t2) +
          0.4 * np.sin(2 * np.pi * 1760.0 * t2) +
          0.2 * np.sin(2 * np.pi * 2640.0 * t2)) * np.exp(-t2 * 6) * mask2
    
    left = e5 * 0.8 + a5 * 0.5
    right = e5 * 0.5 + a5 * 0.85
    return np.column_stack((left, right))

def gen_countdown_tick():
    # 0.08s: Subtle, crisp woodblock clock tick
    dur = 0.08
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # 1350Hz fundamental + 2700Hz harmonic
    tick = (np.sin(2 * np.pi * 1350 * t) + 0.3 * np.sin(2 * np.pi * 2700 * t)) * np.exp(-t * 90)
    # Soft tactile transient
    trans = np.sin(2 * np.pi * 4200 * t) * np.exp(-t * 180) * 0.3
    mono = tick + trans
    return np.column_stack((mono, mono))

def gen_countdown_urgent():
    # 0.18s: Urgent double heartbeat pulse
    dur = 0.18
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # Pulse 1 at 0.0s
    p1 = (np.sin(2 * np.pi * 140 * t) * np.exp(-t * 30) * 0.6 +
          np.sin(2 * np.pi * 1600 * t) * np.exp(-t * 120) * 0.4)
    # Pulse 2 at 0.07s
    t2 = np.maximum(0, t - 0.07)
    mask2 = (t >= 0.07).astype(float)
    p2 = (np.sin(2 * np.pi * 115 * t2) * np.exp(-t2 * 25) * 0.7 +
          np.sin(2 * np.pi * 1300 * t2) * np.exp(-t2 * 100) * 0.35) * mask2
    mono = p1 + p2
    return np.column_stack((mono, mono))

def gen_button_click():
    # 0.035s: Luxurious tactile UI click (soft, non-fatiguing)
    dur = 0.035
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    click = np.sin(2 * np.pi * 1950 * t) * np.sin(np.pi * (t / dur)) * np.exp(-t * 110)
    body = np.sin(2 * np.pi * 420 * t) * np.exp(-t * 70) * 0.35
    mono = click + body
    return np.column_stack((mono, mono))

def gen_special_hand():
    # 1.4s: Resonant orchestral chime / gong swell for Trio / Trump Cut / Tiplu
    dur = 1.4
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # Major triad bells: C5 (523Hz), G5 (784Hz), C6 (1046Hz)
    c5 = np.sin(2 * np.pi * 523.25 * t) * np.exp(-t * 3.5)
    g5 = np.sin(2 * np.pi * 783.99 * t) * np.exp(-t * 4.0) * 0.7
    c6 = np.sin(2 * np.pi * 1046.50 * t) * np.exp(-t * 4.5) * 0.5
    # Shimmering high bell overtone (2093Hz)
    shimmer = np.sin(2 * np.pi * 2093.0 * t) * np.exp(-t * 6.0) * 0.3
    # Sub bass boom (90Hz)
    boom = np.sin(2 * np.pi * 90 * t) * np.exp(-t * 8) * 0.5
    left = c5 * 0.8 + g5 * 0.5 + c6 * 0.7 + shimmer * 0.4 + boom
    right = c5 * 0.5 + g5 * 0.8 + c6 * 0.6 + shimmer * 0.6 + boom
    return np.column_stack((left, right))

def gen_error_buzz():
    # 0.22s: Soft double wooden knock for invalid moves
    dur = 0.22
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    k1 = np.sin(2 * np.pi * 190 * t) * np.exp(-t * 40)
    t2 = np.maximum(0, t - 0.08)
    mask2 = (t >= 0.08).astype(float)
    k2 = np.sin(2 * np.pi * 145 * t2) * np.exp(-t2 * 40) * mask2
    mono = (k1 + k2) * 0.7
    return np.column_stack((mono, mono))

# ==============================================================================
# 4. VICTORY, LOSS, AND REWARDS
# ==============================================================================

def gen_win_jingle():
    # 1.8s: Radiant C-Major victory fanfare (C5 -> E5 -> G5 -> C6 shimmer)
    dur = 1.8
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    notes = [
        (0.00, 523.25, 0.7, 5.0),   # C5
        (0.14, 659.25, 0.7, 5.0),   # E5
        (0.28, 783.99, 0.8, 4.5),   # G5
        (0.42, 1046.50, 1.0, 3.0),  # C6
        (0.42, 1318.51, 0.6, 3.2),  # E6
        (0.42, 1567.98, 0.5, 3.5),  # G6
    ]
    left = np.zeros_like(t)
    right = np.zeros_like(t)
    
    for start, freq, amp, decay in notes:
        st = np.maximum(0, t - start)
        mask = (t >= start).astype(float)
        # Fundamental + harmonics for rich brass/synth bell
        tone = (np.sin(2 * np.pi * freq * st) +
                0.35 * np.sin(2 * np.pi * (freq * 2) * st) +
                0.15 * np.sin(2 * np.pi * (freq * 3) * st)) * np.exp(-st * decay) * mask * amp
        pan = 0.3 + 0.4 * (freq / 1600.0)
        left += tone * pan
        right += tone * (1.0 - pan)
    # Warm sub-bass support on final chord
    sub_t = np.maximum(0, t - 0.42)
    sub = np.sin(2 * np.pi * 130.81 * sub_t) * np.exp(-sub_t * 3.0) * (t >= 0.42).astype(float) * 0.5
    left += sub
    right += sub
    return np.column_stack((left, right))

def gen_lose_stinger():
    # 1.4s: Gentle, mellow descending minor chord (A4 -> F4 -> D4)
    dur = 1.4
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    notes = [
        (0.00, 440.00, 0.6),  # A4
        (0.20, 349.23, 0.6),  # F4
        (0.42, 293.66, 0.7),  # D4
    ]
    left = np.zeros_like(t)
    right = np.zeros_like(t)
    for start, freq, amp in notes:
        st = np.maximum(0, t - start)
        mask = (t >= start).astype(float)
        tone = (np.sin(2 * np.pi * freq * st) +
                0.25 * np.sin(2 * np.pi * (freq * 2) * st)) * np.exp(-st * 3.5) * mask * amp
        left += tone * 0.7
        right += tone * 0.6
    # Low warm felt thud at end
    thud = np.sin(2 * np.pi * 95 * t) * np.exp(-t * 6) * 0.35
    left += thud
    right += thud
    return np.column_stack((left, right))

def gen_coins_collect():
    # 0.90s: Cascading coin shower (18 shimmering metallic coins)
    dur = 0.90
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    left = np.zeros_like(t)
    right = np.zeros_like(t)
    
    np.random.seed(101)
    for i in range(18):
        start = i * 0.038 + np.random.uniform(0, 0.02)
        st = np.maximum(0, t - start)
        mask = (t >= start).astype(float)
        freq = 3200 + np.random.uniform(0, 3800)
        pan = np.random.uniform(0.1, 0.9)
        coin = (np.sin(2 * np.pi * freq * st) +
                0.4 * np.sin(2 * np.pi * (freq * 1.6) * st)) * np.exp(-st * 75) * mask
        left += coin * pan
        right += coin * (1.0 - pan)
    return np.column_stack((left, right))

# ==============================================================================
# 5. AMBIENT LOOPS (SEAMLESS BGM)
# ==============================================================================

def gen_lobby_ambient():
    # 16.0s luxury casino lounge loop (80 BPM, 4/4 time = 4 bars, 16 beats)
    # Chord progression: Dm9 -> G13 -> Cmaj9 -> Am9 (smooth jazz casino lounge)
    dur = 16.0
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    left = np.zeros_like(t)
    right = np.zeros_like(t)
    
    # Chords (frequencies for root, 3rd, 5th, 7th, 9th)
    chords = [
        # Bar 1: Dm9 (D3, F3, A3, C4, E4)
        (0.0, 4.0, [146.83, 174.61, 220.00, 261.63, 329.63], 146.83),
        # Bar 2: G13 (G2, B3, F4, A4, E4)
        (4.0, 8.0, [98.00, 246.94, 349.23, 440.00, 329.63], 98.00),
        # Bar 3: Cmaj9 (C3, E3, G3, B3, D4)
        (8.0, 12.0, [130.81, 164.81, 196.00, 246.94, 293.66], 130.81),
        # Bar 4: Am9 (A2, C3, E3, G3, B3)
        (12.0, 16.0, [110.00, 130.81, 164.81, 196.00, 246.94], 110.00),
    ]
    
    for bar_start, bar_end, freqs, bass_freq in chords:
        bar_mask = (t >= bar_start) & (t < bar_end)
        bar_t = t[bar_mask] - bar_start
        bar_dur = bar_end - bar_start
        # Smooth window envelope for chord
        chord_env = np.sin(np.pi * (bar_t / bar_dur)) ** 0.6
        
        # Rhodes EP sound: fundamental + warm 2nd/3rd harmonics + gentle chorus/tremolo
        tremolo = 1.0 + 0.15 * np.sin(2 * np.pi * 4.5 * bar_t)
        chord_sig = np.zeros_like(bar_t)
        for i, f in enumerate(freqs):
            h1 = np.sin(2 * np.pi * f * bar_t)
            h2 = 0.3 * np.sin(2 * np.pi * f * 2 * bar_t)
            h3 = 0.1 * np.sin(2 * np.pi * f * 3 * bar_t)
            pan_offset = 0.1 * (i - 2)
            chord_sig += (h1 + h2 + h3) * (0.12 / len(freqs))
            
        left[bar_mask] += chord_sig * chord_env * tremolo * 0.8
        right[bar_mask] += chord_sig * chord_env * tremolo * 0.85
        
        # Walking Bass
        bass_env = np.sin(np.pi * np.clip(bar_t / 0.8, 0, 1)) * np.exp(-bar_t * 0.5)
        bass = (np.sin(2 * np.pi * bass_freq * bar_t) +
                0.25 * np.sin(2 * np.pi * bass_freq * 2 * bar_t)) * bass_env * 0.35
        left[bar_mask] += bass
        right[bar_mask] += bass
        
    # Shaker / soft acoustic hi-hat on every eighth note
    beat_dur = 60.0 / 80.0  # 0.75s per quarter, 0.375s per eighth
    num_eighths = int(dur / (beat_dur / 2))
    for i in range(num_eighths):
        s_time = i * (beat_dur / 2)
        st = np.maximum(0, t - s_time)
        mask = (t >= s_time) & (t < s_time + 0.06)
        shaker = np.random.uniform(-1, 1, len(t)) * np.exp(-st * 90) * mask * 0.06
        left += shaker * 0.4
        right += shaker * 0.6
        
    # Gentle seamless loop crossfade (1.5s window)
    xfade_dur = 1.5
    xfade_samples = int(xfade_dur * SAMPLE_RATE)
    fade_in = np.linspace(0, 1, xfade_samples)
    fade_out = 1.0 - fade_in
    
    # Blend end of track into start
    head_l = left[:xfade_samples].copy()
    head_r = right[:xfade_samples].copy()
    tail_l = left[-xfade_samples:].copy()
    tail_r = right[-xfade_samples:].copy()
    
    left[:xfade_samples] = head_l * fade_in + tail_l * fade_out
    right[:xfade_samples] = head_r * fade_in + tail_r * fade_out
    left[-xfade_samples:] = left[:xfade_samples]
    right[-xfade_samples:] = right[:xfade_samples]
    
    return np.column_stack((left * 0.7, right * 0.7))

def gen_table_ambient():
    # 8.0s seamless quiet casino table room tone
    dur = 8.0
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # Deep warm room resonance (55Hz and 110Hz)
    sub = (np.sin(2 * np.pi * 55 * t) + 0.3 * np.sin(2 * np.pi * 110 * t)) * 0.08
    # Subtle felt / vinyl warmth
    noise = np.random.uniform(-1, 1, len(t)) * 0.02
    left = sub + noise
    right = sub + noise * 0.95
    
    # Seamless loop crossfade
    xfade_samples = int(1.0 * SAMPLE_RATE)
    fade_in = np.linspace(0, 1, xfade_samples)
    fade_out = 1.0 - fade_in
    left[:xfade_samples] = left[:xfade_samples] * fade_in + left[-xfade_samples:] * fade_out
    right[:xfade_samples] = right[:xfade_samples] * fade_in + right[-xfade_samples:] * fade_out
    left[-xfade_samples:] = left[:xfade_samples]
    right[-xfade_samples:] = right[:xfade_samples]
    
    return np.column_stack((left * 0.4, right * 0.4))

# ==============================================================================
# MAIN BATCH GENERATOR
# ==============================================================================

def main():
    print("=" * 60)
    print("PATII SOUND DESIGN ENGINE - GENERATING ASSETS")
    print("=" * 60)
    
    save_wav("card_snap.wav", gen_card_snap())
    save_wav("card_slide.wav", gen_card_slide())
    save_wav("deal.wav", gen_deal())
    save_wav("shuffle.wav", gen_shuffle())
    save_wav("card_fold.wav", gen_card_fold())
    save_wav("chip.wav", gen_chip())
    save_wav("chip_single.wav", gen_chip())
    save_wav("chip_multi.wav", gen_chip_multi())
    save_wav("pot_collect.wav", gen_pot_collect())
    save_wav("your_turn.wav", gen_your_turn())
    save_wav("countdown_tick.wav", gen_countdown_tick())
    save_wav("countdown_urgent.wav", gen_countdown_urgent())
    save_wav("button_click.wav", gen_button_click())
    save_wav("special_hand.wav", gen_special_hand())
    save_wav("error_buzz.wav", gen_error_buzz())
    save_wav("win_jingle.wav", gen_win_jingle())
    save_wav("lose_stinger.wav", gen_lose_stinger())
    save_wav("coins_collect.wav", gen_coins_collect())
    save_wav("lobby_ambient.wav", gen_lobby_ambient())
    save_wav("table_ambient.wav", gen_table_ambient())
    
    print("=" * 60)
    print("ALL 20 HIGH-FIDELITY AUDIO ASSETS GENERATED SUCCESSFULLY")
    print("=" * 60)

if __name__ == "__main__":
    main()
