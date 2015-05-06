%Machine Listening Project
%Cem Rifki Aydin 2013800054


%In this file, the features extracted thanks to the use of MIRToolBox are
%used as continuous inputs for HMM algorithm


clc
clear




%% WARNING!
%
%%


%We read the files in the 'data' folder

subDir = dir('data');

subDirInd = [subDir.isdir];

subDir_ = {subDir(subDirInd).name};
ind = ~ismember(subDir_, {'.', '..'});


testDataAll = [];

cntFile = 1;


genreLabels = [];


features_ = [];

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
        
        valz_ = valz_(1:11, [1:5, 6:9, 19:20]);
       
        features_ =  [features_ {valz_}];
        genreLabels = [genreLabels {subDir_{direc}}];
    end
    
    
end



%Unique genre labels are determined
order = unique(genreLabels);
coef = length(genreLabels) / length(order);
length(genreLabels);
%The below variable stores the information for the number of sets to be
%used in cross-validation
kfold = 6;

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
        
    %Below iteration assumes that each one file of ten for each different
    %label is chosen as test sample while others are training data
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
        
             
            %Below comment should be uncommented to see the log-likelihoods
            %fprintf('Word %s compared with %s, likelihood: %0.2f\n', char(order(cntTr)), char(genre.nm), genreLike_);
            
            
            %Below we try finding the maximum likelihood value. Whichever
            %training genre has this value, its label is determined as the
            %predicted genre
            if genreLike_ > likelihoodVal
                likelihoodVal = genreLike_;
                predictedGenre = genre.nm;
            end
        end
        
        %If the label of both of the test genre and the predicted are same,
        %it contributes to the success rate
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

