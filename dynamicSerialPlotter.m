function dynamicSerialPlotter
% Dynamic Serial Plotter
% 
% Overview:
% - MATLAB-based tool for real-time plotting of data from a serial port.
% - User-friendly interface for selecting signals to plot and configuring parameters.
% 
% Features:
% - Real-time plotting of serial data.
% - Automatic detection of variable names.
% - Adjustable time window size.
% - Configurable serial port settings.
% - Data logging to CSV for analysis.
% 
% Requirements:
% - MATLAB R2019a or later.
% - Serial communication device (e.g., Arduino) sending data in specified format.
% 
% Getting Started:
% 1. Clone/download repository.
% 2. Run `dynamicSerialPlotter.m`.
% 3. Select path and filename to store data.
% 4. Configure COM port, baud rate, and time window.
% 5. Click Start to plot real-time data.
% 6. Select signals with checkboxes.
% 7. Click Stop to end plotting.
% 8. Close application when finished.
% 
% Data Format:
% - Data received via serial port:
%   "Time:timevalue,Variable1:value1,...,VariableN:valueN"
% 
% Example Arduino Code:
        % void setup() {
        %   //Create serial communication (for communicating with the computer)
        %   Serial.begin(9600);
        %   while (!Serial)
        %   delay(10);
        % }
        % 
        % void loop() {
        %   // write the time variable
        %   float time = millis()/1000.0;
        %   Serial.print("Time:");
        %   Serial.print(time);
        % 
        %   // Generate 3 sine waves
        %   float DataA = 10*sin(2*3.14*1/5*millis()/1000);
        %   Serial.print(",DataA:");
        %   Serial.print(DataA);
        %   float DataB = 10*sin(2*3.14*1/5*millis()/1000+3.14/2);
        %   Serial.print(",DataB:");
        %   Serial.print(DataB);
        %   float DataC = 10*sin(2*3.14*1/5*millis()/1000+3.14);
        %   Serial.print(",DataC:");
        %   Serial.println(DataC);
        %   delay(5);
        % }
