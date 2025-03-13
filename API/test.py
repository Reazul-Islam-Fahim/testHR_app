from fastapi import FastAPI
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



# Dummy Leave Data Model
class LeaveData(BaseModel):
    leaveType: str
    totalLeave: int
    availed: int
    balance: int

# Dummy data to simulate leave data
dummy_leave_data = [
    LeaveData(leaveType="Sick Leave", totalLeave=10, availed=5, balance=5),
    LeaveData(leaveType="Casual Leave", totalLeave=12, availed=12, balance=0),
    LeaveData(leaveType="Paid Leave", totalLeave=15, availed=5, balance=10),
]

@app.get("/api/leave-data", response_model=List[LeaveData])
async def get_leave_data():
    # Return the dummy leave data
    return dummy_leave_data
