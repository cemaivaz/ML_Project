%"WEARABLE COMPUTING" PROJECT - Team 11, 13/12/2014
%DEVELOPING EXOSKELETON SYSTEM FOR THE MOBILITY-IMPAIRED
%Ali Ozcan, Bugra Oral, Erdem Emekligil, Onur Satici, Cem Rifki Aydin

%PART 3 - Implementation of SVM (radial basis)

%Below is the source code written for the exoskeleton system - recognition of different
%arm movements.

clear
make 
mex -setup

%We scan the files in the 'movements' folder
subDir = dir('movements');

subDirInd = [subDir.isdir];

subDir_ = {subDir(subDirInd).name};
ind = ~ismember(subDir_, {'.', '..'});


testDataAll = [];
movementLabels = [];


valsAll = [];

%All the files in the subdirectories of the folder 'movements' are scanned
for direc = find(ind)
    newDir = fullfile('movements', subDir_{direc});
    allFiles = dir(newDir);
    
    x = newDir;
    fileN = {};
    for file = allFiles';
        
        if strcmp(file.name, '.') == 0 && strcmp(file.name, '..') == 0
            fileN = [fileN; char(strcat(strcat('movements\', strcat(subDir_{direc}, '\')), char(file.name)))];
        end
        
    end
    
    allData = cellstr(fileN);
    
    for u = 1:length(allData)
        
        
        fileMv = allData(u);
        fileMv = char(fileMv);
        
        vals_ = dlmread(fileMv, ' ', 0, 0);
        valsAll = [valsAll; {vals_}];
        
        movementLabels = [movementLabels; {subDir_{direc}}];
    end
end




%Unique movement labels are determined
order = unique(movementLabels);
coef = length(movementLabels) / length(order);
length(movementLabels);

foldNo = 6;
%The below built-in function helps us leverage the cross-validation method,
%where the "k" (fold) value in this case is 10
cv_ = cvpartition(movementLabels, 'k', foldNo);



cnterAll = length(movementLabels);
cnterSucc = 0;

avgSucc = 0;

orderInt = 1:length(unique(movementLabels));

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
    
    %Features to be extracted are determined as the mean, maximum, and
    %variance values of the training data of a whole movement class
    featuresTrAll = [];
    featuresTestAll = [];
    
    featuresLabTrAll = [];
    
    %The below iteration is performed as to divide the data into the test
    %and training ones, whereby one tenth of the files in a movement folder
    %is chosen as the test data, being repeated 10 times.
    for k = 1:foldNo - 1:length(movementLabels) - length(test_)
        
        tra_ = [];
        for p = k:k + foldNo - 2
            tra_ = [tra_; mod_{p}];
        end
        
        
        featuresTr = [mean(tra_(:, 1:3)) var(tra_(:, 1:3)) max(tra_(:, 1:3))];
        featuresTrAll = [featuresTrAll; {featuresTr}];
        
        featuresLabTrAll = [featuresLabTrAll; orderInt(testIter)];
        
        testT = test_{testIter};
        testT = testT(:, 1:3);
        featuresTest = [mean(testT) var(testT) max(testT)];
        featuresTestAll = [featuresTestAll; {featuresTest}];
        
        testIter = testIter + 1;
    end
    
    % Below are the options for the SVM method
    
    %-t 3: sigmoid function
    
    %-t 2: radial basis
    
    %-t 1: polynomial (default degree is 3)
    
    %-t 0: linear
    
    
    
    
    
    train_label = featuresLabTrAll;
    train_data = cell2mat(featuresTrAll);
    
    
    
    for w = 1:length(featuresTestAll)
        
        test_label = [orderInt(w)];
        test_data = featuresTestAll{w};
        
        %The below built-in function provided by the libsvm library trains
        %a model through the data collected by the application "Accelerometere Monitor".
        model_linear = svmtrain(train_label, train_data, '-t 2');
        
        %The below built-in function detects the labels, and accuracy
        %percentage, where the test data and labels to be classified are inputs.
        [predict_label_L, accuracy_L, dec_values_L] = svmpredict(test_label, test_data, model_linear);
        
        avgSucc = avgSucc + accuracy_L(1);
        
        testWord = order(w);
        testWord = testWord{1};
        predictedWord = order(predict_label_L);
        predictedWord = predictedWord{1};
        if accuracy_L(1) ~= 100
            
            RESULTS{resind} = ['FALSE - Test movement: ', testWord, ', Predicted movement: ', predictedWord];
        else
            
            RESULTS{resind} = ['TRUE - Test movement: ', testWord, ', Predicted movement: ', predictedWord];
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


