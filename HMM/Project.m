%Cem Rifki Aydin 2013800054
%SPEECH PROCESSING PROJECT

%In this project, hidden Markov model (HMM) algorithm through the use of
%expectation-mazimization process is benefited from for recognizing some
%isolated words. After training some audio samples of words, test data 
%spoken by different users are fed into models built through HMM, and
%success rate is seen to be high.

%Below, feature extraction process is benefited from. Features are
%considered formants of the audio2 samples in this case.

% Read the data back into MATLAB, and listen to audio. 

clc
clear




%We read the files in the 'audio2' folder
subDir = dir('audio2');

subDirInd = [subDir.isdir];

subDir_ = {subDir(subDirInd).name};
ind = ~ismember(subDir_, {'.', '..'});


testDataAll = [];

cntFile = 1;


wordLabels = [];


formantFreqAll = [];

%All files in the subdirectories of the directory 'audio2' are scanned
for direc = find(ind)
    newDir = fullfile('audio2', subDir_{direc});
    allFiles = dir(newDir);
    
    x = newDir;
    fileN = {};
    for file = allFiles';
        
        if strcmp(file.name, '.') == 0 && strcmp(file.name, '..') == 0
            fileN = [fileN; char(strcat(strcat('audio2\', strcat(subDir_{direc}, '\')), char(file.name)))];
        end
        
    end
    
    allData = cellstr(fileN);
    
    for u = 1:length(allData)

        fileSnd = allData(u);
        
        
        fileSnd = char(fileSnd);

        clear y Fs
        [y, Fs, nbits, readinfo] = wavread(fileSnd); 
        sound(y, Fs); 

        %Below code helps plot the spectogram
        y = y(:, 1);
        len = 100; 
        noverlap = 90; 
        NFFT = 128; 
        [y_,freq,time,p] = spectrogram(y,len,noverlap,NFFT,Fs); 
        surf(time,freq,10*log10(abs(p)),'EdgeColor','none'); 
        axis xy; axis tight; colormap(jet); view(0,90); 
        xlabel('Time'); 
        ylabel('Frequency (in terms of Hz)');
        
        
        tSpl = 1/Fs; 

        incr = 0.003;
        dimNo = 3;
        maxi = max(time);

        frek = ones(dimNo, ceil((maxi-0.001)/incr));

        cnter = 1;
        
        formantFile = [];
        %Below we iterate through frames in the audio file speeches
        for k = 0.001:incr:maxi
            if k == 0.001
                stInd = 1;
                endInd = ceil(maxi/tSpl); 
            elseif k+incr > maxi
                stInd = ceil(k/tSpl);
                endInd = ceil(maxi/tSpl); 
            else
                stInd = ceil(k/tSpl);
                endInd = ceil((k+incr)/tSpl); 
            end

            vals = y(stInd:endInd);

            %Hamming window is implemented below
            x1 = vals.*hamming(length(vals)); 
            preemph = [1 0.62]; 
            x1 = filter(1,preemph,x1);
            cnt_ = sum(x1 == 0);
            if cnt_ >= length(x1) / 2 || length(x1) < 8
                continue;
            end
           
            %LPC coefficients are found below
            A = lpc(x1, 8);

            roots_ = roots(A);
            roots_ = roots_(imag(roots_)>=0);
            angz = atan2(imag(roots_),real(roots_)); 
            [freqs, index] = sort(angz.*(Fs / (2*pi))); 
            bw = -1/2*(Fs/(2*pi))*log(abs(roots_(index))); 
            i = 1; 
            [c3, ind] = max(size(freqs));

            length(freqs);

            %The top three formant frequencies are determined below
            for j = 1:c3 
                if (freqs(j) > 90 && bw(j) < 400)
                    formantVals(i) = freqs(j); 
                    i = i + 1; 

                end
                
            end 
            formantVals = sort(formantVals, 'descend');
            formantVals = formantVals(1:3);

            formantVals';
            frek(:,cnter) = formantVals';
            cnter = cnter+1;

            formantFile = [formantFile, formantVals'];
        end
        
        formantFreqAll = [formantFreqAll {formantFile}]
        wordLabels = [wordLabels {subDir_{direc}}];
    end
    
    
end



%Unique word labels are determined
order = unique(wordLabels);
coef = length(wordLabels) / length(order);
length(wordLabels);
%Below built-in function helps utilizing cross-validation method, it is
%10-fold
cv_ = cvpartition(wordLabels, 'k', 10);



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
    for k = 1:9:length(wordLabels) - length(test_)
        
        tra_ = [];
        for p = k:k + 8
            
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

