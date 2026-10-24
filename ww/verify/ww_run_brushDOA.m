function [DET1out, DET2out] = ww_run_brushDOA(DET1in, DET2in, f1in, f2in, pin)
% DOAin should be a table containing at least the following entries:
%   DOA.('TDet') = time of detection in datenum format
%   DOA.('Ang') = azimuth an delevation angles of each detection
%
% For a single 4ch, pass DET2in and f2in as [] (DET2out is returned as []).

global PARAMS HANDLES brushing
warning off
loadParams(PARAMS.path.repo+"\ww\verify\brushing_colors\brushing_pastel")

% test whether label color legend exists
figCol = findall(0, 'Type', 'figure', 'name', 'Legend of Label Colors');
if isempty(figCol)
    labels = ["Whale 1", "Whale 2", "Whale 3", "Whale 4", "Whale 5", ...
        "Whale 6", "Whale 7", "Whale 8", "Whale 9", "Whale 10", ...
        "Whale 11", "Whale 12", "Whale 13", "Whale 14", "Whale 15", ...
        "Whale 16", "Whale 17", "Whale 18", "Whale 19", "Whale 20"];
    ww_generateColorSchemeLegend(brushing,"Whale number",labels) % if legend doesn't exist, generate it
end

% collect inputs per array (one or two 4ch)
if isempty(DET2in) % only one 4ch
    DETin = {DET1in};
    fin = {f1in};
else
    DETin = {DET1in, DET2in};
    fin = {f1in, f2in};
end

% add catches if this is an older file from Where'sWhaledo v1.0:
for a = 1:numel(DETin)
    if ~isdatetime(DETin{a}.TDet(1)), DETin{a}.TDet = datetime(DETin{a}.TDet,'convertfrom','datenum'); end
    if ~ismember('Species', DETin{a}.Properties.VariableNames), DETin{a}.Species = repmat("NaN",height(DETin{a}),1); end
    if ~ismember('Spectra', DETin{a}.Properties.VariableNames), DETin{a}.Spectra = nan(height(DETin{a}),size(fin{a},2)); end
end

% set global data
run_brushDOA(DETin, f1in);

global DET HANDLES freq p

DET1out = DET{1};
DET2out = [];
if numel(DET) > 1
    DET2out = DET{2};
end
p = pin;
freq = fin;

if isfield(HANDLES,'ui') && isfield(HANDLES.ui,'enc') && ...
   isfield(HANDLES.ui.enc,'refreshColumn3Fcn') && ...
   isa(HANDLES.ui.enc.refreshColumn3Fcn,'function_handle')
    HANDLES.ui.enc.refreshColumn3Fcn();
    drawnow limitrate
end

% recognize any whale-number labels already present in the loaded file
% (not just ones assigned during this session) and enable their species
% input fields accordingly
ww_refresh_encounter_options();

end

function run_brushDOA(DETin, f1in)
global brushing DET DETprev f

DET = DETin; % replace the whole cell so no array is left over from a previous file
f = f1in;
nArr = numel(DET);

ww_generateSpectraPlot('init', DET, f, brushing);
ww_generateSpectraPlot('species', DET, f, brushing);
ww_generate3DPlot('init', DET, brushing);

DETprev = DET; % previous detection values (for undo function)

isfig = findall(0, 'Type', 'figure', 'name', 'Brush DOA');    % see if Brush DOA figure already generated
if isempty(isfig)
    fig = figure('Name', 'Brush DOA'); % generate figure
else
    close(isfig)
    fig = figure('Name', 'Brush DOA'); % generate figure
end

fig.Position = brushing.params.figPosition;
brushing.hFig = fig;
% three scatters per array, in order: t vs az, t vs el, az vs el
% (array 1 is hScatter(1:3), array 2 is hScatter(4:6))
brushing.hScatter = gobjects(3*nArr,1);

%% plot DOAs:

% set up plot parameters
ms = 6; % marker size

allTDet = [];
allAng = [];
for a = 1:nArr
    allTDet = [allTDet; DET{a}.('TDet')];
    allAng = [allAng; DET{a}.('Ang')];
end

mmtime(1) = min(allTDet); % minimum time axis value
mmtime(2) = max(allTDet); % maximum time axis value

mmAz(1) = min(allAng(:,1)); % minimum az axis value
mmAz(2) = max(allAng(:,1)); % maximum az axis value

mmEl(1) = min(allAng(:,2)); % minimum el axis value
mmEl(2) = max(allAng(:,2)); % maximum el axis value

% subplot position adjustments for each array: t vs az, t vs el, az vs el
posAdj = {[-.08, .005, .08, .068], [-.08, -.025, .08, .068], [0, 0, .08, .07]; ... % array 1
          [-.08, -.055, .08, .068], [-.08, -0.085, .08, .068], [0, -.06, .08, .07]}; % array 2

% each array takes two rows of a 6-column grid, so one array fills the figure
nRows = 2*nArr;

