

clear
clc
format long
make
mex -setup

%We scan the files in the 'audio' folder
subDir = dir('audio');

addpath('C:\Program Files\MATLAB\R2014a\toolbox\somtoolbox')
addpath('C:\Program Files\MATLAB\R2014a\toolbox\netlab')
addpath('C:\Program Files\MATLAB\R2014a\toolbox\MIRToolboxDemos')
addpath('C:\Program Files\MATLAB\R2014a\toolbox\MIRToolbox')
addpath('C:\Program Files\MATLAB\R2014a\toolbox\AuditoryToolbox')

subDirInd = [subDir.isdir];

subDir_ = {subDir(subDirInd).name};
ind = ~ismember(subDir_, {'.', '..'});


testDataAll = [];
movementLabels = [];


valsAll = [];

%All the files in the subdirectories of the folder 'audio' are scanned
for direc = find(ind)
    newDir = fullfile('audio', subDir_{direc});
    allFiles = dir(newDir);
    
    x = newDir;
    fileN = {};
    
    fileNames = [];
    for file = allFiles';
        
        if strcmp(file.name, '.') == 0 && strcmp(file.name, '..') == 0
            fileNames = [fileNames; {file.name}];
            fileN = [fileN; char(strcat(strcat('audio\', strcat(subDir_{direc}, '\')), char(file.name)))];
        end
        
    end
    
    allData = cellstr(fileN);
    
    for u = 1:length(allData)
        
        
        fileMv = allData(u);
        fileMv = char(fileMv)
        
        
        f_ = char(fileNames(u));
        %         feat_ = mirfeatures(fileMv);
        %         d = mirgetdata(feat_);
        
        
        
        %         vals_ = [d.spectral.centroid(1:2)];
        %         vals_ = [vals_ d.spectral.rolloff95(1:2)];
        %         vals_ = [vals_ d.timbre.spectralflux(1:2)];
        %
        %         vals_ = [vals_ d.timbre.zerocross(1:2)];
        %         vals_ = [vals_ d.timbre.lowenergy];
        %         mfcc_ = d.spectral.mfcc;
        %         mfcc_ = mfcc_(2:6, 1:2);
        %         mfcc_ = mfcc_';
        %         tmpMfcc = [mfcc_(1, :) mfcc_(2,:)];
        %         mfcc_ = tmpMfcc;
        %
        %         vals_ = [vals_ mfcc_];
        %         vals_ = [vals_ mean(d.rhythm.tempo) max(d.rhythm.tempo)];
        
        
        %%
        %         vals_ = [d.spectral.centroid'];
        %         vals_ = [vals_ d.spectral.spectentropy'];
        %         mfcc_ = d.spectral.mfcc';
        %
        %         vals_ = [vals_ mfcc_(:, 1:3)];
        %         vals_ = [vals_ d.timbre.zerocross'];
        %         vals_ = [vals_ d.spectral.spread'];
        %         vals_ = [vals_ repmat(max(d.rhythm.tempo), size(vals_, 1), 1) repmat(var(d.rhythm.tempo), size(vals_, 1), 1) repmat(mean(d.rhythm.tempo), size(vals_, 1), 1)];
        
        
        %%
        
        %         vals_ = [d.spectral.centroid'];
        %         vals_ = [vals_ d.spectral.rolloff95'];
        %         vals_ = [vals_ [d.spectral.spectentropy']];
        %
        %         vals_ = [vals_ d.timbre.zerocross'];
        %         vals_ = [vals_ repmat(d.timbre.lowenergy, size(vals_, 1), 1)];
        %
        %         vals_ = [vals_ d.spectral.mfcc'];
        %         vals_ = [vals_ repmat(mean(d.rhythm.tempo), size(vals_, 1), 1) repmat(max(d.rhythm.tempo), size(vals_, 1), 1)];
        
        
        %spectrCentr, spectrRolloff, spectrEntropy, timbre.Zerocross,
        %timbre.lowEnergy, spectr.mfcc(13), meanTempo, maxTempo
        f_ = char(fileNames(u));
        
        if strcmp(strcat(char(subDir_{direc})), 'rap')
            
            feat_ = mirfeatures(fileMv);
            d = mirgetdata(feat_);
        
            
            vals_ = [d.spectral.centroid'];
            vals_ = [vals_ d.spectral.rolloff95'];
            vals_ = [vals_ [d.spectral.spectentropy']];
            
            vals_ = [vals_ d.timbre.zerocross'];
            vals_ = [vals_ repmat(d.timbre.lowenergy, size(vals_, 1), 1)];
            
            vals_ = [vals_ d.spectral.mfcc'];
            vals_ = [vals_ repmat(mean(d.rhythm.tempo), size(vals_, 1), 1) repmat(max(d.rhythm.tempo), size(vals_, 1), 1)];
            
            
            dlmwrite(char(strcat(strcat('data\', strcat(subDir_{direc}, '\')), strcat(f_(1:end-4), '.ent12'))), vals_);

        end
        
        %vals_ = dlmread(char(strcat(strcat('audio\', strcat(subDir_{direc}, '\')), strcat(f_(1:end-6), '.ent12'))), ',')' ;
        
        %dlmwrite(char(strcat(strcat('audio\', strcat(subDir_{direc}, '\')), strcat(f_(1:end-4), '.ent12'))), vals_);
    end
end




