function spmj_move_realigned_images(sn, varargin)
% Move images created by realign(+unwarp) into imaging_data
% sn should be int when running the function (not CHAR)

% Setting the base directory for the current project
baseDir = '/Volumes/Diedrichsen_data$/data/Chord_exp/EFC_patternfMRI';
imagingRawDir = 'imaging_data_raw';     % Temporary directory for raw functional data
imagingDir    = 'imaging_data_test';     % Preprocessed functional data

% Read subject info from the participants.tsv file
pinfo = dload(fullfile(baseDir, 'participants.tsv'));

% Handling input args:
prefix = 'u';   % 'u' for the 4D images after realign+unwarp; could be 'r' for realigned only.
rtm = 0;        % realign_unwarp registered to the first volume (0) or the mean image (1).
vararginoptions(varargin, {'prefix', 'rtm'});

if isempty(sn)
    error('FUNC:move_realigned_images -> ''sn'' must be passed to this function.')
end

% Extract the participant ID (e.g., 's101') using the subject number.
participant = char(pinfo.participant_id(pinfo.sn == sn));

% For runs, use the runSessN field from the TSV file.
run_list = pinfo.FuncRuns(pinfo.sn == sn);
% If run_list is a single string containing delimited runs, split it:
if ischar(run_list)
    run_list = split(run_list);
end
% Convert run numbers to a two-digit string format if needed:
run_list = cellfun(@(x) sprintf('%.02d', str2double(x)), run_list, 'UniformOutput', false);

% Loop over sessions (using the numSess field)
for sess = 1:pinfo.numSess(pinfo.sn == sn)
    runSessField = sprintf('runsSess%d', sess); % Construct run field name based on current session
    if isfield(pinfo, runSessField) % Check if the field exists
        runSessN = pinfo.(runSessField); % Extract values from the corresponding column
        validRuns = pinfo.FuncRuns(ismember(pinfo.(runSessField), runSessN)); % Get the runs
        run_list = regexp(validRuns, '\.', 'split'); %Split by dots into a cell
        run_list = [run_list{:}];%convert to list
        run_list = cellfun(@str2double, run_list);
        run_list = arrayfun(@(x) sprintf('%02d', x), run_list, 'UniformOutput', false); %convert from 1 to 01 etc.
    end
    % Loop on runs of the session:
    for r = 1:length(run_list)
        % Construct the file name.
        % If the files are like "us1XX_run_XX_sbref.nii", then:
        file_name = [prefix, participant, '_run_', run_list{r}, '_sbref.nii'];
        % TODO: Discuss the decision to use SBREF instead of multiplanar
        fprintf('Processing file: %s\n', file_name)
        
        % Define source and destination directories:
        source = fullfile(baseDir, imagingRawDir, participant, sprintf('sess%d', sess), file_name);
        destDir = fullfile(baseDir, imagingDir, participant, sprintf('sess%d', sess));
        if ~exist(destDir, 'dir')
            mkdir(destDir)
        end
        dest = fullfile(destDir, file_name);
        
        % Move the file:
        [status, msg] = movefile(source, dest);
        if ~status
            error('BIDS:move_realigned_images -> %s', msg)
        end
        
    end
    
end
