from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.responses import JSONResponse
import os
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


# Define a model for the user data
class User(BaseModel):
    name: str
    image: str  # URL or relative path to the image
    designation: str

# Example user data
user_data = {
    "name": "Ikhtiar Uddin Mohammad Bin Bokhtiar Kholji",
    "image": "https://media.istockphoto.com/id/130407085/photo/politician-reading-in-backseat-of-car.webp?s=612x612&w=is&k=20&c=XLmuSYnFVuJL_XizsD1ZQlIYEjGEyPn3ProUDgxgUys=",  # Replace with the correct URL
    "designation": "admin"
}

# Endpoint to return user data
@app.get("/get-user-data", response_model=User)
async def get_user_data():
    return user_data


