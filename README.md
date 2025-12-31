# k-remapping

SS-OCT (Swept-Source Optical Coherence Tomography) Signal Remapping Project

This project implements k-space remapping functionality for SS-OCT systems. It receives k-clock signals and performs remapping on OCT signals.

## Overview

This design detects zero-crossing points in k-clock signals, calculates fractional parts, and then performs remapping on OCT signals using linear interpolation to convert from non-uniform k-space sampling to uniform k-space sampling.

## Module Structure

### Top-Level Module
- **`Remapping_TOP.v`** - Top-level module that integrates all sub-modules, includes FIFO buffers for data synchronization

### Core Functional Modules
- **`ZC_kclk.v`** - k-clock zero-crossing detection module
  - Detects zero-crossing points (rising and falling edges) in k-clock signals
  - Calculates fractional parts for subsequent remapping
  - Uses the first 500 samples to calculate mean value as reference level
  - Uses 17 parallel dividers to handle pipelined operations

- **`remapping_oct.v`** - OCT signal remapping module
  - Performs remapping on OCT signals using linear interpolation
  - Calculates interpolation weights based on k-clock fractional parts
  - Outputs remapped OCT signals

- **`divider.v`** - Divider module
  - Implements fixed-point division operations
  - Supports configurable fractional bit width

### Testbench
- **`tb_remapping.v`** - Testbench for functional verification and simulation

## Working Principle

1. **k-clock Processing** (`ZC_kclk.v`)
   - Initialization phase: Uses the first 500 samples to calculate max/min values and determine the mean value as reference level
   - Zero-crossing detection: Detects zero-crossing points of k-clock signals relative to the mean value
   - Fraction calculation: Calculates the fractional part of zero-crossing positions using dividers for precise computation

2. **OCT Signal Buffering** (`Remapping_TOP.v`)
   - Uses FIFO to buffer OCT signals, delays by 518 clock cycles to synchronize with k-clock processing

3. **Signal Remapping** (`remapping_oct.v`)
   - Uses linear interpolation: `output = data[n] * fraction + data[n-1] * (1 - fraction)`
   - Performs weighted average on two adjacent OCT samples based on k-clock fractional parts

## Parameter Configuration

Default parameters (can be modified through parameterization):
- `WIDTH = 16` - Data bit width
- `FRACTIONBIT = 15` - Fractional bit width
- `OUTPUTWIDTH = 16` - Output data bit width
- `FIFO_DEPTH = 2048` - FIFO depth

## File Structure

```
k_remapping/
├── verilog/
│   ├── Remapping_TOP.v      # Top-level module
│   ├── ZC_kclk.v            # k-clock zero-crossing detection module
│   ├── remapping_oct.v      # OCT signal remapping module
│   └── divider.v            # Divider module
└── testbench/
    └── tb_remapping.v       # Testbench
```

## Usage

1. Connect k-clock data to the `kclk_data` input port
2. Connect OCT signal data to the `oct_data` input port
3. Control data validity through the `i_valid` signal
4. Obtain remapped OCT signals from the `o_data` output port
5. The `o_valid` signal indicates output data validity

## Author

Y.T. Tsai

## Version History

- v0.01 - Initial version