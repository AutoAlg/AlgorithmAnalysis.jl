import os
import subprocess
import re
import json
import sys

def findLatestBatchNumber(logsBasePath):
    """
    Finds the latest batch number by checking the existing batch folders.
    """
    # List all subdirectories in the logs base path
    subdirs = [d for d in os.listdir(logsBasePath) if os.path.isdir(os.path.join(logsBasePath, d))]

    # Filter out batch folders using regex (format: Batch followed by digits)
    batchFolders = sorted([d for d in subdirs if re.match(r"Batch\d{3}$", d)])

    if batchFolders:
        # Get the latest batch number
        latestBatch = batchFolders[-1]
        latestBatchNumber = int(latestBatch.replace("Batch", ""))
    else:
        # If no batch folders exist, start with Batch001
        latestBatchNumber = 0

    return latestBatchNumber

def writeBatchInfoJson(batchFolderPath, batchInfo):
    """
    Writes the batch information to a JSON file in the specified folder.
    """
    # Path for the JSON file
    jsonFilePath = os.path.join(batchFolderPath, "BatchInfo.json")
    
    # Write the batch information to a JSON file
    with open(jsonFilePath, 'w', encoding='utf-8') as jsonFile:
        json.dump(batchInfo, jsonFile, ensure_ascii=False, indent=4)

def runJuliaBatches(numberOfBatches, runsPerBatch, coresUsed, numberOfIterations, language, computeMedia, concurrencyMode, algorithmType):
    """
    Runs the Julia batches and ensures all metadata is captured and saved.
    """
    # Define the base path to the Julia script
    basePath = "S:\\Research Material\\CSE\\MU\\Project\\1Code\\AlgorithmAnalysis.jl\\1CPU\\src"
    juliaScriptPath = os.path.join(basePath, "startupCPU.jl")

    # Base folder for logs
    logsBasePath = "S:\\Research Material\\CSE\\MU\\Project\\6Logs"

    # Find the latest batch number once at the start
    latestBatchNumber = findLatestBatchNumber(logsBasePath)

    for batchIndex in range(numberOfBatches):
        # Increment the batch number
        nextBatchNumber = latestBatchNumber + 1
        batchId = f"Batch{str(nextBatchNumber).zfill(3)}"

        # Define the batch folder path
        batchFolderPath = os.path.join(logsBasePath, batchId)

        # Ensure the folder exists for the current batch
        os.makedirs(batchFolderPath, exist_ok=True)

        # Metadata information for the current batch
        batchInfo = {
            "Batch ID": batchId,
            "Runs Per Batch": runsPerBatch,
            "Language": language,
            "Compute Media": computeMedia,
            "Concurrency Mode": concurrencyMode,
            "Threads Used": coresUsed,
            "Algorithm Type": algorithmType,
            "Number of Steps": numberOfIterations
        }

        # Write the batch information to a JSON file
        writeBatchInfoJson(batchFolderPath, batchInfo)

        # Construct the command to run the Julia script
        juliaCommand = [
            'julia',  # Julia executable
            juliaScriptPath,  # Path to the Julia script
            str(coresUsed),  # Number of threads
            str(numberOfIterations),  # Number of iterations
            batchFolderPath,  # Path to the batch folder
            str(runsPerBatch)  # Number of runs per batch
        ]

        print(f"Starting new batch {batchId} with command: {' '.join(juliaCommand)}")

        # Call the Julia script via subprocess
        process = subprocess.Popen(juliaCommand, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        stdout, stderr = process.communicate()

        # Output handling
        if process.returncode == 0:
            print(f"Batch {batchId} completed successfully.")
        else:
            print(f"Batch {batchId} encountered an error.")
            print("Error details:", stderr)

        # Ensure the Julia session is closed after each batch
        print(f"Completed batch {batchId}. Moving to the next batch...")

        # Update the latest batch number for the next iteration
        latestBatchNumber = nextBatchNumber

    print("All batches have been processed.")

def main():
    runsPerBatch = int(sys.argv[2])           # Number of runs per batch
    numberOfBatches = 1                       # Number of batches
    language = sys.argv[3]                    # Language (e.g., 'Julia')
    computeMedia = sys.argv[4]                # Compute media (e.g., 'CPU')
    concurrencyMode = sys.argv[5]             # Concurrency mode (e.g., 'Single-Core')
    coresUsed = int(sys.argv[6])              # Number of cores used
    algorithmType = sys.argv[7]               # Algorithm type (e.g., 'Gradient Descent')
    numberOfIterations = int(sys.argv[8])     # Number of iterations

    print(f"Runs Per Batch: {runsPerBatch}, Language: {language}, Compute Media: {computeMedia}, "
          f"Concurrency Mode: {concurrencyMode}, Cores Used: {coresUsed}, Algorithm Type: {algorithmType}, "
          f"Number of Iterations: {numberOfIterations}")

    # Run all Julia scripts to generate log files
    runJuliaBatches(numberOfBatches, runsPerBatch, coresUsed, numberOfIterations, language, computeMedia, concurrencyMode, algorithmType)

if __name__ == "__main__":
    main()