for a = 1:nArr
    k = 3*(a-1); % index offset into hScatter/sp for this array
    rowOff = 12*(a-1); % subplot index offset for this array's rows
    C = brushing.params.colorMat(DET{a}.('color'), :);

    sp(k+1) = subplot(nRows, 6, [1, 4]+rowOff);
    brushing.hScatter(k+1) = scatter(DET{a}.('TDet'), DET{a}.('Ang')(:,1), ms, C, 'filled');
    datetick
    set(gca, 'Xticklabel', [])
    xlim(mmtime)
    ylim(mmAz + [-2, 2])
    ylabel("AZ"+a)
    grid on
    subpos = get(sp(k+1), 'Position');
    set(sp(k+1), 'Position', subpos + posAdj{a,1})
    tb = axtoolbar('default');
    tb.Visible = 'off';

    sp(k+2) = subplot(nRows, 6, [7, 10]+rowOff);
    brushing.hScatter(k+2) = scatter(DET{a}.('TDet'), DET{a}.('Ang')(:,2), ms, C, 'filled');
    datetick
    if a < nArr % only label the time axis on the bottom array
        set(gca, 'Xticklabel', [])
    end
    xlim(mmtime)
    ylim(mmEl + [-2, 2])
    ylabel("EL"+a)
    grid on
    subpos = get(sp(k+2), 'Position');
    set(sp(k+2), 'Position', subpos + posAdj{a,2})
    tb = axtoolbar('default');
    tb.Visible = 'off';

    sp(k+3) = subplot(nRows, 6, [5,12]+rowOff);
    brushing.hScatter(k+3) = scatter(DET{a}.('Ang')(:,1), DET{a}.('Ang')(:,2), ms, C, 'filled');
    axis([mmAz(1)-2, mmAz(2)+2, mmEl(1)-2, mmEl(2)+2])
    xlabel("AZ"+a)
    ylabel("EL"+a)
    grid on
    subpos = get(sp(k+3), 'Position');
    set(sp(k+3), 'Position', subpos + posAdj{a,3})
    tb = axtoolbar('default');
    tb.Visible = 'off';
end

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

global brushing

% unselect highlighted points on every plot
for isp = 1:numel(brushing.hScatter)
    if ~isempty(brushing.hScatter(isp).BrushData)
        brushing.hScatter(isp).BrushData = [];
    end
end
end


%% One Brush Action Brush
function onBrushAction(source, eventdata)

global brushing

iBrushedPlot = false(numel(brushing.hScatter),1);
for isp = 1:numel(brushing.hScatter)
    iBrushedPlot(isp) = ~isempty(brushing.hScatter(isp).BrushData);
end
iplot = find(iBrushedPlot, 1);

% add brushed points to the other subplots of the same array
if ~isempty(iplot)
    selectedData = brushing.hScatter(iplot).BrushData;
    a = ceil(iplot/3); % array this plot belongs to
    for isp = 3*(a-1)+(1:3)
        if isp ~= iplot
            brushing.hScatter(isp).BrushData = selectedData;
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

%% Redraw one array's plots from DET (colors and positions)
function refreshArrayPlots(a)

global brushing DET

k = 3*(a-1);
C = brushing.params.colorMat(DET{a}.('color'), :);

% update t vs az plot
set(brushing.hScatter(k+1), 'cdata', C, ...
    'xdata', DET{a}.('TDet'), ...
    'ydata', DET{a}.('Ang')(:,1))

% update t vs el plot
set(brushing.hScatter(k+2), 'cdata', C, ...
    'xdata', DET{a}.('TDet'), ...
    'ydata', DET{a}.('Ang')(:,2))

% update az vs el plot
set(brushing.hScatter(k+3), 'cdata', C, ...
    'xdata', DET{a}.('Ang')(:,1), ...
    'ydata', DET{a}.('Ang')(:,2))
end

%% Keypress Callback
function keyPressCallback(source, eventdata)

global brushing DET DETprev f

key = eventdata.Key;
nArr = numel(DET);

% get highlighted data on each array:
Ind = cell(1,nArr);
for a = 1:nArr
    for isp = 3*(a-1)+(1:3)
        selectedData = brushing.hScatter(isp).BrushData;
        Itemp = find(selectedData~=0);
        Ind{a} = [Ind{a}, Itemp];
        brushing.hScatter(isp).BrushData = []; % unselect highlighted points
    end
end


numkey = str2double(key); % convert keyboard input to a number (returns NaN if value is not a number)
if ~(isempty(numkey)||isnan(numkey)) % if input is number, assign as whale number:
    if numkey>9||numkey<0
        errBox = msgbox('error: invalid whale number\nSelect a number 1 thorugh 9', 'Error');
    else
        DETprev = DET; % set DETprev as current state for undo

        for a = 1:nArr
            if ~isempty(Ind{a})
                DET{a}.('Label') = ww_pad_label_assign(DET{a}.('Label'), Ind{a}, key);
                DET{a}.('color')(Ind{a}) = (numkey + 2);
                refreshArrayPlots(a)
            end
        end

    end
    ww_refresh_encounter_options();

