# Dynamic Serial Plotter

## Overview

The Dynamic Serial Plotter is a MATLAB-based tool for real-time plotting of data received from a serial port. It provides a user-friendly interface for selecting signals to plot and configuring plot parameters. This tool is useful for monitoring and visualizing data from various sensors and devices connected via serial communication.

## Features

- Real-time plotting of data received from a serial port.
- Automatic detection of the variable names
- User-friendly interface with checkboxes for selecting signals to plot.
- Adjustable time window size for dynamic visualization.
- Configurable serial port settings (COM port and baud rate).
- Data logging to a CSV file for further analysis.

## Requirements

- MATLAB R2019a or later.
- Serial communication device (e.g., Arduino) sending data in a specified format.

## Getting Started

1. Clone or download the repository.
2. Open MATLAB and navigate to the project directory.
3. Run the `dynamicSerialPlotter.m` file.
4. Select the path and filename in which the data should be stored by navigating to the desired location and clicking the "Save" button in the pop-up window.
5. Configure the serial port settings (COM port and baud rate) and specify the time window size.
6. Click the Start button to begin plotting real-time data.
7. Select the signals to plot using the checkboxes in the UI.
8. Click the Stop button to stop data acquisition and plotting.
9. Close the application when finished.

## Data Format

The data received via the serial port should be formatted as follows:
```
Time:timevalue,Variable1:value1,Variable2:value2,...,VariableN:valueN
```
Where:
- `Time` is the timestamp of the data point.
- `Variable1`, `Variable2`, etc., are the names of the variables being transmitted.
- `value1`, `value2`, etc., are the corresponding values of the variables.

## Example source-device code (Arduino)

```arduino C
void setup() {
  //Create serial communication (for communicating with the computer)
  Serial.begin(9600);
  while (!Serial)
  delay(10);
}

void loop() {
  // write the time variable
  float time = millis()/1000.0;
  Serial.print("Time:");
  Serial.print(time);

  // Generate 3 sine waves
  float DataA = 10*sin(2*3.14*1/5*millis()/1000);
  Serial.print(",DataA:");
  Serial.print(DataA);
  float DataB = 10*sin(2*3.14*1/5*millis()/1000+3.14/2);
  Serial.print(",DataB:");
  Serial.print(DataB);
  float DataC = 10*sin(2*3.14*1/5*millis()/1000+3.14);
  Serial.print(",DataC:");
  Serial.println(DataC);
  delay(5);
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
