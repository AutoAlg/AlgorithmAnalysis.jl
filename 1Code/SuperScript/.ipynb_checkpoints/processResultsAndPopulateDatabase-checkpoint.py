import pandas as pd
import os
import json
import re
from openpyxl import load_workbook
import psutil
import GPUtil
from datetime import datetime
import platform
import math

# Function to generate a unique ID for each batch or run
def generateUniqueId(excelFilePath, sheetName):
    # Check if the Excel file exists
    if os.path.exists(excelFilePath):
        # Load the existing Excel file and sheet
        excelData = pd.read_excel(excelFilePath, sheet_name=sheetName)

        # Check if the sheet has any data
        if len(excelData) > 0:
            # Get the last UniqueID
            lastUid = excelData['Unique ID'].iloc[-1]

            # Validate lastUid before proceeding
            if isinstance(lastUid, str) and len(lastUid) >= 2:
                # Increment the numeric part of the ID by 1
                lastIdNum = int(lastUid[2:])  # Extract numeric part (remove "JL")
                newIdNum = lastIdNum + 1  # Increment by 1
                newUid = f"JL{newIdNum:06d}"  # Zero-pad the new ID to maintain 6 digits
            else:
                # If lastUid is not valid, start with the initial ID
                newUid = "JL000000"
        else:
            # If the sheet exists but has no data
            newUid = "JL000000"
    else:
        # If the file does not exist
        newUid = "JL000000"

    return newUid

def extractPerformanceMetrics(output):
    # Split the output into lines
    lines = output.splitlines()

    # Initialize variables to store extracted values
    setupTime, algorithmTime, optimTime, ramUsage, threadCount = None, None, None, None, None

    # Use regex to find and extract the values
    for line in lines:
        if "Setup Time" in line:
            setupTime = float(re.search(r"[-+]?\d*\.\d+|\d+", line).group())  # Extract the float number
        elif "Algorithm Computation Time" in line:
            algorithmTime = float(re.search(r"[-+]?\d*\.\d+|\d+", line).group())  # Extract the float number
        elif "Optimization Time" in line:
            optimTime = float(re.search(r"[-+]?\d*\.\d+|\d+", line).group())  
        elif "RAM Usage" in line:
            ramUsage = float(re.search(r"[-+]?\d*\.\d+|\d+", line).group())  # Extract the float number
        elif "Threads Used" in line:
            threadCount = float(re.search(r"[-+]?\d*\.\d+|\d+", line).group())

    return setupTime, algorithmTime, optimTime, ramUsage, threadCount

def prepareDataPoint(batchFolder, runIndex, logContents, batchInfo, excelFilePath, sheetName):
    # Generate a unique ID for the row
    uniqueId = generateUniqueId(excelFilePath, sheetName)

    # Extract performance metrics from log
    setupTime, algorithmTime, optimTime, ramUsage, threadCount = extractPerformanceMetrics(logContents)

    # Calculate total script run time
    totalRunTime = setupTime + algorithmTime + optimTime

    # Detect CPU and RAM information using psutil
    cpuInfo = platform.processor()  # Get CPU model name
    ramInfo = f"{math.ceil(psutil.virtual_memory().total / (1024 ** 3))} GB"  # Get total RAM in GB

    # Detect GPU information using GPUtil
    gpus = GPUtil.getGPUs()  # Get list of all GPUs
    if gpus:
        gpuInfo = ', '.join([f"{gpu.name}" for gpu in gpus])  # Concatenate GPU names
    else:
        gpuInfo = "No compatible GPU detected"

    batchId = batchFolder.replace('Batch', 'B')  # Replace 'Batch' with 'B'
    runId = f"R{str(runIndex+1).zfill(3)}"  # Replace 'Run' with 'R' and zero-pad to 3 digits

    # Prepare the data row with all necessary information
    dataRow = [
        uniqueId,  # Unique ID
        batchId,  # Batch ID
        runId,  # Run ID
        datetime.now().strftime("%m/%d/%Y"),  # Date
        batchInfo["Language"],  # Language Version
        cpuInfo,  # CPU Information
        ramInfo,  # RAM Information
        gpuInfo,  # GPU Information
        batchInfo["Compute Media"],  # Compute Media
        batchInfo["Concurrency Mode"],  # Concurrency Mode
        batchInfo["Threads Used"],  # Threads Used
        batchInfo["Algorithm Type"],  # Algorithm Type
        batchInfo["Number of Steps"],  # Number Of Iterations
        setupTime,  # Preprocessing Time (s)
        algorithmTime,  # Algorithm Time (s)
        optimTime,  # Optimization Time (s)
        totalRunTime,  # Total Script Run Time (s)
        ramUsage  # RAM Used (MB)
    ]

    return dataRow


