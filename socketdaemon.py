#############################################################
# SDI is an open source project.
# Licensed under the GNU General Public License v2.
#
# File Description: 
# 
#
#############################################################

#!/usr/bin/env python

import socket
import sys

def serverstart(tcp, host, port):

    orig = (host, port)
    try:
        tcp.bind(orig)
    except:
        print 'Port already in use. Wait a moment or try another port.'
        sys.exit(1)
    tcp.listen(1024)

    queue = []

    countMAX = 500
    count = countMAX

    while True:
        con, cliente = tcp.accept()
        msg = con.recv(1024)
        if msg == 'acquire':
            if count > 0:
                count -= 1
                con.close()
            else:
                queue.append(con)
        elif msg == 'release':
            con.close()
            if queue:
                queue.pop(0).close()
            else:
                #if countMAX-(count+1)>=0: count +=1
                if count < countMAX: count +=1
        elif msg == 'add':
            countMAX += 10
            count += 10
            con.send("New countMAX = %d"%countMAX)
            con.close()
            for i in range(10):
                if queue:
                    queue.pop(0).close()
        elif msg == 'rem':
            if countMAX > 0:
                countMAX -= 10
                count -= 10
            con.send("New countMAX = %d"%countMAX)
            con.close()
        elif msg == 'status':
            res = []
            res.append("Max. Conec: %d"%countMAX)
            res.append("Corr. Conec.  : %d"%(countMAX-count))
            res.append("Spool Size: %d" %len(queue))
            con.send('\n'.join(res))
        elif msg == 'stop':
            con.close()
            break

if __name__ == '__main__':
    from configsdiparser import configsdiparser
    try:
        tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        tcp.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
        port = int(configsdiparser().get('general', 'socket port'))
        serverstart(tcp,'', port)
        tcp.close()
    except:
        tcp.close()
        raise
        sys.exit(0)
