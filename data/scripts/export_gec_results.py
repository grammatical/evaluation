#!/usr/bin/env python
# -*- coding: utf-8 -*-

from datetime import datetime
import os
import sys


APPRAISE_DIR = '/home/romang/www/Appraise'

if __name__ == "__main__":
    
    if len(sys.argv) < 2:
        print >> sys.stderr, "usage: ./{} task-name".format(sys.argv[0])
        exit()
    else:
        task_name = sys.argv[-1]

    # Properly set DJANGO_SETTINGS_MODULE environment variable.
    os.environ['DJANGO_SETTINGS_MODULE'] = 'appraise.settings'
    PROJECT_HOME = os.path.normpath(APPRAISE_DIR)
    sys.path.append(PROJECT_HOME)

    import appraise.settings as set
    set.DATABASES["default"]["NAME"] = APPRAISE_DIR + "/appraise/development.db"
    set.TEMPLATE_DIRS = (APPRAISE_DIR + "/appraise/templates",);
    
    from appraise.evaluation.models import EvaluationTask
    from django.template.loader import get_template, find_template
    from django.template import Context


    tasks = EvaluationTask.objects.filter(task_name__exact=task_name)
    if len(tasks) < 1:
        print >> sys.stderr, "task '{}' not found".format(task_name)
        exit()
    else:
        task = tasks[0]

    template = get_template('evaluation/result_export.xml')
    export_xml = template.render(Context({'tasks': [task.export_to_xml()]}))

    print export_xml
