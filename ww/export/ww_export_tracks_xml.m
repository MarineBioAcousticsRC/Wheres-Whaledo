function ww_export_tracks_xml()

% ww_export_tracks_nc(opts)
%
% function to export cleaned tracks as .nc files optimized for archive in a
% DRYAD repository

global PARAMS HANDLES

% calculate reference location for position data
insoPath = dir(PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+"\*harp4chParams.mat");
for k = 1:numel(insoPath)
    load(fullfile(insoPath(k).folder,insoPath(k).name));
    hydLoc{k} = recLoc;
end
if numel(hydLoc) == 1
    h0 = hydLoc{1};
elseif numel(hydLoc) == 2
    h0 = mean([hydLoc{1};hydLoc{2}]);
end
ref_lat = h0(1);
ref_lon = h0(2);
ref_depth = h0(3);

% load the encounter table
enc = readtable(HANDLES.ui.export.encPath.Value);

% load in and format data
fileDir = dir(HANDLES.ui.export.inPath.Value);

% define instrument type (deployment or ensemble)
instType = PARAMS.project.DataSourceType;
% if the instrument type is a deployment rather than an ensemble, give a
% warning and go back to the main screen. I don't know what a single
% instrument localization would look like so can develop this once we have
% that sort of tracking approach in the water
if instType == "Deployment"
    uialert(HANDLES.fig.main,"XML file generation not supported for this instrument type.","Error");
    return
end
ens = PARAMS.project.DataSourceName+"_ensemble";

% add Tethys code to the path
addpath(genpath(HANDLES.ui.export.opt1.Value))

% connect to Tethys server
q = dbInit('Server',HANDLES.ui.export.opt2.Value,'Port',str2num(HANDLES.ui.export.opt3.Value));
% dbOpenSchemaDescription(q,'Localize'); % open locaize schema (for our reference)

import nilus.* % import nulis, pg 4

[~,zeroPos] = dbGetEnsembles(q,'Id',ens); % grab the zero position for this ensemble

