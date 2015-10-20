#!/usr/bin/env python
# -*- coding:utf-8 -*-

RES_FILE = '/home/dreamer.xiong/conntrack-check/conntrack.txt'



FIELDS = [
    'stdout',
]
            

class CallbackModule(object):

    def __init__(self):
        pass

    def on_any(self, *args, **kwargs):
        pass
    
    def runner_on_failed(self, host, res, ignore_errors=False):
        pass

    def runner_on_ok(self, host, res):
        if type(res) == type(dict()):
            if "stdout" in res.keys() and "conntrack_max" in res['stdout']:
                f= open(RES_FILE, "a+")
                f.write("%-30s\tconntrack_max: %s\tsysctl: %s\n" % (host, res['stdout'].split("\r\n")[0], res['stdout'].split("\r\n")[1]))
                f.close()
                print res['stdout']

            #if "stdout" in res.keys() and "No such file or directory" in res['stdout']:
            #    f= open(RES_FILE, "a+")
            #    f.write("%-30s\t%s\n" % (host, res['stdout'].split("\r\n")[0]))
            #    f.close()
            #    print res['stdout']
                

    def runner_on_error(self, host, msg):
        pass

    def runner_on_skipped(self, host, item=None):
        pass

    def runner_on_unreachable(self, host, res):
        pass

    def runner_on_no_hosts(self):
        pass

    def runner_on_async_poll(self, host, res, jid, clock):
        pass

    def runner_on_async_ok(self, host, res, jid):
        pass

    def runner_on_async_failed(self, host, res, jid):
        pass

    def playbook_on_start(self):
        pass

    def playbook_on_notify(self, host, handler):
        pass

    def playbook_on_no_hosts_matched(self):
        pass

    def playbook_on_no_hosts_remaining(self):
        pass

    def playbook_on_task_start(self, name, is_conditional):
        pass

    def playbook_on_vars_prompt(self, varname, private=True, prompt=None, encrypt=None, confirm=False, salt_size=None, salt=None, default=None):
        pass

    def playbook_on_setup(self):
        pass

    def playbook_on_import_for_host(self, host, imported_file):
        pass

    def playbook_on_not_import_for_host(self, host, missing_file):
        pass

    def playbook_on_play_start(self, pattern):
        pass

    def playbook_on_stats(self, stats):
        pass

