import os
import json
import subprocess
import yaml

def load_yaml(file_path):
    with open(file_path, 'r') as file:
        return yaml.safe_load(file)

def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

def is_server_online(server):
    try:
        response = subprocess.run(['ping', '-c', '1', server], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return response.returncode == 0
    except Exception as e:
        print(f"Error checking server status: {e}")
        return False

def run_command(server, command):
    try:
        result = subprocess.run(['ssh', server, command], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return result.stdout.decode('utf-8').strip()
    except Exception as e:
        print(f"Error running command on server {server}: {e}")
        return None

def validate_servers(mode):
    if mode not in ['pre', 'post']:
        raise ValueError("Invalid mode. Use 'pre' or 'post'.")

    servers = []
    servers += load_yaml('host_primary.yml')
    servers += load_yaml('host_secondary.yml')
    servers += load_yaml('host_tertiary.yml')

    target_patches = load_yaml('all.yml')
    yum_commands = load_json('software_config_file.json')
    
    all_servers = []

    for server in servers:
        server_status = {
            'Server': server,
            'IsOnline': False,
            'TargetPatches': {},
            'AvailablePatches': {},
            'InstalledPatches': {},
            'ServiceStatus': {},
            'VersionStatus': {}
        }

        if is_server_online(server):
            server_status['IsOnline'] = True
            available_patches = {}
            installed_patches = {}

            for software in yum_commands:
                if not yum_commands[software]['Enabled']:
                    continue
                
                if mode == 'pre':
                    command = yum_commands[software]['list_command']
                    version = run_command(server, command)
                    if version:
                        available_patches[software] = version

                elif mode == 'post':
                    command = yum_commands[software]['install_command']
                    version = run_command(server, command)
                    if version:
                        installed_patches[software] = version
                        # Check if the service is online (assuming a service command is available)
                        service_command = f"systemctl is-active {software}.service"
                        service_status = run_command(server, service_command)
                        server_status['ServiceStatus'][software] = (service_status == 'active')
            
            server_status['AvailablePatches'] = available_patches
            server_status['InstalledPatches'] = installed_patches

            for software, target_version in target_patches.items():
                if mode == 'pre':
                    if software in available_patches:
                        server_status['VersionStatus'][software] = (available_patches[software] >= target_version)
                elif mode == 'post':
                    if software in installed_patches:
                        server_status['VersionStatus'][software] = (installed_patches[software] == target_version)
                        if software in server_status['ServiceStatus']:
                            server_status['VersionStatus'][software] = server_status['VersionStatus'][software] and server_status['ServiceStatus'][software]
        
        all_servers.append(server_status)
    
    return all_servers

# Example usage:
mode = 'pre'  # or 'post'
validation_results = validate_servers(mode)
print(validation_results)
