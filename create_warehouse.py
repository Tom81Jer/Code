
import requests
import json
import base64
import getpass

def create_warehouse(requester_id=None, okta_token=None, department_unit_code=None, environment=None, size="XS", target_user_account=None):
    # Validate required parameters
    if not (requester_id or okta_token):
        raise ValueError("Either requester_id or okta_token must be provided.")
    if not department_unit_code or not environment or not target_user_account:
        raise ValueError("department_unit_code, environment, and target_user_account are required.")
    
    # Validate requester_id format
    if requester_id and not requester_id.endswith("@dimensional.com"):
        raise ValueError("requester_id must end with '@dimensional.com'.")
    
    # Validate environment
    if environment not in ["DEV", "STG", "PRD"]:
        raise ValueError("environment must be one of DEV, STG, or PRD.")
    
    # Validate size
    valid_sizes = ["XS", "S", "M", "L", "XL", "2XL", "3XL", "4XL"]
    if size not in valid_sizes:
        raise ValueError(f"size must be one of {valid_sizes}.")
    
    # Convert department_unit_code to string with leading zero
    department_unit_code_str = f"{int(department_unit_code):03d}"
    
    # Prepare headers
    headers = {}
    if okta_token:
        headers = {"okta-access-token": okta_token, "Content-Type": "application/json"}
    else:
        # Prompt for password securely
        password = getpass.getpass("Enter your password: ")
        # Create bearer token
        bearer_token = base64.b64encode(f"{requester_id}:{password}".encode("ascii")).decode("ascii")
        headers = {"Authorization": f"Basic {bearer_token}", "Content-Type": "application/json"}
    
    # Prepare data
    data = {
        "departmentUnitCode": department_unit_code_str,
        "environment": environment,
        "size": size,
        "userAccount": target_user_account
    }
    
    # API URL
    url = "https://dws.dimensional.com/api/snowflake/warehouse/"
    
    # Send the POST request
    try:
        response = requests.post(url=url, data=json.dumps(data), headers=headers)
        
        # Check the response status code
        if response.status_code == 200:
            # Request was successful
            print("Request successful!")
            print("Response:", response.json())
        else:
            # Request failed
            print(f"Request failed with status code {response.status_code}")
            print("Response:", response.text)
    except requests.exceptions.RequestException as e:
        # Handle network errors
        print(f"An error occurred: {e}")

# Example usage:
# create_warehouse(requester_id="user@dimensional.com", department_unit_code=300, environment="DEV", size="M", target_user_account="user123")
# create_warehouse(okta_token="your_okta_token", department_unit_code=300, environment="DEV", size="M", target_user_account="user123")
