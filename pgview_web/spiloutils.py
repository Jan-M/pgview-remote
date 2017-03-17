import datetime
import logging
import time
from urllib.parse import urljoin

import requests

from .utils import get_short_error_message

logger = logging.getLogger(__name__)

session = requests.Session()

def request(cluster, path, **kwargs):
    if 'timeout' not in kwargs:
        # sane default timeout
        kwargs['timeout'] = (5, 15)
    if cluster.cert_file and cluster.key_file:
        kwargs['cert'] = (cluster.cert_file, cluster.key_file)
    return session.get(urljoin(cluster.api_server_url, path), auth=cluster.auth, verify=cluster.ssl_ca_cert, **kwargs)


def read_pods(cluster, namespace, spilo_cluster):
    r = request(cluster, "/api/v1/namespaces/{}/pods?labelSelector=spilo-cluster%3D{}".format(namespace, spilo_cluster))
    if r.status_code != 200:
        return False
    return r.json()

def read_statefulsets(cluster, namespace):
    r = request(cluster, "/apis/apps/v1beta1/namespaces/{}/statefulsets?labelSelector=application%3Dspilo".format(namespace))
    if r.status_code != 200:
        return False
    return r.json()

def parse_time(s: str):
    return datetime.datetime.strptime(s, '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=datetime.timezone.utc).timestamp()