else % if input is letter, perform associated function
    switch key

        case 'e' % extended numbers

            extend = inputdlg(['Enter extended number 10 through 20']);
            if isempty(extend) % user cancelled the dialog instead of entering a number
                numkey = [];
            else
                numkey = str2double(extend{1});
            end

            if isempty(numkey) || isnan(numkey) || numkey<10 || numkey>20
                errBox = msgbox('error: invalid whale number\nSelect a number 10 through 20', 'Error');
            else
                DETprev = DET; % set DETprev as current state for undo

                for a = 1:nArr
                    if ~isempty(Ind{a})
                        DET{a}.('Label') = ww_pad_label_assign(DET{a}.('Label'), Ind{a}, numkey);
                        DET{a}.('color')(Ind{a}) = (numkey + 2);
                        refreshArrayPlots(a)
                    end
                end
            end
            ww_refresh_encounter_options();


        case 'd' % delete
            DETprev = DET; % set DETprev as current state for undo

            for a = 1:nArr
                if ~isempty(Ind{a})
                    DET{a}(Ind{a}, :) = [];
                    refreshArrayPlots(a)
                end
            end

            % update spectra figure
            ww_generateSpectraPlot('species', DET, f, brushing);
            ww_refresh_encounter_options(); % deleting detections can remove a whale's last remaining label

        case 'a'
            if nArr < 2
                msgbox('Whale association requires two arrays.', 'Associate whales');
                return
            end

            Arrstruct = inputdlg('Enter labeled array (''1'' or ''2''):', 'Associate whales');
            if isempty(Arrstruct) % user cancelled the dialog instead of entering a value
                return
            end
            labeledInstnum = str2double(Arrstruct{1});

            if labeledInstnum==1
                unlabeledInstnum = 2;
            elseif labeledInstnum==2
                unlabeledInstnum = 1;
            else
                errordlg('Invalid instrument number')
                return
            end

            whalenum = inputdlg('Enter whale number to associate(a number, or ''a'' for all): ', 'Associate whales');
            if isempty(whalenum) % user cancelled the dialog instead of entering a value
                return
            end

            if strcmp(whalenum{1}, 'a') % process all whales
                wnums = unique(DET{labeledInstnum}.color);
                wnums(wnums==2) = []; % remove 'unlabeled'
                for wn = 1:length(wnums)
                    DET = ww_whaleAssociate(DET, labeledInstnum, unlabeledInstnum, wnums(wn)-2);

                end
            else % process only specified whale
                wn = str2double(whalenum{1});
                nColors = size(brushing.params.colorMat,1);
                if isnan(wn) || wn<1 || wn>nColors-2
                    errordlg(sprintf('Invalid whale number. Enter a number 1 through %d, or ''a'' for all.', nColors-2))
                elseif ~any(DET{labeledInstnum}.color == wn+2)
                    errordlg(sprintf('Whale %d has no labeled detections on array %d.', wn, labeledInstnum))
                else
                    DET = ww_whaleAssociate(DET, labeledInstnum, unlabeledInstnum, wn);
                end
            end

            % update the newly labeled array's plots
            refreshArrayPlots(unlabeledInstnum)

            % update spectra figure
            ww_generateSpectraPlot('species', DET, f, brushing);
            ww_refresh_encounter_options(); % associating whales can label the other array's detections


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
            tlim = NaT(1,2); % limit of time axes
            for narr = 1:nArr
                tlim(1) = min([tlim(1); DET{narr}.TDet]);
                tlim(2) = max([tlim(2); DET{narr}.TDet]);
            end

            for a = 1:nArr
                if ~isempty(DET{a}.Ang)
                    k = 3*(a-1);
                    set(brushing.hScatter(k+1).Parent, 'XLim', tlim, 'YLim', ...
                        [min(DET{a}.Ang(:,1))-2, max(DET{a}.Ang(:,1))+2]) % update t vs az plot
                    set(brushing.hScatter(k+2).Parent, 'XLim', tlim, ...
                        'YLim', [min(DET{a}.Ang(:,2))-2, max(DET{a}.Ang(:,2))+2]) % update t vs el plot
                    set(brushing.hScatter(k+3).Parent, 'XLim', [min(DET{a}.Ang(:,1)), max(DET{a}.Ang(:,1))], ...
                        'YLim', [min(DET{a}.Ang(:,2))-2, max(DET{a}.Ang(:,2))+2]) % update az vs el plot
                end
            end


        case 'u' % undo
            DET = DETprev;

            for a = 1:nArr
                refreshArrayPlots(a)
            end

            % update spectra figure
            ww_generateSpectraPlot('species', DET, f);
            ww_refresh_encounter_options(); % undo can revert whale-label assignments

        case 'y' % plot the mean spectra of selected clicks

            ww_generateSpectraPlot('selected', DET, f, Ind);

        case 'v' % plot the 3D positions of labeled whales

            if nArr < 2
                msgbox('3D localization requires two arrays.', 'Plot 3D positions');
                return
            end
            ww_generate3DPlot('plot', DET, brushing);

    end % end key input toggles
end

end

% ww_pad_label_assign is now its own file (ww_pad_label_assign.m) so
% ww_whaleAssociate.m can share it too.