def appendDataPointToDatabase(dataList, excelFilePath, sheetName):
    try:
        # Load the existing workbook
        book = load_workbook(excelFilePath)
        # Select the specified sheet
        sheet = book[sheetName]

        # Append the new data as a row
        sheet.append(dataList)
        # Save the file
        book.save(excelFilePath)
    except Exception as e:
        print(f"An error occurred: {e}")

def processLogFiles():
    # Define the base path for the logs
    logsBasePath = "S:\\Research Material\\CSE\\MU\\Project\\6Logs"
    excelFilePath = "S:\\Research Material\\CSE\\MU\\Project\\2Database\\Database.xlsx"

    # Iterate over each batch folder
    for batchFolder in os.listdir(logsBasePath):
        batchFolderPath = os.path.join(logsBasePath, batchFolder)

        # Only process if it is a directory
        if os.path.isdir(batchFolderPath) and batchFolder.startswith('Batch'):
            # Read the configuration from the JSON file
            jsonFilePath = os.path.join(batchFolderPath, "BatchInfo.json")
            with open(jsonFilePath, 'r', encoding='utf-8') as jsonFile:
                batchInfo = json.load(jsonFile)

            # Extract configuration details
            language = batchInfo["Language"]
            sheetName = language  # Use language as the sheet name

            runsPerBatch = batchInfo["Runs Per Batch"]

            # Process each log file in the batch folder
            for runIndex in range(runsPerBatch):
                logFilePath = os.path.join(batchFolderPath, f"Run#{runIndex+1}.log")
                if os.path.exists(logFilePath):
                    with open(logFilePath, 'r', encoding='utf-8') as logFile:
                        logContents = logFile.read()

                    # Check if the log file contains valid benchmarking results
                    if "------ BENCHMARKING RESULTS ------" in logContents and "ERROR" not in logContents:
                        # Valid results found, prepare data point for this run
                        newDataPoint = prepareDataPoint(batchFolder, runIndex, logContents, batchInfo, excelFilePath, sheetName)
                    else:
                        # If no valid results or an error, set all metrics to "N/A"
                        newDataPoint = [
                            generateUniqueId(excelFilePath, sheetName),  # Unique ID
                            batchFolder.replace('Batch', 'B'),  # Batch ID
                            f"R{str(runIndex+1).zfill(3)}",  # Run ID
                            datetime.now().strftime("%m/%d/%Y"),  # Date
                            batchInfo["Language"],  # Language Version
                            "N/A",  # CPU Information
                            "N/A",  # RAM Information
                            "N/A",  # GPU Information
                            batchInfo["Compute Media"],  # Compute Media
                            batchInfo["Concurrency Mode"],  # Concurrency Mode
                            batchInfo["Threads Used"],  # Threads Used
                            batchInfo["Algorithm Type"],  # Algorithm Type
                            batchInfo["Number of Steps"],  # Number Of Iterations
                            "N/A",  # Preprocessing Time (s)
                            "N/A",  # Algorithm Time (s)
                            "N/A",  # Optimization Time (s)
                            "N/A",  # Total Script Run Time (s)
                            "N/A"  # RAM Used (MB)
                        ]

                    # Append the data to the Excel file
                    appendDataPointToDatabase(newDataPoint, excelFilePath, sheetName)

def main():
    processLogFiles()
    print("Database Updated!")

if __name__ == "__main__":
    main()
