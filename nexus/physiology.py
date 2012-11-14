#!/usr/bin/env python2

from trusas0.utils import get_logger
log = get_logger()
from trusas0.packing import default_packer
import pynexus
import argh
import sys


def record(nexus_address, output):
	dev = pynexus.Nexus(nexus_address)
	for sample in dev:
		output.send(sample)

@argh.command
def main(nexus_address):
	record(nexus_address, default_packer())

if __name__ == '__main__':
	parser = argh.ArghParser()
	parser.add_commands([argh.alias('')(main)])
	parser.dispatch(argv=['']+sys.argv[1:])
