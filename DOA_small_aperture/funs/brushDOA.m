function [DET1out, DET2out] = brushDOA(DET1in, DET2in, varargin)
% DOAin should be a table containing at least the following entries:
%   DOA.('TDet') = time of detection in datenum format
%   DOA.('Ang') = azimuth an delevation angles of each detection

global brushing
warning off

if nargin == 2 % no parameter file specified
    if isfile('brushing.params') % see if default parameter file exists
        loadParams('brushing.params')
    else % if no default param file exists, generate one
        makeParamFile
    end
elseif nargin == 3 % parameter file specified
    loadParams(varargin{1})
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

% set global data
run_brushDOA(DET1in, DET2in, varargin);

qselect = input('\nEnter ''q'' to quit: ', 's');

global DET

DET1out = DET{1};
DET2out = DET{2};

end

function run_brushDOA(DET1in, DET2in, varargin)
global brushing DET DETprev

DET{1} = DET1in;
DET{2} = DET2in;

DETprev = DET; % previous detection values (for undo function)

isfig = findall(0, 'Type', 'figure', 'name', 'Brush DOA');    % see if Brush DOA figure already generated
if isempty(isfig)
    fig = figure('Name', 'Brush DOA'); % generate figure
else
    close(isfig)
    fig = figure('Name', 'Brush DOA'); % generate figure
end

fig.Position = brushing.params.figPosition;

%% plot DOAs:

% set up plot parameters
ms = 6; % marker size

mmtime(1) = min([DET{1}.('TDet'); DET{2}.('TDet')]); % minimum time axis value
mmtime(2) = max([DET{1}.('TDet'); DET{2}.('TDet')]); % maximum time axis value

mmAz(1) = min([DET{1}.('Ang')(:,1); DET{2}.('Ang')(:,1)]); % minimum az axis value
mmAz(2) = max([DET{1}.('Ang')(:,1); DET{2}.('Ang')(:,1)]); % maximum az axis value

mmEl(1) = min([DET{1}.('Ang')(:,2); DET{2}.('Ang')(:,2)]); % minimum el axis value
mmEl(2) = max([DET{1}.('Ang')(:,2); DET{2}.('Ang')(:,2)]); % maximum el axis value


% plot Array 1
sp(1) = subplot(4, 6, [1, 4]);
scatter(DET{1}.('TDet'), DET{1}.('Ang')(:,1), ms, brushing.params.colorMat(DET{1}.('color'), :), 'filled')
datetick
set(gca, 'Xticklabel', [])
xlim(mmtime)
ylim(mmAz + [-2, 2])
ylabel('AZ1')
grid on
subpos = get(sp(1), 'Position');
set(sp(1), 'Position', subpos + [-.08, .005, .08, .068])
tb = axtoolbar('default');
tb.Visible = 'off';

sp(2) = subplot(4, 6, [7, 10]);
scatter(DET{1}.('TDet'), DET{1}.('Ang')(:,2), ms, brushing.params.colorMat(DET{1}.('color'), :), 'filled')
datetick
set(gca, 'Xticklabel', [])
xlim(mmtime)
ylim(mmEl + [-2, 2])
ylabel('EL1')
grid on
subpos = get(sp(2), 'Position');
set(sp(2), 'Position', subpos + [-.08, -.025, .08, .068])
tb = axtoolbar('default');
tb.Visible = 'off';
% linkaxes([sp1, sp2], 'x')

sp(3) = subplot(4, 6, [5,12]);
scatter(DET{1}.('Ang')(:,1), DET{1}.('Ang')(:,2), ms, brushing.params.colorMat(DET{1}.('color'), :), 'filled')
axis([mmAz(1)-2, mmAz(2)+2, mmEl(1)-2, mmEl(2)+2])
xlabel('AZ1')
ylabel('EL1')
grid on
subpos = get(sp(3), 'Position');
set(sp(3), 'Position', subpos + [0, 0, .08, .07])
tb = axtoolbar('default');
tb.Visible = 'off';

