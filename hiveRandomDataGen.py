#!/usr/bin/env python
import os
import re
import sys
import uuid
import random
import string
import getopt
from random import randrange
from datetime import *
from collections import OrderedDict
import time
from subprocess import PIPE, Popen


reload(sys)
sys.setdefaultencoding('utf8')

def print_help():
    HELP_STMT = """
       ##############################################
       Hive data generator from schema by Pablo Junge
                       Hortonworks
       ##############################################

       Usage:

       python hiveRandomDataGen.py -s inFileSChema -n numRowsToGenerate -d databaseName [-p 10,2,..]

       -s     =   Create statement input file produced by 
                  "show create table" statement.
       -n     =   Amount of rows to generate based on input schema.
       -p     =   Optional amount of different partitions. If 3 partitions, 
                  you should specify amount for all of them as comma separated
                  list. If not specified, random will be used.
                  
       hiveRandomDataGen.py will generate HiveRandom.hql along with HiveRandom.csv
       Just execute: beeline -f HiveRandom.hql

       Working data types:

           String      :   "string", "varchar", "char"
           Numeric     :   "tinyint", "smallint", "bigint", "int" 
                           "double", "float", "decimal", "numeric"
           Date/Time   :   "timestamp", "date"
           Misc        :   "boolean"

       Not Allowed data types:

           ComplexTypes:   Non of them
           Misc        :   Binary

       """
    print(HELP_STMT)
    exit(1)


version = '1.2'

difsPartitions = ""
numRows = 0
inFile = ""
dbName = ""

options, remainder = getopt.getopt(sys.argv[1:], 's:n:p:d:v:h', ['schema',
                                                              'numberofrow',
                                                              'partitions'
                                                              'database',
                                                              'version',
                                                              'help',

                                                         ])


for opt, arg in options:
    if opt in ('-s', '--schema'):
        inFile = arg
    elif opt in ('-n', '--numberofrow'):
        numRows = int(arg)
    elif opt in ('-p', '--partitions'):
        difsPartitions = arg
    elif opt in ('-d', '--database'):
        dbName = arg
    elif opt in ('-v', '--version'):
        print("Version: ") +version
        exit(0)
    elif opt in ('-h', '--help'):
        print_help()
        exit(0)

if difsPartitions != "":
    difsPartitions = difsPartitions.split(",")
else:
    difsPartitions = []

for num in difsPartitions:
    if num == "":
        print("\n\nError: Empty amount of different partition for a partition.\n\n")
        print_help()
    elif num == "0":
        print("\n\nError: You can not set an amount of different partition to 0.\n\n")
        print_help()


if numRows == 0 or inFile == "":
   print_help()


outPath = os.getcwd() + "/"
outFile   = outPath + "HiveRandom.csv"
outScript = outPath + "HiveRandom.hql"


fDelimiter = ','
rDelimiter = '\n'
tablePostfix = "_random"

dataTypeKeys = ["string", " varchar", " char",
                "tinyint", "smallint", "bigint", "int",
                "double", "float", "decimal", "numeric",
                "timestamp", "date",
                "boolean"]

def my_random_string(string_length=10):
    random_str = str(uuid.uuid4())
    random_str = random_str.upper()
    random_str = random_str.replace("-", "")
    return random_str[0:string_length]


def my_random_int(int_length=8):
    random_int = ''.join([random.choice(string.digits) for n in xrange(int_length)])
    return random_int


def my_random_double(double_length=5, double_precision=4):
    random_double = ''.join([random.choice(string.digits) for n in xrange(double_length)])
    random_double2 = ''.join([random.choice(string.digits) for n in xrange(double_precision)])
    return random_double + "." + random_double2


