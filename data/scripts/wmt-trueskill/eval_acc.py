#!/usr/bin/env python
#encoding: utf-8

import sys
import os    
import numpy as np
import math
import argparse
import csv
from itertools import combinations
from collections import defaultdict
from sklearn.metrics import accuracy_score
import scripts.pref_prob

arg_parser = argparse.ArgumentParser()
arg_parser.add_argument('-d', action='store', dest='d', type=float,
        help='draw range parameter', required=True)
arg_parser.add_argument('-i', action='store', dest='filepath',
        help='system means (*.mu_sigma.json)', required=True)
args = arg_parser.parse_args()

if __name__ == '__main__':
    # score file
    f = open(args.filepath, 'r')
    sys_mu_sigma = json.load(f)
    gold = []
    maxAcc = [0.0, 0]
    acc_all = []

    prediction = []

    for i, (sys1, sys2, ops) in enumerate(csv.reader(sys.stdin, delimiter='\t')):
        if i % 10000 == 0:
            sys.stderr.write("%s\n" % i) 
        
        comparison = 1;
        if ops == "<":
            comparison = 0
        elif ops == ">":
            comparison = 2
            
        try:
            # mu and sigma from training
            sys1_mu = sys_mu_sigma[sys1][0]
            sys2_mu = sys_mu_sigma[sys2][0]
            sys1_sigma = sys_mu_sigma[sys1][1]
            sys2_sigma = sys_mu_sigma[sys2][1]
            if sys1_mu > sys2_mu:
                win, draw, lost = scripts.pref_prob.compute_pref(sys1_mu, sys2_mu, sys1_sigma, sys2_sigma, args.d)
                a = [win, draw, lost]
                prediction.append(a.index(max(a)))
            else:
                win, draw, lost = scripts.pref_prob.compute_pref(sys2_mu, sys1_mu, sys2_sigma, sys1_sigma, args.d)
                a = [lost, draw, win]   # because using sys1 perspevtive
                prediction.append(a.index(max(a)))
    
            # add gold (oracle comparison)
            gold.append(comparison)
    
        except KeyError:
            ## avoid error which is derived by training data from researchers
            ## (no online-A ranking at all)
            pass

    acc = accuracy_score(np.array(gold), np.array(prediction))
    print acc

