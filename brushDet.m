function outDet = brushDet(DATA, inDet, varargin)
% [outDet, labels] = brushDet(DATA, inDet, paramFile) runs GUI which 
% allows user to delete and label detections on top of time series data
% -DATA{i} is the time series data for the ith receiver
% -DATA{i}(1,:) is the time vector for the ith receiver
% -DATA{i}(2,:) is the amplitude vector for the ith receiver
% -inDet{i} are the initial detections for the ith receiver
% inDet is a detection matrix 
% -(optional) paramFile is the path to a parameter file which allows various
% settings for the interface
% -outDet{i} is the output detection table for the ith receiver

global brushing

brushing.DATA = DATA;           % acoustic data
brushing.nAxes = numel(DATA);   % number of axes/receivers to display

% pull out detections within time period of acoustic data
for i = 1:brushing.nAxes
    I = find(inDet{i}.('TDet')>=brushing.DATA{i}(1, 1) & inDet{i}.('TDet')<=brushing.DATA{i}(1, end));
    
    brushing.DET{i} = inDet{i}(I,:);
    brushing.DET{i}.('Ind') = I; % indices from full dataset included in the plot
end

% determine if param file was specified:
if nargin < 2
    errordlg('Not enough input arguments', 'brushDet Error')
elseif nargin == 2 % no parameter file specified
    % check for existing default param file
    if isfile('brushing.params')
        loadParams('brushing.params')
    else
        makeParamFile
    end
elseif nargin == 3 % parameter file specified
    loadParams(varargin{1})
else
    errordlg('incorrect number of input arguments', 'brushDet Error')
end

% test whether label color legend exists
figCol = findall(0, 'Type', 'figure', 'name', 'Legend of Label Colors');
if isempty(figCol) 
    generateColorSchemeLegend(brushing) % if legend doesn't exist, generate it
end

% test whether Keystroke Command Legend exists
figKey = findall(0, 'Type', 'figure', 'name', 'Keystroke Command Legend');
if isempty(figKey)
    generateKeystrokeLegend(brushing) % if legend doesn't exist, generate it
end

run_brushDet % run the GUI

qselect = input('\nEnter ''q'' to quit: ', 's');

outDet = inDet; 
for i = 1:brushing.nAxes
    % update indices which were changed:
    outDet{i}.('Label')(brushing.DET{i}.Ind) = brushing.DET{i}.('Label');
    outDet{i}.('color')(brushing.DET{i}.Ind) = brushing.DET{i}.('color');

    Irem = find(outDet{i}.('color')<=0); % remove indices tagged for removal
    outDet{i}(Irem, :) = [];
end

end


function run_brushDet
% runs the acutal brushDet GUI

% initialize global values
global brushing

brushing.tRange = [nan, nan];        % limits of x axis on plot
for i = 1:brushing.nAxes
    brushing.tRange(1) = min([min(brushing.DATA{i}(1,:)), brushing.tRange(1)]); % minimum time on plot
    brushing.tRange(2) = max([max(brushing.DATA{i}(1,:)), brushing.tRange(2)]); % maximum time on plot
end



uif = findall(0, 'Type', 'figure', 'name', 'Brush Detections'); % activate Brush Detections GUI (if it exists)

if isempty(uif) % If Brush Detections doesn't exist, run init_brushDet
    [uif, ax, sld] = init_brushDet;

else
    if brushing.nAxes~=numel(uif.Children.Children) % detect a change in the number of receivers/axes
        close(uif)
        [uif, ax, sld] = init_brushDet;
    end
    for i = 1:brushing.nAxes
        ax(i) = uif.Children.Children(i).Children(2);
        sld(i) = uif.Children.Children(i).Children(1);
    end
end

for i = 1:brushing.nAxes
    % set slider callback function
    set(sld(i), 'ValueChangedFcn', {@changeThresh, sld(i)})

    plot(ax(i), brushing.DATA{i}(1,:), brushing.DATA{i}(2,:), 'HandleVisibility', 'off', 'color', brushing.params.colorMat(1,:))
    ax(i).Toolbar.Visible = 'off'; % turn off matlab's toolbar so user doesn't click it accidentally
    
    I = find(brushing.DET{i}.('color')>=2); % find indices not tagged for deletion or below threshold

    if ~isempty(I) % determine if there are detections on this receiver
        hold(ax(i), 'on')
        scatter(ax(i), brushing.DET{i}.('TDet'),brushing.DET{i}.('DAmp')(I), 100,...
            brushing.params.colorMat(brushing.DET{i}.('color')(I), :), 'x', 'linewidth', 2) % plot detections
        hold(ax(i), 'off')
        xlim(ax, brushing.tRange)

        if length(I)>1
            % adjust slider range according to detection amplitudes
            uif.Children.Children(i).Children(1).Limits = [min(brushing.DET{i}.('DAmp')(I)), max(brushing.DET{i}.('DAmp')(I))];

            % Set slider value to minimum detection amplitude
            uif.Children.Children(i).Children(1).Value = min(brushing.DET{i}.('DAmp')(I));

            b = brush(uif);
            b.Color = 'r';
            b.Enable = 'on';
        else
            fprintf('\ninsufficient detections on Receiver - no slider functionality %d\n', i)
        end
    else
        fprintf('\nno detections on Receiver %d\n', i)
    end
