#!/usr/bin/python

import pydicom
from optparse import OptionParser

usage = "usage: %prog [-f] filename"
parser = OptionParser(usage)
parser.add_option("-f", "--filename", dest="filename", type=str, help="Path to the file we're going to scrub")
parser.add_option("-a", "--adrcnum", dest="adrcnum", type=str, help="The ADRC ID to populate into this file")

(options, args) = parser.parse_args()

if len(args) != 1:
	parser.error("incorrect number of arguments")

filename = options.filename if options.filename else args[0]

# I'm going to hardcode the fields we want to scrub, since this changes very infrequently,
# and we need to keep some fields for NACC. Here's the list, because maybe someone reading
# this would like some context:

"""
# fields to keep
(0010,0020)	Patient ID
(0020,000E)	Series Instance UID
(0020,000D)	Study Instance UID
(0020,0013)	Instance Number
(0008,103E)	Series Description
(0008,0020)	Study Date
(0018,0087)	Magnetic Field Strength
(0008,0070)	Manufacturer
(0008,1090)	Manufacturer's Model Name
"""

def scrub(handle, address):
	elem = handle[address[0],address[1]]
	elem.value = None

# fields we've been scrubbing
to_scrub = [(0x0010,0x0030), # 'DOB'
	(0x0010,0x0010), # 'Name'
	(0x0008,0x0050), # 'Accession Number',
	(0x0040,0x0254), # 'Performed Proc Step Desc',
	(0x0008,0x0080), # 'Institution Name',
	(0x0008,0x1010), # 'Station Name',
	(0x0009,0x1002), # 'Private',
	(0x0009,0x1030), # 'Private',
	(0x0018,0x1000), # 'Device Serial Number',
	(0x0025,0x101A), # 'Private',
	(0x0040,0x0242), # 'Performed Station Name',
	(0x0040,0x0243)] # 'Performed Location'


dcm = pydicom.dcmread(filename)

for field in to_scrub:
	scrub(dcm, field)

dcm.PatientID = options.adrcnum

dcm.save_as(filename)

