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


# Mock database to store leave requests
leave_requests_db = [
    {
        "id": "1",
        "employeeName": "John Doe",
        "employeeId": "123",
        "startDate": "2023-10-01",
        "endDate": "2023-10-05",
        "leaveType": "Sick Leave",
        "status": "Pending"
    },
    {
        "id": "2",
        "employeeName": "Jane Smith",
        "employeeId": "456",
        "startDate": "2023-10-10",
        "endDate": "2023-10-12",
        "leaveType": "Vacation",
        "status": "Pending"
    }
]

# Pydantic model for leave request
class LeaveRequest(BaseModel):
    id: str
    employeeName: str
    employeeId: str
    startDate: str
    endDate: str
    leaveType: str
    status: str

# Pydantic model for updating leave status
class UpdateLeaveStatus(BaseModel):
    leaveId: str
    status: str

# API to fetch all leave requests
@app.get("/api/leave-requests", response_model=List[LeaveRequest])
def get_leave_requests():
    return leave_requests_db

# API to update leave status
@app.post("/api/update-leave-status")
def update_leave_status(request: UpdateLeaveStatus):
    leave_id = request.leaveId
    new_status = request.status

    # Find the leave request in the database
    leave_request = next((lr for lr in leave_requests_db if lr["id"] == leave_id), None)

    if not leave_request:
        raise HTTPException(status_code=404, detail="Leave request not found")

    # Update the status
    leave_request["status"] = new_status

    return {"message": f"Leave request {leave_id} status updated to {new_status}"}