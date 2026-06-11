function ww_show_encounter_options(fname)

% ww_show_encounter_options(fname)
%
% screen shown after user selects an encounter to verify.
% can color detections by either whale number or species label
% button for auto-labeling + keystroke commands for brushDOA
% column for mapping whale numbers to species
% column for mapping species labels from ID files to their scientific names
% button for saving cleaned encounter

global PARAMS HANDLES DET freq p brushing
DET = []; % clear old globals
freq = [];
p = [];

ww_clear_HANDLES_ui_content(); % clear old ui handles
HANDLES.fig.main.Name = PARAMS.project.Software + " v" + PARAMS.project.Version + ...
    " - " + PARAMS.project.ProjectName + " Clean Encounter";

close all; % close old brushDOA windows, if they're open

% ---- root layout: top bar + main content ----
root = uigridlayout(HANDLES.ui.content,[4 1]);
root.RowHeight   = {40, 60, 44, '1x'};
root.ColumnWidth = {'1x'};
root.Padding     = [20 20 20 20];
root.RowSpacing  = 12;

% ---- top bar ----
topbar = uigridlayout(root,[1 4]);
topbar.Layout.Row = 1;
topbar.ColumnWidth = {260,220,'1x',1};
topbar.Padding = [0 0 0 0];
HANDLES.ui.encscreen.btnBack = uibutton(topbar,'push', ...
    'Text',"← Select a different encounter", ...
    'FontSize',12, ...
    'FontWeight','bold', ...
    'ButtonPushedFcn', @(~,~) ww_show_verify_tracks());
HANDLES.ui.encscreen.btnBack.Layout.Row = 1;
HANDLES.ui.encscreen.btnBack.Layout.Column = 1;

