import os
import json
import subprocess
import yaml
import postgres
import logging
import paramiko
from utils import host

logger = logging.getLogger(__name__)

# Import data from the files containing host names. 
# Returns hostnames as a List.
def load_hosts(files):
    hosts = []
    try:
        for file in files:
            with open(file, 'r') as f:
                for line in f:
                    hosts.append(line.rstrip('\n'))
        return hosts
    except Exception as error:
        logger.error("{}".format(error))
        return 1

# Check if the host is online. 
# Returns True or False.
def is_online(host):
    try:
        subprocess.check_output(["ping", "-c", "1", host])
        return True
    except subprocess.CalledProcessError as error:
        logger.error(f"could not connect to server: {host}. Error: {error}")
        return False

# Extract given type (Install or Available) of Yum commands from the data. 
# Returns a list of software:command key/value pairs.
def get_commands(data, command_type):
    output = []
    for item in data['software']:
        if item['Enabled'] != True:
            continue
        software = item['name']
        command = item[command_type] 
        output.append({"software" : software, "command" : command})
    return output
    
# Runs the given set of commands on the target server.
# Returns a list of software:version key/value pairs.
def run_commands(server, yum_commands, username, rsa_file):
    ssh = key_based_connect(server, username, rsa_file)
    output = []
    for data in yum_commands:
        json_string = json.dumps(data)
        item = json.loads(json_string)
        stdin, stdout, stderr = ssh.exec_command(item["command"])
        version = (stdout.read().decode()).rstrip('\n')
        error = stderr.read().decode()        
        if error:
            logger.error(f'Error while running command. Server: {server}, Software: {item["software"]}, Command: {item["command"][4:18]}, Error: {error}')
        else:
            if version:
                output.append({"software" : item["software"] + "_version", "version" : version})
    ssh.close()
    return output

# Runs all the Yum Instlled commands against all the given servers.
# Returns a list of json objects, each containing server name, online status flag and a list of {software name:installed version} for each installed software.
def get_install_versions(servers, commands, username, rsa_file):
    install_versions = []
    for server in servers:
        logger.info(f"running yum install commands on: {server}")
        online = False
        versions = []
        if is_online(server):
            online = True 
            versions = run_commands(server, commands, username, rsa_file)
        install_versions.append({"server": server, "online": online, "versions": versions})        
    return install_versions
    
# Runs all the Yum Available commands against all the given servers.
# Returns a list of json objects, each containing server name, online status flag and a list of {software:available version} for each installed software.
def get_available_versions(installed_versions, available_commands, username, rsa_file):
    available_versions = []    
    for item in installed_versions:
        versions = []
        if item['online']:
            logger.info(f"running yum available commands on: {item['server']}")
            commands = []          
            # first let's get the yum available commands for all the softwares installed on the server:
            for software in item['versions']:
                for avl_command in available_commands:
                    if avl_command['software'] == software['software'].replace("_version", ""):
                        commands.append(avl_command)
            # now let's run the available commands against the server to get the available patch for each installed software:
            versions = run_commands(item['server'], commands, username, rsa_file)
        available_versions.append({"server" : item['server'], "online": item['online'], "versions" : versions})
    return available_versions

# Main funcion to validate installed or available versions of softwares against the target configuration
# Returns a list of {servername, online status flag, list of {software name, desired verison, actual version}}
def validate_patching(
    mode: str,
    username: str,
    rsa_file: str,
    host_files: list[str] = ['../ansible/inventories/hosts_primary', '../ansible/inventories/hosts_secondary', '../ansible/inventories/hosts_tertiary'],
    yum_commands_file: str = '../config/software_config_file.json',
    target_versions_file: str = '../ansible/inventories/group_vars/all.yml'
    ):
    """
    Depending upon the mode, return available or installed patch versions of all the softwares on all the target hosts.

    Args:
        mode: Mandatory, valid values are "pre" and "post".
        username: Mandatory, username to be used to connect to the hosts.
        rsa_file: Mandatory, the RSA private key file to be used to authenticate the given username.
        host_files: Optional, the path and names of the files containing target host names.
        yum_commands_file: Optional, path and name of the file that contains the Yum installed/Available commands for softwares.
        target_versions_file: Optional, path and name of the file containing target versions for all the softwares.
    
    Returns:
        List of dictionary objects each containing server and versions of all the softwares installed on it.
    """
    mode = mode.lower()
    if mode not in ('pre', 'post'):
        logger.error('Invalid value for "mode" parameter. must be "pre" or "post".')
        return 1
    logger.info('Loading host files...')    
    servers = load_hosts(host_files)
    logger.info('Loading target_versions_file ...')
    with open(target_versions_file, 'r') as file:
        target_versions = yaml.safe_load(file)
    logger.info('Loading yum_commands_file...')
    with open(yum_commands_file, 'r') as file:
        commands_data = json.load(file)
    install_commands = get_commands(commands_data, "install_command")
    installed_versions = get_install_versions(servers, install_commands, username, rsa_file)
    if mode == 'pre':
        available_commands = get_commands(commands_data, "list_command")
        available_versions = get_available_versions(installed_versions, available_commands, username, rsa_file)
        yum_output = available_versions
    else:
        yum_output = installed_versions
    output = []
    for server in servers:
        for item in yum_output:
            if item['server'] != server:
                continue
            online = item['online']
            versions = []
            if item['online']:                
                if item['versions']:                    
                    for software_version in item['versions']:                    
                        for key, value in target_versions.items():
                            if software_version["software"] == key:
                                software = key.replace("_version", "")
                                desired_version = value
                                actual_version = software_version['version']
                                versions.append({"software" : software, "desired_version" : desired_version, "actual_version" : actual_version})
        output.append({"server" : server, "online" : online, "versions" : versions})
    return output
# End of the script #
