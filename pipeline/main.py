#!/usr/bin/env python2

from os import path
import sys

from trusas0.script import sh
from trusas0 import ROOT
from trusas0.service import ServiceSpec
from trusas0.ui import run_ui
import logging
import os


NEXUS_ADDR = "00:A0:96:2F:A8:A6"
# This is no big secret as it's broadcasted
# in the device name
NEXUS_PIN = "0115"

#NEXUS_ADDR = "00:A0:96:2D:C3:99"
#NEXUS_PIN = "0089"

mypath=path.dirname(path.realpath(__file__))
myroot=path.dirname(mypath)
datapath=path.join(myroot, 'sessions')

s = ServiceSpec()

s['nexus'] = ROOT+'/nexus/physiology.py -p %s %s'%(NEXUS_PIN, NEXUS_ADDR)
s['blind_pursuit'] = ROOT+'/../blindPursuit.sh'


run_ui(spec=s,
	base_dir=datapath,
	content=open(path.join(mypath, 'main.html')).read()
	)