% plot array 2
sp(4) = subplot(4, 6, [13, 16]);
scatter(DET{2}.('TDet'), DET{2}.('Ang')(:,1), ms, brushing.params.colorMat(DET{2}.('color'), :), 'filled')
datetick
set(gca, 'Xticklabel', [])
xlim(mmtime)
ylim(mmAz + [-2, 2])
ylabel('AZ2')
grid on
subpos = get(sp(4), 'Position');
set(sp(4), 'Position', subpos + [-.08, -.055, .08, .068])
tb = axtoolbar('default');
tb.Visible = 'off';

sp(5) = subplot(4, 6, [19, 22]);
scatter(DET{2}.('TDet'), DET{2}.('Ang')(:,2), ms, brushing.params.colorMat(DET{2}.('color'), :), 'filled')
datetick
xlim(mmtime)
ylim(mmEl + [-2, 2])
ylabel('EL2')
grid on
subpos = get(sp(5), 'Position');
set(sp(5), 'Position', subpos + [-.08, -0.085, .08, .068])
tb = axtoolbar('default');
tb.Visible = 'off';
% linkaxes([sp3, sp4], 'x')

sp(6) = subplot(4, 6, [17,24]);
scatter(DET{2}.('Ang')(:,1), DET{2}.('Ang')(:,2), ms, brushing.params.colorMat(DET{2}.('color'), :), 'filled')
axis([mmAz(1)-2, mmAz(2)+2, mmEl(1)-2, mmEl(2)+2])
xlabel('AZ2')
ylabel('EL2')
grid on
subpos = get(sp(6), 'Position');
set(sp(6), 'Position', subpos + [0, -.06, .08, .07])
tb = axtoolbar('default');
tb.Visible = 'off';

%brush on
b = brush(fig);

b.Enable = 'on';
% disable any brushed data before brushing new data
b.ActionPreCallback = {@onBrushDisableAction};

% brush data in one plot and apply it to corresponding subplots of the same
% array. PostCallBack incorporates key press actions
b.ActionPostCallback = {@onBrushAction};

end

%% Disable Previous One Brush Action
function onBrushDisableAction(source, eventdata)

iBrushedPlot = nan(6,1);
for isp = 1:6
    iBrushedPlot(isp) = ~isempty(source.Children(isp).Children.BrushData);
end
iplot = find(iBrushedPlot);
if ~isempty(iplot)
    % remove highlighted data
    for i = 1:length(iplot)
        % unselect highlighted points
        source.Children(iplot(i)).Children.BrushData = [];
    end
end
end


%% One Brush Action Brush
function onBrushAction(source, eventdata)

iBrushedPlot = nan(6,1);
for isp = 1:6
    iBrushedPlot(isp) = ~isempty(source.Children(isp).Children.BrushData);
end
iplot = find(iBrushedPlot);
selectedData = source.Children(iplot).Children.BrushData;
% get highlighted data on AR1:
if iplot > 3 % subplots 4, 5, & 6 are for AR1
    for isp = 4:6
        % add brushed points to corresponding subplots of AR1 
        if isp ~= iplot
        source.Children(isp).Children.BrushData = selectedData;
        end
    end
end

% get highlighted data on AR2:
if iplot <= 3 % subplots 1, 2, & 3 are for AR2
    for isp = 1:3
        % add brushed points to corresponding subplots of AR2 
        if isp ~= iplot
        source.Children(isp).Children.BrushData = selectedData;
        end
    end
end

% Get mode manager and current mode property to set keypress function
hManager = uigetmodemanager(source);
% Allows to change key press callback function
[hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2 (on 2014b or later)

% Keypress Callback
set(source, 'KeyPressFcn', @keyPressCallback);
end

%% Keypress Callback
function keyPressCallback(source, eventdata)

global brushing DET DETprev

key = eventdata.Key;

% get highlighted data on AR1:
Ind{1} = []; % highlighted data on AR1
for isp = 4:6 % subplots 4, 5, & 6 are for AR1
    selectedData = source.Children(isp).Children.BrushData;
    Itemp = find(selectedData~=0);
    Ind{1} = [Ind{1}, Itemp];
    source.Children(isp).Children.BrushData = []; % unselect highlighted points
end

% get highlighted data on AR2:
Ind{2} = []; % highlighted data on AR2
for isp = 1:3 % subplots 1, 2, & 3 are for AR2
    selectedData = source.Children(isp).Children.BrushData;
    Itemp = find(selectedData~=0);
    Ind{2} = [Ind{2}, Itemp];
    source.Children(isp).Children.BrushData = []; % unselect highlighted points
end


numkey = str2double(key); % convert keyboard input to a number (returns NaN if value is not a number)
if ~(isempty(numkey)||isnan(numkey)) % if input is number, assign as whale number:
    if numkey>8||numkey<0
        errBox = msgbox('error: invalid whale number\nSelect a number 1 thorugh 8', 'Error');
    else
        DETprev = DET; % set DETprev as current state for undo

        % update AR1
        if ~isempty(Ind{1})
            DET{1}.('Label')(Ind{1}) = key;
            DET{1}.('color')(Ind{1}) = (numkey + 2);
            for isp = 4:6
                set(source.Children(isp).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :))
            end
        end

        % update AR2
        if ~isempty(Ind{2})
            DET{2}.('Label')(Ind{2}) = key;
            DET{2}.('color')(Ind{2}) = numkey + 2;
            for isp = 1:3
                set(source.Children(isp).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :))
            end
        end

    end