end

hManager = uigetmodemanager(uif);
[hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2 (on 2014b or later)
set(uif, 'KeyPressFcn', @keyPressCallback);

end

function [uif, ax, sld] = init_brushDet
% Initializes the Brush Detections plot.
% nAxes = number of axes in the plot (number of receivers)
% uif is the figure handle
% ax(i) is the axes handle for receiver i

global brushing
uif = uifigure('Name', 'Brush Detections');
uif.Position = brushing.params.figPosition;
set(uif, 'ToolBar', 'none')
set(uif, 'MenuBar', 'none')
grd = uigridlayout(uif, [brushing.nAxes, 1]); % divide uifigure into nAxes X 1 grids

for i = 1:brushing.nAxes

    uipan(i) = uipanel(grd, 'Title', ['Receiver ', num2str(i)]); % create panel on each grid

end
drawnow
pause(1)
for i = 1:brushing.nAxes
    ax(i) = axes(uipan(i), 'Position', [0.08, 0.11, 0.88, 0.815]); % make plot axes on each panel
    ax(i).Toolbar.Visible = 'off'; % turn off matlab's toolbar so user doesn't click it accidentally
    % Set slider position:
    sldPos(1) = 10; % Distance from left edge of panel (pixels)
    sldPos(2) = 10;  % Distance from bottom edge of panel (pixels)
    sldPos(3) = 3;
    sldPos(4) = uipan(i).InnerPosition(4)-20;

    sld(i) = uislider(uipan(i), 'Orientation', 'vertical', ...
        'Position', sldPos);

end

end

function changeThresh(hObject, sldVal, handles)
% Detects a slider change and updates the detections
% sldVal.Value is the current slider value
% sldVal.PreviousValue is the previous slider value

global brushing

ax = hObject.Parent; % get the axis handle
iRec = str2double(ax.Title(end)); % Receiver number

if sldVal.Value>sldVal.PreviousValue % slider value increased
    
    Irem = find(brushing.DET{iRec}.('DAmp')<sldVal.Value); % indices of detections which are lower than threshold
    
    brushing.DET{iRec}.('color')(Irem) = 0;

    I = find(brushing.DET{iRec}.('color')>=2);

    set(ax.Children(2).Children, 'xdata', brushing.DET{iRec}.('TDet')(I), 'ydata', brushing.DET{iRec}.('DAmp')(I), ...
        'cdata', brushing.params.colorMat(brushing.DET{iRec}.('color')(I), :));

elseif sldVal.Value<sldVal.PreviousValue % slider value decreased
    
    Iadd = find(brushing.DET{iRec}.('color')==0 & brushing.DET{iRec}.('DAmp')>=sldVal.Value); % indices of points to be added back onto plot
    
    % add those points back into plotted data
    brushing.DET{iRec}.('color')(Iadd) = 2;


    I = find(brushing.DET{iRec}.('color')>=2); 
    set(ax.Children(2).Children, 'xdata', brushing.DET{iRec}.('TDet')(I), 'ydata', brushing.DET{iRec}.('DAmp')(I), ...
        'cdata', brushing.params.colorMat( brushing.DET{iRec}.('color')(I), :));

else % slider value did not change-- if you're here something went wrong
    errBox = msgbox('error: slider value didn''t change. I don''t know how you got here.', 'Magic Error');
end



end

%% kepPressCallback Function
function keyPressCallback(source,eventdata)
% runs when use presses a 
global brushing

% Receive keyboard input
key = eventdata.Key; % pressed key
% fprintf(['\n''', key, ''' key pressed\n']) % print message (for debugging)

for i = 1:brushing.nAxes % get highlighted points on each receiver
    if ~isempty(source.Children.Children(i).Children(2).Children)
        selectedData = source.Children.Children(i).Children(2).Children.BrushData;
        Ind{i} = find(selectedData~=0); % indices of selected data
    else
        Ind{i} = [];
    end
end

numkey = str2double(key); % convert keyboard input to a number (returns NaN if value is not a number)

if ~(isempty(numkey)||isnan(numkey))
    if numkey>8 || numkey<0
        errBox = msgbox('error: invalid whale number\nSelect a number 1 thorugh 8', 'Error');
    else % valid number selected
        for i = 1:brushing.nAxes
            if ~isempty(Ind{i})
                source.Children.Children(i).Children(2).Children.BrushData(Ind{i}) = []; % unselect all brushed points
                brushing.DET{i}.('label')(Ind{i}) = key; % set labels as the whalenumber
                brushing.DET{i}.('color')(Ind{i}) = numkey+2; % set color of datapoints
                
                I = find(brushing.DET{i}.('color')>=2);
                set(source.Children.Children(i).Children(2).Children, ...
                    'cdata', brushing.params.colorMat(brushing.DET{i}.('color')(I), :));
            end
        end
    end
else

    switch key
        case 'd' % delete selected points
            for i = 1:numel(Ind)
                if ~isempty(Ind{i})
                    % don't actually delete, just label as -1 and these
                    % points will be deleted after brushing is complete
                    source.Children.Children(i).Children(2).Children.BrushData(Ind{i}) = []; % unselect all brushed points
                    brushing.DET{i}.('color')(Ind{i}) = -1;
                    
                    I = find(brushing.DET{i}.('color')>=2);

                    set(source.Children.Children(i).Children(2).Children, ...
                        'xdata', brushing.DET{i}.('TDet')(I), 'ydata', brushing.DET{i}.('DAmp')(I), ...
                        'cdata', brushing.params.colorMat(brushing.DET{i}.('color')(I), :));

                end
            end
        case 'b' % label selected points as a buzz
            for i = 1:numel(Ind)
                if ~isempty(Ind{i})

                    source.Children.Children(i).Children(2).Children.BrushData(Ind{i}) = []; % unselect all brushed points
                    brushing.DET{i}.('Label')(Ind{i}) = 'b'; % set labels as 'b'
                    brushing.DET{i}.('color')(Ind{i}) = 11; % set color of datapoints
                    
                    I = find(brushing.DET{i}.('color')>=2);

                    set(source.Children.Children(i).Children(2).Children, ...
                        'cdata', brushing.params.colorMat(brushing.DET{i}.('color')(I), :));

                end
            end
        case 'z' % turn on zoom
            
            % enable zoom functionality
            z = zoom(source); % get zoom object of figure

            z.Enable = 'on'; % turn on zoom
            z.Direction = 'in'; % set zoom to "in"
            
            % reenable keyPress (zoom and brush automatically disable this)
            hManager = uigetmodemanager(source);
            [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2 (on 2014b or later)
            set(source, 'KeyPressFcn', @keyPressCallback);

            
        case 'x' % turn off zoom
            z = zoom(source); % get zoom object of figure
            z.Enable = 'off';  % turn on zoom
            
            % reenable brush:
            b = brush(source);
            b.Color = 'r';
            b.Enable = 'on';

            % reenable keyPress (zoom and brush automatically disable this)
            hManager = uigetmodemanager(source);
            [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2 (on 2014b or later)
            set(source, 'KeyPressFcn', @keyPressCallback);
        case 'n' % select a new detection
            
            iRecCell = inputdlg('Which receiver?', 'Select New Detections');
            iRec = str2double(iRecCell{1});
            
            if iRec <= numel(source.Children.Children) && iRec~=0


                detPoint = drawpoint(source.Children.Children(iRec).Children(2)); % point struct of selected datapoint(s)
                
                
                distToDatapoints = sum((brushing.DATA{iRec} - detPoint.Position.').^2); % distance between selected point and all points in data
                [~, Imin] = min(distToDatapoints);

                newDet = brushing.DATA{iRec}(:, Imin);

                % add point into plotted data
                [numRow, numCol] = size(brushing.DET{iRec}); % number of rows and columns in table
                newRow = brushing.DET{iRec}(numRow, :);
                for ic = 1:numCol
                    elemClass = class(brushing.DET{iRec}{numRow, ic});
                    if strcmp(elemClass, 'double')
                        newRow{1, ic} = nan(size(brushing.DET{iRec}{numRow, ic}));
                    elseif strcmp(elemClass, 'char')
                        newRow{1, ic} = ' ';
                    else
                        newRow{1, ic} = brushing.DET{iRec}{numRow, ic};
                    end
                end
                    
                brushing.DET{iRec} = [brushing.DET{iRec}; newRow];
                
                brushing.DET{iRec}.('TDet')(numRow+1) = newDet(1);
                brushing.DET{iRec}.('DAmp')(numRow+1) = newDet(2);
                brushing.DET{iRec}.('Label')(numRow+1) = '0';
                brushing.DET{iRec}.('color')(numRow+1) = 2;

                I = find(brushing.DET{iRec}.('color')>=2);
                set(source.Children.Children(iRec).Children(2).Children(2), ...
                        'xdata', brushing.DET{iRec}.('TDet')(I), 'ydata', brushing.DET{iRec}.('DAmp')(I), ...
                        'cdata', brushing.params.colorMat(brushing.DET{iRec}.('color')(I), :));

                % reenable brush:
                b = brush(source);
                b.Color = 'r';
                b.Enable = 'on';

                % reenable keyPress (zoom and brush automatically disable this)
                hManager = uigetmodemanager(source);
                [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2 (on 2014b or later)
                set(source, 'KeyPressFcn', @keyPressCallback);

            else
                errBox = msgbox(['error: invalid receiver number. \nEnter a number from 1 to ', num2str(numel(source.Children.Children))], 'Error');
            end

    end
end
end

%%

