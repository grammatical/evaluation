Human Evaluation of Grammatical Error Correction Systems
---

Data and scripts for our 
[EMNLP paper](http://aclweb.org/anthology/D15-1052):

    @inproceedings{grundkiewicz-junczysdowmunt-gillian:2015:EMNLP,
      author = {Grundkiewicz, Roman  and  Junczys-Dowmunt, Marcin  and  Gillian, Edward},
      title = {Human Evaluation of Grammatical Error Correction Systems},
      booktitle = {Proceedings of the 2015 Conference on Empirical Methods in Natural Language Processing},
      month = {September},
      year = {2015},
      address = {Lisbon, Portugal},
      publisher = {Association for Computational Linguistics},
      pages = {461--470},
      url = {http://aclweb.org/anthology/D15-1052},
    }

Reproducing our results
---

The ranking data is contained in `data/judgments.xml`. Rankings look like this:

    <ranking-item doc-id="10000.0.txt-321" duration="00:00:41.916000" id="321" src-id="307" user="annotator01">
      <translation rank="4" system="CAMB"/>
      <translation rank="4" system="POST"/>
      <translation rank="2" system="RAC SJTU"/>
      <translation rank="3" system="UMC"/>
      <translation rank="5" system="AMU CUUI IITB INPUT IPN UFC"/>
    </ranking-item>
  
    <ranking-item doc-id="10000.0.txt-324" duration="00:00:34.165000" id="324" src-id="98" user="annotator01">
      <translation rank="2" system="CAMB"/>
      <translation rank="5" system="POST"/>
      <translation rank="5" system="AMU IITB INPUT IPN RAC SJTU UFC UMC"/>
      <translation rank="5" system="CUUI PKU"/>
      <translation rank="5" system="NTHU"/>
    </ranking-item>

Ranks with multiple systems have been collapsed if the system output was the same. The attribute `src-id` references the position of the judged sentence in a system output. The system names correspond to the filenames in `data/original/official_submissions` which contains the original system outputs.

The tables presented in our paper can be generated using

    cd data
    make -j 8

Since TrueSkill bootstrapping takes a couple of hours you need to invoke it separately (see requirements below):

    make -j 8 trueskill

The generated files `data/EW.ranking.txt` and optionally `data/TS.ranking.txt` contain the final rankings presented in the paper. A couple more latex tables will be placed into `data/includes` they should contain the same numbers as reported in the paper. See `data/Makefile` for details how to run the scripts.

To compare ExpectedWins and TrueSkill ranking accuracy (may take ages due to running 100 folds with 100 rankings each for both ranking methods) use:

    make accuracy.bootstrap

Requirements
---

To generate the ExpectedWins head2head table you will need to install R and the perl package Statistics::R. On Ubuntu you can do:

    sudo apt-get install r-base r-base-dev
    sudo perl -MCPAN -e shell
    > install Statistics::R

For TrueSkill you will also need the trueskill python module:

    sudo pip install trueskill

Code in the `data/scripts/trueskill` folder has been adapted from Keisuke Sakaguchi's repository https://github.com/keisks/wmt-trueskill
