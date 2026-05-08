import pandas as pd

def clean(df):
    df.columns = [c.replace(" ", "_") for c in df.columns]
    # Add custom logic for rec013 here
    return df
