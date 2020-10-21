%% Yacine Mahdid 05 Septembre 2020
% This is the way that Dr. Lucrezia Liuzzi calculate pli

%% Path Setup
% Local Source
%{
INPUT_DIR = "/media/yacine/My Book/datasets/consciousness/AEC vs wPLI/source localized data/";
OUTPUT_DIR = "/media/yacine/My Book/test_result/liuzzi_graph/";
%}

% Remote Source
%
INPUT_DIR = "/lustre03/project/6010672/yacine08/aec_vs_pli/data/source_localized_data/";
OUTPUT_DIR = "/lustre03/project/6010672/yacine08/aec_vs_pli/result/ex_1_pli_generation_comparison/liuzzi_graphs/";
NEUROALGO_PATH = "/lustre03/project/6010672/yacine08/NeuroAlgo";

% Add NA library to our path so that we can use it
addpath(genpath(NEUROALGO_PATH));
%}

%% Experiment Variables
P_IDS = {'MDFA03', 'MDFA05', 'MDFA06', 'MDFA07', 'MDFA10', 'MDFA11', 'MDFA12', 'MDFA15', 'MDFA17'};
EPOCHS = {'eyesclosed_1', 'induction', 'emergence_first', 'emergence_last', 'eyesclosed_8'};

% indice of the scalp regions
SCALP_REGIONS = [82 62 54 56 58 60 30 26 34 32 28 24 36 86 66 76 84 74 72 70 88 3 78 52 50 48 5 22 46 38 40 98 92 90 96 94 68 16 18 20 44 83 63 55 57 59 61 31 27 35 33 29 25 37 87 67 77 85 75 71 73 89 4 79 53 51 49 6 23 47 39 41 99 93 91 97 95 69 17 19 21 45];
NUM_REGIONS = length(SCALP_REGIONS);

% wPLI Parameters:
% Alpha bandpass
low_frequency = 8;
high_frequency = 13;

% Size of the cuts for the data
window_size = 10; % in seconds
step_size = 1; % in seconds
cut = 10;

% Type of graph to calculate
graph = 'wpli';

%% Setup the Directory Structure
mkdir(OUTPUT_DIR)


%% Calculate wPLI on all windows
for p = 1:length(P_IDS)
   p_id = P_IDS{p};
   for e = 1:length(EPOCHS)
        epoch = EPOCHS{e};
        
        fprintf("Analyzing participant '%s' at epoch '%s'\n", p_id, epoch);
        
        participant_in_path = strcat(INPUT_DIR, p_id, filesep, p_id, '_', epoch, '.mat');
        participant_out_path = strcat(OUTPUT_DIR, p_id, '_', epoch, '_', graph, '.mat');
 
        %% Load data
        load(participant_in_path);

        Value = Value(SCALP_REGIONS,:);
        Atlas.Scouts = Atlas.Scouts(SCALP_REGIONS);

        % Get ROI labels from atlas
        LABELS = cell(1,NUM_REGIONS);
        for ii = 1:NUM_REGIONS
            LABELS{ii} = Atlas.Scouts(ii).Label;
        end

        % Sampling frequency : need to round
        fd = 1/(Time(2)-Time(1));

        %% Filtering
        % Frequency filtering, requires eeglab or other frequency filter.
        Vfilt = filter_bandpass(Value, fd, low_frequency, high_frequency);
        Vfilt = Vfilt';

        % number of time points and Regions of Interest
        num_points = length(Vfilt);

        %% No correction + PLI calculation
        [m,R] = size(Vfilt);
        
        ht = hilbert(Vfilt);
        ht = ht(cut+1:end-cut,:);
        ht = bsxfun(@minus,ht,mean(ht,1));
        % Phase information
        theta = angle(ht);

        % Bandwidth
        B = high_frequency-low_frequency;
        % Window duration for PLI calculation
        T = 100/(2*B);                % ~100 effective points
        N = round(T*fd/2)*2;
        K = fix((m-N/2-cut*2)/(N/2)); % number of windows, 50% overlap
        V = nchoosek(R,2);            % number of ROI pairs
        pli_vector = zeros(V,K);

        
        %% Iterate over each window and calculate pairwise corrected aec
        result = struct();
        pli = zeros(NUM_REGIONS, NUM_REGIONS, K);
        
        % Boolean mask to convert to a square matrix
        ind = logical(triu(ones(R),1));
        
        % Loop over time windows
        for k = 1:K

            ibeg = (N/2)*(k-1) + 1;
            iwind = ibeg:ibeg+N-1;

            % loop over all possible ROI pairs
            for jj = 2:R
                ii = 1:jj-1;
                indv = ii + sum(1:jj-2);
                % Phase difference
                RP = bsxfun(@minus,theta(iwind,jj),theta(iwind, ii));
                srp = sin(RP);
                pli_vector(indv,k) = abs(sum(sign(srp),1))/N;

            end
            
            % Attempt at converting from a vector to a pli matrix
            pli_temp = zeros(NUM_REGIONS, NUM_REGIONS);
            pli_temp(ind) = pli_vector(:, k);
            pli_temp = pli_temp + pli_temp';
            
            pli(:, :, k) = pli_temp;
        end
        
        result.wpli = pli;

        % Bundling some metadata that could be useful along with the graph
        result.window_size = window_size;
        result.step_size = step_size;
        result.labels = LABELS;

        % Save the result structure at the right spot
        save(participant_out_path, 'result');
      
   end
end
