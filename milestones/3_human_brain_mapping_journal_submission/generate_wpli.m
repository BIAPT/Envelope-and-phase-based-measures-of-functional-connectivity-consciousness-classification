%% Yacine Mahdid August 17 2020
% This script goal is to generate the wPLI matrices that are needed to
% calculate the features for each participants from the source localized
% data.

%This will need to be broken down into two script:
% - one that will generate aec
% - one that will generate wpli
% this way we can parallelize these on the cluster
% But first we need to clean this out

INPUT_DIR = "/media/yacine/My Book/datasets/consciousness/AEC vs wPLI/source localized data/";
SCALP_REGIONS = [82 62 54 56 58 60 30 26 34 32 28 24 36 86 66 76 84 74 72 70 88 3 78 52 50 48 5 22 46 38 40 98 92 90 96 94 68 16 18 20 44 83 63 55 57 59 61 31 27 35 33 29 25 37 87 67 77 85 75 71 73 89 4 79 53 51 49 6 23 47 39 41 99 93 91 97 95 69 17 19 21 45];
NUM_REGIONS = length(SCALP_REGIONS);
participant_path = strcat(INPUT_DIR, 'MDFA03/MDFA03_emergence_first.mat');


%% TO REFACTOR

% Lucrezia Liuzzi, SPMIC, University of Nottingham, 09/06/2017
%
% Comparison of amplitude envelope correlation (AEC) 
% (1) with multivariate leakage correction applied over all time course, 
% (2) multivariate leakage correction applied in sliding windows,
% (3) pairwise correction in sliding windowns ,
% and phase lag index (PLI) averaged over shorter sliding windows.
%
% Requires "symmetric_orthogonalise.m", "leakage_reduction.mexa64", and
% EEGlab package or alternative frequency filter (see line 72).


%% Load data
load(participant_path);

Value= Value(SCALP_REGIONS,:);
Atlas.Scouts = Atlas.Scouts(SCALP_REGIONS);

% Get ROI labels from atlas
LABELS = cell(1,NUM_REGIONS);
for ii = 1:NUM_REGIONS
    LABELS{ii} = Atlas.Scouts(ii).Label;
end

% Sampling frequency
fd = 1/(Time(2)-Time(1));


%%  Choose frequency band
fname = 'alpha';
switch fname
    case 'delta'
        lowpass = 4;
        highpass = 1;
    case 'theta'
        lowpass = 8;
        highpass = 4;
    case 'alpha'
        lowpass = 13;
        highpass = 8;
    case 'beta'
        lowpass = 30;
        highpass = 13;
    case 'gamma'
        lowpass = 48;
        highpass = 30;
end


% Frequency filtering, requires eeglab or other frequency filter.
Vfilt = eegfilt(Value,fd,highpass,lowpass,0,0,0,'fir1');

Vfilt = Vfilt';

% number of time points and Regions of Interest
[m,R] = size(Vfilt);  

% cuts edge points from hilbert transform
cut = 10;

%% No correction + PLI calculation
ht = hilbert(Vfilt);
ht = ht(cut+1:end-cut,:);
ht = bsxfun(@minus,ht,mean(ht,1));

% Phase information
theta = angle(ht);

% Bandwidth
B = lowpass-highpass;

% Window duration for PLI calculation
T = 10;

N = round(T*fd/2)*2;
K = fix((m-N/2-cut*2)/(N/2)); % number of windows, 50% overlap
V = nchoosek(R,2);            % number of ROI pairs

pli = zeros(V,K);

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
        pli(indv,k) = abs(sum(sign(srp),1))/N;
        
    end
end

% Convert to a square matrix
ind = logical(triu(ones(R),1));
PLI = zeros(R);

% Average over windows
PLI(ind) = mean(pli,2);
PLI = PLI + PLI';