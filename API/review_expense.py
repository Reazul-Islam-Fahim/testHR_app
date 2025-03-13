from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Allow all origins for simplicity (you can customize this for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
)


# Dummy database to store expense requests
expense_requests_db = [
    {
        "id": "1",
        "startDate": "2023-10-01",
        "endDate": "2023-10-05",
        "category": "Travel",
        "amount": 15000,
        "comments": "Business trip to CTG",
        "attachments": [
            "https://example.com/receipt1.pdf",
            "https://example.com/receipt2.pdf"
        ],
        "status": "Pending"
    },
    {
        "id": "2",
        "startDate": "2023-10-10",
        "endDate": "2023-10-13",
        "category": "Food",
        "amount": 7550,
        "comments": "Team lunch",
        "attachments": [
            "https://example.com/receipt3.pdf"
        ],
        "status": "Pending"
    }
]

# Pydantic model for expense request
class ExpenseRequest(BaseModel):
    id: str
    startDate: str
    endDate: str
    category: str
    amount: float
    comments: str
    attachments: List[str]
    status: str

# Pydantic model for updating expense status
class UpdateExpenseStatus(BaseModel):
    expenseId: str
    status: str

# API to fetch all expense requests
@app.get("/api/expense-requests", response_model=List[ExpenseRequest])
def get_expense_requests():
    return expense_requests_db

# API to update expense status
@app.post("/api/update-expense-status")
def update_expense_status(request: UpdateExpenseStatus):
    expense_id = request.expenseId
    new_status = request.status

    # Find the expense request in the database
    expense_request = next((er for er in expense_requests_db if er["id"] == expense_id), None)

    if not expense_request:
        raise HTTPException(status_code=404, detail="Expense request not found")

    # Update the status
    expense_request["status"] = new_status

    return {"message": f"Expense request {expense_id} status updated to {new_status}"}