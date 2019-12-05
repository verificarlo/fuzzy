# -*- coding: utf-8 -*-
"""
Created on Wed Dec  4 11:54:21 2019

@author: rhann
"""

#Goal 1:

#Write a script in Python/Java (other other programming language of interest) that a) tries to find the issue we showed in that notebook above
#Add a bit to your script that runs this expression a few (~100) times, and prints the result each time
#Finally, add a piece that averages the results and prints the aggregate

#Goal 2:

#Get access to a system that has Docker installed (I will look for these for you, as well)
#Run your script in the Docker container and look at if the results are different from the "healthy" environment 

import numpy as np

def first_function(N):
    step_one = 1/N
    step_two = sum([step_one for _ in range(N)])
    
    return step_two

def second_function(N, B):
    for _ in range(B):
        M = N ** 0.5
        N = M ** 2
    
    return N

def u(K):
    if K == 0:
        return 2
    elif K ==1:
        return -4
    else: 
        uminus1 = u(K - 1)
        uminus2 = u(K - 2)
        return 111 - (1130/uminus1) + 3000/(uminus1 * uminus2)
    

def X(N):
    if N == 0:
        return 1.5100050721319
    else:
        xminus1 = X(N-1)
        return ((3*xminus1**4) - (20*xminus1**3) + (35*xminus1**2) - 24)/((4*xminus1**3) - (30*xminus1**2) + (70*xminus1 - 50 ))

    

def run_x_times(function, x, *args):
    result = []
    for _ in range (x):
        result += [function(*args)]
        sumresult = sum(result)/x
    return sumresult, np.mean(sumresult), np.std(sumresult)

#for every value of k up to 30:
#run u(k) ~ 100 times
#compute std and mean
#print k, mean, and std to screen
for _ in range(10):
    print(run_x_times(u, 100, _))

#print(run_x_times(third_function, 100000, 100000))
#print(X(30))
#print(u(30))