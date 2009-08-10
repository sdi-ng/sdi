#!/usr/bin/env python

import sys,os

# check python version to import configparser
if sys.version_info[0]<3:
    from ConfigParser import ConfigParser as configparser
else:
    from configparser import configparser

class configsdiparser:

    def __init__(self, conf='sdi.conf'):
        # get the correct conf path
        dirname = os.path.dirname(sys.argv[0])
        self.conffilepath = dirname +'/'+ conf

        # define default variable values
        self.defaults = {
            'general':   {'prefix': dirname,
                          'cmd dir': '%(prefix)s/cmds',
                          'cmd general': '%(cmd dir)s/general',
                          'tmp dir': '/tmp/sdi',
                          'pid dir': '%(tmp dir)s/pids',
                          'pid dir sys': '%(pid dir)s/system',
                          'pid dir hosts': '%(pid dir)s/hosts',
                          'shooks': '%(prefix)s/states-enabled',
                          'launch delay': '0.05',
                          'kill tout': '30',
                          'log': '%(prefix)s/sdi.log',
                          'hooks':  '%(prefix)s/commands-enabled',
                          'fifo dir':  '%(tmp dir)s/fifos',
                          'socket port': '18193',
                          'sfifo': '%(fifo dir)s/states.fifo'},
            'ssh':       {'sdiuser': 'root',
                          'timeout': '240',
                          'ssh port': '22',
                          'sshopt[0]': 'PreferredAuthentications=publickey',
                          'sshopt[1]': 'StrictHostKeychecking=no',
                          'sshopt[2]': 'ConnectTimeout=%(timeout)s',
                          'sshopt[3]': 'TCPKeepAlive=yes',
                          'sshopt[4]': 'ServerAliveCountMax=3',
                          'sshopt[5]': 'ServerAliveInterval=100'},
            'web':       {'prefix': dirname,
                          'web mode': 'true',
                          'sdi web': 'sdiweb',
                          'classes dir': 'CLASSES',
                          'class name': 'MACHINES',
                          'wwwdir': 'www',
                          'host columnname': 'Hostname',
                          'default columns': 'Hostname,Uptime,Status'},
            'data':      {'prefix': dirname,
                          'data dir': '%(prefix)s/data',
                          'use fast data dir': 'no',
                          'fast data dir': '/dev/shm/sdi/data',
                          'data sync interval': '3',
                          'data history format': '%Y.%m'},
            'send file': {'send limit': '1'}
        }

        self.config = configparser()

        # read the config file
        try:
            self.config.read(self.conffilepath)
        except:
            print 'error: bad config file'
            sys.exit(1)

    def printvars(self, sections):
        if sections[0] == 'all':
            sections = self.config.sections()

        for sec in sections:
            if self.defaults.has_key(sec):
                for var,value in self.defaults[sec].items():
                    if not var in [i[0] for i in self.config.items(sec,1)]:
                        self.config.set(sec,var,value)
                # Transform array into a single option
                if sec == "ssh":
                    newopt = "'"
                    for key, value in self.config.items("ssh",1):
                        if key.startswith('sshopt'):
                            newopt += "-o %s " % value.replace('"','')
                            self.config.remove_option("ssh",key)
                    newopt += "'"
                    self.config.set("ssh","sshopts",newopt)

            for var,value in self.config.items(sec):
                print '%s=%s ' %(var.upper().replace(' ',''),value),

    def get(self, section, var):
        return self.config.get(section, var)

if __name__ == '__main__':
    if len(sys.argv)==1:
        sys.exit(1)

    parse = configsdiparser()
    parse.printvars(sys.argv[1:])