def my_random_date(date_type='timestamp'):
    start = datetime.strptime('1/1/2008 1:30 PM', '%m/%d/%Y %I:%M %p')
    end = datetime.strptime('1/1/2018 4:50 AM', '%m/%d/%Y %I:%M %p')

    delta = end - start
    int_delta = (delta.days * 24 * 60 * 60) + delta.seconds
    random_second = randrange(int_delta)
    res = start + timedelta(seconds=random_second)
    if date_type == "timestamp":
        return str(res)
    else:
        spl = str(res).split(" ")
        return spl[0]


def get_field_delimiter(tmp_data=[]):
    f_delimiter_reg = re.compile("fields terminated by '(.*)'", re.IGNORECASE)
    for tempLine in tmp_data:
        fd = f_delimiter_reg.search(tempLine)
        if fd and len(fd.group()) > 1:
            return fd.group(1)
    return ''


def get_value_for_type(col_type, tmp_char_regex, tmp_deci_regex):
    if col_type == "string":
        return my_random_string(10)
    elif col_type == "int":
        return my_random_int(8)
    elif col_type == "tinyint":
        return my_random_int(2)
    elif col_type == "smallint":
        return my_random_int(4)
    elif col_type == "bigint":
        return my_random_int(18)
    elif col_type == "double":
        return my_random_double(6)
    elif col_type == "float":
        return my_random_double(6)
    elif "decimal" in col_type:
        dec_sol = tmp_deci_regex.search(col_type)
        if dec_sol and len(dec_sol.groups()) == 2:
            return my_random_double(int(dec_sol.group(1)), int(dec_sol.group(2)))
        else:
            return my_random_double()
    elif col_type == "numeric":
        return my_random_double(6)
    elif col_type == "date":
        return my_random_date("date")
    elif col_type == "timestamp":
        return my_random_date("timestamp")
    elif "char" in col_type:
        char_sol = tmp_char_regex.search(col_type).group(1)
        return my_random_string(int(char_sol))
    elif col_type == "boolean":
        bran = int(my_random_int(1)) % 2
        if bran:
            return "true"
        else:
            return "false"


create_regex = re.compile("CREATE[\w| ]* TABLE [`|'|\"](.*)[`|'|\"]", re.IGNORECASE)
global_regex = re.compile("[`|'|\"][\w]*[`|'|\"][ ][\w]*")  # match
char_regex = re.compile("char[(][\d]*[)]")  # match char and varchar
decimal_regex = re.compile("decimal[(][\d]*,\d*[)]")  # matches decimal
final_regex = re.compile("[`|'|\"][\w]*[`|'|\"][ ]*.*[)][ ]*$")  # final
vname_regex = re.compile("[`|'|\"]([\w]*)[`|'|\"]")


def get_data_type_for_line(temp_line=""):
    m = global_regex.search(temp_line)
    n = char_regex.search(temp_line)
    k = decimal_regex.search(temp_line)
    if m or n or k:
        found_data_type = False
        for dataType in dataTypeKeys:
            if dataType in temp_line:
                if dataType == " char" or dataType == " varchar":
                    el_type = n.group(0)
                    return el_type
                elif dataType == "decimal":
                    el_type = "decimal"
                    if k and len(k.group()):
                        el_type = k.group(0)
                    return el_type
                else:
                    return dataType
                break
        if not found_data_type:
            print("Error: Could not parse data type for: " + temp_line + "\n")
            exit(1)


def get_column_name_for_line(temp_line=""):
    vn = vname_regex.search(temp_line)
    if vn and len(vn.groups()) == 1:
        return vn.group(1)
    print("Error: Could not parse column name: ") + temp_line
    exit(1)


now = time.time()
print ("\n")
print ("Parsing input schema")
try:
    with open(inFile, "r") as i:
        orgLines = i.readlines()
except:
    print ("Error: Could not open ") + inFile
    exit(1)

# Clean the schema
emptyRegex = re.compile("^[ |\t]*$")
lines = []
for line in orgLines:

    line = line.replace(u'\xa0', '')
    #line = line.replace(u'\x2c', '')
    line = str(line)
    if "------------------" in line:
        continue
    elif "     createtab_stmt    " in line:
        continue
    elif emptyRegex.search(line):
        continue

    lines.append(line.replace("|", ""))

