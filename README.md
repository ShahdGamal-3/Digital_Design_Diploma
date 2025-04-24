# Digital Design Diploma

## Overview
This repository contains projects developed as part of the Digital Design Diploma. The projects focus on FPGA-based digital design, including SPI Slave with Single Port RAM and DSP48A1 slice implementation. These projects demonstrate expertise in Verilog, VHDL, Vivado, QuestaSim, and FPGA design methodologies.

## Projects

### 1. SPI Slave with Single Port RAM
- **Description**: Designed and implemented an SPI Slave interface integrated with a single-port asynchronous RAM.
- **Key Features**:
  - Verified SPI transactions using directed testbenches in QuestaSim.
  - Conducted timing analysis, synthesis, and FPGA resource utilization.
  - Integrated a debug core for internal signal analysis and successfully generated a bitstream.
- **Tools Used**: Vivado, QuestaSim, Verilog.
- **Files**:
  - RTL: `spi_slave_interface.v`, `single_port_async_ram.v`
  - Testbench: `spi_slave_interface_tb.v`, `single_port_async_ram_tb.v`
  - Constraints: `SPI.xdc`

### 2. DSP48A1 Slice Implementation
- **Description**: Developed and tested a DSP48A1 slice for high-speed digital signal processing on Spartan-6 FPGA.
- **Key Features**:
  - Verified functionality with robust testbenches using directed test patterns.
  - Ensured optimal performance by refining constraints and analyzing timing reports.
  - Evaluated synthesis reports to optimize design efficiency.
- **Tools Used**: Vivado, QuestaSim, Verilog.
- **Files**:
  - RTL: `DSP.v`
  - Testbench: `DSP_tb.v`
  - Constraints: `Constraints_DSP.xdc`

## Directory Structure
- `DSP/`: Contains DSP48A1 slice implementation files.
- `SPI/`: Contains SPI Slave with Single Port RAM implementation files.
- `vivado/`: Vivado project files for both projects.
- `lint/`: Linting reports and logs.
- `wave/`: Waveform images from simulations.
- `PDF/`: Project documentation in PDF format.

## How to Use
1. Clone the repository.
2. Open the Vivado project files in the `vivado/` directory.
3. Run simulations using QuestaSim with the provided testbenches.
4. Synthesize and implement the design in Vivado.

## Acknowledgments
Special thanks to our instructor Kareem Waseem for his invaluable guidance and support.

## License
This repository is licensed under the MIT License. See the LICENSE file for details.
