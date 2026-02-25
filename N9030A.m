classdef N9030A
    properties
       visaAddress;
       v;
    end
    
    methods
        function obj = N9030A()
            VisaList = visadevlist;
            VisaList = VisaList(VisaList.Model == "N9030A", :);
            [numInstruments, ~] = size(VisaList);
            for i = 1:numInstruments
                tempRN = VisaList(i,:).ResourceName;
                % disp(tempRN)
                if contains(tempRN, 'inst0')
                    resourceName = tempRN;
                    disp(strcat("N9030A at: ", resourceName))
                    break
                end
            end
            % obj.v = visadev('TCPIP0::169.254.250.0::inst0::INSTR');
            obj.v = visadev(resourceName);
            % Buffer size must precede open command
            % set(pxa,'InputBufferSize', 640000);
            set(obj.v,'OutputBufferSize', 640000);
            writeline(obj.v, '*CLS');
            % Check to ensure the error queue is clear. Response is "+0, No Error"
            writeline(obj.v, 'SYST:ERR?');
            errIdentifyStart = readline(obj.v);
            if (isvalid(obj.v) == 0)
                obj.deInit();
                error('Cannot instantiate Keysight N9030A');
            end
        end

        function rsp = sendResp(obj, cmd)
            obj.sendCommand(cmd);
            rsp = readline(obj.v);
        end

        function sendCommand(obj, cmd)
            writeline(obj.v, cmd)
        end

        function reset(obj)
            obj.sendCommand('SYST:PRES');
        end

        function waitUntilDone(obj)
            thresh = 10000;
            n = 0;
            while ~str2double(obj.sendResp('*OPC?'))
                n = n + 1;
                if n > thresh
                    warning('PXA timeout occured')
                    break
                end
            end
        end

        function setContinuous(obj, bool)
            if bool
                obj.sendCommand('INIT:CONT 1');
            else
                obj.sendCommand('INIT:CONT 0');
            end
        end

        function [datadB, freqAxis] = readTrace(obj)
            datadB = obj.getTraceData();
            [fStart, fStop] = obj.getFreqRange();
            freqAxis = linspace(fStart, fStop, numel(datadB));
        end

        function datadB = getTraceData(obj)
            datStr = obj.sendResp('TRACE:DATA? TRACE1');
            datadB = obj.csvstr2array(datStr);
        end


        function [fStart, fStop] = getFreqRange(obj)
            fStart = str2double(obj.sendResp('SENS:FREQ:START?'));
            fStop = str2double(obj.sendResp('SENS:FREQ:STOP?'));
        end

        function data = csvstr2array(~, dataStr)
            splt = split(dataStr, ',');
            % removeCR = splt(end);
            % removeCR = removeCR(1:end-1);
            % splt(end) = removeCR;
            data = str2double(splt);
        end

        function setFreqRange(obj, start, stop)
            cmdStart = "SENS:FREQ:START " + num2str(start);
            cmdStop = "SENS:FREQ:STOP " + num2str(stop);
            obj.sendCommand(cmdStart);%multiple commands separated by semicolon
            obj.sendCommand(cmdStop);
        end

        function triggerOnce(obj)
            obj.setContinuous(0)%turns off continuous mode
            obj.sendCommand('INIT;*WAI'); %triggers and then waits for trigger to complete
        end

        function val = amplitudeAtFrequency(obj, freq, IFBW)
            switch nargin
                case 2
                    IF = 10e6; %default to 10 KHz
                case 3
                    IF = IFBW;
            end
            [amplitudes, freqRange] = obj.readTrace();
            freqIdxs = freqRange >= (freq - IF/2) & freqRange <= (freq + IF/2);
            val = max(amplitudes(freqIdxs));
        end


        function bool = deInit(obj)
            if(isvalid(obj.v) == 1)
                obj.sendCommand('SYST:LOC')
                obj.reset();
                clear obj.v;
                bool = 1;
            else
                bool = 0;
            end

        end
    end
end