print ("\nChecking main columns")
columnsToGen2 = OrderedDict()
lastLine = ""

tName = ""
isExternal = ""
isOrc = False
for line in lines:

    ff = final_regex.search(lastLine)
    if ff:
        break
    elif create_regex.search(line):
        cc = create_regex.search(line)
        tName = cc.group(1)
        if "external" in line.lower():
            isExternal = "EXTERNAL";
        continue
    else:
        columnsToGen2[get_column_name_for_line(line)] = get_data_type_for_line(line)

    lastLine = line
    if "orc" in line:
        isOrc = True

if dbName == "":
    dbName = tName.split(".")[0] if len(tName.split(".")) == 2 else "default"

tNameArr = tName.split(".")
if len(tNameArr) == 2:
    tName = tNameArr[1]
else:
    tName = tNameArr[0]
print ("     " + str(len(columnsToGen2)) + " columns found.")

# CHECK IF THERE ARE PARTITION COLUMNS
print( "\nChecking partitions")
hasPartition = False
lastLine = ""
partitionsToGen2 = OrderedDict()

partReg = re.compile("[`|'|\"](\w*)[`|'|\"] ", re.IGNORECASE)
for line in lines:
    if hasPartition:
        ff = final_regex.search(lastLine)
        if ff:
            break
        else:
            partitionsToGen2[get_column_name_for_line(line)] = get_data_type_for_line(line)

    lastLine = line

    if "PARTITIONED BY" in line:
        hasPartition = True

if len(partitionsToGen2):
    print ("     " + str(len(partitionsToGen2)) + " partitions found.")
else:
    print ("     " +  "No partitions found.")

# CHECK FIELD DELIMITERS
# print "\nChecking delimiters"
# if not isOrc:
#     fDelimiter = get_field_delimiter(lines)
#     if fDelimiter == '':
#         print "     Fields delimiter not found, will use standard ','."
#         fDelimiter = ','
#     else:
#         print "     Found fields delimiter: '" + fDelimiter + "'."
# else:
#     print "Table is ORC, will use standard delimiter: ','."

######## GENERATE DUMMY DATA FILE ########
print ("")
print ("Generating " + str(numRows) + " rows for " + str(len(columnsToGen2)) + "\n columns and " + str(len(partitionsToGen2)) + " partitions in table " + tName + ".")

char = re.compile("char[(](\d*)[)]")
deci = re.compile("decimal[(](\d*),(\d*)[)]")


# Gen Amount of difs partitions vector based on input
newDifsPartitions = []
if len(difsPartitions) != len(partitionsToGen2):
    lenDifs = len(difsPartitions)
    lenPart = len(partitionsToGen2)
    i = 0
    for part in partitionsToGen2:
        if i < lenDifs:
            newDifsPartitions.append(int(difsPartitions[i]))
        else:
            newDifsPartitions.append(0)
        i = i + 1
else:
    for num in difsPartitions:
        newDifsPartitions.append(int(num))

# Generate diferent partitions
partsValsDic = {}
i = 0
if hasPartition and len(difsPartitions) != 0:
    for colName in partitionsToGen2:
        partsVals = []
        for p in range(newDifsPartitions[i]):
            partsVals.append(get_value_for_type(partitionsToGen2[colName], char, deci))
        partsValsDic[colName] = partsVals
        i = i + 1

with open(outFile, 'w') as o:
    for z in range(numRows + 1):
        tempRow = ""
        for colName in columnsToGen2:
            tempRow = tempRow + get_value_for_type(columnsToGen2[colName], char, deci) + fDelimiter
        zz = 0
        for colName in partitionsToGen2:
            if newDifsPartitions[zz] != 0:
                partsVals = partsValsDic[colName]
                t_int = int(get_value_for_type("int", char, deci)) % (newDifsPartitions[zz])
                tempRow = tempRow + partsVals[t_int] + fDelimiter
                zz = zz + 1
            else:
                tempRow = tempRow + get_value_for_type(partitionsToGen2[colName], char, deci) + fDelimiter

        tempRow = tempRow[:-1]
        if z != numRows:
            tempRow = tempRow + rDelimiter

        o.write(tempRow)

