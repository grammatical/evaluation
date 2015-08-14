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

from collections import defaultdict
from itertools import combinations
import argparse

arg_parser = argparse.ArgumentParser()
arg_parser.add_argument('ranking', help='file containing (clustered) system ranking')
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

def read_ranking(filename):
    """Reads a list of ranked systems from a file, best to worst"""

    rankings = [[]]
    for line in open(filename):
        if line.startswith('+++'):
            rankings.append([])
            continue

        system, mean, rest = line.split(' ', 2)

        rankings[-1].append(system)

    return rankings

if __name__ == '__main__':
    # ExpectedWin
    print '%.5f' % accuracy(sys.stdin, read_ranking(args.ranking))