% create a file for each encounter
for j = 1:height(enc)

    % match the track to this encounter number
    matchIdx = find(strcmp({fileDir.name}, ['enc', num2str(enc.encN(j))]));

    if ~isempty(matchIdx) % if we tracked whales in this encounter

        % create our elements
        l = Localize();
        h = Helper();
        m = MarshalXML();

        m.marshal(l); % generate our XML (empty right now)
        h.createRequiredElements(l); % create the required elements

        thisUnqId = [ens+'_'+PARAMS.project.ProjectName+'_tracks_'+PARAMS.project.UserId+'_encounter'+num2str(enc.encN(j))];

        l.setUserId(PARAMS.project.UserId);
        l.setId(thisUnqId); % unique ID for this file
        l.getDataSource().setEnsembleId(ens); % replace this with real instruments
        % m.marshal(l)

        % description
        h.createElement(l,'Description');
        description = l.getDescription();
        description.setAbstract(PARAMS.project.Abstract);
        description.setMethod("See the associated Where'sWhaledo publications for full details, Baggett et al., 2025 (https://doi.org/10.1038/s41598-025-24490-x) and Snyder et al., 2024 (https://doi.org/10.1371/journal.pcbi.1011456). See also the software source code and manual at https://github.com/MarineBioAcousticsRC/Wheres-Whaledo.")
        % m.marshal(description)

        % algorithm
        alg = l.getAlgorithm();
        h.createRequiredElements(alg);
        alg.setSoftware(PARAMS.project.Software);
        alg.setVersion(PARAMS.project.Version);

        % add in specific paramters
        h.createElement(alg,'Parameters')
        algparm = alg.getParameters();
        algparmList = algparm.getAny();

        paramsFiles = dir(PARAMS.projectSaveFolder+PARAMS.project.InstrumentOrientationRelPath+"\*harp4chParams.mat");
        instruments = extractBefore(string({paramsFiles.name}),'_harp4chParams.mat');
        ior = load(fullfile(paramsFiles(1).folder,paramsFiles(1).name));

        if isfield(PARAMS.project,'DetectionLocalizationParams')
            h.AddAnyElement(algparmList,'bandpass_edge_low_Hz',num2str(PARAMS.project.DetectionLocalizationParams.bpEdges(1)));
            h.AddAnyElement(algparmList,'bandpass_edge_high_Hz',num2str(PARAMS.project.DetectionLocalizationParams.bpEdges(2)));
            h.AddAnyElement(algparmList,'detection_threshold_counts',num2str(PARAMS.project.DetectionLocalizationParams.detThresh_counts));
            h.AddAnyElement(algparmList,'signal_duration_samples',num2str(PARAMS.project.DetectionLocalizationParams.sigDur_us));
            h.AddAnyElement(algparmList,'max_TDOA_ms',num2str(PARAMS.project.DetectionLocalizationParams.maxTDOA_ms));
            h.AddAnyElement(algparmList,'min_pk_dist_ms',num2str(PARAMS.project.DetectionLocalizationParams.minPkDist_ms));
            h.AddAnyElement(algparmList,'sound_speed_ms-1',num2str(ior.c));
        end

        % effort
        effort = l.getEffort();
        h.createRequiredElements(effort)
        effort.setStart(h.timestamp(dbSerialDateToISO8601(enc.startSnipped(j))));
        effort.setEnd(h.timestamp(dbSerialDateToISO8601(enc.endSnipped(j))));
        effort.setTimeReference('relative');
        effort.setDimension(3);
        ltype = effort.getLocalizationType();
        ltype.add('Track');
        % m.marshal(effort)

        % coordinate reference
        crs = effort.getCoordinateReferenceSystem();
        crs.setSubtype('Engineering');
        crs.setName('Cartesian');
        % m.marshal(crs)

        % reference frame
        h.createElement(crs,'ReferenceFrame');
        ref = crs.getReferenceFrame();
        ref.setAnchor('WGS84');
        % can use the helper class to convert this to a double
        ref.setLatitude(h.toXsDouble(zeroPos.Latitude));
        ref.setLongitude(h.toXsDouble(zeroPos.Longitude));
        ref.setElevationM(h.toXsDouble(zeroPos.ElevationInstrument_m));
        % m.marshal(ref)

        % load the tracked data for this encounter
        thisFile = dir([fileDir(matchIdx).folder,'\',fileDir(matchIdx).name,'\*whale_struct.mat']);
        load(fullfile(thisFile.folder,thisFile.name))
        whale = whale(~cellfun('isempty',whale)); % remove empty cells
        keepIdx = cellfun(@(x) ~(istable(x) && any(size(x)==0)), whale);
        whale = whale(keepIdx);

        % retrieve the list of localizations, this will be empty at first
        loc_list = l.getLocalizations().getLocalization();
        % loc_list = l.getLocalizations();

        % loop over the tracks in this encounter
        for wn = 1:numel(whale)

            track = LocalizationType();
            h.createElement(track,'TimeStamp')
            h.createElement(track,'Track')
            h.createElement(track,'SpeciesId')
            t = track.getTrack();
            h.createElement(t,'Cartesian')
            h.createElement(t,'TimeStamps')
            cart = t.getCartesian();
            h.createElement(cart,'Coordinates')
            h.createElement(cart,'CoordinateError')

            % set the first timestamp
            track.setTimeStamp(h.timestamp(dbSerialDateToISO8601(whale{wn}.TDet(1))));

            % set species id
            spc = q.QueryTethys(char("lib:completename2tsn(""" + whale{wn}.Species(1) + """)")); % get the ITIS species code
            speciestype = SpeciesIDType();
            speciestype.setValue(h.toXsInteger(str2num(spc)));
            track.setSpeciesId(speciestype)

            % set coordinate bounds        
            bounds = cart.getCoordinateBounds();
            nw = bounds.getNorthWest();
            nw.setXM(min(whale{wn}.wloc(:,1)))
            nw.setYM(max(whale{wn}.wloc(:,2)))
            bounds.setNorthWest(nw)
            se = bounds.getSouthEast();
            se.setXM(max(whale{wn}.wloc(:,1)))
            se.setYM(min(whale{wn}.wloc(:,2)))

            % add timestamps
            ts = t.getTimeStamps();
            for n = 1:height(whale{wn})
                ts.add(h.timestamp(dbSerialDateToISO8601(whale{wn}.TDet(n))));
            end
           
            % create X,Y,Z
            locations = whale{wn}.wloc;
            col = 1;
            c = cart.getCoordinates();
            for field = ["XM", "YM", "ZM"]
                h.createElement(c, field);
                % we want to call c.getXM, c.getYM, etc.
                coord_list = javaMethod(sprintf("get%s", field), c);
                for row = 1:size(locations, 1)
                    coord_list.add(locations(row, col));
                end
                col = col + 1;
            end

            % create X,Y,Z error
            errs = [abs(whale{wn}.CIx(:,1)-whale{wn}.CIx(:,2))/2, abs(whale{wn}.CIy(:,1)-whale{wn}.CIy(:,2))/2, abs(whale{wn}.CIz(:,1)-whale{wn}.CIz(:,2))/2];
            col = 1;
            c = cart.getCoordinateError();
            for field = ["XM", "YM", "ZM"]
                h.createElement(c, field);
                % we want to call c.getXM, c.getYM, etc.
                coord_list = javaMethod(sprintf("get%s", field), c);
                for row = 1:size(errs, 1)
                    coord_list.add(errs(row, col));
                end
                col = col + 1;
            end

            % add this track to the list
            track.setTrack(t)
            loc_list.add(track);
            
        end % move onto the next track

        % m.marshal(l)
        xml_out = [HANDLES.ui.export.outPath.Value+"\"+thisUnqId+".xml"];
        fprintf('XML document formatted for Tethys saving at: %s\n',xml_out)
        m.marshal(l, xml_out) % save the xml file in your path from above

    end

end

