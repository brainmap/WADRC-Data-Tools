#!/usr/bin/python

import pydicom
import json
from pydicom import Tag
from optparse import OptionParser

usage = "usage: %prog [-f] filename"
parser = OptionParser(usage)
parser.add_option("-f), "--filename", dest="filename", type=str, help="Path to the file we're going to dump")

(options, args) = parser.parse_args()

if len(args) != 1:
	parser.error("incorrect number of arguments")

filename = options.filename if options.filename else args[0]



dcm = pydicom.dcmread(filename)

keys_of_interest = ['00080080','0008103E','00081030','00081070','00100010', \
'00100020','00100040','00180050','00181100','00180080', \
'00280030','00181314','00180087','00180088','00181020', \
'00181030','00200105','00080018','0020000E','0020000D', \
'00200010','00201002','00280010','00280011']

dcm_obj = json.loads(dcm.to_json())

outbound_hash = {}

for key in list(set(keys_of_interest) & set(dcm_obj.keys())):
	if len(dcm_obj[key]["Value"]) == 1:
		outbound_hash[key] = dcm_obj[key]["Value"][0]
	else:
		outbound_hash[key] = dcm_obj[key]["Value"]

print(json.dumps(outbound_hash))
