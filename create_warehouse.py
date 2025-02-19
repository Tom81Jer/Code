
import requests
import base64
import getpass
import json

def create_warehouse(kp_db, kp_key_file, kp_title):
    
    """
    Returns Keypass info for a title

    Args:   
    kp_db - path to database and db name with extension
    kp_key_file - path to key file and key file name and extension
    kp_title - title of entry you are retrieving info for

    Parameters:
    kp_db - "\\\\smof-fs01p\\techapps\\TECHNOLOGY\\PS_KP\\GDS\\GDS_SecretVault.kdbx"
    kp_key_file - "\\\\dimensional.com\\dfaapps$\\Technology\\DataServices\\DS_EncryptionKeys\\Secure\GDS_KeyFile.key"
    kp_title - , "dfa01-acct_0900_02"
    
    Example:
    result = get_kp_title_cred("\\\\smof-fs01p\\techapps\\TECHNOLOGY\\PS_KP\\GDS\\GDS_SecretVault.kdbx",
                                "\\\\dimensional.com\\dfaapps$\\Technology\\DataServices\\DS_EncryptionKeys\\Secure\GDS_KeyFile.key", "dfa01-acct_0900_02")
    print(result)
    
    Returns:
        Dictionary:
        {
            'username': username,
            'password': password,
            'url': url
        }
        or
        1 for failure
    """
      # configure logging
    # try:
    #     setup_logging("c:\\temp\\")
    # except Exception as e:
    #     logging.exception("An error occurred in configuring logging")
    #     return 1
    logger = logging.getLogger(__name__)
    
    # Log the parameters passed in
    logger.info('****************************Variables passed****************************')
    logger.info('database: {}'.format(kp_db))
    logger.info('key file: {}'.format(kp_key_file))
    logger.info('title: {}'.format(kp_title))
    logger.info('************************************************************************')

user =  "Gunvant.Patil@dimensional.com"
#user =  "GPatildsa1@dimensional.com"
pwd = getpass.getpass("Enter your password: ")
bearer_token = (base64.b64encode(f"{user}:{pwd}".encode("ascii")).decode("ascii"))
#okta_token = "eyJraWQiOiJ3bTZCY0JaQlhFckNNeGtvSDBjV1A4UUJ3NjJlS25TQU0wZlhBRXNtTUVRIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULlVESGNjSnZDNV9WRFgyempIdHdFWU1MTFA3RC1qSS1Cd2c1VWxpb1NpbkUiLCJpc3MiOiJodHRwczovL2RpbWVuc2lvbmFsLm9rdGEuY29tL29hdXRoMi9hdXNrcG80Ym1sdTB0aTY4RTM1NyIsImF1ZCI6IkVuZyBTdmNzIiwiaWF0IjoxNzM5Mzg5NDE5LCJleHAiOjE3MzkzOTMwMTksImNpZCI6IjBvYWtwbndlc2xUdHlQV0h6MzU3IiwidWlkIjoiMDB1MTRnb3h4Z3FkU2RKZzQzNTgiLCJzY3AiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIl0sImF1dGhfdGltZSI6MTczOTM4OTQxOCwiZHdzLWFwcC11c2VyIjpbIkRXU19BcHBfVXNlcnMiXSwic3ViIjoiR3VudmFudC5QYXRpbEBkaW1lbnNpb25hbC5jb20iLCJJVF9WQ1NfR2l0aHViIjpbIklUX1ZDU19HaXRodWIiXSwiZHdzLWRhdGFiYXNlLXVzZXIiOlsiRFdTX0RhdGFiYXNlX1VzZXJzIl0sImR3cy1zbm93Zmxha2UtYWRtaW4iOlsiRFdTX1Nub3dmbGFrZV9BZG1pbnMiXSwiZHdzLWRhdGFiYXNlLWFkbWluIjpbIkRXU19EYXRhYmFzZV9BZG1pbnMiXSwiZHdzLWNtZGItcmVhZGVyIjpbIlNRTF9QXzAxMDBfY21kYl9jbWRicmVhZGVyIl19.g6iDKfXbhaZvzGvHhiSrWI3AIdboTL1Mg6V8wR37OLlgwwAgHi78PWK_tQlOUREw4BGgvFDvqzNz-qYkYsWfmCbSoQwU0gKV_7pQ50PaTb_HGOmUJJ17ee6bY-aLajoZCii2VT9O9z5gmrs5GQplbFa8rYmOrZsItcL8CHHsp0QgDMxv1Z-D3MdLXh09QC0Ji0XTC5R2vKxFTJtBbNeOoapWg5rY-eDEHRgkEWQcWX1yhW9IYms8p4UOSaR7XXTaPNIWsNWY3tSV7NTaBapEfBa26GiYH5YSodL5uJ86qfh5lZi7DQXaEqPGTW-5ixpeSvGJ0zeS33ULFPGgjK6Shg"
headers = {"Authorization": f"Basic {bearer_token}", "Content-Type": "application/json"}
#headers = {"okta-access-token" : okta_token, "Content-Type": "application/json"}
url = 'https://dws.dimensional.com/api/snowflake/warehouse/'
data = {"departmentUnitCode" : "0300",
        "environment" : "DEV",
        "size" : "XS",
        "userAccount" : "CStone"
       }
# Send the POST request
try:
    response  = requests.post(url = url, data = json.dumps(data), headers = headers)

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