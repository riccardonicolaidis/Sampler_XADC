# Parametrised ADC sampler using the ARTY A7 developement board
## Introduction
The aim of this project is to create an easy way, HDL implemented, to visualise data coming from the analog to digital converter (ADC) mounted onto the FPGA developement board. In this way, it is possible to characterise the ADC, perform some tests on the ADC performances, test some Digital Signal Processing (DSP) modules or to sample analog signals.

## Details about the project
- The FPGA developement board used is the **ARTY A7** by **Digilent** on which there is tha Artix-7 35T FPGA by Xilinx

![Arty A7 35T](https://digilent.com/reference/_media/reference/programmable-logic/arty/arty-0.png)

- The software used is **Vivado 2021.1** by Xilinx 

![Vivado logo](https://www.xilinx.com/content/dam/xilinx/imgs/products/vivado/vivado-ml/vivado-hero-logo-web.png)

- The HDL language used is **SystemVerilog**

## Functionalities of the developed platform
- Using the IP integrator (IP catalogue) in Vivado, it has been possible to instantiate the XADC module into the design. The Artix-7 FPGA has inside the XADC chip which is the analog to digital converter provided by Xilinx.
- A particular Wrapping circuit has been built in order to create a simple interface accessible from other eventual modules.
- A module called "Printer_UART" has been developed in order to print on screen the data sampled by the XADC.
- The system has also inside a chronometer to store the time at which the sample has been recorded.
- A "Pulse generator" is aimed to the generation of the signal triggering the sampling process. Here, by sampling process, I mean that the pulse will enable the printer to send the data via the UART cable to a computer.
- To read the data from the UART cable it is possible to use a terminal like "PuTTY".


- In this specific implementation, the sampling frequency (in this case I am referring to the samples displayed on the PC screen and not the actual sampling frequency of the XADC) is 1 Hz. However, this frequency can be changed in the top module changing the period of the PULSE_GENERATOR. 


In the picture below you can see the data sent by the FPGA via the UART cable.

![PuTTY terminal window](Terminal_output.png) 

The numbers displayed represents the following data:
- First column: Time expressed in milliseconds. Since the sampling frequency set up is 1Hz you can see that the least significant digits are zero. 
- Second and third column: The digitalised output from the pin A0. (Sincerely I don't know why the "Printer module" is sending this channel twice.) 
- Fourth column: The digitalised output from the pin A1.
- Fifth column: Eventual digitalised output from pin A2. In this case the XADC is configured only for the acquisition of the channels A0 and A1. Therefore the last column is populated by the constant value 2048 (see later for the reason why it is 2048 and not 0).

## Important remark on the number convention adopted.
- The XADC has been configured in the "Bipolar mode". This means that it can digitalise voltage signals in the range -1.5 V to +1.5 V. The resultant digitalised number is returned in the **bipolar binary notation**. This means that a negative signal is coded with the **2's complement**. 
- Since in the output I didn't want to print the + and - characters, I translated the numbers from the bipolar notation to the unipolar notation. Then, I had to negate the most significant bit. To understand better see the following example:

EXAMPLE: 
1. Input = 0 V
2. Digitalised input = 000000000000
3. From bipolar notation (000000000000) to bipolar notation 1000000000000
4. From binary to decimal we obtain 2^(12-1) = 2^11 = 2048





## IP catalogue
To build up the design I have used some IPs by Xilinx. These modules can be configurated from the **IP catalogue** in **Vivado**. 
To create your personal module follow these steps:
- Click on IP catalogue in the **Project flow navigator**
- Search for the desired IP. In our case the IPs used are the **XADC Wiziard** and the **FIFO generator**
- Click on the IP desired
- Customize the IP according to the fatures required
- Click on **Generate IP instance**
- Then you have to generate and synthesise the required files (Click on **Generate** in the pop-up window). 
- In the file manager, where you can see the **Source Hierarchy** click on the **IP sources** panel.
- In the path: IP_COMPONENT_NAME >> Instantiation template >> ...    youìll find the two **Instantiation templates**, one written in **Verilog HDL** and the other in **VHDL**. Now you can instantiate your customised module into your design. 




## Some resources
Here some useful online resources which I have used to develope this simple ADC sampler:
- Digilent reference webpage (Arty A7) : https://digilent.com/reference/programmable-logic/arty-a7/start

![Digilent logo](https://cdn11.bigcommerce.com/s-7gavg/images/stencil/original/digilent-logo_ni_2021-260px_1_1627086513__23106.original.png)

- Arty A7 reference manual : https://digilent.com/reference/programmable-logic/arty-a7/reference-manual
- OpenCores (a useful web platform where it is possible to find HDL open source cores) : https://opencores.org/
- Companion website for the book **FPGA prototyping by SystemVerilog examples** by Dr. Chu : https://academic.csuohio.edu/chu_p/index.html
- Xilinx Vivado website: https://www.xilinx.com/products/design-tools/vivado.html
- Digilent GitHub repositories : https://github.com/digilent

## How to create a Vivado project
To build up a Vivado project, the following operations are required:
- Open Vivado
- Click on **New project**
- Give a name to the project and click on **Create project subdirectory** and click on **Next**
- Click on **RTL project**. Then, click **Next**
- Now choose all the sources files .v (if the files are written in verilog), .sv (if they are written in SystemVerilog), .vhd (if files are written in VHDL), click on **Scan and add RTL include files into the project** and **Copy sources into project**. Then, click on **Next**
- Import the **Costraint file** .xdc in the same manner as before.
- Now you need to select the **Target device**. To do this, select the **Boards** menu and search for **ARTY A7-35T**. To do this operation you need to install on your computer the **Digilent boards files**. This procedure is described at the following link https://digilent.com/reference/programmable-logic/guides/installing-vivado-and-vitis if you use the latest versions of Vivado and Vitis unified platform or the following link https://digilent.com/reference/programmable-logic/guides/installing-vivado-and-sdk if you use Vivado and Vivado SDK. 
- Now it is possible to modify the project, run the synthesis, the implementation and the bitstream generation
