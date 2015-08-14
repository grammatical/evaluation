J=32
LIMIT=400
SAMPLE=999

FOLDP1=100
FOLD=$(shell perl -e 'print $(FOLDP1)-1,"\n"')
RESAMPLE=99
LENGTH=$(shell perl -MPOSIX -e 'print ceil(log('$(FOLD)')/log(10)), "\n"')

all: includes

includes: agreement pairwisestats expected-wins trueskill correl alljudges
#includes: agreement pairwisestats expected-wins trueskill correl alljudges

agreement: include/agreement.tex

pairwisestats: include/pairwisestats.tex

expected-wins: include/EW.ranking.tex include/EW.head2head.tex

trueskill: include/TS.ranking.tex

correl: include/correl.table.EW.tex include/correl.annotator.EW.tex

include/correl.table.EW.tex: metrics EW.ranking.txt
	perl scripts/latex_correl.pl > $@

################################################################################

judges/EW.ranking.%.txt: judgments.xml
	mkdir -p judges
	cat $^ | perl scripts/EW.pl -u annotator0$* -p 0.1 > $@

include/EW.ranking.%.tex : judges/EW.ranking.%.txt
	mkdir -p include
	cat $^ | perl scripts/latex_ranking.pl -h > $@

JUDGES=$(addsuffix .txt, $(addprefix judges/EW.ranking.,$(shell seq 1 8)))
NOJUDGES=$(addsuffix .txt, $(addprefix judges/EW.ranking.no,$(shell seq 1 8)))
JUDGESTEX=$(addsuffix .tex, $(addprefix include/EW.ranking.,$(shell seq 1 8)))

judges/stats.txt: judgments.xml
	mkdir -p judges
	cat $^ | perl scripts/stats.pl -r | cut -f 1,5 > $@

include/correl.annotator.EW.tex: judges/stats.txt $(JUDGES) $(NOJUDGES)
	perl scripts/latex_correl_judges.pl > $@

alljudges: include/correl.annotator.EW.tex $(JUDGESTEX)

################################################################################

include/EW.head2head.tex : judgments.xml
	perl scripts/head2head.pl < $^ > $@

################################################################################

exported/export.%.xml : 
	python scripts/export_gec_results.py $* > $@

judgments.xml : exported/export.conll-eval-1-1000.xml exported/export.conll-eval-1000-2000.xml
	perl scripts/join_xml.pl --limit ${LIMIT} $^ > $@

include/agreement.tex: judgments.xml
	mkdir -p include
	cat $^ | perl scripts/agreement.pl > $@

include/pairwisestats.tex: judgments.xml
	mkdir -p include
	cat $^ | perl scripts/stats.pl > $@

################################################################################

pairs.ops.txt: judgments.xml
	cat $^  | perl scripts/print_pairs.pl > $@

pairs.tup.txt: judgments.xml
	cat $^  | perl scripts/print_pairs.pl -r > $@

EW_BOOT=$(addsuffix _mu_sigma.json, $(addprefix EW/run.,$(shell seq 0 $(SAMPLE))))
TS_BOOT=$(addsuffix _mu_sigma.json, $(addprefix TS/run.,$(shell seq 0 $(SAMPLE))))

include/%.ranking.tex: %.ranking.txt
	mkdir -p include
	cat $^ | perl scripts/latex_ranking.pl -h > $@

EW/run.%_mu_sigma.json: pairs.ops.txt
	mkdir -p EW 
	cat $^ | python scripts/wmt-trueskill/EW.py EW/run.$*

TS/run.%_mu_sigma.json: pairs.tup.txt
	mkdir -p TS
	cat $^ | python scripts/wmt-trueskill/TS.py TS/run.$* -n 2 -d 0

EW.ranking.txt: $(EW_BOOT)
	mkdir -p include
	python scripts/wmt-trueskill/eval/cluster.py -by-rank -i 0.95 include/EW EW/run.*_mu_sigma.json -pdf > $@

TS.ranking.txt: $(TS_BOOT)
	mkdir -p include 
	python scripts/wmt-trueskill/eval/cluster.py -by-rank -i 0.95 include/TS TS/run.*_mu_sigma.json -pdf > $@

################################################################################

metrics: include/m2.spearman.EW.tsv include/m2.pearson.EW.tsv \
	include/m2.0.spearman.EW.tsv include/m2.0.pearson.EW.tsv \
	include/m2.1.spearman.EW.tsv include/m2.1.pearson.EW.tsv

include/%.spearman.EW.tsv : EW.ranking.txt metrics/scores.%
	perl scripts/spearman.m2graph.pl $^ > $@

include/%.pearson.EW.tsv : EW.ranking.txt metrics/scores.%
	perl scripts/pearson.m2graph.pl $^ > $@


include/%.spearman.TS.tsv : TS.ranking.txt metrics/scores.%
	perl scripts/spearman.m2graph.pl $^ > $@

include/%.pearson.TS.tsv : TS.ranking.txt metrics/scores.%
	perl scripts/pearson.m2graph.pl $^ > $@

################################################################################

accuracy.bootstrap: accuracy/EW.accuracy accuracy/TS.accuracy

