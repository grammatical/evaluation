Human Evaluation of Grammatical Error Correction Systems
---

Data and scripts for our 
[upcoming paper](http://emjotde.github.io/publications/pdf/mjd.emnlp2015.draft.pdf):

    @inproceedings{grundkiewicz_emnlp_2015,
      author = {Roman Grundkiewicz and Marcin Junczys-Dowmunt and Edward Gillian},
      title = {Human Evaluation of Grammatical Error Correction Systems},
      booktitle = {Proceedings of the Conference on Empirical Methods in Natural Language Processing},
      publisher = {Association for Computational Linguistics},
      note = {Accepted for publication},
      year = {2015},
      url = {http://emjotde.github.io/publications/pdf/mjd.emnlp2015.draft.pdf},
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

Ranks with multiple systems have been collapsed if the system output was the same. The attribute `src-id` references the position of the judged sentence in a system output. The system names correspondsto the filenames in `data/original/official_submissions` which contains the original system outputs.

The tables presented in our paper can be generated using

    cd data
    make -j 8

Since TrueSkill bootstrapping takes a couple of hours you need to invoke it separately:

    make -j 8 trueskill

The generated files `data/EW.txt` and optionally `data/TS.txt` contain the final rankings presented in the paper.

Requirements
---

For some of the tables to correctly be generated you will need to install R and the perl package Statistics::R, on Ubuntu you can do:

    sudo apt-get install r-base r-base-dev
    sudo perl -MCPAN -e shell
    > install Statistics::R

For TrueSkill you will also need the trueskill python module:

    How did I install that?


