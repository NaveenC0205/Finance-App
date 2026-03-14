import os
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import io
import parser_engine

app = FastAPI(title="Family Expense Tracker API")

# Allow requests from the local Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Transaction(BaseModel):
    id: str
    date: str
    person: str
    bank: str
    description: str
    amount: float
    type: str # 'Income' or 'Expense'
    category: str

@app.get("/")
def read_root():
    return {"status": "Family Expense Tracker Backend Running"}

@app.post("/upload")
async def upload_statement(
    file: UploadFile = File(...),
    person: str = Form(...),
    bank: str = Form(...)
):
    try:
        content = await file.read()
        filename = file.filename.lower()
        
        parsed_transactions = []
        
        if filename.endswith(".csv"):
            parsed_transactions = parser_engine.parse_csv(content, person, bank)
        elif filename.endswith((".xls", ".xlsx")):
            parsed_transactions = parser_engine.parse_excel(content, person, bank)
        elif filename.endswith(".pdf"):
            parsed_transactions = parser_engine.parse_pdf(content, person, bank)
        else:
            raise HTTPException(status_code=400, detail="Unsupported file type")
            
        return {
            "message": f"Successfully parsed {len(parsed_transactions)} transactions.",
            "transactions": parsed_transactions
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
