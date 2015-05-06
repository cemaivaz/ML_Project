classdef HMM_ < handle

    
    %HMM has those properties as follows:
    properties
        nm = ''; %It stands for the name (label) of a movement
        pri; %It stands for the prior probabilities of states
        m; %It stands for the mean values
        cov; %It stands for the covariance matrix
        A; %It stands for the state transition probabilities
        StN = 3; %It stands for the number of states
        
    end
    
    %Methods of this class are as follows:
    methods
        
        %Constructor
        function self = HMM_(nm)
            self.nm = nm;
        end
        
        %The below function creates a Gaussian mixture, taking account of the given observation
        %samples values
        function gauss = mvndistr(self, samples)
            gauss = ones(self.StN, length(samples));
            i = 1;
            
            %For each state, a different distribution is created
            while i <= self.StN
                gauss(i, :) = mvnpdf(samples', self.m(:, i)', self.cov(:, :, i));
              
                i = i + 1;
            end
        end
        
        %Backward method is as follows
        function beta = backw(self, samples, gauss)
            lim = length(samples); 
            beta = ones(self.StN, lim);
            
            beta(:, lim) = ones(self.StN, 1);
            
            i = lim - 1;
            %It goes backward in time (dimension)
            while i >= 1
                
                beta(:, i) = self.A * (gauss(:, i + 1) .* beta(:, i + 1));
                
                beta(:, i) = beta(:, i) ./ sum(beta(:, i));
                
                i = i - 1;
            end
        end
        
        %Below is defined the forward algorithm
        function [likelihoodLog, alpha] = forw(self, samples, gauss)
            lim = length(samples);
            likelihoodLog = 0;
            alpha = ones(self.StN, lim);
            
            i = 1;
            %It goes forward in time (dimension)
            while i <= lim
                if i ~= 1
                    alpha(:, i) = (self.A' * alpha(:, i - 1)) .* self.pri;
                    
                else
                    alpha(:, i) = self.pri .* gauss(:, i);
                end
                %Likelihood calculated below determines how similar
                %two movement data are to one another
                likelihoodLog = likelihoodLog + log(sum(alpha(:, i)));
                alpha(:, i) = alpha(:, i) ./ sum(alpha(:, i));
                i = i + 1;
            end
            
            
        end
        %The below function calculates the similarity between two movement
        %data, be it pertaining to the same, or different action group
        function likelihoodLog = likelihoodLog(self, samples)
            likelihoodLog = forw(self, samples, self.mvndistr(samples));
        end
        %Below is the main function implementing HMM that invokes other
        %methods
        function process(self, samples)
            
            %Below, prior and initial transition probabilities are randomly
            %assigned some values such that the sum of each row equals 1
            matr = rand(self.StN, 1);
            self.pri = matr ./ repmat(sum(matr,1), size(matr, 1), 1);
            matr = rand(self.StN, self.StN);
            self.A = matr ./ repmat(sum(matr, 2), 1, size(matr, 2));
            
            
            
            i = 1;
            
            initM = [];
            
            %Below, some random observation samples are defined as the mean
            %values of Gaussian mixtures
            while i < 100000000 %It could be the value Inf as well
                
                numb = rand(1, 1) * length(samples);
                
                if ismember(ceil(numb), initM) == 0
                   initM = [initM; ceil(numb)]; 
                else
                    continue;
                end
                
                if length(initM) == self.StN
                    break;
                end
                i = i + 1;
            end
           
            self.m = samples(:, initM);
            
            
            %Covariance values are determined as follows
            covar = diag(diag(cov(samples')));
            no = self.StN;
            self.cov = repmat(covar, [1 1 no]);
            
            %The EM iteration number value stated below can be chosen as
            %any, in this case we assigned it the value 10
            iterateNo = 10;
            
            for j = 1:1:iterateNo
                B = self.mvndistr(samples);
                lengthSam = length(samples);
                dim = size(samples, 1);
                
                gamma = zeros(self.StN, lengthSam);
                xiS = zeros(self.StN, self.StN);
                
                beta = self.backw(samples, B);
                [likelihoodLog, alpha] = self.forw(samples, B);
                
                w = 1;
                
                %Below, ksi and gamma values are calculated since they are
                %to be used by the Baum-Welch algorithm
                while w <= (lengthSam - 1)
                   
                    matr = (self.A .* (alpha(:, w) * (beta(:, w + 1) .* B(:, w + 1))'));
                    
                    matr = matr ./ repmat(sum(matr,1), size(matr, 1), 1);
                    xiS = xiS + matr;
                   
                    matr2 = (alpha(:, w) .* beta(:, w));
                    gamma(:, w) = matr2 ./ repmat(sum(matr2, 1), size(matr2, 1), 1);
                  
                    w = w + 1;
                end
                
                matr = alpha(:, lengthSam) .* beta(:, lengthSam);
                gamma(:, lengthSam) = matr ./ repmat(sum(matr,1), size(matr, 1), 1);
                
                new_A = xiS ./ repmat(sum(xiS, 2), 1, size(xiS, 2));
                new_Prior = gamma(:, 1);
                
                gamma_Sum = sum(gamma, 2);
                
                new_Cov = ones(dim, dim, self.StN);
                new_m = ones(dim, self.StN);
                
                gamma_Sum = (gamma_Sum == 0) + gamma_Sum;
                
                k = 1;
                
                %Iteration is performed n times, where the value "n" denotes the state number
                %This is required to update HMM parameters
                while k <= self.StN
                
                    samplesUpd = samples .* repmat(gamma(k, :), [dim 1]);
                    new_m(:, k) = sum(samplesUpd, 2) / gamma_Sum(k);
                    
                    matr = samplesUpd * samples' / gamma_Sum(k) - ...
                                                     new_m(:, k) * new_m(:, k)';
                    
                    new_Cov(:, :, k) = triu(matr)' + triu(matr) - diag(diag(matr));                             
                    k = k + 1;
                end
                
                new_Cov = repmat(eye(dim, dim) * 0.01, [1 1 self.StN]) + new_Cov; 
                
                %HMM parameters are updated by the values that are found
                %through EM
                self.A = new_A;
                self.pri = new_Prior;
                self.cov = new_Cov;
                self.m = new_m;
                
            end
        end
        
    end
    
end