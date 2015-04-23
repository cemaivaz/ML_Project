%% Simple Gaussian Classifier for Music Genre Classification Lab
%% EAAAI - 2012
%% Note: This code is not optimized for Matlab performance. Rather
%%  it was developed to be general (e.g., use of loops) so that it 
%%  can be ported to other programming languages.
%%
%% Author: Douglas Turnbull, EAAI 2012 Model AI Assignment, Feb 2012

clear all;

%% Script Parameters
dataRoot = 'data\';
genres = {'classical','country','jazz','pop','rock','techno'};
genres = {'classical','country'};


%% Import Data
for i  = 1:length(genres)
    genreDir = [dataRoot genres{i} '\']
    files =  dir([genreDir '*.ent12']);      % 
    for s = 1:length(files)
        datafile = [genreDir files(s).name];
        songdata = importdata(datafile);
        songs(i,s).name = songdata.textdata;
        songs(i,s).featureMat = songdata.data; 
        songs(i,s).genreID = i;
    end
    
end

%% Split Training and Evaluation Datasets    
rp = randperm(25);
trainIdx = rp(1:20);
testIdx = rp(21:25);


%% Learn Gaussian Model from Training Data
for i = 1:length(genres)
    trData(i).vecs = [];
    for s = 1:length(trainIdx)
        trData(i).vecs = [trData(i).vecs; songs(i,trainIdx(s)).featureMat];
    end
    
    trData(i).mean = mean(trData(i).vecs);
    trData(i).icov = inv(cov(trData(i).vecs));
    
end


%% Evaluate Models with Test Data
cnt = 1;
for g = 1:length(genres)
    for s = 1:length(testIdx)
        for m = 1:length(genres)
            numVec = size(songs(g,testIdx(s)).featureMat,1);
            d = songs(g,testIdx(s)).featureMat - repmat(trData(m).mean,numVec,1);
           
            logL = [];
            for v = 1:numVec
                logL(v) = -0.5 * d(v,:) * trData(m).icov * d(v,:)';
            end 
            meanLogL(m,cnt) = mean(logL);
        end
        truth(cnt) = g;
        cnt = cnt+1;
        
    end
end

%% Performance Evaluation
[v guess ] = max(meanLogL);
peformance = [truth; guess; truth==guess]'; %use information for a confusion matrix
accuracy = length(find(truth==guess))/length(truth)
disp(sprintf('Music Classifier Accuracy: %4.2f',accuracy));