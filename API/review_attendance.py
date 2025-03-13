from fastapi import FastAPI, Query
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional
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

# Dummy data class for the attendance data
class AttendanceDetails(BaseModel):
    inTime: str
    outTime: str
    timestamp: str

class AttendanceResponse(BaseModel):
    employeeId: str
    date: str
    details: AttendanceDetails

# Dummy data for employees
attendance_data = [
    {
        "employeeId": "E001",
        "date": "2025-03-11",
        "details": {
            "inTime": "09:00 AM",
            "outTime": "05:00 PM",
            "timestamp": "2025-03-11 09:00:00"
        }
    },
    {
        "employeeId": "E002",
        "date": "2025-03-11",
        "details": {
            "inTime": "08:30 AM",
            "outTime": "04:30 PM",
            "timestamp": "2025-03-11 08:30:00"
        }
    },
    {
        "employeeId": "E003",
        "date": "2025-03-11",
        "details": {
            "inTime": "09:15 AM",
            "outTime": "05:15 PM",
            "timestamp": "2025-03-11 09:15:00"
        }
    },
    {
        "employeeId": "E001",
        "date": "2025-03-12",
        "details": {
            "inTime": "09:00 AM",
            "outTime": "05:00 PM",
            "timestamp": "2025-03-12 09:00:00"
        }
    },
    {
        "employeeId": "E002",
        "date": "2025-03-12",
        "details": {
            "inTime": "08:30 AM",
            "outTime": "04:30 PM",
            "timestamp": "2025-03-12 08:30:00"
        }
    }
]

# Dummy API to fetch attendance data with optional date and employeeId
@app.get("/attendance", response_model=List[AttendanceResponse])
async def get_attendance(
    date: Optional[str] = Query(None, description="Filter by date (YYYY-MM-DD)"),
    employeeId: Optional[str] = Query(None, description="Filter by employee ID")
):
    # Filter the attendance data based on the provided parameters
    filtered_data = attendance_data

    if date:
        filtered_data = [record for record in filtered_data if record["date"] == date]

    if employeeId:
        filtered_data = [record for record in filtered_data if record["employeeId"] == employeeId]

    return filtered_data

# Start FastAPI server using the command: uvicorn main:app --reload