#!/usr/bin/python

import pydicom, json
from optparse import OptionParser

usage = "usage: %prog [-f] filename"
parser = OptionParser(usage)
parser.add_option("-f", "--filename", dest="filename", type=str, help="Path to the file we're going to scrape")

(options, args) = parser.parse_args()

if len(args) != 1:
	parser.error("incorrect number of arguments")

filename = options.filename if options.filename else args[0]

# This script is set up to look at some dicom headers, massage the values a little, and return a JSON report.
# If anything goes wrong, return a JSON report that includes a description of the error.

# column_mapping = [(0x0018, 0x0022), # Scan Options, should include 'FILTERED_GEMS' is this is PURE corrected
# 	(0x0043, 0x102d), # Filter Mode', should have "P+", "p+", or "wp+" if this is PURE corrected
# 	(0x0018,0x9021), # 'T2 Preparation', this may be blank :(
# 	(0x0018,0x1250), # 'Receive Coil Name', from which I can get the number of channels
# 	(0x0008,0x1090), # 'Manufacturer's mode name', which will become 'scanner_name'
# ]

# ["t2_prep", "pure_correction", "channel_count", "coil_name", "scanner"]

dcm = pydicom.dcmread(filename)

json_report = {}

try:
	scan_options = dcm[(0x0018,0x0022)] # Scan Options, should include 'FILTERED_GEMS' is this is PURE corrected
	filter_mode = dcm[(0x0043,0x102d)] # Filter Mode', should have "P+", "p+", or "wp+" if this is PURE corrected

	pure_corrected_status = 'False'

	if ('FILTERED_GEMS' in scan_options.value) and (filter_mode.value in ["P+", "p+", "wp+"]):
		pure_corrected_status = 'True'
	elif ('FILTERED_GEMS' in scan_options.value) or (filter_mode.value in ["P+", "p+", "wp+"]):
		pure_corrected_status = 'Other - (scan options is %s, filter mode is %s' % (','.join(scan_options.value), filter_mode.value)

	t2_prep = dcm[(0x0018,0x9021)].value if (0x0018,0x9021) in dcm.keys() else None # 'T2 Preparation', this may be blank :(
	coil_name = dcm[(0x0018,0x1250)] # 'Receive Coil Name', from which I can get the number of channels
	scanner = dcm[(0x0008,0x1090)] # 'Manufacturer's mode name', which will become 'scanner_name'

	channel_count = 0
	if coil_name == '8HRBRAIN':
		channel_count = 8

	json_report = {'t2_prep': t2_prep, 'pure_correction': pure_corrected_status, 'channel_count':channel_count, 'coil_name':coil_name.value, 'scanner':scanner.value}

except Exception as e:
	if 'error' not in json_report.keys():
		json_report['error'] = []
	json_report['error'].append("%s, %s" % (type(e), e))


print(json.dumps(json_report))

