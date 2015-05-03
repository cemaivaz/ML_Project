%Cem Rifki Aydin 2013800054

%In this project, hidden Markov model (HMM) algorithm through the use of
%expectation-mazimization process is benefited from for recognizing some
%isolated words. After training some audio samples of words, test data 
%spoken by different users are fed into models built through HMM, and
%success rate is seen to be high.

%Below, feature extraction process is benefited from. Features are
%considered formants of the data samples in this case.

% Read the data back into MATLAB, and listen to audio. 

clc
clear




%We read the files in the 'data' folder
subDir = dir('data');

subDirInd = [subDir.isdir];

subDir_ = {subDir(subDirInd).name};
ind = ~ismember(subDir_, {'.', '..'});


testDataAll = [];

cntFile = 1;


wordLabels = [];


formantFreqAll = [];

%All files in the subdirectories of the directory 'data' are scanned
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
        
        valz_ = dlmread(char(strcat(strcat('data\', strcat(subDir_{direc}, '\')), strcat(f_(1:end-6), '.ent12'))), ',')' ;
        valz_(isnan(valz_)) = 0;
        
        %spectrCentr, spectrRolloff, spectrEntropy, timbre.Zerocross,
        %timbre.lowEnergy, spectr.mfcc(13), meanTempo, maxTempo
        valz_ = valz_(1:10, [1:5, 6:9, 19:20]);
        formantFreqAll =  [formantFreqAll {valz_}];
        wordLabels = [wordLabels {subDir_{direc}}];
    end
    
    
end



%Unique word labels are determined
order = unique(wordLabels);
coef = length(wordLabels) / length(order);
length(wordLabels);
%Below built-in function helps utilizing cross-validation method, it is
%10-fold
kfold = 6;
cv_ = cvpartition(wordLabels, 'k', kfold);



cnterAll = length(wordLabels);
cnterSucc = 0;

%We below iterate through the sets created through cross-validation
for j = 1:cv_.NumTestSets
    
    trDat = cv_.training(j);
    testDat = cv_.test(j);
    orderNo = 1;
    
    words_ = [];
    wordsTest_ = [];
    iter = 1;
    testIter = 1;
    
    mod_ = formantFreqAll(trDat == 1);
       
    test_ = formantFreqAll(trDat == 0);
        
    %Below iteration assumes that each one file of ten for each different
    %label is chosen as test sample while others are training data
    for k = 1:kfold - 1:length(wordLabels) - length(test_)
        
        tra_ = [];
        for p = k:k + kfold - 2
            
            tra_ = [tra_ mod_{p}];
        end
        
        new_funcs = funcs(order(orderNo));
        new_funcs.process(tra_);
        orderNo = orderNo + 1;
        words_ = [words_, new_funcs];
        wordsTest_ = [wordsTest_ {test_{testIter}}];
        testIter = testIter + 1;
    end
    
    cntTr = 1;
    
    for wordTest = wordsTest_
        likelihoodVal = -Inf;

        predictedWord = '';

        wordTest_ = wordTest{1};
        for word = words_
            
            wordLike_ = word.likelihoodLog(wordTest_);
        
             
            %Below comment should be uncommented to see the log-likelihoods
            %fprintf('Word %s compared with %s, likelihood: %0.2f\n', char(order(cntTr)), char(word.nm), wordLike_);
            
            
            %Below we try finding the maximum likelihood value. Whichever
            %training word has this value, its label is determined as the
            %predicted word
            if wordLike_ > likelihoodVal
                likelihoodVal = wordLike_;
                predictedWord = word.nm;
            end
        end
        
        %If the label of both of the test word and the predicted are same,
        %it contributes to the success rate
        if  strcmp(order(cntTr), predictedWord)
            cnterSucc = cnterSucc + 1;
            fprintf('True - Test word: %s, Predicted word: %s\n', char(order(cntTr)), char(predictedWord));
        else
            fprintf('False - Test word: %s, Predicted word: %s\n', char(order(cntTr)), char(predictedWord));
        end
        
        cntTr = cntTr + 1;
    end
    
    display('-----------------');
end 

%Success rate is printed as follows
fprintf('Success rate: %0.2f%%\n', (cnterSucc / cnterAll) * 100);