accuracy/pairs.tup.txt: pairs.tup.txt
	mkdir -p accuracy
	cat $^ | shuf > $@

accuracy/pairs.ops.txt: accuracy/pairs.tup.txt
	cat $^ | perl scripts/tup2ops.pl > $@

accuracy/split.EW: accuracy/pairs.ops.txt
	mkdir -p accuracy/split.EW
	cat $^ | split -a $(LENGTH) -d -n r/$(FOLDP1) - accuracy/split.EW/split.EW.

accuracy/split.TS: accuracy/pairs.tup.txt
	mkdir -p accuracy/split.TS
	cat $^ | split -a $(LENGTH) -d -n r/$(FOLDP1) - accuracy/split.TS/split.TS.

EW_FOLD_TARGETS=$(addprefix accuracy/EW.accuracy.,$(shell seq -w 0 $(FOLD)))

accuracy/EW.accuracy: $(EW_FOLD_TARGETS)
	cat $^ | perl -ne '$$s += $$_; END { print $$s/$$.,"\n" }' > $@
	cat $@

TS_FOLD_TARGETS=$(addprefix accuracy/TS.accuracy.,$(shell seq -w 0 $(FOLD)))

accuracy/TS.accuracy: $(TS_FOLD_TARGETS)
	cat $^ | perl -ne '$$s += $$_; END { print $$s/$$.,"\n" }' > $@
	cat $@

accuracy/EW.accuracy.%: accuracy/EW.ranking.%
	cat accuracy/split.EW/split.EW.$* | python scripts/wmt-trueskill/eval/accuracy.py $^ > $@

accuracy/TS.accuracy.%: accuracy/TS.ranking.%
	cat accuracy/split.EW/split.EW.$* | python scripts/wmt-trueskill/eval/accuracy.py $^ > $@

.PRECIOUS: accuracy/EW.ranking.%

accuracy/EW.ranking.%: accuracy/split.EW
	mkdir -p accuracy/EW.$*
	seq 0 ${RESAMPLE} | parallel -j${J} 'echo -n "$* {} "; find accuracy/split.EW/split.EW.* | grep -v {} | xargs cat | python scripts/wmt-trueskill/EW.py accuracy/EW.$*/run.{}'
	python scripts/wmt-trueskill/eval/cluster.py -by-rank -i 0.95 include/EW accuracy/EW.$*/run.*_mu_sigma.json > $@

accuracy/TS.ranking.%: accuracy/split.TS
	mkdir -p accuracy/TS.$*
	seq 0 ${RESAMPLE} | parallel -j${J} 'echo -n "$* {} "; find accuracy/split.TS/split.TS.* | grep -v {} | xargs cat | python scripts/wmt-trueskill/TS.py -n 2 -d 0 accuracy/TS.$*/run.{}'
	python scripts/wmt-trueskill/eval/cluster.py -by-rank -i 0.95 include/TS accuracy/TS.$*/run.*_mu_sigma.json > $@

################################################################################

accuracy.radius: accuracy/EW.accuracy.radius accuracy/TS.accuracy.radius

accuracy/EW.accuracies.grid: accuracy/split.EW
	mkdir -p accuracy/EW
	seq -w 0 $(FOLD) | \
	parallel -j${J} 'find accuracy/split.EW/split.EW.?? \
	| grep -v {} | xargs cat | \
	python scripts/wmt-trueskill/EW.py accuracy/EW/run.{}'
	for d in `LC_ALL=C seq 0 0`; do \
	seq -w $(FOLD) | \
	parallel -j${J} -k "echo -ne '{}\t'$$d'\t'; cat accuracy/split.EW/split.EW.{} \
	| python scripts/wmt-trueskill/eval/accuracy_d.py -d $$d -m $(M) accuracy/EW/run.{}_mu_sigma.json 2>/dev/null"; \
	done | tee $@

accuracy/TS.accuracies.grid: accuracy/split.TS
	mkdir -p accuracy/TS
	seq -w 0 $(FOLD) | \
	parallel -j${J} 'find accuracy/split.TS/split.TS.?? \
	| grep -v {} | xargs cat | \
	python scripts/wmt-trueskill/TS.py -n 2 -d 0 accuracy/TS/run.{}'
	for d in `LC_ALL=C seq 0 0`; do \
	seq -w 0 $(FOLD) | \
	parallel -j${J} "echo -ne '{}\t'$$d'\t'; cat accuracy/split.EW/split.EW.{}  \
	| python scripts/wmt-trueskill/eval/accuracy_d.py -d $$d -m $(M) accuracy/TS/run.{}_mu_sigma.json 2>/dev/null"; \
	done | tee $@

accuracy/EW.accuracy.radius: accuracy/EW.accuracies.grid
	cat $^ | sort -n | perl scripts/radius_average.pl > $@

accuracy/TS.accuracy.radius: accuracy/TS.accuracies.grid
	cat $^ | sort -n | perl scripts/radius_average.pl > $@

################################################################################

clean:
	rm -rf judgments.xml pairs.ops.txt pairs.tup.txt \
	EW.ranking.txt EW_cluster.pdf EW EW.ranking.*.txt \
	TS.ranking.txt TS_cluster.pdf TS \
	accuracy judges include