######## GENERATE INFORMATION AND SCRIPTS ########

schema = ""
# Enable dynamic partitioning
schema = schema + "set hive.exec.dynamic.partition=true;\n"
schema = schema + "set hive.exec.dynamic.partition.mode=nonstrict;\n\n"
# Set the database
schema = schema + "CREATE DATABASE IF NOT EXISTS " + dbName + ";\n"
schema = schema + "USE " + dbName + ";\n"

# Generate the input schema without the location if it specifies.""
lastLine = ""
for line in lines:
    if "location  " in line.lower():
        lastLine = line
        continue
    elif "hdfs://" in line.lower() and ("location  " in lastLine.lower() or "hdfs://" in lastLine.lower()):
        lastLine = line
        continue

    if "create " in line.lower() and " table " in line.lower():
        schema = schema + "CREATE " + isExternal + " TABLE IF NOT EXISTS `" + dbName + "`.`" + tName + "`(\n\n"
        lastLine = line
        continue
    schema = schema + line
    lastLine = line

schema = schema + ";\n\n\n"
# Create Statement for dummy schema
schema = schema + "CREATE " + isExternal + " TABLE IF NOT EXISTS `" + dbName + "`.`" + tName + tablePostfix + "`(\n\n"
# Main Columns
colNum = 0
numCols = len(columnsToGen2)
for colName in columnsToGen2:
    schema = schema + " `" + colName + "` " + columnsToGen2[colName]
    if colNum == numCols-1 and not hasPartition:
        schema = schema + ")\n"
    else:
        schema = schema + ",\n"

    colNum = colNum + 1

# Partition Columns
partNum = 0
numParts = len(partitionsToGen2)
for parName in partitionsToGen2:
    schema = schema + " `" + parName + "` " + partitionsToGen2[parName]
    if partNum == numParts-1:
        schema = schema + ")\n"
    else:
        schema = schema + ",\n"

    partNum = partNum + 1

# Delimiters
schema = schema + " ROW FORMAT DELIMITED FIELDS TERMINATED BY " + "'" + fDelimiter + "'\n"
schema = schema + " LINES TERMINATED BY '\\n'\n"
schema = schema + " STORED AS TEXTFILE\n"

# create path to your username on hdfs
hdfs_path = os.path.join(os.sep, 'tmp')
hdfs_file = os.path.join(os.sep, 'tmp', "HiveRandom.csv")

# put csv into hdfs
put = Popen(["hdfs", "dfs", "-put", outFile, hdfs_path], stdin=PIPE, bufsize=-1)
put.communicate()

# Load data stage
load = "\nLOAD DATA INPATH '" + hdfs_file + "' INTO TABLE " + dbName + "." + tName + tablePostfix + ";\n"
load = load + "\nINSERT INTO TABLE " + tName

if hasPartition:
    load = load + " PARTITION("
    for partition in partitionsToGen2:
        load = load + partition + ","
    load = load[:-1]
    load = load + ") "

load = load + " SELECT "
for colName in columnsToGen2:
    load = load + colName + ", "

if hasPartition:
    parts = ""
    for partition in partitionsToGen2:
        parts = parts + partition + ","
    parts = parts[:-1]
    load = load  + parts
else:
    load = load[:-2]
load = load + " FROM " + tName + tablePostfix + ";\n\n"

schema = schema + ";\n"
schema = schema + load + "\n"
with open(outScript, 'w') as o:
        o.write(schema)

print ("\nAll done. Please execute: \n\t $ beeline -f HiveRandom.hql\n")

later = time.time()
difference = int(later - now)

print ("Time: " + str(difference) + " s.")