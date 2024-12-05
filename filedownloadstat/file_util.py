import os
import sys
from pathlib import Path
from log_parser import LogParser
from parquet_writer import ParquetWriter


class FileUtil:

    def __init__(self):
        pass

    def get_file_paths(self, root_dir):
        """
        Traverse the directory tree and retrieve all file paths.
        Handles variable folder depth safely using pathlib.
        :param root_dir: Root directory to start traversal.
        :return: List of file paths.
        """
        root_path = Path(root_dir)
        return [str(file) for file in root_path.rglob("*.tsv.gz")]

    def process_access_methods(self, root_directory: str, file_paths_list: str, protocols: list):
        """
        Process logs and generate Parquet files for each file in the specified access method directories.
        """

        file_paths = []

        for protocol in protocols:
            method_directory = Path(root_directory) / protocol / "public"
            files = self.get_file_paths(str(method_directory))

            for file_path in files:
                file_paths.append(file_path)

        # Write the array to a file
        with open(file_paths_list, "w") as f:
            for path in file_paths:
                f.write(path.strip() + '\n')  # Ensure no extra whitespace or newlines

        print(f"File paths written to {file_paths_list}")
        return file_paths_list

    def process_log_file(self, file_path: str, parquet_output_file: str, resource_list: list, completeness_list: list, batch_size: int):
        data_written = False
        try:
            print(f"Parsing log file started: {file_path}")

            if not os.path.exists(file_path):
                raise FileNotFoundError(f"Input file does not exist: {file_path}")

            print(f"Parsing file and writing output to {parquet_output_file}")

            lp = LogParser(file_path, resource_list, completeness_list)
            writer = ParquetWriter(parquet_path=parquet_output_file, write_strategy='batch', batch_size=batch_size)

            for batch in lp.parse_gzipped_tsv(batch_size=batch_size):
                if writer.write_batch(batch):
                    data_written = True

            # Finalize and check if any data was written
            if writer.finalize():
                data_written = True

            if data_written:
                print(f"Parquet file written to {parquet_output_file} for {file_path}")
            else:
                print(f"No data found to write :  {file_path}")
        except Exception as e:
            print(f"Error while processing file: {e}", file=sys.stderr)
            sys.exit(1)