else % if input is letter, perform associated function
    switch key
            
        case 'd' % delete
            DETprev = DET; % set DETprev as current state for undo

            % update AR1
            if ~isempty(Ind{1})
                DET{1}(Ind{1}, :) = [];

                % update az vs el plot
                set(source.Children(4).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :), ...
                    'xdata', DET{1}.('Ang')(:,1), ...
                    'ydata', DET{1}.('Ang')(:,2))


                % update t vs el plot
                set(source.Children(5).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :), ...
                    'xdata', DET{1}.('TDet'), ...
                    'ydata', DET{1}.('Ang')(:,2))

                % update t vs az plot
                set(source.Children(6).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :), ...
                    'xdata', DET{1}.('TDet'), ...
                    'ydata', DET{1}.('Ang')(:,1))


            end

            % update AR2
            if ~isempty(Ind{2})
                DET{2}(Ind{2}, :) = [];

                % update az vs el plot
                set(source.Children(1).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :), ...
                    'xdata', DET{2}.('Ang')(:,1), ...
                    'ydata', DET{2}.('Ang')(:,2))


                % update t vs el plot
                set(source.Children(2).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :), ...
                    'xdata', DET{2}.('TDet'), ...
                    'ydata', DET{2}.('Ang')(:,2))

                % update t vs az plot
                set(source.Children(3).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :), ...
                    'xdata', DET{2}.('TDet'), ...
                    'ydata', DET{2}.('Ang')(:,1))


            end

        case 'b' % label as buzz
            % update AR1
            if ~isempty(Ind{1})
                DET{1}.('Label')(Ind{1}) = key;
                DET{1}.('color')(Ind{1}) = 11;
                for isp = 4:6
                    set(source.Children(isp).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :))
                end
            end

            % update AR2
            if ~isempty(Ind{2})
                DET{2}.('label')(Ind{2}) = key;
                DET{2}.('color')(Ind{2}) = 11;
                for isp = 1:3
                    set(source.Children(isp).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :))
                end
            end

        case 'a'
            Arrstruct = inputdlg('Enter labeled array (''1'' or ''2''):', 'Associate whales');
            labeledInstnum = str2double(Arrstruct{1});
            
            if labeledInstnum==1
                unlabeledInstnum = 2;
            elseif labeledInstnum==2
                unlabeledInstnum = 1;
            else
                errordlg('Invalid instrument number')
            end

            whalenum = inputdlg('Enter whale number to associate(a number, or ''a'' for all): ', 'Associate whales');
            
            if strcmp(whalenum{1}, 'a') % process all whales
                wnums = unique(DET{labeledInstnum}.color);
                wnums(wnums==2) = []; % remove 'unlabeled'
                for wn = 1:length(wnums)
                    DET = whaleAss(DET, labeledInstnum, unlabeledInstnum, wnums(wn)-2);
                    
                end
            else % process only specified whale
                wn = str2double(whalenum{1});
                DET = whaleAss(DET, labeledInstnum, unlabeledInstnum, wn);
            end

            if unlabeledInstnum==1
                % update array 1 plots

                % update az vs el plot
                set(source.Children(4).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :))


                % update t vs el plot
                set(source.Children(5).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :))

                % update t vs az plot
                set(source.Children(6).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :))

            elseif unlabeledInstnum==2
                % update array 2 plots
                % update az vs el plot
                set(source.Children(1).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :))

                % update t vs el plot
                set(source.Children(2).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :))

                % update t vs az plot
                set(source.Children(3).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :))
            end


        case 'z' % toggle zoom on

            % enable zoom functionality
            z = zoom(source); % get zoom object of figure

            z.Enable = 'on'; % turn on zoom
            z.Direction = 'in'; % set zoom to "in"

            % reenable keyPress (zoom and brush automatically disable this)
            hManager = uigetmodemanager(source);
            [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2 (on 2014b or later)
            set(source, 'KeyPressFcn', @keyPressCallback);

        case 'x' % toggle zoom off
            z = zoom(source); % get zoom object of figure
            z.Enable = 'off';  % turn on zoom

            % reenable brush:
            b = brush(source);
            b.Enable = 'on';

            % reenable keyPress (zoom and brush automatically disable this)
            hManager = uigetmodemanager(source);
            [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2 (on 2014b or later)
            set(source, 'KeyPressFcn', @keyPressCallback);
        case 'r' % refresh (return zoom to full encounter, set plot boundaries to encompass only retained detections)

            % calculate limits of time axes:
            tlim = nan(1,2); % limit of time axes
            for narr = 1:2
                tlim(1) = min([tlim(1); DET{narr}.TDet]);
                tlim(2) = max([tlim(2); DET{narr}.TDet]);
            end
            
            % update AR1:
            if ~isempty(DET{1}.Ang)
                set(source.Children(4), 'XLim', [min(DET{1}.Ang(:,1)), max(DET{1}.Ang(:,1))], ...
                    'YLim', [min(DET{1}.Ang(:,2))-2, max(DET{1}.Ang(:,2))+2]) % update az vs el plot
                set(source.Children(5), 'XLim', tlim, ...
                    'YLim', [min(DET{1}.Ang(:,2))-2, max(DET{1}.Ang(:,2))+2]) % update t vs el plot
                set(source.Children(6), 'XLim', tlim, 'YLim', ...
                    [min(DET{1}.Ang(:,1))-2, max(DET{1}.Ang(:,1))+2]) % update t vs az plot
            end

            % update AR2:
            if ~isempty(DET{2}.Ang)
                set(source.Children(1), 'XLim', [min(DET{2}.Ang(:,1)), max(DET{2}.Ang(:,1))], ...
                    'YLim', [min(DET{2}.Ang(:,2))-2, max(DET{2}.Ang(:,2))+2]) % update az vs el plot
                set(source.Children(2), 'XLim', tlim, ...
                    'YLim', [min(DET{2}.Ang(:,2))-2, max(DET{2}.Ang(:,2))+2]) % update t vs el plot
                set(source.Children(3), 'XLim', tlim, 'YLim', ...
                    [min(DET{2}.Ang(:,1))-2, max(DET{2}.Ang(:,1))+2]) % update t vs az plot

            end


        case 'u' % undo
            DET = DETprev;


            % update AR1:

            % update az vs el plot
            set(source.Children(4).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :), ...
                'xdata', DET{1}.('Ang')(:,1), ...
                'ydata', DET{1}.('Ang')(:,2))


            % update t vs el plot
            set(source.Children(5).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :), ...
                'xdata', DET{1}.('TDet'), ...
                'ydata', DET{1}.('Ang')(:,2))

            % update t vs az plot
            set(source.Children(6).Children, 'cdata', brushing.params.colorMat(DET{1}.('color'), :), ...
                'xdata', DET{1}.('TDet'), ...
                'ydata', DET{1}.('Ang')(:,1))



            % update AR2

            % update az vs el plot
            set(source.Children(1).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :), ...
                'xdata', DET{2}.('Ang')(:,1), ...
                'ydata', DET{2}.('Ang')(:,2))

            % update t vs el plot
            set(source.Children(2).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :), ...
                'xdata', DET{2}.('TDet'), ...
                'ydata', DET{2}.('Ang')(:,2))

            % update t vs az plot
            set(source.Children(3).Children, 'cdata', brushing.params.colorMat(DET{2}.('color'), :), ...
                'xdata', DET{2}.('TDet'), ...
                'ydata', DET{2}.('Ang')(:,1))

    end
end

end