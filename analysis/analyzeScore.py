import numpy as np
import matplotlib.pyplot as plt
import json
import os
import sys

def plotSession(directory):
    """
    scr = []
    for row in open(os.path.join(directory, 'nexus.data')):
        row = json.loads(row)
        ts = row[0]['ts']
        scr.append((ts, row[1]['E']))
    scr = np.array(scr)
    scr[:,1] = 1.0/scr[:,1]
    """
    
    obj = []
    for row in open(os.path.join(directory, 'blind_pursuit.data')):
        row = json.loads(row)
        ts = row['time']
        data = row['data']
        if "balancingTask" not in data:
            continue
        td = data['balancingTask']

        obj.append((ts, td['ballPosition'], td['time'], td['timeWarp']))
    
    obj = np.rec.fromrecords(obj, names='ts,ballPos,time,timeWarp')
    plt.plot(obj['ts'], np.abs(obj['ballPos']))
    jumps = np.flatnonzero(np.diff(obj['timeWarp']))
    jumps = obj['ts'][jumps]
    for jump in jumps:
        plt.axvline(jump, color='black')
    #plt.plot(obj['ts'][1:], np.diff(np.abs(obj['timeWarp'])))
    plt.show()

plotSession(sys.argv[1])
