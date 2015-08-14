#!/usr/bin/env python
#encoding: utf-8
"""
Takes a ranking file with text-based clusters and computes the accuracy on a dataset.
"""

__author__ = "Matt Post"

import sys
import os
import json
import random
import csv
from operator import itemgetter, attrgetter, methodcaller

from collections import defaultdict
from itertools import combinations
import argparse

arg_parser = argparse.ArgumentParser()
arg_parser.add_argument('ranking', help='file containing (clustered) system ranking')
arg_parser.add_argument('-d', action='store', dest='d', type=float,
        help='draw range parameter', required=True)
arg_parser.add_argument('-m', action='store', dest='m', type=float,
        help='minimum number of clusters', default=3)
args = arg_parser.parse_args()

def get_prediction(ranking, s1, s2):
    """Returns one of {<, =, >} depending on whether s1 is better than, equivalent to, or worse than
    s2.  ranking is a list of systems sorted from best to worst.
    """
    for rank_tier in ranking:
        for system in rank_tier:
            if system == s1:
                if s2 in rank_tier:
                    return '='
                else:
                    return '<'
            elif system == s2:
                if s1 in rank_tier:
                    return '='
                else:
                    return '>'

    raise RuntimeError


def accuracy(csv_fh, ranking):
    win_dict = defaultdict(int)

    num_correct = 0
    num_total = 0
    answer_key = {}
    for s1, s2, obs in csv.reader(sys.stdin, delimiter='\t'):
        if not answer_key.has_key((s1,s2)):
            answer_key[(s1,s2)] = get_prediction(ranking, s1, s2)

        num_total += 1
        if obs == answer_key[(s1,s2)]:
            num_correct += 1

    return 1.0 * num_correct / num_total

def read_ranking(filename, d=0, m=3):
    """Reads a list of ranked systems from a file, best to worst"""

    sys_mu_sigma = json.load(open(filename))
    del sys_mu_sigma["data_points"]
    sys_list = [(sys, sys_mu_sigma[sys][0]) for sys in sys_mu_sigma]
    sys_list.sort(key=itemgetter(1))
    sys_list.reverse()

    rankings = []
    lastmean = 100
    for sysPair in sys_list:
        
        sys, mean = sysPair
        if(lastmean - mean > d):
            rankings.append([])
        rankings[-1].append(sys)
        lastmean = mean

    if len(rankings) < m:
        rankings = [ [sys] for sys, mean in sys_list ]
    return rankings

if __name__ == '__main__':
    # ExpectedWin
    print '%.5f' % accuracy(sys.stdin, read_ranking(args.ranking, args.d, args.m))

