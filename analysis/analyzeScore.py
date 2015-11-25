import numpy as np
import matplotlib.pyplot as plt
import json
import os
import sys

def plotSession(directory):
    scr = []
    for row in open(os.path.join(directory, 'nexus.data')):
        row = json.loads(row)
        ts = row[0]['ts']
        scr.append((ts, row[1]['E']))
    scr = np.array(scr)
    scr[:,1] = 1.0/scr[:,1]
    
    obj = []
    trial = 0
    for i, row in enumerate(open(os.path.join(directory, 'blind_pursuit.data'))):
        row = json.loads(row)
        if row['data'].get('loadingScenario') == 'blindPursuit':
            trial += 1
        ts = row['time']
        data = row['data']
        if "balancingTask" not in data:
            continue
        td = data['balancingTask']

        obj.append((trial, ts, td['ballPosition'], td['time'], td['timeWarp'], td['targetVisible']))
    
    obj = np.rec.fromrecords(obj, names='trial,ts,ballPos,time,timeWarp,targetVisible')
    obj = obj[obj['trial'] > 1]
    #plt.plot(obj['ts'], np.abs(obj['ballPos']))
    scr = scr[::60]
    #plt.plot(scr[:,0][1:], np.diff(scr[:,1]))
    plt.plot(scr[:,0], scr[:,1])
    
    blinks = np.flatnonzero(np.diff(obj['targetVisible'].astype(np.int)) < 0)
    #jumps = obj['ts'][jumps]
    blinktimes = obj['ts'][blinks]

    jumps = np.flatnonzero(np.diff(obj['timeWarp']))
    jumptimes = obj['ts'][jumps]
    for t in blinktimes:
        plt.axvline(t, color='black', alpha=0.1)
    for t in jumptimes:
        plt.axvline(t, color='black', alpha=0.5)
    #plt.plot(obj['ts'][1:], np.diff(np.abs(obj['timeWarp'])))
    
    plt.figure()
    dt = np.mean(np.diff(scr[:,0]))
    dscr = np.diff(scr[:,1])/dt
    scr = scr[1:]
    front = int(5/dt)
    back = int(10/dt)
    trng = np.arange(-front, back)*dt
    nsamples = front + back
    spans = []
    for t in jumptimes:
        s = scr[:,0].searchsorted(t) - front
        spans.append(dscr[s:(s+nsamples)])
    plt.plot(trng, np.mean(spans, axis=0), color='red', label='Jump')
    
    spans = []
    pureblinks = blinks[~np.in1d(blinks, jumps)]
    for t in blinktimes:
        s = scr[:,0].searchsorted(t) - front
        spans.append(dscr[s:(s+nsamples)])
    plt.plot(trng, np.mean(spans, axis=0), color='black', label='Blink')

    plt.axvline(0)
    plt.xlabel("Time from event")
    plt.ylabel("Skin conductance change")
    plt.legend()

    plt.show()

plotSession(sys.argv[1])
