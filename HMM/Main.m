%Machine Listening Project

%MUSICAL GENRE CATEGORIZATION
%HMM Main

%Cem Rifki Aydin    2013800054
%06.05.2015

%In this file, the features extracted thanks to the use of MIRToolBox are
%utilized as continuous inputs for HMM algorithm


clear all;
close all;
clc


%% WARNING:
% In this file, the features already extracted through the use of
% MIRToolBox are used. Such an approach is followed due to that the audio
% files occupy a lot of space.



%%


%We read the files in the 'data' folder, containing the features of the
%song excerpts of different genres

subDir = dir('data');


%However, if one wants to extract the features through the use of
%MIRToolBox, the below comments starting with "addpath"
%should be uncommented, and the directory names should be corrected in
%accordance with one's directory full path where the toolbox package
%resides
% addpath('C:\Program Files\MATLAB\R2014a\toolbox\somtoolbox')
% addpath('C:\Program Files\MATLAB\R2014a\toolbox\netlab')
% addpath('C:\Program Files\MATLAB\R2014a\toolbox\MIRToolboxDemos')
% addpath('C:\Program Files\MATLAB\R2014a\toolbox\MIRToolbox')
% addpath('C:\Program Files\MATLAB\R2014a\toolbox\AuditoryToolbox')

subDirInd = [subDir.isdir];

subDir_ = {subDir(subDirInd).name};
ind = ~ismember(subDir_, {'.', '..'});


testDataAll = [];

cntFile = 1;


genreLabels = [];


features_ = [];

%All the files in the subdirectories of the directory 'data' are scanned
for direc = find(ind)
    newDir = fullfile('data', subDir_{direc});
    allFiles = dir(newDir);
    
    x = newDir;
    fileN = {};
    fileNames = [];
    for file = allFiles';
        
        if strcmp(file.name, '.') == 0 && strcmp(file.name, '..') == 0
            fileNames = [fileNames {file.name}];
            fileN = [fileN; char(strcat(strcat('data\', strcat(subDir_{direc}, '\')), char(file.name)))];
        end
        
    end
    
    allData = cellstr(fileN);
    
    for u = 1:length(allData)

        fileSnd = allData(u);
        
        
        fileSnd = char(fileSnd);

        
        
        f_ = char(fileNames(u));
        %% If one wants to extract the features through the use of MIRToolBox, the
%comment section below has thoroughly to be uncommented
%         tmpFile_ = fileMv;
%         tmpFile_ = strrep(tmpFile_, 'data\', 'audio\');
%         tmpFile_ = strrep(tmpFile_, '.ent12', '.wav');
%         
%         feat_ = mirfeatures(tmpFile_);
%         d = mirgetdata(feat_);
%         
%      
%         vals_ = [d.spectral.centroid'];
%         vals_ = [vals_ d.spectral.rolloff95'];
%         vals_ = [vals_ [d.spectral.spectentropy']];
%         
%         vals_ = [vals_ d.timbre.zerocross'];
%         vals_ = [vals_ repmat(d.timbre.lowenergy, size(vals_, 1), 1)];
%      
%         vals_ = [vals_ d.spectral.mfcc'];
%         vals_ = [vals_ repmat(mean(d.rhythm.tempo), size(vals_, 1), 1) repmat(max(d.rhythm.tempo), size(vals_, 1), 1)];
%         dlmwrite(char(strcat(strcat('data\', strcat(subDir_{direc}, '\')), strcat(f_(1:end-6), '.ent12'))), vals_);
        %%
        songFeats_ = dlmread(char(strcat(strcat('data\', strcat(subDir_{direc}, '\')), strcat(f_(1:end-6), '.ent12'))), ',')' ;
        %Since NaN (not a number) values can be problematic, these values
        %are converted to 0 below
        songFeats_(isnan(songFeats_)) = 0;
        
        %All features:
        %spectrCentr, spectrRolloff, spectrEntropy, timbre.Zerocross,
        %timbre.lowEnergy, spectr.mfcc(13), meanTempo, maxTempo
        
        %Below, some spectral values, mean and maximal tempo values are
        %taken into account
        %Below is the value that can be between 1 and 12, specifying the
        %number of MFCC coefficients that are taken account of
        mfccCnt = 3;
        songFeats_ = songFeats_(1:11, [1:5, 6:6 + mfccCnt, 19:20]);
       
        features_ =  [features_ {songFeats_}];
        genreLabels = [genreLabels {subDir_{direc}}];
    end
    
    
end



%Unique genre labels are determined
order = unique(genreLabels);
coef = length(genreLabels) / length(order);
length(genreLabels);
%The below variable stores the information for the number of sets to be
%used in cross-validation
kfold = length(allData);

cv_ = cvpartition(genreLabels, 'k', kfold);



cnterAll = length(genreLabels);
cnterSucc = 0;

%We below iterate through the sets created through cross-validation
for j = 1:cv_.NumTestSets
    
    trDat = cv_.training(j);
    testDat = cv_.test(j);
    orderNo = 1;
    
    genres_ = [];
    genresTest_ = [];
    iter = 1;
    testIter = 1;
    
    mod_ = features_(trDat == 1);
       
    test_ = features_(trDat == 0);
        
    %The below iteration assumes that each file of six for each different
    %genre label is chosen as the test sample while others as training data
    for k = 1:kfold - 1:length(genreLabels) - length(test_)
        
        tra_ = [];
        for p = k:k + kfold - 2
            
            tra_ = [tra_ mod_{p}];
        end
        
        new_funcs = HMM_(order(orderNo));
        new_funcs.process(tra_);
        orderNo = orderNo + 1;
        genres_ = [genres_, new_funcs];
        genresTest_ = [genresTest_ {test_{testIter}}];
        testIter = testIter + 1;
    end
    
    cntTr = 1;
    
    for genreTest = genresTest_
        likelihoodVal = -Inf;

        predictedGenre = '';

        genreTest_ = genreTest{1};
        for genre = genres_
            
            genreLike_ = genre.likelihoodLog(genreTest_);
        
             
            %The below comment should be uncommented to see the log-likelihoods
            %fprintf('Genre %s compared with %s, likelihood: %0.2f\n', char(order(cntTr)), char(genre.nm), genreLike_);
            
            
            %Below, we try finding the maximum likelihood value. Whichever
            %training genre has this value, its label is chosen as the
            %predicted genre
            if genreLike_ > likelihoodVal
                likelihoodVal = genreLike_;
                predictedGenre = genre.nm;
            end
        end
        
        %If the label of both of the test genre and the predicted are the same,
        %it increases the success rate
        if  strcmp(order(cntTr), predictedGenre)
            cnterSucc = cnterSucc + 1;
            fprintf('True - Test genre: %s, Predicted genre: %s\n', char(order(cntTr)), char(predictedGenre));
        else
            fprintf('False - Test genre: %s, Predicted genre: %s\n', char(order(cntTr)), char(predictedGenre));
        end
        
        cntTr = cntTr + 1;
    end
    
    display('-----------------');
end 

%Success rate is printed as follows
fprintf('Success rate: %0.2f%%\n', (cnterSucc / cnterAll) * 100);

