import pandas as pd
from pathlib import Path


class StatParquet:

    def __init__(self):
        pass

    def count_records_by_accession(self,parquet_folder):
        """
        Count the number of records for each accession across multiple Parquet files.

        :param parquet_folder: Path to the folder containing Parquet files.
        :return: A DataFrame with accession and their respective counts.
        """
        parquet_files = Path(parquet_folder).glob("*.parquet")
        accession_counts = {}

        for file in parquet_files:
            # Read the Parquet file into a DataFrame
            df = pd.read_parquet(file)

            # Group by accession and count the records
            counts = df.groupby('accession').size()

            # Update the global accession_counts dictionary
            for accession, count in counts.items():
                accession_counts[accession] = accession_counts.get(accession, 0) + count

        # Convert the counts dictionary to a DataFrame
        result_df = pd.DataFrame(list(accession_counts.items()), columns=['accession', 'record_count'])
        return result_df
