import pandas as pd
import pdfplumber
import io
import uuid

def parse_csv(file_content, person, bank):
    df = pd.read_csv(io.BytesIO(file_content))
    return _normalize_dataframe(df, person, bank)

def parse_excel(file_content, person, bank):
    df = pd.read_excel(io.BytesIO(file_content))
    return _normalize_dataframe(df, person, bank)

def parse_pdf(file_content, person, bank):
    # This is a very basic PDF table extraction.
    # Real-world bank PDFs require custom layouts per bank, but pdfplumber usually finds tables.
    transactions = []
    with pdfplumber.open(io.BytesIO(file_content)) as pdf:
        for page in pdf.pages:
            tables = page.extract_tables()
            for table in tables:
                if not table:
                    continue
                # Assume first row is header, but real-world needs robustness
                df = pd.DataFrame(table[1:], columns=table[0])
                transactions.extend(_normalize_dataframe(df, person, bank))
    return transactions

def _normalize_dataframe(df, person, bank):
    # This attempts to find common columns.
    # Real-world: Need a mapping config for each bank (e.g. "Transaction Date" -> "date")
    
    # Lowercase headers for easier matching
    df.columns = [str(c).lower().strip() for c in df.columns]
    
    normalized = []
    
    # Very naive column guessing
    date_col = next((c for c in df.columns if 'date' in c), None)
    desc_col = next((c for c in df.columns if 'desc' in c or 'narrative' in c or 'particulars' in c), None)
    
    # Some banks have 1 'amount' col, others have 'debit' and 'credit'
    debit_col = next((c for c in df.columns if 'debit' in c or 'withdrawal' in c), None)
    credit_col = next((c for c in df.columns if 'credit' in c or 'deposit' in c), None)
    amount_col = next((c for c in df.columns if 'amount' in c), None)

    for _, row in df.iterrows():
        # Skip if essential columns are missing
        if not date_col or not desc_col:
            continue
            
        date_val = str(row.get(date_col, ''))
        desc_val = str(row.get(desc_col, ''))
        
        amount = 0.0
        t_type = 'Expense' # Default
        
        if debit_col and pd.notna(row.get(debit_col)):
            val = str(row.get(debit_col)).replace(',', '')
            try:
                amount = float(val)
                t_type = 'Expense'
            except ValueError:
                pass
        elif credit_col and pd.notna(row.get(credit_col)):
            val = str(row.get(credit_col)).replace(',', '')
            try:
                amount = float(val)
                t_type = 'Income'
            except ValueError:
                pass
        elif amount_col and pd.notna(row.get(amount_col)):
            val = str(row.get(amount_col)).replace(',', '')
            try:
                amount = float(val)
                if amount < 0:
                    t_type = 'Expense'
                    amount = abs(amount)
                else:
                    t_type = 'Income'
            except ValueError:
                pass
                
        # Skip invalid amounts
        if amount == 0.0:
            continue
            
        category = _categorize_transaction(desc_val)

        normalized.append({
            "id": str(uuid.uuid4()),
            "date": date_val,
            "person": person,
            "bank": bank,
            "description": desc_val,
            "amount": amount,
            "type": t_type,
            "category": category
        })
        
    return normalized

def _categorize_transaction(description: str) -> str:
    desc = description.lower()
    if any(word in desc for word in ['zomato', 'swiggy', 'restaurant', 'mcdonalds', 'kfc']):
        return 'Food'
    elif any(word in desc for word in ['grocery', 'supermarket', 'mart', 'reliance fresh', 'bigbasket']):
        return 'Groceries'
    elif any(word in desc for word in ['fuel', 'petrol', 'hpcl', 'bharat petroleum', 'shell']):
        return 'Fuel'
    elif any(word in desc for word in ['uber', 'ola', 'irctc', 'make my trip', 'airlines']):
        return 'Travel'
    elif any(word in desc for word in ['netflix', 'amazon prime', 'hotstar', 'movie', 'pvr']):
        return 'Entertainment'
    elif any(word in desc for word in ['amazon', 'flipkart', 'myntra', 'zara', 'h&m']):
        return 'Shopping'
    elif any(word in desc for word in ['electricity', 'water', 'bescom', 'jio', 'airtel', 'recharge']):
        return 'Utilities'
    elif any(word in desc for word in ['rent']):
        return 'Rent'
    elif any(word in desc for word in ['emi', 'loan']):
        return 'EMI'
    elif any(word in desc for word in ['zerodha', 'groww', 'mutual fund', 'sip']):
        return 'Investments'
    else:
        return 'Others'
