import numpy as np
import matplotlib.pyplot as plt
import json
import os
import sys
import gsr

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
    scr = scr[::16]
    dt = np.mean(np.diff(scr[:,0]))
    #dscr = np.diff(scr[:,1])/dt
    #scr = scr[1:]
    scr_phasic, baseline, kernel = gsr.deconv_baseline(scr[:,1], 1/dt)
    #scr_phasic = scr[:,1]
    #plt.plot(scr[:,0][1:], np.diff(scr[:,1]))
    plt.plot(scr[:,0], scr_phasic)
    
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
    plt.show()
    
    plt.figure()
    
    front = int(20/dt)
    back = int(20/dt)
    trng = np.arange(-front, back)*dt
    nsamples = front + back
    spans = []
    for t in jumptimes:
        s = scr[:,0].searchsorted(t) - front
        spans.append(scr_phasic[s:(s+nsamples)])
    plt.plot(trng, np.mean(spans, axis=0), color='red', label='Jump')
    
    pureblinks = blinks[~np.in1d(blinks, jumps)]
    means = []
    for i in range(1000):
        spans = []
        for t in np.random.choice(blinktimes, len(jumptimes)):
            s = scr[:,0].searchsorted(t) - front
            spans.append(scr_phasic[s:(s+nsamples)])
        means.append(np.mean(spans, axis=0))

    plt.plot(trng, np.mean(means, axis=0), color='black', label='Blink')

    plt.axvline(0)
    plt.xlabel("Time from event")
    plt.ylabel("Skin conductance change")
    plt.legend()

    plt.show()

plotSession(sys.argv[1])