% ---- title (its own root row) ----
titleLbl = uilabel(root, ...
    'Text',"Cleaning File: "+fname, ...
    'FontSize',28, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center');
titleLbl.Layout.Row = 2;

% ---- radio row: label + button group ----
radioRow = uigridlayout(root,[1 2]);
radioRow.Layout.Row = 3;
radioRow.ColumnWidth = {220, '1x'};
radioRow.Padding = [0 0 0 0];
radioRow.ColumnSpacing = 12;
lbl = uilabel(radioRow, ...
    'Text',"Color detections by:", ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','center');
lbl.Layout.Column = 1;
HANDLES.ui.enc.colMethod = uibuttongroup(radioRow, ...
    'BorderType','none', ...
    'BackgroundColor',[0.7608 0.8392 0.7059], ...
    'SelectionChangedFcn', @onModeChanged);
HANDLES.ui.enc.colMethod.Layout.Column = 2;
HANDLES.ui.enc.rbWhaleNum = uiradiobutton(HANDLES.ui.enc.colMethod, ...
    'Text',"Whale number", ...
    'Position',[10 8 140 22]);
HANDLES.ui.enc.rbSpeciesLab = uiradiobutton(HANDLES.ui.enc.colMethod, ...
    'Text',"Species label", ...
    'Position',[170 8 140 22]);
HANDLES.ui.enc.colMethod.SelectedObject = HANDLES.ui.enc.rbWhaleNum;

% ---- 3-column area spanning the rest of the screen ----
cols = uigridlayout(root,[1 3]);
cols.Layout.Row = 4;
cols.ColumnWidth = {'1x','1x','1x'};
cols.ColumnSpacing = 18;
cols.RowSpacing = 10;
cols.Padding = [0 0 0 0];

% ---- first column, color key and auto label button ----
p1 = uipanel(cols);
p1.Layout.Column = 1;
col1 = uigridlayout(p1,[2 1]);
col1.RowHeight = {120, '1x'};   % button | text | stretch
col1.Padding = [10 10 10 10];
col1.RowSpacing = 10;
HANDLES.ui.enc.btnAuto = uibutton(col1,'push', ...
    'Text',"Auto-label detections", ...
    'FontSize',14,...
    'Enable','off',...
    'ButtonPushedFcn', @(~,~) onAutoLabel());
HANDLES.ui.enc.btnAuto.Layout.Row = 1;
HANDLES.ui.enc.infoText = uitextarea(col1, ...
    'Editable','off', ...
    'FontSize',14, ...   % ← increase this
    'Value',[ ...
    "Keystroke Commands:"
    "• Press 0 to remove a whale number label"
    "• Press numbers to assign whale number labels"
    "• Press 'e' to assign a whale number greater than 9"
    "• Press 'd' to delete detections"
    "• Press 'z' to turn zooming on"
    "• Press 'x' to turn zooming off"
    "• Press 'r' to reset zoom"
    "• Press 'a' to associate whales across arrays"
    "• Press 'u' to undo"
    "• Press 'y' to view mean spectra of selected detections"
    "• Press 'v' to view 3D positions of labeled whales"
    ""
    "Use brushing to select points."
    ]);
HANDLES.ui.enc.infoText.Layout.Row = 2;

% ---- second column, match whales to species ----
p2 = uipanel(cols,'Title',"Assign species labels to whales:");
p2.Layout.Column = 2;

% ---- add content inside column 2 (9 text inputs) ----
col2 = uigridlayout(p2,[15 2]);  % header + 9 rows, 2 columns (label | input)
col2.Padding = [10 10 10 10];
col2.RowSpacing = 10;
col2.ColumnSpacing = 12;
col2.ColumnWidth = {80,'1x'};
col2.RowHeight = [repmat({23},1,15)];  % title row + 9 input rows

% create 9 label+editfield rows in a loop
for k = 1:15
    uilabel(col2, ...
        'Text',sprintf("Whale %d:",k), ...
        'HorizontalAlignment','right', ...
        'VerticalAlignment','center', ...
        'Layout', matlab.ui.layout.GridLayoutOptions('Row',k,'Column',1));
    HANDLES.ui.enc.whaleSpecies(k) = uieditfield(col2,'text', ...
        'Editable','off','Enable','off',...
        'Layout', matlab.ui.layout.GridLayoutOptions('Row',k,'Column',2), ...
        'ValueChangedFcn', @(src,evt) onWhaleSpeciesChanged(k, src.Value));
end

% ---- layout inside the third column ----
p3 = uipanel(cols,'Title',"Match latin species names to shorthand species codes:");
p3.Layout.Column = 3;

HANDLES.ui.enc.col3 = uigridlayout(p3,[2 2]);   % start with 1 row, 2 cols
HANDLES.ui.enc.col3.Padding = [10 10 10 10];
HANDLES.ui.enc.col3.RowSpacing = 10;
HANDLES.ui.enc.col3.ColumnSpacing = 12;
HANDLES.ui.enc.col3.ColumnWidth = {80,'1x'};

HANDLES.ui.enc.saveFolderLabel = uilabel(HANDLES.ui.enc.col3, ...
    'Text',"Save location:", ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','center');
% grab encounter name
encNum = regexp(fname, 'enc\d+_', 'match');
encNum = extractBefore(encNum,strlength(encNum));
HANDLES.ui.enc.saveFolder = uieditfield(HANDLES.ui.enc.col3,'text', ...
    'Value',PARAMS.projectSaveFolder+"\cleaned_encounters\" + encNum + "\"+extractBefore(fname,".mat")+"_cleaned_"+PARAMS.project.UserId+".mat",...
    'Editable','on');
HANDLES.ui.enc.SaveFolderLabel.Layout.Row = 1;
HANDLES.ui.enc.SaveFolderLabel.Layout.Column = 1;
HANDLES.ui.enc.saveFolder.Layout.Row = 1;
HANDLES.ui.enc.saveFolder.Layout.Column = 2;

HANDLES.ui.enc.btnSave = uibutton(HANDLES.ui.enc.col3,'push', ...
    'Text',"Save labels for this encounter", ...
    'FontSize',14, ...
    'ButtonPushedFcn', @(src,event) onSave());
HANDLES.ui.enc.btnSave.Layout.Row = 2;
HANDLES.ui.enc.btnSave.Layout.Column = [1 2];

% populate once at startup (will do nothing if DET empty)
refreshColumn3();

% ---- callbacks ----
    function onModeChanged(src,event) % recolor by species/whale
        mode = string(event.NewValue.Text);
        ww_brushDOA_setColorMode(mode);
    end

    function onAutoLabel(src, event) % assign labels automatically
        % run auto-labels algorithm on the array with more detections, then
        % use association to match the labels to the second array
        % if there's just one 4ch, then run on only that instrument
        if numel(DET) == 1
            ww_auto_label_whales(DET{1});
        elseif numel(DET) > 1
            if height(DET{1}) > height(DET{2})
                ww_auto_label_whales(DET{1});
            else
                ww_auto_label_whales(DET{2});
            end
            % associate here
        end


        ww_auto_label_whales()
    end

    function refreshColumn3()
        % nested helper function to update the third column based on inputs
        % from the second

        gl = HANDLES.ui.enc.col3;
        if isempty(gl) || ~isvalid(gl)
            return
        end

        % ----- compute unique species safely -----
        unqSp = strings(0,1);
        if ~isempty(DET)
            for sp = 1:numel(DET)
                if isempty(DET{sp}) || ~istable(DET{sp}) || ...
                        ~ismember('Species', DET{sp}.Properties.VariableNames)
                    continue
                end
                s = string(DET{sp}.Species);
                s = s(:);
                s(ismissing(s) | strlength(s)==0) = [];
                unqSp = [unqSp; unique(s)]; %#ok<AGROW>
            end
        end
        unqSp = unique(unqSp);
        % ignore "NaN" rows (per your request)
        unqSp = unqSp(unqSp ~= "NaN");

        % ----- persistent-ish state (stored in HANDLES) -----
        if ~isfield(HANDLES.ui.enc,'col3State') || isempty(HANDLES.ui.enc.col3State)
            HANDLES.ui.enc.col3State.species = strings(0,1);
            HANDLES.ui.enc.col3State.lbl     = gobjects(0,1);
            HANDLES.ui.enc.col3State.edt     = gobjects(0,1);
        end
        S = HANDLES.ui.enc.col3State;

        % prune invalid handles from state
        if ~isempty(S.species)
            ok = true(numel(S.species),1);
            for i = 1:numel(S.species)
                if i > numel(S.lbl) || i > numel(S.edt) || ...
                        ~isvalid(S.lbl(i)) || ~isvalid(S.edt(i))
                    ok(i) = false;
                end
            end
            S.species = S.species(ok);
            S.lbl     = S.lbl(ok);
            S.edt     = S.edt(ok);
        end

        oldSp = S.species;
        newSp = unqSp;

        % ----- remove old loading label if it exists and we now have species -----
        if isfield(HANDLES.ui.enc,'col3Loading') && ~isempty(HANDLES.ui.enc.col3Loading) && ...
                isvalid(HANDLES.ui.enc.col3Loading) && ~isempty(newSp)
            delete(HANDLES.ui.enc.col3Loading);
            HANDLES.ui.enc.col3Loading = [];
        end

        % ----- delete rows that disappeared -----
        removedMask = ~ismember(oldSp, newSp);
        if any(removedMask)
            for i = find(removedMask).'
                if isvalid(S.lbl(i)), delete(S.lbl(i)); end
                if isvalid(S.edt(i)), delete(S.edt(i)); end
            end
            S.species(removedMask) = [];
            S.lbl(removedMask)     = [];
            S.edt(removedMask)     = [];
            oldSp = S.species;
        end

        % ----- add rows for newly-seen species (do NOT touch existing edt values) -----
        keepMask = ismember(newSp, oldSp);
        addSp = newSp(~keepMask);
        if ~isempty(addSp)
            for i = 1:numel(addSp)
                thisSp = addSp(i);

                hL = uilabel(gl, ...
                    'Text', thisSp, ...
                    'HorizontalAlignment','right', ...
                    'VerticalAlignment','center');

                hE = uieditfield(gl,'text', ...
                    'Editable','on');

                S.species(end+1,1) = thisSp;
                S.lbl(end+1,1)     = hL;
                S.edt(end+1,1)     = hE;
            end
        end

        % ----- layout: species rows (dynamic) + spacer + saveLocation + saveButton -----
        n = numel(newSp);
        gl.ColumnWidth = {80,'1x'};
        gl.RowHeight = [repmat({30},1,n), {'1x'}, {30}, {120}];

        % optional loading message if there are no species yet
        if n == 0
            % keep any old species rows already deleted above; just show message
            if ~isfield(HANDLES.ui.enc,'col3Loading') || isempty(HANDLES.ui.enc.col3Loading) || ...
                    ~isvalid(HANDLES.ui.enc.col3Loading)
                HANDLES.ui.enc.col3Loading = uilabel(gl, ...
                    'Text',"Loading species labels for this encounter...", ...
                    'HorizontalAlignment','left', ...
                    'Layout', matlab.ui.layout.GridLayoutOptions('Row',1,'Column',[1 2]));
            else
                HANDLES.ui.enc.col3Loading.Layout.Row = 1;
                HANDLES.ui.enc.col3Loading.Layout.Column = [1 2];
            end
        else
            % ensure loading label is gone if species exist
            if isfield(HANDLES.ui.enc,'col3Loading') && ~isempty(HANDLES.ui.enc.col3Loading) && ...
                    isvalid(HANDLES.ui.enc.col3Loading)
                delete(HANDLES.ui.enc.col3Loading);
                HANDLES.ui.enc.col3Loading = [];
            end
        end

        % reorder / place species rows to match newSp order
        if n > 0
            [~, orderIdx] = ismember(newSp, S.species);  % indices into S for each row in newSp
            for row = 1:n
                ii = orderIdx(row);
                S.lbl(ii).Layout.Row = row;
                S.lbl(ii).Layout.Column = 1;
                S.edt(ii).Layout.Row = row;
                S.edt(ii).Layout.Column = 2;
            end
        end

        % ----- fixed footer rows (ALWAYS present; never recreated) -----
        % save location row
        HANDLES.ui.enc.saveFolderLabel.Layout.Row = n + 2;
        HANDLES.ui.enc.saveFolderLabel.Layout.Column = 1;

        HANDLES.ui.enc.saveFolder.Layout.Row = n + 2;
        HANDLES.ui.enc.saveFolder.Layout.Column = 2;

        % save button row
        HANDLES.ui.enc.btnSave.Layout.Row = n + 3;
        HANDLES.ui.enc.btnSave.Layout.Column = [1 2];

        % store updated state
        HANDLES.ui.enc.col3State = S;

    end

    function refreshWhaleSpeciesInputs()
        % refreshWhaleSpeciesInputs()
        %
        % nested helper function to display species information once the
        % user has assigned a whale number

        nMax = numel(HANDLES.ui.enc.whaleSpecies);
        present = false(nMax,1);
        % accumulate all species strings for each whale across arrays
        spAll = cell(nMax,1);

        if ~isempty(DET)
            for arr = 1:numel(DET)
                if isempty(DET{arr}) || ~istable(DET{arr}) || ...
                        ~ismember('Label',   DET{arr}.Properties.VariableNames) || ...
                        ~ismember('Species', DET{arr}.Properties.VariableNames)
                    continue
                end

                % --- normalize Label to string vector ---
                L = DET{arr}.Label;
                if iscell(L),      L = string(L);
                elseif ischar(L),  L = string(cellstr(L));
                else,              L = string(L);
                end
                L = L(:);

                % --- normalize Species to string vector ---
                Sp = DET{arr}.Species;
                if iscell(Sp),      Sp = string(Sp);
                elseif ischar(Sp),  Sp = string(cellstr(Sp));
                else,               Sp = string(Sp);
                end
                Sp = Sp(:);

                % --- whale nums for each row ---
                wn = str2double(L);

                % valid whale-number rows
                ok = ~isnan(wn) & wn>=1 & wn<=nMax;
                wn = wn(ok);
                Sp = Sp(ok);
                if isempty(wn)
                    continue
                end
                present(unique(wn)) = true;

                % accumulate species strings per whale
                for k = unique(wn(:)).'
                    spk = Sp(wn == k);
                    if isempty(spk)
                        continue
                    end
                    spAll{k} = [spAll{k}; spk(:)];
                end
            end
        end

        % compute modalSpecies with "NaN => second mode" rule
        modalSpecies = strings(nMax,1);
        modalSpecies(:) = "NaN"; % default if nothing / no second mode
        for k = 1:nMax
            spk = spAll{k};
            if isempty(spk)
                continue
            end
            % Treat missing/empty as "NaN" so they don't crash
            spk = string(spk);
            spk(ismissing(spk) | strlength(spk)==0) = "NaN";
            c = categorical(spk);
            [cats,~,ic] = unique(c);
            n = accumarray(ic,1);
            % sort categories by count (desc)
            [nSort, ord] = sort(n, 'descend');
            catsSort = string(cats(ord));
            % pick top mode; if it's "NaN", try second mode
            if catsSort(1) ~= "NaN"
                modalSpecies(k) = catsSort(1);
            else
                if numel(catsSort) >= 2
                    modalSpecies(k) = catsSort(2);
                else
                    modalSpecies(k) = "NaN";
                end
            end
        end

        % enable/disable fields + populate
        for k = 1:nMax
            if present(k)
                HANDLES.ui.enc.whaleSpecies(k).Enable   = 'on';
                HANDLES.ui.enc.whaleSpecies(k).Editable = 'on';
                HANDLES.ui.enc.whaleSpecies(k).Value    = modalSpecies(k);
            else
                HANDLES.ui.enc.whaleSpecies(k).Enable   = 'off';
                HANDLES.ui.enc.whaleSpecies(k).Editable = 'off';
                HANDLES.ui.enc.whaleSpecies(k).Value    = "";
            end
        end

    end

    function onWhaleSpeciesChanged(whaleNum, newLabel)
        % assign species label to all detections with Label == whaleNum
        % newLabel: char/string from edit field
        if isempty(DET)
            return
        end
        newLabel = string(strtrim(newLabel));
        if strlength(newLabel) == 0
            newLabel = "NaN";
        end
        wnStr = string(whaleNum);
        for arr = 1:numel(DET)
            if isempty(DET{arr}) || ~istable(DET{arr})
                continue
            end
            L = DET{arr}.Label;
            if iscell(L),      L = string(L);
            elseif ischar(L),  L = string(cellstr(L));
            else,              L = string(L);
            end
            L = L(:);
            idx = (L == wnStr);
            if any(idx)
                Sp = DET{arr}.Species;
                if iscell(Sp),      Sp = string(Sp);
                elseif ischar(Sp),  Sp = string(cellstr(Sp));
                else,               Sp = string(Sp);
                end
                Sp = Sp(:);
                Sp(idx) = newLabel;
                DET{arr}.Species = Sp;
            end
        end
        refreshColumn3(); % species list may have changed,rebuild column 3
        ww_generateSpectraPlot('species', DET);
    end

    function onSave(src,event)

        % assign species labels (latin) to detections
        for j = 1:numel(DET)
            DETout{j} = DET{j}; % save in an output struct
            unqWhales = str2num(unique(DETout{j}.Label));
            unqWhales = num2str(unqWhales(unqWhales>0)); % find whale labels
            for wn = 1:length(unqWhales)
                thisWhale = find(DETout{j}.Label==unqWhales(wn));
                labelMatch = HANDLES.ui.enc.whaleSpecies(wn).Value; % find the species label
                latinMatch = find(strcmp({HANDLES.ui.enc.col3State.lbl.Text}, labelMatch), 1); % find index of matching latin name
                latinValue = string(HANDLES.ui.enc.col3State.edt(latinMatch).Value); % grab latin input
                DETout{j}.Species(thisWhale) = latinValue; % assign latin input in DET struct
            end
        end

        % save the output file
        DET = DETout;
        outFile = string(HANDLES.ui.enc.saveFolder.Value);
        outFolder = fileparts(outFile);
        if ~isfolder(outFolder)
            mkdir(outFolder)
        end
        save(extractBefore(outFile, strlength(outFile)-3)+"_DET.mat",'DET','freq','p');

        % run cross-fix positions
        whale = ww_loc3D_DOAintersect_includeCI(DET, brushing);
        smoothParams.vel = 1; smoothParams.win = 20; smoothParams.maxTimeGap = 60;
        whale = ww_kalman_smooth_whales(whale,smoothParams.vel,smoothParams.win,smoothParams.maxTimeGap);

        % plot these figures for saving
        wfig = figure();
        scatter3(brushing.h1(1), brushing.h1(2), brushing.h1(3)+brushing.h0(3), 24, 'k^', 'filled')
        hold on
        scatter3(brushing.h2(1), brushing.h2(2), brushing.h2(3)+brushing.h0(3), 24, 'k^', 'filled')
        for wn = 1:length(whale)
            if isempty(whale{wn}) % if no whale with this num
                continue
            else
                scatter3(whale{wn}.wloc(:,1),whale{wn}.wloc(:,2),whale{wn}.wloc(:,3)+brushing.h0(3),...
                    'filled','markerfacecolor',brushing.params.colorMat(wn+2, :))
            end
        end
        zlabel('Depth (m)')
        xlabel('E-W Distance (m)')
        ylabel('N-S Distance (m)')
        saveas(wfig,extractBefore(outFile, strlength(outFile)-3)+"_whale_loc3D_DOA_fig"); % save the fig
        close(wfig);

        wsmoothfig = figure();
        scatter3(brushing.h1(1), brushing.h1(2), brushing.h1(3)+brushing.h0(3), 24, 'k^', 'filled')
        hold on
        scatter3(brushing.h2(1), brushing.h2(2), brushing.h2(3)+brushing.h0(3), 24, 'k^', 'filled')
        for wn = 1:length(whale)
            if isempty(whale{wn}) % if no whale with this num
                continue
            else
                plot3(whale{wn}.wlocSmooth(:,1),whale{wn}.wlocSmooth(:,2),whale{wn}.wlocSmooth(:,3)+brushing.h0(3),...
                    'color',brushing.params.colorMat(wn+2, :),'LineWidth',3)
            end
        end
        zlabel('Depth (m)')
        xlabel('E-W Distance (m)')
        ylabel('N-S Distance (m)')
        saveas(wsmoothfig,extractBefore(outFile, strlength(outFile)-3)+"_whale_loc3D_DOA_smoothedFig"); % save the fig
        close(wsmoothfig);

        save(extractBefore(outFile, strlength(outFile)-3)+"_loc3D_DOA_whale_struct",'whale','smoothParams'); % save the whale struct
        
        close all; % close brushDOA windows
        ww_show_verify_tracks(); % go back to encounter screen
    end

HANDLES.ui.enc.refreshWhaleSpeciesFcn = @refreshWhaleSpeciesInputs;
HANDLES.ui.enc.refreshColumn3Fcn = @refreshColumn3;

end