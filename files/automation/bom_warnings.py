#!/usr/bin/python3
# -*- coding: utf-8 -*-

import paho.mqtt.client as mqtt
import xml.etree.ElementTree as xml
import atexit, logging, requests, socket, sys, os
import datetime, ftplib, tempfile, yaml

from urllib.parse import urlparse
from time import sleep
from apscheduler.schedulers.background import BackgroundScheduler

# Load config file
filename = '/usr/local/etc/bomxml2mqtt.yml'
try:
    CONFIG = yaml.safe_load(open(filename, 'r'))
except IOError:
    print("Please create a config file at %s." % filename)
    sys.exit(1)

BROKER = CONFIG['mqtt']['broker_fqdn']
USERNAME = CONFIG['mqtt']['broker_username']
PASSWORD = CONFIG['mqtt']['broker_password']
URL = CONFIG['forecast']['url']
TOPIC = CONFIG['forecast']['mqtt_topic']


# request properties
bomuri = URL
xmlfile = '/tmp/xmlfile.xml'

# MQTT connection properties
broker = BROKER
port = 1883
username = USERNAME
password = PASSWORD
topic = TOPIC

# logging properties
logfile = '/var/log/bomxml.log'
loglevel = 'DEBUG'
logformat = '%(asctime)-15s %(levelname)-5s [%(module)s] %(message)s'

# initialise logging
logging.basicConfig(filename=logfile, level=loglevel, format=logformat)
logging.info("Starting BoM XML monitor")
logging.info("INFO MODE")
logging.debug("DEBUG MODE")

# initialise MQTT broker connection
mqttc = mqtt.Client('bomxml')
mqttc.connected_flag=False


# initialise scheduler
sched = BackgroundScheduler()
sched.start()
atexit.register(lambda: sched.shutdown(wait=False))

def on_connect(client, userdata, flags, rc):
    if (rc == 0):
        logging.debug("Successfully connected to MQTT broker")
        mqttc.connected_flag=True
    elif (rc == 1):
        logging.info("Connection refused - unacceptable protocol version")
    elif (rc == 2):
        logging.info("Connection refused - identifier rejected")
    elif (rc == 3):
        logging.info("Connection refused - server unavailable")
    elif (rc == 4):
        logging.info("Connection refused - bad user name or password")
    elif (rc == 5):
        logging.info("Connection refused - not authorised")
    else:
        logging.warning("Connection failed - result code %d" % (rc))

def on_disconnect(mosq, userdata, result_code):
    if result_code == 0:
        logging.info("Clean disconnection from MQTT broker")
    else:
        logging.info("Connection to MQTT broker lost. Will attempt to reconnect in 5s...")
        sleep(5)

def connect_mqtt():
    logging.debug("Attempting connection to MQTT broker %s:%d..." % (broker, port))
    mqttc.on_connect = on_connect
    mqttc.on_disconnect = on_disconnect
    mqttc.username_pw_set(username, password)
    try:
        mqttc.connect(broker, port, 60)
        mqttc.loop_start()
        while not mqttc.connected_flag:
            sleep(1)
    except Exception as e:
        logging.error("Cannot connect to MQTT broker at %s:%d: %s" % (broker, port, str(e)))
        sys.exit(2)

#    while True:
#        try:
#            mqttc.loop_forever()
#        except socket.error:
#            logging.info("MQTT server disconnected. Sleeping...")
#            sleep(5)
#        except:
#            break

def publish_data(name, data):
    # send update to our MQTT topic
    mqttc.publish(topic + name, str(data), qos=0, retain=True)


def get_ftp(uri):
    # Break apart the URI
    parts = urlparse(uri)
    netloc = parts[1]                         # FQDN
    bompath = parts[2].rsplit('/', 1)[0]      # Path
    bomfile = parts[2].rsplit('/', 1)[-1]     # File

    # Create a tempfile to hold the local copy
#    xmlfile, filename = tempfile.mkstemp()

    # We need to download the source via FTP...
    ftp = ftplib.FTP(netloc)
    ftp.login("Anonymous", "Anonymous")
    ftp.cwd(bompath)
    try:
        ftp.retrbinary("RETR " + bomfile ,open(xmlfile, 'wb').write)
        return filename
    except:
        logging.error("Error retrieving input file: %s" % bomfile)
        return


def request_xml(xmlfile):
    tree = xml.parse(xmlfile)
    root = tree.getroot()

    os.remove(xmlfile)
    return root


def request_data():

    today = datetime.datetime.today()
    tomorrow = today + datetime.timedelta(1)
    today = datetime.datetime.strftime(today,'%Y/%m/%d')
    tomorrow = datetime.datetime.strftime(tomorrow,'%Y/%m/%d')

    get_ftp(bomuri)

    root = request_xml(xmlfile)

    if root is None:
        logging.warn("Request for xml returned nothing, skipping")
        return

    for child in root:
        if (child.tag == 'forecast'):
            for sub in child:
                if (sub.attrib['description'] == 'Queanbeyan'):
                    for day in sub:
                        if (day.attrib['index'] == '0'):
                            forecast_max_today = "NA"
                            forecast_min_today = "NA"
                            for element in day:
                                if (element.attrib['type'] == 'precis'):
                                    forecast_text_today = element.text[:-1]
                                if (element.attrib['type'] == 'air_temperature_maximum'):
                                    forecast_max_today = element.text
                                if (element.attrib['type'] == 'air_temperature_minimum'):
                                    forecast_min_today = element.text
                            publish_data('forecast_today', forecast_text_today)
                            publish_data('forecast_today_max', forecast_max_today)
                            publish_data('forecast_today_min', forecast_min_today)
#                            print forecast_text_today
#                            print forecast_max_today
#                            print forecast_min_today

                        if (day.attrib['index'] == '1'):
                            for element in day:
                                if (element.attrib['type'] == 'precis'):
                                    forecast_text_tomorrow = element.text[:-1]
                                if (element.attrib['type'] == 'air_temperature_maximum'):
                                    forecast_max_tomorrow = element.text
                                if (element.attrib['type'] == 'air_temperature_minimum'):
                                    forecast_min_tonight = element.text
                            publish_data('forecast_tomorrow', forecast_text_tomorrow)
                            publish_data('forecast_tomorrow_max', forecast_max_tomorrow)
                            publish_data('forecast_tonight_min', forecast_min_tonight)
#                            print forecast_text_tomorrow
#                            print forecast_max_tomorrow
#                            print forecast_min_tonight



if __name__ == "__main__":

#    sched.add_job(request_data, 'interval', minutes=5)
    connect_mqtt()
    request_data()
