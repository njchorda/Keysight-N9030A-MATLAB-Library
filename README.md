# N9030A — MATLAB VISA Driver

A MATLAB class for communicating with the **Keysight N9030A PXA Signal Analyzer** over VISA (TCP/IP). Wraps common instrument control operations into a clean, readable interface so you can spend less time writing SCPI and more time measuring.

---

## Requirements

- MATLAB R2021a or later (uses `visadev`)
- [Instrument Control Toolbox](https://www.mathworks.com/products/instrument.html)
- Keysight IO Libraries Suite (or compatible VISA layer)
- Keysight N9030A connected via LAN (resource name containing `inst0`)

---

## Installation

1. Copy `N9030A.m` into your MATLAB working directory or add it to your path.
2. Ensure your N9030A is reachable on the network and appears in `visadevlist`.

---

## Quick Start

```matlab
% Discover and connect to the instrument
pxa = N9030A();

% Set frequency range (Hz)
pxa.setFreqRange(1e9, 3e9);   % 1 GHz – 3 GHz

% Trigger a single sweep and wait
pxa.triggerOnce();
pxa.waitUntilDone();

% Read back trace data
[datadB, freqAxis] = pxa.readTrace();

% Plot
plot(freqAxis / 1e9, datadB);
xlabel('Frequency (GHz)');
ylabel('Amplitude (dBm)');
title('N9030A Spectrum');

% Clean up
pxa.deInit();
```

---

## API Reference

### Constructor

```matlab
obj = N9030A()
```

Scans `visadevlist` for an N9030A instrument with `inst0` in its resource name, opens the VISA connection, clears the instrument state, and verifies the error queue.

---

### Frequency Control

| Method | Description |
|---|---|
| `setFreqRange(start, stop)` | Set start and stop frequency in Hz |
| `[fStart, fStop] = getFreqRange()` | Query current start/stop frequency |

---

### Sweep & Triggering

| Method | Description |
|---|---|
| `triggerOnce()` | Disable continuous mode and fire a single sweep |
| `setContinuous(bool)` | Enable (`true`) or disable (`false`) continuous sweep mode |
| `waitUntilDone()` | Poll `*OPC?` until the current operation completes |

---

### Data Acquisition

| Method | Description |
|---|---|
| `[datadB, freqAxis] = readTrace()` | Read TRACE1 and return amplitude array + frequency axis |
| `datadB = getTraceData()` | Return raw amplitude data from TRACE1 (dBm) |
| `val = amplitudeAtFrequency(freq)` | Peak amplitude near `freq` Hz (default IF BW: 10 MHz) |
| `val = amplitudeAtFrequency(freq, IFBW)` | Peak amplitude near `freq` Hz within a custom IF bandwidth |

---

### Instrument Management

| Method | Description |
|---|---|
| `reset()` | Send `SYST:PRES` to restore default settings |
| `sendCommand(cmd)` | Send a raw SCPI command string |
| `rsp = sendResp(cmd)` | Send a SCPI query and return the response string |
| `bool = deInit()` | Return instrument to local control, reset, and close connection |

---

## Notes

- The output buffer is set to **640 000 bytes** to accommodate large trace payloads.
- `waitUntilDone()` will emit a warning and break after 10 000 polling cycles to prevent infinite loops.
- `amplitudeAtFrequency` returns the **peak** amplitude within the specified bandwidth window around the target frequency.
- Always call `deInit()` when finished to release the VISA resource cleanly.

---

## License

MIT — see [LICENSE](LICENSE) for details.
