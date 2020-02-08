#!/usr/bin/python3

import sys, argparse, os, yaml, requests, getpass
import simplejson as json



def http_get_json(location, json_data):
    """Performs a GET with input data to the URL location."""
    try:
        result = requests.get(
            location,
            data=json_data,
            auth=(foremanUsername, foremanPassword),
            verify=True,
            headers={'content-type': 'application/json'})
    except requests.exceptions.RequestException as e:
        print(e, file=sys.stderr)
        sys.exit(1)
    return result.json()


def get_hosts(foremanFilter):
    """Query Foreman for all hosts matching query"""
    hosts = http_get_json(
        foremanUrl + "hosts/",
        json.dumps(
            {
                "per_page": "1000",
                "search": foremanFilter,
            }
            )
        )

    # Build and return a list of hostnames
    hostlist = []
    try:
        for hostname in hosts['results']:
            hostlist.append(hostname['name'] + ':9100')
    except:
        print("Foreman Error - verify credentials and search filter terms", file=sys.stderr)
        sys.exit(1)
    return hostlist


def build_yaml(hostlist,label,tgtfile):
    """Builds Prometheus file_sd yaml file"""
    config = [
        {
        "targets": hostlist,
        "labels": {
            "job": label
        }
        }
    ]
    x = yaml.dump(config, sort_keys=False)
    print(x)

    f = open(tgtfile, "w")
    f.write(x)
    f.close()


def main(args):
    """Main Routine"""
    #pylint: disable-msg=R0912,R0914,R0915

    global foremanUrl, foremanUsername, foremanPassword

    # Check for sane input
    parser = argparse.ArgumentParser(description='Prometheus Foreman Service Discovery.')
    # pylint: disable=bad-continuation
    parser.add_argument('-f', '--foreman', help='Foreman FQDN', required=True)
    parser.add_argument('-u', '--username', help='Foreman Username', required=False)
    parser.add_argument('-p', '--password', help='Foreman Password', required=True)
    parser.add_argument('-s', '--search', help='Foreman Host Search String', required=False)
    parser.add_argument('-d', '--directory', help='Prometheus Node Exporter config directory', required=False)
    parser.add_argument('-l', '--label', help='Prometheus Node Exporter Label to apply', required=False)
    args = parser.parse_args()

    # Use default values if overriding params are not specified
    foremanFilter = 'domain = core.home.gatwards.org' if not args.search else args.search
    nodeExporterDir = '/etc/prometheus/nodeexporter' if not args.directory else args.directory
    nodeExporterLabel= 'node' if not args.label else args.label
    foremanUsername = 'admin' if not args.username else args.username

    if (args.password == ''):
        foremanPassword = getpass.getpass(prompt='Foreman Password: ')
    else:
        foremanPassword = args.password

    # Build internal vars from provided input
    foremanUrl = args.foreman + '/api/v2/'
    nodeExporterTargets = nodeExporterDir + '/foreman_' + nodeExporterLabel + '_targets.yml'

    # Do the work...
    hostlist = get_hosts(foremanFilter)
    build_yaml(hostlist,nodeExporterLabel,nodeExporterTargets)



if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except KeyboardInterrupt:
        print("\n\nExiting on user cancel.", file=sys.stderr)
        sys.exit(1)