% 
% License:
% MIT License - see LICENSE file.
%
% Nicolas Herzig 2024


    % Create a figure for the GUI
    fig = figure('Name', 'Real-Time Serial Plotter', 'NumberTitle', 'off', ...
                 'Position', [100, 100, 1000, 600], 'CloseRequestFcn', @closeFig);
    
    % UIAxes for plotting
    ax = axes('Parent', fig, 'Position', [0.1, 0.1, 0.6, 0.8]);
    title(ax, 'Real-time Data Plot');
    xlabel(ax, 'Time');
    hold(ax, 'on');
    
    % Panel for checkboxes
    checkboxPanel = uipanel('Parent', fig, 'Title', 'Select Signals to Plot', ...
                            'Position', [0.75, 0.3, 0.2, 0.6]);
    
    % Initialize serial port and timer
    serialObj = [];
    timerObj = [];

    % Count of dynamically added fields
    numFields = 0;

    % Data storage for plotting
    timeData = [];
    dataStruct = struct();  % To hold different variables dynamically
    
    % UI element storage
    fieldStruct = struct();
    checkboxStruct = struct();
    
    
    
    % Figure and Save parameters
    figparPanel = uipanel('Parent', fig, 'Title', 'Fig and save parameters', ...
                            'Position', [0.75, 0.1, 0.2, 0.2]);
    % Time window size edit field
    uicontrol('Parent', figparPanel,'Style', 'text', 'Units', 'normalized', 'Position', [0, 0.8, 1, 0.2], 'String', 'Time Window Size');
    windowSizeField = uicontrol('Parent', figparPanel,'Style', 'edit', 'Units', 'normalized', 'Position',[0, 0.6, 1, 0.2], 'String', 10);
    %file name field
    uicontrol('Parent', figparPanel,'Style', 'text', 'Units', 'normalized', 'Position', [0, 0.4, 0.5, 0.2], 'String', 'COMPort');
    comPortField = uicontrol('Parent', figparPanel,'Style', 'popupmenu', 'Units', 'normalized', 'Position',[0, 0.2, 0.5, 0.2], 'String', {'COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9','COM10'},'Value',10);
    uicontrol('Parent', figparPanel,'Style', 'text', 'Units', 'normalized', 'Position', [0.5, 0.4, 0.5, 0.2], 'String', 'Baudrate');
    bauderateField = uicontrol('Parent', figparPanel,'Style', 'edit', 'Units', 'normalized', 'Position',[0.5, 0.2, 0.5, 0.2], 'String', '9600');
    % Start and Stop buttons
    uicontrol('Parent', figparPanel,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0, 0, 0.5, 0.2], ...
              'String', 'Start', 'Callback', @startButtonPushed);
    uicontrol('Parent', figparPanel,'Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.5, 0, 0.5, 0.2], ...
              'String', 'Stop', 'Callback', @stopButtonPushed);

    % Initialize CSV file
    headers = {'Time'};
    [file, path] = uiputfile('test.csv');
    csvFilePath = fullfile(path, file);

    % Open file in append mode
    fid = fopen(csvFilePath, 'a');

    function startButtonPushed(~, ~)
        if isempty(serialObj)
            % Use COM10 as the serial port name
            serialObj = serialport(comPortField.String{comPortField.Value}, str2num(bauderateField.String));  
            configureTerminator(serialObj, "LF");
        end
        
        if isempty(timerObj)
            timerObj = timer('ExecutionMode', 'fixedSpacing', ...
                             'Period', 0.01, ...
                             'TimerFcn', @readSerialData);
        end
        
        start(timerObj);
    end

    function stopButtonPushed(~, ~)
        if ~isempty(timerObj)
            stop(timerObj);
        end
    end

    function readSerialData(~, ~)
        if serialObj.NumBytesAvailable > 0
            data = readline(serialObj);
            parseAndPlotData(data);
            writeDataToCSV(data);
        end
    end

    function parseAndPlotData(data)
        % Example data format: "Time:1,Variable1:100,Variable2:50,..."
        dataPairs = split(data, ',');
        time = NaN;  % Initialize time to NaN

        for i = 1:length(dataPairs)
            kvPair = split(dataPairs{i}, ':');
            if length(kvPair) == 2
                name = strtrim(kvPair{1});
                value = str2double(kvPair{2});
                
                if strcmp(name, 'Time')
                    time = value;
                else
                    % Dynamically create fields in dataStruct and UI elements
                    if ~isfield(dataStruct, name)
                        dataStruct.(name) = [];
                        % Add numeric fields
                        numFields = numFields + 1;
                        headers{end+1} = name;  % Add new variable to headers
                        updateCSVHeaders();
                        
                        % Add checkbox for the new variable
                        checkboxStruct.(name) = uicontrol('Parent', checkboxPanel, 'Style', 'checkbox', ...
                                                          'String', name, 'Value', 1, ...
                                                          'Callback', @plotCheckboxChanged, ...
                                                          'Units', 'normalized', ...
                                                          'Position', [0.1, 1 - 0.1 * numFields, 0.8, 0.1]);
                    end
                    dataStruct.(name) = [dataStruct.(name); value];
                end
            end
        end

        % Ensure time is not NaN and present before plotting
        if isnan(time)
            error('Time value is missing in the received data.');
        else
            windowSize = str2double(windowSizeField.String);
            if isnan(windowSize) || windowSize <= 0
                error('Invalid window size.');
            end
            startTime = max(0, time - windowSize);
            startTimeIndex = find(timeData >= startTime, 1);
            if isempty(startTimeIndex)
                startTimeIndex = 1;
            end
            timeData = [timeData; time];
            plotData(timeData, dataStruct,startTimeIndex);
            xlim(ax,[timeData(startTimeIndex) max(timeData(end),windowSize)])
            drawnow;
        end
    end

    function plotData(timeData, dataStruct,startTimeIndex)
        % Clear previous plots
        cla(ax);
        fields = fieldnames(dataStruct);
        colors = lines(length(fields));  % Generate different colors for each field
        for i = 1:length(fields)
            if checkboxStruct.(fields{i}).Value  % Plot only if the checkbox is selected
                plot(ax, timeData(startTimeIndex:end), dataStruct.(fields{i})(startTimeIndex:end), 'DisplayName', fields{i}, 'Color', colors(i, :));
            end
        end
        legend(ax, 'show');
    end

    function plotCheckboxChanged(~, ~)
        plotData(timeData, dataStruct);
    end

    function numericFieldChanged(src, fieldName)
        value = str2double(src.String);
        if ~isnan(value) && ~isempty(serialObj)
            command = sprintf('%s:%d\n', fieldName, value);
            writeline(serialObj, command);
        end
    end

    function writeDataToCSV(data)
        % Example data format: "Time:1,Variable1:100,Variable2:50,..."
        dataPairs = split(data, ',');
        datacsv = "";
        for i = 1:length(dataPairs)
            kvPair = split(dataPairs{i}, ':');
            if length(kvPair) == 2
                value = str2double(kvPair{2});
                datacsv = strcat(datacsv, num2str(value));
                if i < length(dataPairs)
                    datacsv = strcat(datacsv, ',');
                end
            end
        end
        fprintf(fid, '%s\n', datacsv);
    end

    function updateCSVHeaders()
        fclose(fid);  % Close file to write headers
        fid = fopen(csvFilePath, 'w');  % Reopen file in write mode
        fprintf(fid, '%s\n', strjoin(headers, ','));  % Write updated headers
        fclose(fid);  % Close file again
        fid = fopen(csvFilePath, 'a');  % Reopen file in append mode
    end

    function closeFig(~, ~)
        if ~isempty(timerObj)
            stop(timerObj);
            delete(timerObj);
        end
        
        if ~isempty(serialObj)
            clear serialObj;
        end
        
        if fid ~= -1
            fclose(fid);
        end
        
        delete(fig);
    end
end