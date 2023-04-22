import argparse
import os

import shutil
import subprocess
import zipfile
import datetime
import pandas as pd
from DataCollector.Miners import miners_list





def compress_folder(folder_path, output_path):
    """Compresses all the files in a folder into a zip archive"""
    # Create a ZipFile object
    with zipfile.ZipFile(output_path, 'w') as zip_obj:
        # Iterate through all the files in the folder
        for root, dirs, files in os.walk(folder_path):
            for file in files:
                file_path = os.path.join(root, file)
                zip_obj.write(file_path, os.path.relpath(file_path, folder_path))




tmp_data_path = "./tmp_data"
backup_data_path = "./backup_data"
data_path = "DataVisualizer/data"


parser = argparse.ArgumentParser(description='Collect information on a topic from leading scientific publishers and visualize it ')
group = parser.add_mutually_exclusive_group()
group.add_argument('-c', '--collect', nargs=3, metavar=('term', 'start_year', 'end_year'),
                   type=str, help='Collect term information from start_year to end_year:  scientific_analyzer.py -c "blockchain" 2013 2022')
group.add_argument('-v', '--visualizer', action='store_true', help='Open a shiny app with the latest data collected')
group.add_argument('-l', '--load', action='store_true', help='Transfer the data you recently gathered in \'./tmp_data\' to the parser')
args = parser.parse_args()



if args.collect:
    term = args.collect[0]
    start_year = int(args.collect[1])
    end_year = int(args.collect[2])
    print("Option A chosen with arguments:", args.collect)
    print("term: {}  \nSyear: {} \nEdata: {}".format(term, start_year, end_year))

    # Clean tmp_data
    # Delete all csv files in the destination folder
    files = [f for f in os.listdir(tmp_data_path) if f.endswith(".csv")]
    for f in files:
        os.remove(os.path.join(tmp_data_path, f))

    # Save search term on .csv
    with open(tmp_data_path + "/term.csv", "w") as f:
        f.write(term)

    # Save search term on .csv
    with open(tmp_data_path + "/time.csv", "w") as f:
        f.write(datetime.datetime.now().strftime("%Y-%m-%d"))


    for MinerClass in miners_list:
        miner = MinerClass(term, start_year, end_year, tmp_data_path)
        miner.run()

    print()
    print()
    print()
    print("__________________________")
    print("Please execute the \'scientific_analyzer.py -l\' command to transfer the data you recently gathered in './tmp_data' to the parser.")
    print("__________________________")
    print()
    print()
    print()


elif args.visualizer:
    #print("Option B chosen with no additional arguments")
    res = subprocess.call('R -e "shiny::runApp(\'./DataVisualizer\')"', shell=True)
    res
    #os.system('R -e "shiny::runApp(\'~/DataVisualizer\')"')
    #
elif args.load:
    print("LOADING...")

    # OLD DATA BACKUP
    # Get the current date in the format YYYY-MM-DD
    current_date = datetime.datetime.now()
    # Define the name of the output archive
    output_path = backup_data_path+"/old_data_{}.zip".format(current_date)
    # Compress the folder
    compress_folder(data_path, output_path)

    # Delete all csv files in the destination folder
    files = [f for f in os.listdir(data_path) if f.endswith(".csv")]
    for f in files:
        os.remove(os.path.join(data_path, f))


    all_files = [f for f in os.listdir(tmp_data_path) if f.endswith("_data.csv")]

    df_list = []
    for file in all_files:
        df = pd.read_csv(os.path.join(tmp_data_path, file), dtype={'year': int, 'title': str, 'citations': int, 'authors': str, 'editorial': str})
        df_list.append(df)
    merged_df = pd.concat(df_list)
    merged_df.to_csv(os.path.join(data_path, "all.csv"), index=False)

    shutil.copy(tmp_data_path + "/time.csv", data_path + "/time.csv")
    shutil.copy(tmp_data_path + "/term.csv", data_path + "/term.csv")
    print("LOADED")
else:
    print()
    print()
    print("Run scientific_analyzer.py -h")
    print()
    print()