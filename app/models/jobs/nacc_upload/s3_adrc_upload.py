#!/usr/bin/python

import boto3
import os, sys, json
from optparse import OptionParser

usage = "usage: %prog [-f] filename [-p prefix] [-t target_bucket]"
parser = OptionParser(usage)
parser.add_option("-f", "--filename", dest="filename", type=str, help="the name of the file to send to S3")
parser.add_option("-p", "--prefix", dest="prefix", type=str, default="MRI/37/", help="a filename prefix for the destination S3 file")
parser.add_option("-t", "--target_bucket", dest="target_bucket", type=str, default="naccimageraw", help="the name of the S3 bucket to upload to")

(options, args) = parser.parse_args()

if len(args) != 1:
	parser.error("incorrect number of arguments")

filename = options.filename if options.filename else args[0]

directory = "/home/panda_user/upload_adrc/"

# This script will try to upload a specific archive file if finds it in this directory. It will then check
# S3 to see if the file has uploaded correctly (that the remote size matches the local size), and if
# so, moves that tar.gz to the "sent" folder.
# Finally, it builds a report, and prints the report in JSON to STDOUT. This is used by the Panda to 
# send files to NACC, and hopefully the Panda is listening, and will read the JSON that this script
# responds with.

# Credentials for talking to S3 are in ~/.aws/credentials, and are read automatically by boto3

s3 = boto3.resource('s3')

files = [x for x in os.listdir(directory) if x.endswith(".zip") or x.endswith(".tar.gz") or x.endswith(".tgz") ]

report = {}
client = boto3.client(service_name='s3', use_ssl=True)

if filename in files:
	report[filename] = {}
	s3.meta.client.upload_file(directory + filename, options.target_bucket, options.prefix + filename)

	#the "head_object" for this file will tell us the remote file size
	response = client.head_object(Bucket=options.target_bucket, Key=options.prefix + filename)

	#and this tells us the local filesize
	local_size = os.stat(directory + filename).st_size

	report[filename]['remote_size'] = int(response['ContentLength'])
	report[filename]['local_size'] = int(local_size)
	
	if report[filename]['remote_size'] == report[filename]['local_size']:
		report[filename]['status'] = 'success'

		#move the tar.gz to sent
		os.rename(directory + filename, directory + 'sent/' + filename)
	else:
		report[filename]['status'] = 'fail'

json.dumps(report)
