# Cleaning a Messy Orders File with Power Query

I cleaned a raw text file of 5,000 orders using Power Query M in Excel. The file had mixed delimiters, dates in different formats, city names spelled in many ways, and phone numbers that were not consistent. The final result is one clean table that is ready for analysis.

## The Problem

The orders came as a single `.txt` file. You can't just open it in Excel and start working, because:

- Columns are separated by different delimiters.
- Some rows have extra spaces.
- Dates are written as `11/07/2025`, `2025.07.11`, `2025-07-11`, and `Sep 5, 2025`.
- The same city is written in more than one way (for example `Cairo`, `القاهره` and `القاهرة`).
- Phone numbers have dashes, spaces, or a country code (`+20`, `0020`).
- Some rows are missing values.

## What I Found and How I Fixed It

| Problem | Fix |
|---|---|
| Mixed delimiters (tab, `;`, ` - `, `,`) | Replaced all of them with one delimiter, then split each line |
| Comma inside dates (`Sep 5, 2025`) | Removed that comma before splitting, so the date stays in one column |
| Extra spaces | Trimmed every value |
| 4 different date formats | One function that checks the format and converts to a real date |
| City spelled in different ways | A small lookup list that maps every spelling to one correct name |
| Messy phone numbers | Kept digits only, removed the country code, made all numbers start with `0` |
| Amount written as text (`3200 EGP`) | Removed `EGP` and changed the column to a whole number |
| Rows with missing columns | Filled the missing date and status with `null` so the columns line up, then removed the rows with no status (they have no date either) |

## Results

- I started with 5,000 rows.
- I removed 250 rows that had no status and no order date. A row like that has no real order information, so I did not keep it.
- The final table has 4,750 rows.
- Every date is now a real date, every phone number looks like `01xxxxxxxxx`, and each city has one spelling.

*(Screenshots of the data before and after are in the `Screenshots` folder.)*

## How It Works

The whole cleaning is one Power Query (M) script. These are the main steps:

1. Read the file line by line.
2. Split each line into 7 columns (`OrderID`, `Customer`, `Phone`, `City`, `OrderDate`, `Status`, `Amount_EGP`).
3. Clean each column with its own function (`CleanPhone`, `FixCity`, `ParseOrderDate`).
4. Filter out the rows where `Status` is empty (these rows have no order date either).
5. Set the correct data type for each column.

The file path is not written inside the code. It comes from a parameter called `FilePath`, so you can change the path in one place without touching the script.

## How to Use It

1. Open Excel and go to **Data > Get Data > Launch Power Query Editor**.
2. Create a parameter called `FilePath` (**Manage Parameters > New Parameter**, type Text) and put the path to the `.txt` file as the value.
3. Create a blank query, open **Advanced Editor**, and paste the code from `Clean_Orders.m`.
4. Click **Close & Load**.

## Tools

Excel, Power Query (M language)

## Files

- `Clean_Orders.pq`: the Power Query script
- `clean orders.xlsx`: the cleaned table
- `Screenshots/`: before and after
