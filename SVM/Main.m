%Machine Listening Project

%MUSICAL GENRE CATEGORIZATION
%SVM Main

%Cem Rifki Aydin    2013800054
%06.05.2015

%In this file, the features extracted thanks to the use of MIRToolBox are
%utilized as continuous inputs for HMM algorithm


clear all;
close all;
clc
format long
make 
mex -setup

%We scan the files in the 'data' folder, including the features of the
%songs of different genre
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
genreLabels = [];


valsAll = [];

%All the files in the subdirectories of the folder 'data' are scanned
for direc = find(ind)
    newDir = fullfile('data', subDir_{direc});
    allFiles = dir(newDir);
    
    x = newDir;
    fileN = {};
    
    fileNames = [];
    for file = allFiles';
        
        if strcmp(file.name, '.') == 0 && strcmp(file.name, '..') == 0
            fileNames = [fileNames; {file.name}];
            fileN = [fileN; char(strcat(strcat('data\', strcat(subDir_{direc}, '\')), char(file.name)))];
        end
        
    end
    
    allData = cellstr(fileN);
    
    for u = 1:length(allData)
        
        
        fileMv = allData(u);
        fileMv = char(fileMv)
        
        
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
        
        %Features:
        %spectral.centroid, spectral.rolloff, spectral.spectentropy, timbre.zerocross,
        %timbre.lowenergy, spectral.mfcc, meanTempo, maxTempo
        f_ = char(fileNames(u));
        
        vals_ = dlmread(char(strcat(strcat('data\', strcat(subDir_{direc}, '\')), strcat(f_(1:end-6), '.ent12'))), ',')' ;
        
        
        vals_(isnan(vals_)) = 0;
        
        %If a different feature selection is wanted to be performed, the
        %following has to be uncommented. Here, the mffcCount has to be
        %a value between 1 and 12
        %mffcCount = 3;
        %vals_ = vals_(:, [1:5, 6:6 + mffcCount, 19:20]));
        
        %spectrCentr, spectrRolloff, spectrEntropy, timbre.Zerocross,
        %timbre.lowEnergy, spectr.mfcc(13), meanTempo, maxTempo

        valsAll = [valsAll; {vals_}];
        
        genreLabels = [genreLabels; {subDir_{direc}}];
    end
end




%Unique genre labels are determined
order = unique(genreLabels);
coef = length(genreLabels) / length(order);
length(genreLabels);

foldNo = length(allData);
%The below built-in function helps us leverage the cross-validation method,
%where the "k" (fold) value in this case is 6
cv_ = cvpartition(genreLabels, 'k', foldNo);



cnterAll = length(genreLabels);
cnterSucc = 0;

avgSucc = 0;

orderInt = 1:length(unique(genreLabels));

avgSucc = 0;

RESULTS = [];
resind = 1;

%We, below, iterate over the sets created through cross-validation
for j = 1:cv_.NumTestSets
    
    trDat = cv_.training(j);
    testDat = cv_.test(j);
    
    testIter = 1;
    
    mod_ = valsAll(trDat == 1);
    
    
    test_ = valsAll(trDat == 0);
    
    %Features to be extracted are chosen as the mean, maximum, and
    %variance values of the training data of a genre class
    featuresTrAll = [];
    featuresTestAll = [];
    
    featuresLabTrAll = [];
    
    %The below iteration is performed as to divide the data into the test
    %and training ones, whereby one sixth of the files in a genre folder
    %is chosen as the test data, being repeated 6 times.
    for k = 1:foldNo - 1:length(genreLabels) - length(test_)
        
        tra_ = [];
        for p = k:k + foldNo - 2
            tmpMod = mod_{p}';
            %Feature extraction is performed below such that the mean,
            %maximum, and variance of the features selected above are
            %calculated
            tra_ = [tra_; max(tmpMod) mean(tmpMod) var(tmpMod)];
            featuresLabTrAll = [featuresLabTrAll; orderInt(testIter)];
        end
        
        featuresTr = [tra_];
        
        featuresTrAll = [featuresTrAll; {featuresTr}];
       
        testT = test_{testIter};

        testT = testT';
        
        %The same feature extraction method is performed for the test song
        %excerpts
        featuresTest = [ max(testT) mean(testT) var(testT)];
        

        featuresTestAll = [featuresTestAll; {featuresTest}];
        
        testIter = testIter + 1;
    end
    

    
    
    
    
    
    train_label = featuresLabTrAll;
    train_data = cell2mat(featuresTrAll);

    
    %The below built-in function provided by the libsvm library trains
    %a model through the data collected by the application "Accelerometere Monitor".
   
    % Below are the options for the SVM method
    
    %-t 3: sigmoid function
    
    %-t 2: radial basis
    
    %-t 1: polynomial (default degree is 3)
    
    %-t 0: linear
    model_linear = svmtrain(train_label, train_data, '-t 1');
    
    
    for w = 1:length(featuresTestAll)
        
        test_label = [orderInt(w)];
        test_data = featuresTestAll{w};
        
        %The below built-in function detects the labels, and accuracy
        %percentage, where the test data and labels to be classified are inputs.
        [predict_label_L, accuracy_L, dec_values_L] = svmpredict(test_label, test_data, model_linear);
        
        avgSucc = avgSucc + accuracy_L(1);
        
        testGenre = order(w);
        testGenre = testGenre{1};
        predictedGenre = order(predict_label_L);
        predictedGenre = predictedGenre{1};
        if accuracy_L(1) ~= 100
            
            RESULTS{resind} = ['FALSE - Test genre: ', testGenre, ', Predicted genre: ', predictedGenre];
        else
            
            RESULTS{resind} = ['TRUE - Test genre: ', testGenre, ', Predicted genre: ', predictedGenre];
        end
        resind = resind + 1;
    end
    RESULTS{resind} = '_______________';
    resind = resind + 1;
end

clc

fprintf('SVM results:\n\n');

for i = 1:length(RESULTS)
    fprintf('%s\n', RESULTS{i});
end
%Success rate gets printed
fprintf('\n\nOverall success rate: %0.2f%%\n', avgSucc / (cv_.NumTestSets * length(order)));


