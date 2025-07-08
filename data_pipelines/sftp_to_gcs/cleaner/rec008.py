import pandas as pd

def clean(df):
    # Standardize column names
    df.columns = [c.replace(" ", "_") for c in df.columns]

    # Convert OrderDate column to YYYY-MM-DD
    if "OrderDate" in df.columns:
        df["OrderDate"] = pd.to_datetime(df["OrderDate"], errors="coerce").dt.strftime("%Y-%m-%d")

    # Clean Bottle_Quantity column
    if "Bottle_Quantity" in df.columns:
        df["Bottle_Quantity"] = pd.to_numeric(df["Bottle_Quantity"], errors="coerce").fillna(0).astype(int)

    return df
